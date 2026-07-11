import type { Sighting } from "./types";
import { DAY_LABELS, dayOfWeek, hourLabel, hourOfDay, predictZone } from "./fingerprint";
import { type Confidence, confidenceFromLowerBound, recencyWeight, wilsonLowerBound } from "./confidence";
import { nearestLandmark } from "./zoneLandmarks";

export interface InsightDebug {
  /** Raw (unweighted) number of sightings backing this claim. */
  sampleSize: number;
  /** Recency-weighted total, when this insight uses weighted tallying. */
  weightedSampleSize?: number;
  observedSharePct?: number;
  confidenceLowerBoundPct?: number;
  confidence?: Confidence;
  /** Free-form method note - which technique/threshold decided this. */
  note?: string;
}

export interface Insight {
  kind: "prediction" | "pattern" | "caveat";
  text: string;
  debug: InsightDebug;
}

// Pluralizing the 3-letter DAY_LABELS abbreviations reads badly ("Thus",
// "Suns", "Sats") - a recurring-day sentence ("most active on ___s") needs
// the full name instead, which pluralizes cleanly with a plain +s.
const DAY_LABELS_FULL = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

// Below this many total sightings, every insight below gets skipped rather
// than dressing up a handful of data points as a confident pattern.
const MIN_SAMPLE = 5;

// A single shared bar for "is this share of the data strong enough to say
// out loud at all" - the Wilson lower bound (see confidence.ts) of the
// claimed proportion has to clear this before an insight fires. Chosen to
// match confidenceFromLowerBound's "moderate" tier, so nothing below
// moderate confidence ever gets stated as a pattern.
const MIN_CONFIDENCE_LOWER_BOUND = 0.25;

// Well-established TBC Classic facts about what each zone is *for* (raid/
// dungeon entrances, world PvP objectives, daily hubs) - not derived from
// this app's own data, just static context. Paired with a named-landmark
// call-out below (see zoneLandmarks.ts) when the subject's positions cluster
// tightly enough to name a specific spot rather than just the zone.
const ZONE_HINTS: Record<string, string> = {
  "Hellfire Peninsula":
    "home to the Dark Portal and the Hellfire Ramparts/Blood Furnace/Shattered Halls instances - could be questing, farming, or camping the portal",
  Zangarmarsh:
    "home to the Coilfang Reservoir instances (Underbog/Slave Pens/Steamvault/Serpentshrine Cavern) - could be farming or running instances",
  "Terokkar Forest":
    "home to the Auchindoun instance complex and the Skettis dailies - could be questing or running instances",
  Nagrand: "home to Halaa (the contested world PvP objective) and the Ogri'la dailies - activity here often means world PvP or dailies",
  Netherstorm:
    "home to the Tempest Keep raid/heroics (The Eye/Botanica/Mechanar/Arcatraz) and Area 52 - could be raiding, running heroics, or dailies",
  "Shadowmoon Valley": "home to the Black Temple raid and the Wrath Gate area - could be raiding or questing",
};

function plural(n: number, noun = "sighting"): string {
  return `${n} ${noun}${n === 1 ? "" : "s"}`;
}

function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

/** Recency-weighted tally of some key extracted from each sighting -
 * shared building block for every insight below except the raw descriptive
 * charts (Top zones / hour histogram / heatmap), which intentionally stay
 * unweighted since they're presented as historical record, not prediction. */
function weightedTally<T extends string>(sightings: Sighting[], now: number, keyFn: (s: Sighting) => T | undefined) {
  const weights = new Map<T, number>();
  let total = 0;
  for (const s of sightings) {
    const key = keyFn(s);
    if (key === undefined) continue;
    const w = recencyWeight(s.ts, now);
    weights.set(key, (weights.get(key) ?? 0) + w);
    total += w;
  }
  const sorted = Array.from(weights.entries()).sort((a, b) => b[1] - a[1]);
  return { sorted, total };
}

