// Statistical helpers shared by the prediction/insights engine. Still not a
// trained model - every number here is closed-form arithmetic anyone can
// re-derive by hand - but replaces the old hand-picked "MIN_SAMPLE=5" /
// "pct >= 40" style magic numbers with two well-established, principled
// techniques:
//
// 1. Wilson score intervals, so how much a claimed share is trusted scales
//    with sample size instead of a flat percentage cutoff (a 75% share from
//    4 sightings and a 75% share from 100 sightings are NOT equally
//    trustworthy, and a flat threshold treated them identically).
// 2. Exponential recency decay, so a habit from 6 weeks ago doesn't out-vote
//    one from yesterday when a guild's schedule has genuinely shifted.

const Z_90 = 1.645; // one-sided ~90% confidence bound

/** Lower bound of the Wilson score confidence interval for a proportion
 * successes/n (see https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval).
 * Used here as a single principled substitute for separate hand-tuned
 * "minimum sample size" + "minimum percentage" thresholds - small samples
 * naturally need a much higher observed share to clear the same bar.
 *
 * Note: when `successes`/`n` come from recency-weighted (fractional) sums
 * rather than raw integer counts, this is an approximation, not a textbook-
 * exact interval (the underlying binomial variance assumption is for actual
 * counts) - still meaningfully more principled than a flat cutoff, but
 * worth being honest that it's a heuristic layered on a heuristic. */
export function wilsonLowerBound(successes: number, n: number, z = Z_90): number {
  if (n <= 0) return 0;
  const p = Math.min(1, Math.max(0, successes / n));
  const z2 = z * z;
  const denom = 1 + z2 / n;
  const center = p + z2 / (2 * n);
  const margin = z * Math.sqrt((p * (1 - p)) / n + z2 / (4 * n * n));
  return Math.max(0, (center - margin) / denom);
}

export type Confidence = "low" | "moderate" | "high";

export function confidenceFromLowerBound(lowerBound: number): Confidence {
  if (lowerBound >= 0.5) return "high";
  if (lowerBound >= 0.25) return "moderate";
  return "low";
}

// A sighting from this many days ago counts half as much as one from today.
// ~2 weeks was picked to roughly match how fast a guild's actual schedule
// can shift (a changed raid night) while still treating a month-plus of
// history as meaningful signal rather than discarding it outright.
export const RECENCY_HALF_LIFE_DAYS = 14;

/** Exponential-decay weight for one sighting. Anchored to the real current
 * time by default (not the dataset's own latest timestamp) - deliberately,
 * so a "right now" read is honestly less confident against a stale import
 * instead of pretending old data is as fresh as new data. */
export function recencyWeight(ts: number, now: number = Date.now() / 1000, halfLifeDays = RECENCY_HALF_LIFE_DAYS): number {
  const ageDays = Math.max(0, (now - ts) / 86400);
  return Math.pow(0.5, ageDays / halfLifeDays);
}
