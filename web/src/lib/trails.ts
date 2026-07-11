// Above this many distinct players in the current (filtered) point set,
// drawing a trail per player would just be visual spaghetti rather than
// useful movement history - skip trails entirely and let the dots alone
// carry the view. Below it (e.g. narrowed via the name/guild filter, or
// just a quiet zone), a trail per player is the whole point.
const MAX_TRAIL_PLAYERS = 10;

/** Groups points by player, sorted chronologically within each group - one
 * array per player who has at least two positions (a trail needs two ends).
 * Returns nothing if there are too many distinct players for a trail to add
 * clarity rather than noise. */
export function buildTrails<T extends { player: string; ts: number }>(points: T[]): T[][] {
  const byPlayer = new Map<string, T[]>();
  for (const p of points) {
    const list = byPlayer.get(p.player);
    if (list) list.push(p);
    else byPlayer.set(p.player, [p]);
  }
  if (byPlayer.size > MAX_TRAIL_PLAYERS) return [];

  const trails: T[][] = [];
  for (const list of byPlayer.values()) {
    if (list.length < 2) continue;
    trails.push([...list].sort((a, b) => a.ts - b.ts));
  }
  return trails;
}
