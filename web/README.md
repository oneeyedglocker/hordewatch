# HordeRadar web app

Dashboard for the HordeWatch WoW addon's PvP sighting data. See `../DATA_MODEL.md`
for the full data model.

## Run it

```sh
npm install
npm run dev
```

## Importing data

Two ways in, both handled entirely client-side (no backend):

1. **Paste an export string** — from `/hw export` (or `/hw export all`) in-game.
   Decoded via a JS port of LibDeflate's print encoding + zlib inflate (`pako`) +
   a port of AceSerializer's deserializer.
2. **Upload JSON** — produced by `../tools/parse-savedvariables` from a raw
   SavedVariables file.

Imported sightings merge (deduped by character+id) and persist to `localStorage`.

## Zone map imagery

The Zone Map view renders a real basemap (Leaflet + `L.CRS.Simple`) once you've
supplied one - see `public/maps/README.md` for how to extract your own from
your own licensed client with wow.export. Falls back to a placeholder scatter
square for any zone you haven't added an image for yet.

## Verifying the decode pipeline

`scripts/manual-fixture-test.ts` checks the JS decoder against a string
actually produced by the *real* vendored `LibDeflate.lua`/`AceSerializer-3.0.lua`
under a standalone Lua interpreter — not just JS agreeing with itself:

```sh
npm run verify:decode
```
