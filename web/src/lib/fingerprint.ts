import type { Sighting } from "./types";
import { type Confidence, confidenceFromLowerBound, recencyWeight, wilsonLowerBound } from "./confidence";

export const DAY_LABELS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

export function hourOfDay(ts: number): number {
  return new Date(ts * 1000).getHours();
}

export function dayOfWeek(ts: number): number {
  return new Date(ts * 1000).getDay();
}

export function hourLabel(hour: number): string {
  const h = ((hour % 24) + 24) % 24;
  const period = h < 12 ? "AM" : "PM";
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return `${h12} ${period}`;
}

/** Count of sightings in each of the 24 local hours, summed across every day
 * in range - "what time of day is this subject usually active." */
export function buildHourHistogram(sightings: Sighting[]): number[] {
  const buckets = new Array(24).fill(0) as number[];
  for (const s of sightings) buckets[hourOfDay(s.ts)]++;
  return buckets;
}

/** [dayOfWeek][hour] sighting counts - the day+time-of-day "fingerprint" a
 * single hour histogram can't show (e.g. active weekday evenings but not
 * weekend mornings). */
export function buildDayHourMatrix(sightings: Sighting[]): number[][] {
  const matrix = Array.from({ length: 7 }, () => new Array(24).fill(0) as number[]);
  for (const s of sightings) matrix[dayOfWeek(s.ts)][hourOfDay(s.ts)]++;
  return matrix;
}

export function topZones(sightings: Sighting[], n = 6): [string, number][] {
  const counts = new Map<string, number>();
  for (const s of sightings) counts.set(s.zone, (counts.get(s.zone) ?? 0) + 1);
  return Array.from(counts.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, n);
}

function hourDistance(a: number, b: number): number {
  const diff = Math.abs(a - b);
  return Math.min(diff, 24 - diff);
}

export interface ZonePrediction {
  zone: string;
  /** Recency-weighted vote share the winning zone got within its tier's
   * rows (0-1) - NOT a raw count; see recencyWeight in confidence.ts. */
  weightedShare: number;
  /** Raw (unweighted) number of rows backing the winning tier - the number
   * to show a human, since "12.4 weighted sightings" reads oddly. */
  sampleSize: number;
  /** Which fallback tier produced this guess - see predictZone. */
  basis: "day+hour" | "hour-only" | "overall";
  runnerUp?: [string, number];
  confidence: Confidence;
  /** Wilson lower-bound of the winning zone's weighted share, as a 0-100
   * percent - the number confidence is actually derived from. */
  confidenceLowerBoundPct: number;
}

// A +/-1hr window around the target hour, so "8pm" also counts 7-9pm
// sightings - a single hour is too narrow a bucket for most real logs to
// clear MIN_SAMPLE. Below MIN_SAMPLE, this is a coin flip dressed up as a
// prediction, so we fall back a tier instead of reporting it.
const HOUR_WINDOW = 1;
const MIN_SAMPLE = 3;

/** Frequency-based "prediction" - NOT a trained model, just "where has this
 * player/guild historically been seen closest to this day+hour," weighted so
 * recent sightings count more than old ones (see recencyWeight). Falls back
 * from day+hour -> any-day hour-of-day -> the subject's all-time top zone as
 * the matching window gets too sparse to trust, and reports which tier won
 * plus a Wilson-score confidence on the winning zone's share so the UI can
 * be honest about how much it's guessing. `now` is exposed for testing -
 * production callers should leave it as the real wall-clock default. */
export function predictZone(
  sightings: Sighting[],
  targetDow: number,
  targetHour: number,
  now: number = Date.now() / 1000,
): ZonePrediction | null {
  const withZone = sightings.filter((s) => s.zone);
  if (withZone.length === 0) return null;

  const dayHour = withZone.filter(
    (s) => dayOfWeek(s.ts) === targetDow && hourDistance(hourOfDay(s.ts), targetHour) <= HOUR_WINDOW,
  );
  const hourOnly = withZone.filter((s) => hourDistance(hourOfDay(s.ts), targetHour) <= HOUR_WINDOW);

  let rows: Sighting[];
  let basis: ZonePrediction["basis"];
  if (dayHour.length >= MIN_SAMPLE) {
    rows = dayHour;
    basis = "day+hour";
  } else if (hourOnly.length >= MIN_SAMPLE) {
    rows = hourOnly;
    basis = "hour-only";
  } else {
    rows = withZone;
    basis = "overall";
  }

  const weighted = new Map<string, number>();
  let totalWeight = 0;
  for (const s of rows) {
    const w = recencyWeight(s.ts, now);
    weighted.set(s.zone, (weighted.get(s.zone) ?? 0) + w);
    totalWeight += w;
  }
  const sorted = Array.from(weighted.entries()).sort((a, b) => b[1] - a[1]);
  if (sorted.length === 0) return null;
  const [zone, weight] = sorted[0];
  const lowerBound = wilsonLowerBound(weight, totalWeight);
  return {
    zone,
    weightedShare: totalWeight > 0 ? weight / totalWeight : 0,
    sampleSize: rows.length,
    basis,
    runnerUp: sorted[1] ? [sorted[1][0], Math.round(sorted[1][1] * 10) / 10] : undefined,
    confidence: confidenceFromLowerBound(lowerBound),
    confidenceLowerBoundPct: Math.round(lowerBound * 100),
  };
}
