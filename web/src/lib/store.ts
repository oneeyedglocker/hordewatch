import type { Sighting } from "./types";

const STORAGE_KEY = "hordewatch.sightings.v1";

/** `id` is only unique within one character's own SavedVariables file (see
 * DATA_MODEL.md), so a stable cross-import key needs the source character
 * folded in. Falls back to a content key for rows with no id (shouldn't
 * happen for real addon data, but keeps ingestion robust). */
function sightingKey(s: Sighting): string {
  if (s.id !== undefined) return `${s.sourceRealm ?? "?"}/${s.sourceCharacter ?? "?"}#${s.id}`;
  return `${s.player}@${s.ts}@${s.reporter}`;
}

export function mergeSightings(existing: Sighting[], incoming: Sighting[]): Sighting[] {
  const byKey = new Map<string, Sighting>();
  for (const s of existing) byKey.set(sightingKey(s), s);
  for (const s of incoming) {
    const key = sightingKey(s);
    const prev = byKey.get(key);
    // Newer data for the same row (re-import after more corroboration)
    // wins outright; rows are otherwise immutable once logged.
    if (!prev || s.ts >= prev.ts) byKey.set(key, s);
  }
  return Array.from(byKey.values()).sort((a, b) => b.ts - a.ts);
}

export function loadSightings(): Sighting[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function saveSightings(sightings: Sighting[]): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(sightings));
  } catch (err) {
    console.error("HordeWatch: failed to persist sightings to localStorage", err);
  }
}

export function clearSightings(): void {
  localStorage.removeItem(STORAGE_KEY);
}
