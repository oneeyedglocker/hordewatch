import { decodeExportString } from "../src/lib/decodeExport";

// This exact string was produced by the *Lua* implementation
// (test_roundtrip.lua running the real vendored LibDeflate.lua +
// AceSerializer-3.0.lua) so a successful decode here proves the JS port's
// bit-packing/token format matches the addon byte-for-byte, not just that
// JS agrees with itself.
const FIXTURE =
  "4XzDr2TBIddef(jcusGuOsvRe0UILBcvyKAPxmQMKPjr4Fq2oqzvlp7DSbkuenxe5z0mh)DogIHzaZwxw5QvLwQil0XGc(wSawamNL61lnk8fdS6c)mSnAJOyoKDtV(32ojfycCnkgBh1GwRFVCbNoWEAW0PJNmfys(QNHSO2PXjD6sZx2ulkagtlXDVE3iF1F29AgF3huJp9iSsBCOXdvyQYMTWqGnXvHM9NDhWG0TLx12KSgEosdzYjB1S4fTIQiy0kYGOYn(biRZjXpPmtIUknbKJBkrs5)hw9FOq8wTHq8ruvRSncEWkZ9wPxFY2uozGSUjel1Qc9gVaUFgz08(7nok6qmbz9OJR2Vl7VkuULyO1uKlKhH7EDJI0jbc)M9ZhI0O9pejxK7d)1CZDYH5A5cUtOlpAYx4QsUrYn2QRgnx1yEe(2yjNCdBzJqi52LxyKycbcI8k(5sJVhUTIbNhzr(vdrXm06oKkR3lb8vtuVFg";

function assertEqual(actual: unknown, expected: unknown, label: string) {
  if (actual !== expected) {
    throw new Error(`FAIL ${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
  console.log(`OK ${label}`);
}

const payload = decodeExportString(FIXTURE);

assertEqual(payload.char, "Someguy", "char");
assertEqual(payload.realm, "TestRealm", "realm");
assertEqual(payload.sightings.length, 2, "sighting count");

const s1 = payload.sightings[0];
assertEqual(s1.player, "Enemyguy-Realm", "s1.player");
assertEqual(s1.class, "WARRIOR", "s1.class");
assertEqual(s1.race, "Orc", "s1.race");
assertEqual(s1.level, 70, "s1.level");
assertEqual(s1.guild, "Some <Guild> Na~me^", "s1.guild (escaped chars)");
assertEqual(s1.zone, "Hellfire Peninsula", "s1.zone");
assertEqual(Math.abs((s1.mapX ?? 0) - 0.512345) < 1e-6, true, "s1.mapX precision");
assertEqual(s1.worldX, -1234.5, "s1.worldX");
assertEqual(s1.reportCount, 2, "s1.reportCount");
assertEqual([...(s1.reporters ?? [])].sort().join(","), "Otherguy,Someguy", "s1.reporters");

const s2 = payload.sightings[1];
assertEqual(s2.player, "Skullmask", "s2.player");
assertEqual(s2.class, undefined, "s2.class (nil)");
assertEqual(s2.levelIsGuess, true, "s2.levelIsGuess");
assertEqual(s2.method, "combatlog", "s2.method");

console.log("ALL FIXTURE ASSERTIONS PASSED");
