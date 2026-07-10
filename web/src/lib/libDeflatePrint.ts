// JS port of LibDeflate's EncodeForPrint/DecodeForPrint 6-bit printable
// encoding (LibDeflate.lua, (C) Haoqian He, zlib license), so the web app
// can decode the export string produced by HordeWatch/Export.lua without
// a Lua runtime. Algorithm ported line-for-line from LibDeflate.lua so the
// bit-packing matches exactly; see that file for the canonical version.

const ALPHABET =
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()";

const BYTE_TO_CHAR: string[] = ALPHABET.split("");
const CHAR_TO_BYTE: Record<string, number> = {};
for (let i = 0; i < ALPHABET.length; i++) {
  CHAR_TO_BYTE[ALPHABET[i]] = i;
}

/** Reverses LibDeflate:DecodeForPrint - decodes a print-safe string back
 * into the raw compressed bytes. Returns null on malformed input, mirroring
 * the Lua function returning nil. */
export function decodeForPrint(input: string): Uint8Array | null {
  // Strip leading/trailing control chars or spaces (bytes <= 32), same as
  // the Lua `str:gsub("^[%c ]+", ""):gsub("[%c ]+$", "")`.
  let start = 0;
  let end = input.length;
  while (start < end && input.charCodeAt(start) <= 32) start++;
  while (end > start && input.charCodeAt(end - 1) <= 32) end--;
  const str = input.slice(start, end);

  const strlen = str.length;
  if (strlen === 1) return null;

  const out: number[] = [];
  let i = 0;
  const strlenMinus3 = strlen - 3;
  while (i < strlenMinus3) {
    const x1 = CHAR_TO_BYTE[str[i]];
    const x2 = CHAR_TO_BYTE[str[i + 1]];
    const x3 = CHAR_TO_BYTE[str[i + 2]];
    const x4 = CHAR_TO_BYTE[str[i + 3]];
    if (x1 === undefined || x2 === undefined || x3 === undefined || x4 === undefined) {
      return null;
    }
    i += 4;
    let cache = x1 + x2 * 64 + x3 * 4096 + x4 * 262144;
    const b1 = cache % 256;
    cache = (cache - b1) / 256;
    const b2 = cache % 256;
    const b3 = (cache - b2) / 256;
    out.push(b1, b2, b3);
  }

  let cache = 0;
  let cacheBitlen = 0;
  while (i < strlen) {
    const x = CHAR_TO_BYTE[str[i]];
    if (x === undefined) return null;
    cache = cache + x * 2 ** cacheBitlen;
    cacheBitlen += 6;
    i++;
  }
  while (cacheBitlen >= 8) {
    const byte = cache % 256;
    out.push(byte);
    cache = (cache - byte) / 256;
    cacheBitlen -= 8;
  }

  return new Uint8Array(out);
}

/** Mirrors LibDeflate:EncodeForPrint - not needed by the web app today
 * (it only decodes what the addon produces) but kept for completeness /
 * testing the round trip. */
export function encodeForPrint(bytes: Uint8Array): string {
  const strlen = bytes.length;
  const strlenMinus2 = strlen - 2;
  let i = 0;
  let out = "";
  while (i < strlenMinus2) {
    const x1 = bytes[i];
    const x2 = bytes[i + 1];
    const x3 = bytes[i + 2];
    i += 3;
    let cache = x1 + x2 * 256 + x3 * 65536;
    const b1 = cache % 64;
    cache = (cache - b1) / 64;
    const b2 = cache % 64;
    cache = (cache - b2) / 64;
    const b3 = cache % 64;
    const b4 = (cache - b3) / 64;
    out += BYTE_TO_CHAR[b1] + BYTE_TO_CHAR[b2] + BYTE_TO_CHAR[b3] + BYTE_TO_CHAR[b4];
  }

  let cache = 0;
  let cacheBitlen = 0;
  while (i < strlen) {
    const x = bytes[i];
    cache = cache + x * 2 ** cacheBitlen;
    cacheBitlen += 8;
    i++;
  }
  while (cacheBitlen > 0) {
    const bit6 = cache % 64;
    out += BYTE_TO_CHAR[bit6];
    cache = (cache - bit6) / 64;
    cacheBitlen -= 6;
  }

  return out;
}
