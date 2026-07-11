import type { Sighting } from "./types";
import { DAY_LABELS, buildHourHistogram, dayOfWeek, hourLabel, predictZone, topZones } from "./fingerprint";

export interface Insight {
  kind: "prediction" | "pattern" | "caveat";
  text: string;
}

// Pluralizing the 3-letter DAY_LABELS abbreviations reads badly ("Thus",
// "Suns", "Sats") - a recurring-day sentence ("most active on ___s") needs
// the full name instead, which pluralizes cleanly with a plain +s.
const DAY_LABELS_FULL = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

// Below this many total sightings, every insight below gets skipped rather
// than dressing up a handful of data points as a confident pattern.
const MIN_SAMPLE = 5;

// Well-established TBC Classic facts about what each zone is *for* (raid/
// dungeon entrances, world PvP objectives, daily hubs) - not derived from
// this app's own data, just static context that turns "80% of sightings in
// Netherstorm" into something actually useful. Deliberately doesn't name
// specific in-zone coordinates/landmarks (Throne of Kil'jaeden, Halaa's
// exact position, etc) since we have no calibrated POI-coordinate data for
// those - only the zone-level image/world-anchor calibration from
// DATA_MODEL.md. Extend this table if more zone images get added.
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

// Smallest contiguous local-hour window (wrapping past midnight) that
// covers a clear majority of the subject's sightings - "most active
// between 7pm and 9pm" reads better and is more honest than just naming
// the single busiest hour, which can look precise while actually resting
// on one or two lucky bucket boundaries.
function findPeakWindow(hist: number[], total: number): { startHour: number; endHour: number; pct: number } | null {
  if (total === 0) return null;
  for (let len = 2; len <= 8; len++) {
    let bestSum = -1;
    let bestStart = 0;
    for (let start = 0; start < 24; start++) {
      let sum = 0;
      for (let i = 0; i < len; i++) sum += hist[(start + i) % 24];
      if (sum > bestSum) {
        bestSum = sum;
        bestStart = start;
      }
    }
    const pct = Math.round((bestSum / total) * 100);
    if (pct >= 45) {
      return { startHour: bestStart, endHour: (bestStart + len) % 24, pct };
    }
  }
  return null;
}

function buildTimeOfDayInsight(sightings: Sighting[]): Insight | null {
  const hist = buildHourHistogram(sightings);
  const window = findPeakWindow(hist, sightings.length);
  if (!window) return null;
  return {
    kind: "pattern",
    text: `Most active between ${hourLabel(window.startHour)} and ${hourLabel(window.endHour)} (${window.pct}% of sightings).`,
  };
}

function buildZoneAffinityInsight(sightings: Sighting[]): Insight | null {
  const zones = topZones(sightings, 1);
  if (zones.length === 0) return null;
  const [zone, count] = zones[0];
  const pct = Math.round((count / sightings.length) * 100);
  if (pct < 40) return null;
  const hint = ZONE_HINTS[zone];
  return {
    kind: "pattern",
    text: `Spends ${pct}% of logged time in ${zone}${hint ? ` - ${hint}` : ""}.`,
  };
}

// A day-of-week that's both disproportionately active AND dominated by one
// zone (more than its overall share) reads like a standing appointment -
// a raid night, a dailies routine, whatever - rather than coincidence.
function buildScheduleInsight(sightings: Sighting[], subjectType: "player" | "guild"): Insight | null {
  const total = sightings.length;
  const dayCounts = new Array(7).fill(0) as number[];
  for (const s of sightings) dayCounts[dayOfWeek(s.ts)]++;
  const peakDay = dayCounts.indexOf(Math.max(...dayCounts));
  const peakDayShare = dayCounts[peakDay] / total;
  if (peakDayShare < 0.28) return null; // even split across 7 days is ~14% - this needs to be well above that

  const daySightings = sightings.filter((s) => dayOfWeek(s.ts) === peakDay);
  const dayTopZones = topZones(daySightings, 1);
  if (dayTopZones.length === 0) return null;
  const [zone, zoneCountInDay] = dayTopZones[0];
  const zoneShareInDay = zoneCountInDay / daySightings.length;
  const overallZoneCount = topZones(sightings, sightings.length).find(([z]) => z === zone)?.[1] ?? 0;
  const overallZoneShare = overallZoneCount / total;
  if (zoneShareInDay < 0.5 && zoneShareInDay - overallZoneShare < 0.15) return null;

  const subjectNoun = subjectType === "guild" ? "This guild" : "This player";
  const suffix = subjectType === "guild" ? "which may point to a scheduled raid or event time" : "possibly a regular routine";
  return {
    kind: "pattern",
    text: `${subjectNoun} is most active on ${DAY_LABELS_FULL[peakDay]}s in ${zone} (${Math.round(peakDayShare * 100)}% of sightings fall on that day) - ${suffix}.`,
  };
}

