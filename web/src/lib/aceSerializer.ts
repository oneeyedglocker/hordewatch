// JS port of AceSerializer-3.0's Deserialize (AceSerializer-3.0.lua, Ace3
// license), so the web app can read the export string produced by
// HordeWatch/Export.lua without a Lua runtime. Ported line-for-line from
// the vendored HordeWatch/Libs/AceSerializer-3.0/AceSerializer-3.0.lua so
// the token format matches exactly - see that file for the canonical
// version and format documentation. Serialize() isn't needed (the web app
// only ever reads addon-produced data) so only decoding is implemented.

const SER_INF = "1.#INF";
const SER_INF_MAC = "inf";
const SER_NEG_INF = "-1.#INF";
const SER_NEG_INF_MAC = "-inf";

function deserializeStringHelper(escape: string): string {
  // escape is always exactly 2 chars: "~" + one byte.
  const b = escape.charCodeAt(1);
  if (b < 122) {
    return String.fromCharCode(b - 64);
  } else if (b === 122) {
    return String.fromCharCode(30);
  } else if (b === 123) {
    return String.fromCharCode(127);
  } else if (b === 124) {
    return String.fromCharCode(126);
  } else if (b === 125) {
    return String.fromCharCode(94);
  }
  throw new Error(`AceSerializer: bad escape sequence '${escape}'`);
}

function unescapeString(data: string): string {
  return data.replace(/~[\s\S]/g, deserializeStringHelper);
}

function deserializeNumberHelper(numberStr: string): number {
  if (numberStr === SER_NEG_INF || numberStr === SER_NEG_INF_MAC) return -Infinity;
  if (numberStr === SER_INF || numberStr === SER_INF_MAC) return Infinity;
  const n = Number(numberStr);
  if (Number.isNaN(n) && numberStr.trim() !== "nan") {
    throw new Error(`AceSerializer: invalid serialized number '${numberStr}'`);
  }
  return n;
}

type Token = [ctl: string, data: string];

/** Mirrors Lua's `gmatch(str, "(^.)([^^]*)")`: repeated (ctl, data) pairs
 * where ctl is "^" plus one type character and data runs until the next
 * "^" or end of string. */
function makeTokenIterator(str: string): () => Token | null {
  let pos = 0;
  return function next(): Token | null {
    if (pos >= str.length || str.charCodeAt(pos) !== 94 /* '^' */) return null;
    const ctl = str.slice(pos, pos + 2);
    pos += 2;
    const dataStart = pos;
    while (pos < str.length && str.charCodeAt(pos) !== 94) pos++;
    return [ctl, str.slice(dataStart, pos)];
  };
}

function finalizeTable(entries: Array<[string | number, unknown]>): unknown {
  if (entries.length === 0) return [];
  const numericKeys = entries
    .map(([k]) => k)
    .filter((k): k is number => typeof k === "number");
  if (numericKeys.length === entries.length) {
    const sorted = [...numericKeys].sort((a, b) => a - b);
    const isSequential = sorted.every((k, idx) => k === idx + 1);
    if (isSequential) {
      const byKey = new Map(entries as Array<[number, unknown]>);
      return sorted.map((k) => byKey.get(k));
    }
  }
  const obj: Record<string, unknown> = {};
  for (const [k, v] of entries) obj[String(k)] = v;
  return obj;
}

// `single`/`ctl`/`data` mirror DeserializeValue's recursive-mode params in
// the Lua source: called with a pre-fetched token when parsing a value
// inside a table (key or value), or fetching its own token at top level.
function deserializeValue(
  iter: () => Token | null,
  single: boolean,
  ctl?: string,
  data?: string,
): unknown {
  if (!single) {
    const tok = iter();
    if (!tok) throw new Error("AceSerializer: data misses terminator ('^^')");
    [ctl, data] = tok;
  }
  if (ctl === undefined || data === undefined) {
    throw new Error("AceSerializer: data misses terminator ('^^')");
  }

  if (ctl === "^^") return undefined;

  let res: unknown;
  switch (ctl) {
    case "^S":
      res = unescapeString(data);
      break;
    case "^N":
      res = deserializeNumberHelper(data);
      break;
    case "^F": {
      const tok2 = iter();
      if (!tok2 || tok2[0] !== "^f") {
        throw new Error(`AceSerializer: expected '^f', got '${tok2?.[0]}'`);
      }
      const m = Number(data);
      const e = Number(tok2[1]);
      res = m * 2 ** e;
      break;
    }
    case "^B":
      res = true;
      break;
    case "^b":
      res = false;
      break;
    case "^Z":
      res = undefined;
      break;
    case "^T": {
      const entries: Array<[string | number, unknown]> = [];
      for (;;) {
        const kTok = iter();
        if (!kTok) throw new Error("AceSerializer: unterminated table");
        if (kTok[0] === "^t") break;
        const k = deserializeValue(iter, true, kTok[0], kTok[1]);
        const vTok = iter();
        if (!vTok) throw new Error("AceSerializer: unterminated table");
        const v = deserializeValue(iter, true, vTok[0], vTok[1]);
        if (typeof k === "string" || typeof k === "number") {
          entries.push([k, v]);
        }
      }
      res = finalizeTable(entries);
      break;
    }
    default:
      throw new Error(`AceSerializer: invalid control code '${ctl}'`);
  }

  return res;
}

/** Decodes a string produced by AceSerializer:Serialize(...). Returns the
 * first serialized value (HordeWatch only ever serializes one table). */
export function aceDeserialize(rawStr: string): unknown {
  // Strip all control characters and spaces, same as the Lua
  // `gsub(str, "[%c ]", "")` - defensive against email/paste mangling.
  // eslint-disable-next-line no-control-regex -- intentional, matching Lua's %c class
  const str = rawStr.replace(/[\x00-\x20\x7f]/g, "");

  const iter = makeTokenIterator(str);
  const first = iter();
  if (!first || first[0] !== "^1") {
    throw new Error("AceSerializer: not AceSerializer data (rev 1)");
  }

  return deserializeValue(iter, false);
}
