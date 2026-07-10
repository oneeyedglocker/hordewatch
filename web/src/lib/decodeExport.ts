import { inflate } from "pako";
import { decodeForPrint } from "./libDeflatePrint";
import { aceDeserialize } from "./aceSerializer";
import type { ExportPayload, Sighting } from "./types";

/** WoW's Lua strings are raw byte strings, not guaranteed UTF-8 (realm
 * locale dependent). We deserialize as one JS char per byte (Latin-1) to
 * keep the parsing logic byte-exact, then best-effort re-decode as UTF-8
 * for display - falling back to the Latin-1 rendering if the bytes aren't
 * valid UTF-8. Unverified against a live non-English client, same caveat
 * as HereBeDragons coordinates in DATA_MODEL.md. */
function toDisplayString(binaryStr: string): string {
  const bytes = new Uint8Array(binaryStr.length);
  for (let i = 0; i < binaryStr.length; i++) bytes[i] = binaryStr.charCodeAt(i) & 0xff;
  try {
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    return binaryStr;
  }
}

function bytesToBinaryString(bytes: Uint8Array): string {
  let s = "";
  const CHUNK = 0x8000;
  for (let i = 0; i < bytes.length; i += CHUNK) {
    s += String.fromCharCode(...bytes.subarray(i, i + CHUNK));
  }
  return s;
}

export class ExportDecodeError extends Error {}

/** Reverses HordeWatch/Export.lua's pipeline:
 *   EncodeForPrint -> CompressZlib -> AceSerializer:Serialize
 * @param exportString the pasted export string from `/hw export`.
 */
export function decodeExportString(exportString: string): ExportPayload {
  const compressed = decodeForPrint(exportString.trim());
  if (!compressed) {
    throw new ExportDecodeError(
      "Couldn't decode that string - it doesn't look like a HordeWatch export (bad characters or truncated paste).",
    );
  }

  let inflated: Uint8Array;
  try {
    inflated = inflate(compressed);
  } catch (err) {
    throw new ExportDecodeError(
      `Couldn't decompress that string - it may be truncated or corrupted. (${(err as Error).message})`,
    );
  }

  const binaryStr = bytesToBinaryString(inflated);

  let payload: unknown;
  try {
    payload = aceDeserialize(binaryStr);
  } catch (err) {
    throw new ExportDecodeError(
      `Couldn't parse that string as HordeWatch data. (${(err as Error).message})`,
    );
  }

  if (typeof payload !== "object" || payload === null || !("sightings" in payload)) {
    throw new ExportDecodeError("Decoded data doesn't look like a HordeWatch export payload.");
  }

  return normalizeExportPayload(payload as Record<string, unknown>);
}

function toDisplayStringIfString(v: unknown): unknown {
  return typeof v === "string" ? toDisplayString(v) : v;
}

function normalizeExportPayload(raw: Record<string, unknown>): ExportPayload {
  const char = toDisplayString(String(raw.char ?? "?"));
  const realm = toDisplayString(String(raw.realm ?? "?"));
  const rawSightings = Array.isArray(raw.sightings) ? raw.sightings : [];

  const sightings: Sighting[] = rawSightings.map((r) => normalizeSighting(r, char, realm));

  return {
    v: Number(raw.v ?? 1),
    char,
    realm,
    exportedAt: Number(raw.exportedAt ?? 0),
    sightings,
  };
}

function normalizeSighting(raw: unknown, sourceCharacter: string, sourceRealm: string): Sighting {
  const r = (raw ?? {}) as Record<string, unknown>;

  let reporters: string[] | undefined;
  if (Array.isArray(r.reporters)) {
    reporters = r.reporters.map((x) => toDisplayString(String(x)));
  } else if (r.reporters && typeof r.reporters === "object") {
    reporters = Object.keys(r.reporters as object).map((k) => toDisplayString(k));
  }

  return {
    id: typeof r.id === "number" ? r.id : undefined,
    player: toDisplayString(String(r.player ?? "?")),
    class: typeof r.class === "string" ? r.class : undefined,
    race: typeof r.race === "string" ? toDisplayStringIfString(r.race) as string : undefined,
    level: typeof r.level === "number" ? r.level : undefined,
    levelIsGuess: typeof r.levelIsGuess === "boolean" ? r.levelIsGuess : undefined,
    guild: typeof r.guild === "string" ? toDisplayString(r.guild) : undefined,
    zone: toDisplayString(String(r.zone ?? "Unknown")),
    subZone: typeof r.subZone === "string" ? toDisplayString(r.subZone) : undefined,
    mapID: typeof r.mapID === "number" ? r.mapID : undefined,
    mapX: typeof r.mapX === "number" ? r.mapX : undefined,
    mapY: typeof r.mapY === "number" ? r.mapY : undefined,
    worldX: typeof r.worldX === "number" ? r.worldX : undefined,
    worldY: typeof r.worldY === "number" ? r.worldY : undefined,
    continentID: typeof r.continentID === "number" ? r.continentID : undefined,
    layer: typeof r.layer === "number" ? r.layer : undefined,
    method: (typeof r.method === "string" ? r.method : "comm") as Sighting["method"],
    ts: typeof r.ts === "number" ? r.ts : 0,
    reporter: toDisplayString(String(r.reporter ?? "?")),
    relayed: typeof r.relayed === "boolean" ? r.relayed : undefined,
    relaySender: typeof r.relaySender === "string" ? toDisplayString(r.relaySender) : undefined,
    relayDelay: typeof r.relayDelay === "number" ? r.relayDelay : undefined,
    windowStart: typeof r.windowStart === "number" ? r.windowStart : undefined,
    reportCount: typeof r.reportCount === "number" ? r.reportCount : undefined,
    reporters,
    sourceCharacter,
    sourceRealm,
  };
}