// Smallest contiguous local-hour window (wrapping past midnight) that
// covers a clear majority of the subject's sightings - "most active
// between 7pm and 9pm" reads better and is more honest than just naming
// the single busiest hour, which can look precise while actually resting
// on one or two lucky bucket boundaries.
function findPeakWindow(
  weightedHist: number[],
  totalWeight: number,
): { startHour: number; endHour: number; sharePct: number; lowerBoundPct: number } | null {
  if (totalWeight <= 0) return null;
  for (let len = 2; len <= 8; len++) {
    let bestSum = -1;
    let bestStart = 0;
    for (let start = 0; start < 24; start++) {
      let sum = 0;
      for (let i = 0; i < len; i++) sum += weightedHist[(start + i) % 24];
      if (sum > bestSum) {
        bestSum = sum;
        bestStart = start;
      }
    }
    const lowerBound = wilsonLowerBound(bestSum, totalWeight);
    if (lowerBound >= MIN_CONFIDENCE_LOWER_BOUND) {
      return {
        startHour: bestStart,
        endHour: (bestStart + len) % 24,
        sharePct: Math.round((bestSum / totalWeight) * 100),
        lowerBoundPct: Math.round(lowerBound * 100),
      };
    }
  }
  return null;
}

function buildTimeOfDayInsight(sightings: Sighting[], now: number): Insight | null {
  const weightedHist = new Array(24).fill(0) as number[];
  let totalWeight = 0;
  for (const s of sightings) {
    const w = recencyWeight(s.ts, now);
    weightedHist[hourOfDay(s.ts)] += w;
    totalWeight += w;
  }
  const window = findPeakWindow(weightedHist, totalWeight);
  if (!window) return null;
  return {
    kind: "pattern",
    text: `Most active between ${hourLabel(window.startHour)} and ${hourLabel(window.endHour)} (${window.sharePct}% of sightings).`,
    debug: {
      sampleSize: sightings.length,
      weightedSampleSize: round1(totalWeight),
      observedSharePct: window.sharePct,
      confidenceLowerBoundPct: window.lowerBoundPct,
      confidence: confidenceFromLowerBound(window.lowerBoundPct / 100),
      note: `sliding 2-8hr window, recency-weighted (14-day half-life)`,
    },
  };
}

function buildZoneAffinityInsight(sightings: Sighting[], now: number): Insight | null {
  const { sorted: zoneSorted, total: zoneTotal } = weightedTally(sightings, now, (s) => s.zone);
  if (zoneSorted.length === 0) return null;
  const [zone, zoneWeight] = zoneSorted[0];
  const zoneLowerBound = wilsonLowerBound(zoneWeight, zoneTotal);
  if (zoneLowerBound < MIN_CONFIDENCE_LOWER_BOUND) return null;
  const pct = Math.round((zoneWeight / zoneTotal) * 100);
  const hint = ZONE_HINTS[zone];

  // Which named, real-coordinate landmark (see zoneLandmarks.ts) do their
  // positions within this zone cluster nearest to most often?
  const zoneSightings = sightings.filter((s) => s.zone === zone && s.mapX !== undefined && s.mapY !== undefined);
  const { sorted: landmarkSorted, total: landmarkTotal } = weightedTally(zoneSightings, now, (s) => {
    const landmark = nearestLandmark(zone, s.mapX!, s.mapY!);
    return landmark?.name;
  });
  const topLandmark = landmarkSorted[0];
  const landmarkLowerBound = topLandmark ? wilsonLowerBound(topLandmark[1], landmarkTotal) : 0;

  const debug: InsightDebug = {
    sampleSize: sightings.length,
    weightedSampleSize: round1(zoneTotal),
    observedSharePct: pct,
    confidenceLowerBoundPct: Math.round(zoneLowerBound * 100),
    confidence: confidenceFromLowerBound(zoneLowerBound),
    note: "recency-weighted (14-day half-life)",
  };

  if (topLandmark && landmarkLowerBound >= MIN_CONFIDENCE_LOWER_BOUND) {
    const landmarkPct = Math.round((topLandmark[1] / landmarkTotal) * 100);
    return {
      kind: "pattern",
      text: `Spends ${pct}% of logged time in ${zone}, mostly near **${topLandmark[0]}** (${landmarkPct}% of their sightings there)${
        hint ? ` - ${hint}` : ""
      }.`,
      debug: {
        ...debug,
        note: `${debug.note}; landmark confidence lower bound ${Math.round(landmarkLowerBound * 100)}%`,
      },
    };
  }
  return {
    kind: "pattern",
    text: `Spends ${pct}% of logged time in ${zone}${hint ? ` - ${hint}` : ""}.`,
    debug,
  };
}