// Recent 7 days vs the 7 before that - only fires with enough history for
// both windows, and only when the swing is large enough to not just be
// normal week-to-week noise.
function buildMomentumInsight(sightings: Sighting[]): Insight | null {
  const WEEK = 7 * 86400;
  const maxTs = Math.max(...sightings.map((s) => s.ts));
  const minTs = Math.min(...sightings.map((s) => s.ts));
  const recentStart = maxTs - WEEK;
  const priorStart = maxTs - 2 * WEEK;
  if (minTs > priorStart) return null;

  const recentCount = sightings.filter((s) => s.ts >= recentStart).length;
  const priorCount = sightings.filter((s) => s.ts >= priorStart && s.ts < recentStart).length;
  if (priorCount === 0) return null;

  const pctChange = Math.round(((recentCount - priorCount) / priorCount) * 100);
  if (Math.abs(pctChange) < 25) return null;
  const dir = pctChange > 0 ? "up" : "down";
  return {
    kind: "pattern",
    text: `Sightings are ${dir} ${Math.abs(pctChange)}% over the last 7 days versus the week before (${recentCount} vs ${priorCount}).`,
  };
}

function buildRightNowPrediction(sightings: Sighting[]): Insight | null {
  const now = new Date();
  const prediction = predictZone(sightings, now.getDay(), now.getHours());
  if (!prediction) return null;

  let basis: string;
  if (prediction.basis === "day+hour") {
    basis = `based on ${plural(prediction.sampleSize)} seen on a ${DAY_LABELS[now.getDay()]} around this time`;
  } else if (prediction.basis === "hour-only") {
    basis = `not enough ${DAY_LABELS[now.getDay()]}-specific history yet - based on ${plural(prediction.sampleSize)} around this hour on any day`;
  } else {
    basis = `not enough time-of-day history yet - their overall most-sighted zone across ${plural(prediction.sampleSize)}`;
  }
  return { kind: "prediction", text: `Right now, most likely in **${prediction.zone}** - ${basis}.` };
}

function buildReliabilityInsight(sightings: Sighting[]): Insight | null {
  const reporters = new Set(sightings.map((s) => s.reporter));
  if (reporters.size > 1) return null;
  const [only] = reporters;
  return {
    kind: "caveat",
    text: `Every sighting so far comes from a single reporter (${only}) - worth corroborating from another character before treating this as solid intel.`,
  };
}

/** Builds the "Trending Snapshot & Predictions" bullet list for one subject.
 * Every insight is a heuristic read of logged sightings - frequency and
 * co-occurrence, not a trained model - and each one independently decides
 * whether the data backing it is strong enough to state, skipping itself
 * otherwise rather than forcing a claim out of thin data. */
export function buildInsights(sightings: Sighting[], subjectType: "player" | "guild"): Insight[] {
  if (sightings.length < MIN_SAMPLE) return [];

  const insights: Insight[] = [];
  const rightNow = buildRightNowPrediction(sightings);
  if (rightNow) insights.push(rightNow);
  const timeOfDay = buildTimeOfDayInsight(sightings);
  if (timeOfDay) insights.push(timeOfDay);
  const zoneAffinity = buildZoneAffinityInsight(sightings);
  if (zoneAffinity) insights.push(zoneAffinity);
  const schedule = buildScheduleInsight(sightings, subjectType);
  if (schedule) insights.push(schedule);
  const momentum = buildMomentumInsight(sightings);
  if (momentum) insights.push(momentum);
  const reliability = buildReliabilityInsight(sightings);
  if (reliability) insights.push(reliability);
  return insights;
}
