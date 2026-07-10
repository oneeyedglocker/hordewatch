# hordewatch
PVP Intel

- `HordeWatch/` — the WoW (TBC Classic) addon. See `DATA_MODEL.md` for what it captures and how.
- `tools/parse-savedvariables/` — offline converter from the addon's SavedVariables file to JSON.
- `web/` — the web dashboard (React + Vite + TS) that imports sightings via `/hw export` or the JSON parser above.
