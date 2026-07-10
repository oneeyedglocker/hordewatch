import type { ImportEvent, Sighting } from "./types";

const STORAGE_KEY = "hordewatch.sightings.v1";
const HISTORY_KEY = "hordewatch.importHistory.v1";

/** `id` is only unique within one character's own SavedVariables file (see
 * DATA_MODEL.md), so a stable cross-import key needs the source character
 * folded in. Falls back to a content key for rows with no id (shouldn't
 * happen for real addon data, but keeps ingestion robust). */
function sightingKey(s: Sighting): string {
  if (s.id !== undefined) return `${s.sourceRealm ?? "?"}/${s.sourceCharacter ?? "?"}#${s.id}`;
  return `${s.player}@${s.ts}@${s.reporter}`;
}

export interface MergeResult {
  merged: Sighting[];
  newCount: number;
}

export function mergeSightings(existing: Sighting[], incoming: Sighting[]): MergeResult {
  const byKey = new Map<string, Sighting>();
  for (const s of existing) byKey.set(sightingKey(s), s);
  let newCount = 0;
  for (const s of incoming) {
    const key = sightingKey(s);
    const prev = byKey.get(key);
    if (!prev) newCount++;
    // Newer data for the same row (re-import after more corroboration)
    // wins outright; rows are otherwise immutable once logged.
    if (!prev || s.ts >= prev.ts) byKey.set(key, s);
  }
  return { merged: Array.from(byKey.values()).sort((a, b) => b.ts - a.ts), newCount };
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
  localStorage.removeItem(HISTORY_KEY);
}

export function loadImportHistory(): ImportEvent[] {
  try {
    const raw = localStorage.getItem(HISTORY_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function saveImportHistory(events: ImportEvent[]): void {
  try {
    localStorage.setItem(HISTORY_KEY, JSON.stringify(events));
  } catch (err) {
    console.error("HordeWatch: failed to persist import history to localStorage", err);
  }
}
