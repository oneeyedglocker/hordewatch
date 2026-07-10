# parse-savedvariables

Converts HordeWatch's per-character SavedVariables file(s) into a single
JSON file the web app (`web/`) can import. See `DATA_MODEL.md` at the repo
root for why this step exists and what it can't do (no basemap art, no
transport other than this + the in-game export string).

## Usage

```sh
npm install
node index.mjs "/path/to/WoW/_classic_/WTF/Account/YOURACCOUNT" --out sightings.json
```

Point it at any directory containing one or more
`.../<Realm>/<CharacterName>/SavedVariables/HordeWatch.lua` files (it walks
recursively), or at a single file directly. Realm/character are derived from
the folder structure; override with `--realm`/`--character` when parsing a
single file outside that layout.

Output: `{ "sightings": [...] }`, one entry per row in that character's
`Sightings` log, tagged with `sourceCharacter`/`sourceRealm` since a
sighting's `id` is only unique within one character's own file.