// A day-of-week that's both disproportionately active AND dominated by one
// zone (more than its overall share) reads like a standing appointment -
// a raid night, a dailies routine, whatever - rather than coincidence.
function buildScheduleInsight(sightings: Sighting[], subjectType: "player" | "guild", now: number): Insight | null {
  const { sorted: daySorted, total: dayTotal } = weightedTally(sightings, now, (s) => String(dayOfWeek(s.ts)));
  if (daySorted.length === 0) return null;
  const [peakDayStr, peakDayWeight] = daySorted[0];
  const peakDay = Number(peakDayStr);
  const peakDayLowerBound = wilsonLowerBound(peakDayWeight, dayTotal);
  if (peakDayLowerBound < MIN_CONFIDENCE_LOWER_BOUND) return null;
  const peakDayShare = peakDayWeight / dayTotal;

  const daySightings = sightings.filter((s) => dayOfWeek(s.ts) === peakDay);
  const { sorted: zoneInDaySorted, total: zoneInDayTotal } = weightedTally(daySightings, now, (s) => s.zone);
  if (zoneInDaySorted.length === 0) return null;
  const [zone, zoneInDayWeight] = zoneInDaySorted[0];
  const zoneInDayShare = zoneInDayWeight / zoneInDayTotal;
  const zoneInDayLowerBound = wilsonLowerBound(zoneInDayWeight, zoneInDayTotal);

  const { sorted: overallZoneSorted, total: overallZoneTotal } = weightedTally(sightings, now, (s) => s.zone);
  const overallZoneShare = (overallZoneSorted.find(([z]) => z === zone)?.[1] ?? 0) / overallZoneTotal;

  const clearsOwnBar = zoneInDayLowerBound >= MIN_CONFIDENCE_LOWER_BOUND;
  const clearsDeltaBar = zoneInDayShare - overallZoneShare >= 0.15;
  if (!clearsOwnBar && !clearsDeltaBar) return null;

  const subjectNoun = subjectType === "guild" ? "This guild" : "This player";
  const suffix = subjectType === "guild" ? "which may point to a scheduled raid or event time" : "possibly a regular routine";
  return {
    kind: "pattern",
    text: `${subjectNoun} is most active on ${DAY_LABELS_FULL[peakDay]}s in ${zone} (${Math.round(peakDayShare * 100)}% of sightings fall on that day) - ${suffix}.`,
    debug: {
      sampleSize: sightings.length,
      weightedSampleSize: round1(dayTotal),
      observedSharePct: Math.round(peakDayShare * 100),
      confidenceLowerBoundPct: Math.round(peakDayLowerBound * 100),
      confidence: confidenceFromLowerBound(peakDayLowerBound),
      note: `zone-in-day share ${Math.round(zoneInDayShare * 100)}% (lower bound ${Math.round(
        zoneInDayLowerBound * 100,
      )}%) vs overall zone share ${Math.round(overallZoneShare * 100)}%, recency-weighted`,
    },
  };
}

// Recent 7 days vs the 7 before that. Instead of a flat "must differ by
// >=25%" cutoff, uses a log-rate-ratio z-approximation (the standard
// lightweight test for comparing two counts, e.g. epidemiological rate
// ratios) - so a 150% swing between 2 and 5 sightings (easily noise) is
// correctly suppressed, while a 30% swing between 200 and 260 (backed by a
// much bigger sample) correctly fires.
function buildMomentumInsight(sightings: Sighting[]): Insight | null {
  const WEEK = 7 * 86400;
  const maxTs = Math.max(...sightings.map((s) => s.ts));
  const minTs = Math.min(...sightings.map((s) => s.ts));
  const recentStart = maxTs - WEEK;
  const priorStart = maxTs - 2 * WEEK;
  if (minTs > priorStart) return null;

  const recentCount = sightings.filter((s) => s.ts >= recentStart).length;
  const priorCount = sightings.filter((s) => s.ts >= priorStart && s.ts < recentStart).length;
  if (recentCount === 0 || priorCount === 0) return null;

  const logRatio = Math.log(recentCount / priorCount);
  const standardError = Math.sqrt(1 / recentCount + 1 / priorCount);
  const zScore = logRatio / standardError;
  if (Math.abs(zScore) < 1.5) return null;

  const pctChange = Math.round((Math.exp(logRatio) - 1) * 100);
  const dir = pctChange > 0 ? "up" : "down";
  return {
    kind: "pattern",
    text: `Sightings are ${dir} ${Math.abs(pctChange)}% over the last 7 days versus the week before (${recentCount} vs ${priorCount}).`,
    debug: {
      sampleSize: recentCount + priorCount,
      note: `log-rate-ratio z=${zScore.toFixed(2)} (needs |z|>=1.5)`,
      confidence: Math.abs(zScore) >= 2.5 ? "high" : "moderate",
    },
  };
}

