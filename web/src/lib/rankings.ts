import type { Sighting } from "./types";

export interface RankedEntry {
  type: "player" | "guild";
  name: string;
  count: number;
}

/** Sighting counts per player, most-seen first - the "who should show up
 * first without typing anything" ranking used by the subject picker and
 * the overview's quick-pick lists. */
export function rankPlayers(sightings: Sighting[]): RankedEntry[] {
  const counts = new Map<string, number>();
  for (const s of sightings) counts.set(s.player, (counts.get(s.player) ?? 0) + 1);
  return Array.from(counts.entries())
    .map(([name, count]) => ({ type: "player" as const, name, count }))
    .sort((a, b) => b.count - a.count);
}

export function rankGuilds(sightings: Sighting[]): RankedEntry[] {
  const counts = new Map<string, number>();
  for (const s of sightings) if (s.guild) counts.set(s.guild, (counts.get(s.guild) ?? 0) + 1);
  return Array.from(counts.entries())
    .map(([name, count]) => ({ type: "guild" as const, name, count }))
    .sort((a, b) => b.count - a.count);
}
