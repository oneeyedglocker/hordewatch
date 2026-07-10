#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { extractGlobalTable } from "./luaTable.mjs";

// Converts one or more HordeWatch per-character SavedVariables files
// (WTF/Account/<ACCOUNT>/<Realm>/<CharacterName>/SavedVariables/HordeWatch.lua)
// into a single JSON file the web app can import. See DATA_MODEL.md
// ("Where the data actually lives today") for why this step exists at all -
// WoW addons can't make HTTP calls, and each character has its own
// independent sighting log.

function findSavedVariablesFiles(root) {
  const results = [];
  function walk(dir) {
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else if (entry.isFile() && entry.name === "HordeWatch.lua" && path.basename(dir) === "SavedVariables") {
        results.push(full);
      }
    }
  }

  const stat = fs.statSync(root);
  if (stat.isFile()) {
    results.push(root);
  } else {
    walk(root);
  }
  return results;
}

function deriveProvenance(filePath) {
  // .../<Realm>/<CharacterName>/SavedVariables/HordeWatch.lua
  const savedVarsDir = path.dirname(filePath);
  const characterDir = path.dirname(savedVarsDir);
  const realmDir = path.dirname(characterDir);
  return { character: path.basename(characterDir), realm: path.basename(realmDir) };
}

function normalizeSighting(raw, sourceCharacter, sourceRealm) {
  const reportersRaw = raw.reporters;
  let reporters;
  if (Array.isArray(reportersRaw)) {
    reporters = reportersRaw;
  } else if (reportersRaw && typeof reportersRaw === "object") {
    reporters = Object.keys(reportersRaw);
  }
  return { ...raw, reporters, sourceCharacter, sourceRealm };
}

function parseFile(filePath, overrideCharacter, overrideRealm) {
  // Read as latin1 (one JS char per byte) to match the addon's raw byte
  // strings, same reasoning as decodeExport.ts on the web side.
  const source = fs.readFileSync(filePath, "latin1");
  const charDB = extractGlobalTable(source, "HordeWatchCharDB");
  if (!charDB || !Array.isArray(charDB.Sightings)) return [];

  const derived = deriveProvenance(filePath);
  const character = overrideCharacter ?? derived.character;
  const realm = overrideRealm ?? derived.realm;
  return charDB.Sightings.map((s) => normalizeSighting(s, character, realm));
}

function printUsage() {
  console.error(`
Usage: node index.mjs <path...> [--out output.json] [--character NAME] [--realm NAME]

<path> can be:
  - A WTF/Account directory root, walked recursively for every
    .../<Realm>/<Character>/SavedVariables/HordeWatch.lua file, or
  - A single HordeWatch.lua SavedVariables file.

--character/--realm override the values normally derived from the folder
structure - only meaningful when passing a single file.
`);
}

function main() {
  const args = process.argv.slice(2);
  if (args.length === 0 || args.includes("-h") || args.includes("--help")) {
    printUsage();
    process.exit(args.length === 0 ? 1 : 0);
  }

  let outFile = null;
  let character = null;
  let realm = null;
  const inputs = [];
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "--out" || a === "-o") outFile = args[++i];
    else if (a === "--character") character = args[++i];
    else if (a === "--realm") realm = args[++i];
    else inputs.push(a);
  }

  if (inputs.length === 0) {
    console.error("No input path given.");
    printUsage();
    process.exit(1);
  }

  const allSightings = [];
  for (const input of inputs) {
    const resolved = path.resolve(input);
    if (!fs.existsSync(resolved)) {
      console.error(`Warning: path does not exist: ${input}`);
      continue;
    }
    const files = findSavedVariablesFiles(resolved);
    if (files.length === 0) {
      console.error(`Warning: no HordeWatch.lua SavedVariables files found under ${input}`);
    }
    for (const file of files) {
      try {
        const sightings = parseFile(file, character, realm);
        console.error(`Parsed ${sightings.length} sighting(s) from ${file}`);
        allSightings.push(...sightings);
      } catch (err) {
        console.error(`Failed to parse ${file}: ${err.message}`);
      }
    }
  }

  const output = JSON.stringify({ sightings: allSightings }, null, 2);
  if (outFile) {
    fs.writeFileSync(outFile, output);
    console.error(`Wrote ${allSightings.length} sighting(s) total to ${outFile}`);
  } else {
    process.stdout.write(output + "\n");
  }
}

main();