function buildRightNowPrediction(sightings: Sighting[], now: number): Insight | null {
  const nowDate = new Date(now * 1000);
  const prediction = predictZone(sightings, nowDate.getDay(), nowDate.getHours(), now);
  if (!prediction) return null;

  let basis: string;
  if (prediction.basis === "day+hour") {
    basis = `based on ${plural(prediction.sampleSize)} seen on a ${DAY_LABELS[nowDate.getDay()]} around this time`;
  } else if (prediction.basis === "hour-only") {
    basis = `not enough ${DAY_LABELS[nowDate.getDay()]}-specific history yet - based on ${plural(prediction.sampleSize)} around this hour on any day`;
  } else {
    basis = `not enough time-of-day history yet - their overall most-sighted zone across ${plural(prediction.sampleSize)}`;
  }
  return {
    kind: "prediction",
    text: `Right now, most likely in **${prediction.zone}** - ${basis} (${prediction.confidence} confidence).`,
    debug: {
      sampleSize: prediction.sampleSize,
      observedSharePct: Math.round(prediction.weightedShare * 100),
      confidenceLowerBoundPct: prediction.confidenceLowerBoundPct,
      confidence: prediction.confidence,
      note: `tier: ${prediction.basis}${prediction.runnerUp ? `; runner-up ${prediction.runnerUp[0]} (weighted ${prediction.runnerUp[1]})` : ""}, recency-weighted (14-day half-life)`,
    },
  };
}

function buildReliabilityInsight(sightings: Sighting[]): Insight | null {
  const reporters = new Set(sightings.map((s) => s.reporter));
  if (reporters.size > 1) return null;
  const [only] = reporters;
  return {
    kind: "caveat",
    text: `Every sighting so far comes from a single reporter (${only}) - worth corroborating from another character before treating this as solid intel.`,
    debug: { sampleSize: sightings.length, note: "binary check, no confidence scoring applies" },
  };
}

/** Builds the "Trending Snapshot & Predictions" bullet list for one subject.
 * Every insight is a heuristic read of logged sightings - frequency,
 * recency-weighted co-occurrence, and Wilson-score confidence bounds, not a
 * trained model - and each one independently decides whether the data
 * backing it clears MIN_CONFIDENCE_LOWER_BOUND, skipping itself otherwise
 * rather than forcing a claim out of thin data. `now` is exposed for
 * testing; production callers should leave it as the real wall-clock
 * default so recency weighting and the "right now" prediction stay honest
 * against stale imports. */
export function buildInsights(sightings: Sighting[], subjectType: "player" | "guild", now: number = Date.now() / 1000): Insight[] {
  if (sightings.length < MIN_SAMPLE) return [];

  const insights: Insight[] = [];
  const rightNow = buildRightNowPrediction(sightings, now);
  if (rightNow) insights.push(rightNow);
  const timeOfDay = buildTimeOfDayInsight(sightings, now);
  if (timeOfDay) insights.push(timeOfDay);
  const zoneAffinity = buildZoneAffinityInsight(sightings, now);
  if (zoneAffinity) insights.push(zoneAffinity);
  const schedule = buildScheduleInsight(sightings, subjectType, now);
  if (schedule) insights.push(schedule);
  const momentum = buildMomentumInsight(sightings);
  if (momentum) insights.push(momentum);
  const reliability = buildReliabilityInsight(sightings);
  if (reliability) insights.push(reliability);
  return insights;
}
