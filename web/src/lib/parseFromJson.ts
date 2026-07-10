import type { Sighting } from "./types";

const VALID_METHODS = new Set(["target", "mouseover", "nameplate", "combatlog", "minimap", "comm"]);

/** Normalizes the output of tools/parse-savedvariables (already plain JS
 * values, unlike decodeExport.ts which has to unpack Lua byte strings) into
 * the app's Sighting shape. Loosely validates so one malformed row in a
 * huge file doesn't sink the whole import. */
export function parseSightingsJson(raw: unknown): Sighting[] {
  if (typeof raw !== "object" || raw === null || !("sightings" in raw)) {
    throw new Error("Expected a JSON object with a top-level \"sightings\" array.");
  }
  const list = (raw as { sightings: unknown }).sightings;
  if (!Array.isArray(list)) {
    throw new Error("\"sightings\" must be an array.");
  }

  const out: Sighting[] = [];
  for (const item of list) {
    const s = normalizeOne(item);
    if (s) out.push(s);
  }
  return out;
}

function normalizeOne(raw: unknown): Sighting | null {
  if (typeof raw !== "object" || raw === null) return null;
  const r = raw as Record<string, unknown>;
  if (typeof r.player !== "string" || typeof r.ts !== "number") return null;

  let reporters: string[] | undefined;
  if (Array.isArray(r.reporters)) {
    reporters = r.reporters.filter((x): x is string => typeof x === "string");
  } else if (r.reporters && typeof r.reporters === "object") {
    reporters = Object.keys(r.reporters as object);
  }

  const method = typeof r.method === "string" && VALID_METHODS.has(r.method)
    ? (r.method as Sighting["method"])
    : "comm";

  return {
    id: typeof r.id === "number" ? r.id : undefined,
    player: r.player,
    class: typeof r.class === "string" ? r.class : undefined,
    race: typeof r.race === "string" ? r.race : undefined,
    level: typeof r.level === "number" ? r.level : undefined,
    levelIsGuess: typeof r.levelIsGuess === "boolean" ? r.levelIsGuess : undefined,
    guild: typeof r.guild === "string" ? r.guild : undefined,
    zone: typeof r.zone === "string" ? r.zone : "Unknown",
    subZone: typeof r.subZone === "string" ? r.subZone : undefined,
    mapID: typeof r.mapID === "number" ? r.mapID : undefined,
    mapX: typeof r.mapX === "number" ? r.mapX : undefined,
    mapY: typeof r.mapY === "number" ? r.mapY : undefined,
    worldX: typeof r.worldX === "number" ? r.worldX : undefined,
    worldY: typeof r.worldY === "number" ? r.worldY : undefined,
    continentID: typeof r.continentID === "number" ? r.continentID : undefined,
    layer: typeof r.layer === "number" ? r.layer : undefined,
    method,
    ts: r.ts,
    reporter: typeof r.reporter === "string" ? r.reporter : "?",
    relayed: typeof r.relayed === "boolean" ? r.relayed : undefined,
    relaySender: typeof r.relaySender === "string" ? r.relaySender : undefined,
    relayDelay: typeof r.relayDelay === "number" ? r.relayDelay : undefined,
    windowStart: typeof r.windowStart === "number" ? r.windowStart : undefined,
    reportCount: typeof r.reportCount === "number" ? r.reportCount : undefined,
    reporters,
    sourceCharacter: typeof r.sourceCharacter === "string" ? r.sourceCharacter : undefined,
    sourceRealm: typeof r.sourceRealm === "string" ? r.sourceRealm : undefined,
  };
}
