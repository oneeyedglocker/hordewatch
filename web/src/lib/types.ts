// Mirrors the sighting record shape produced by HordeWatch/Data.lua.
// See DATA_MODEL.md for the authoritative field-by-field description.
export type DetectionMethod =
  | "target"
  | "mouseover"
  | "nameplate"
  | "combatlog"
  | "minimap"
  | "comm";

export interface Sighting {
  id?: number;
  player: string;
  class?: string;
  race?: string;
  level?: number;
  levelIsGuess?: boolean;
  guild?: string;
  zone: string;
  subZone?: string;
  mapID?: number;
  mapX?: number;
  mapY?: number;
  worldX?: number;
  worldY?: number;
  continentID?: number;
  layer?: number;
  method: DetectionMethod;
  ts: number;
  reporter: string;
  relayed?: boolean;
  relaySender?: string;
  relayDelay?: number;
  windowStart?: number;
  reportCount?: number;
  reporters?: string[];

  // Provenance added by the importer, not present in the addon's own
  // record - which file/export this row came from, since `id` is only
  // unique within one character's own SavedVariables file.
  sourceCharacter?: string;
  sourceRealm?: string;
}

export interface ExportPayload {
  v: number;
  char: string;
  realm: string;
  exportedAt: number;
  sightings: Sighting[];
}

// A record of one import action (paste or upload), kept locally so the
// History view can show what was brought in and when - separate from the
// Sighting log itself, which has no notion of "when did I import this."
export interface ImportEvent {
  id: string;
  at: number;
  source: "string" | "json";
  label: string;
  count: number;
  newCount: number;
}
