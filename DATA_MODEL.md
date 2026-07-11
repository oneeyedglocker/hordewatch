# HordeWatch Data Model

This documents what the HordeWatch WoW addon (`HordeWatch/`) actually captures,
where it lives, and what's still missing before a web app can consume it. It
exists so a fresh chat/session building the web component doesn't have to
re-derive any of this from source or from prior conversation history — this
file plus the addon source in `HordeWatch/*.lua` is the full picture.

If anything here looks stale, the addon source is the ground truth (this doc
can drift; the code can't lie about itself). Field-by-field authority:
`HordeWatch/Data.lua` (record shape, collapse logic), `HordeWatch/Position.lua`
(coordinate capture, layer fingerprint), `HordeWatch/Detection.lua` (how each
field gets populated), `HordeWatch/Comm.lua` (wire format, validation).

## What HordeWatch is

A WoW Burning Crusade Classic (`Interface: 20505`) addon that detects
opposing-faction players near you (target, mouseover, nameplate, combat log,
and minimap-tracking-blip refresh — see "Detection methods" below) and logs
structured sighting records for later trend/heatmap analysis, instead of just
alerting you like the addon it's modeled on (Spy). It also shares sightings
with other HordeWatch users in your guild over an addon comm channel.

## Where the data actually lives today

**Nothing is exported anywhere yet — this is the single biggest gap.** WoW
addons cannot make HTTP calls; there is no code in this project that ships
data anywhere. The data sits in a Lua file on whatever machine played the
session:

```
WTF/Account/<ACCOUNT>/<Realm>/<CharacterName>/SavedVariables/HordeWatch.lua
```

That file is **per-character** (`SavedVariablesPerCharacter`), not
account-wide — a player with multiple toons has one separate file per
character, each with its own independent sighting log. Anything that ingests
this data needs to walk every character's folder, not just one.

It is also **Lua source, not JSON**. WoW's SavedVariables serializer writes a
plain Lua table literal:

```lua
HordeWatchCharDB = {
    ["Sightings"] = {
        [1] = { ["player"] = "Someguy-Realm", ["class"] = "WARRIOR", ... },
        -- ...
    },
    ["CurrentState"] = { ["Someguy-Realm"] = {...} },
    ["NextId"] = 4821,
}
```

It's regular and predictable (no metatables, functions, or cycles — WoW's
serializer never produces those), so it converts cleanly to JSON with a small
script, but that conversion step doesn't exist yet either. Two options,
neither built:

1. **Offline parser** — a script (Python/Node) that reads the `.lua` file
   after a session (via `luaparse`/`slpp`, or shelling out to a Lua
   interpreter to `loadstring` + dump JSON) and produces JSON for the web app.
2. **In-game export string** — the addon serializes+compresses recent
   sightings (AceSerializer + LibDeflate) into a copy-pasteable string, which
   a page on the website decodes client-side. Estimated size: roughly
   15–25 compressed+encoded bytes per sighting, so a batch of a few hundred
   new sightings stays comfortably paste-able; dumping the *entire* history
   at once would not (keep it to "since last export" batches).

Whichever is built, it's a step that happens **after** logout/`/reload` —
WoW only flushes SavedVariables to disk at those points, never mid-session.
A client crash loses whatever hasn't been saved yet.

There is also a second, account-wide SavedVariables table (`HordeWatchDB`,
via AceDB) — but that's addon **settings** (see "User-tunable settings"
below), not sighting data. Don't confuse the two when writing a
parser: `HordeWatchDB` = config, `HordeWatchCharDB` = actual sightings.

## The sighting record schema

Every entry in `HordeWatchCharDB.Sightings[]` (and the equivalent one in
`CurrentState[playerName]`, which is just the latest record per player) has
this shape. All fields except `player`, `ts`, `method`, `id`, `windowStart`,
`reportCount`, and `reporters` can be `nil`.

| Field | Type | Notes |
|---|---|---|
| `id` | number | Incrementing counter, **scoped to one character's own file** — not a stable cross-character/cross-guildmate key. Don't use it to dedupe across multiple ingested files. |
| `player` | string | `"Name-Realm"` (realm suffix present if cross-realm; normalized to a single `-`, no spaces). |
| `class` | string \| nil | English class token, e.g. `"WARRIOR"`. One of: `DRUID, HUNTER, MAGE, PALADIN, PRIEST, ROGUE, SHAMAN, WARLOCK, WARRIOR` (TBC-era classes only — see `Comm.lua`'s `ValidClasses`). |
| `race` | string \| nil | English race token, e.g. `"Orc"`. One of: `Human, Orc, Dwarf, Tauren, Troll, NightElf, Scourge, Gnome, BloodElf, Draenei`. |
| `level` | number \| nil | 1–70ish. `nil` if never learned (e.g. skull-masked and no matching live unit to backfill from). |
| `levelIsGuess` | bool | True if `level` is uncertain/absent. |
| `guild` | string \| nil | Only populated if the detection method had access to it (direct unit token) or a matching visible unit backfilled it for a combat-log-only sighting — see "Detection methods." |
| `zone` | string | Zone name text (or instance name if no valid map position). |
| `subZone` | string \| nil | Sub-zone text. |
| `mapID` | number \| nil | Blizzard's `UiMapID` for the zone — stable join key to a zone/basemap catalog. |
| `mapX`, `mapY` | number \| nil | **Zone-local** coordinates, 0–1, relative to that one zone's map image only. Not comparable across different `mapID`s. |
| `worldX`, `worldY` | number \| nil | **Continent-scale** coordinates in yards, continuous across every zone sharing the same `continentID`. This is what a multi-zone map should render against, not `mapX`/`mapY`. |
| `continentID` | number \| nil | Which continent's coordinate space `worldX`/`worldY` belong to (Eastern Kingdoms, Kalimdor, Outland are different values). **Different continents are still different coordinate spaces** — there's no single planet-wide coordinate system, same as Blizzard's own world map. A real "world map" needs a continent switcher, not one continuous image. |
| `layer` | number \| nil | Opaque shard/layer fingerprint — see "Layer/shard fingerprint" below. **Not** the game's human-readable "Layer 1/2/3." |
| `method` | string | One of `target, mouseover, nameplate, combatlog, minimap, comm` — see "Detection methods." |
| `ts` | number | Unix epoch seconds, **from the reporting character's own local system clock**, not a server-synced time. Cross-reporter merges can have clock-skew noise. |
| `reporter` | string | Character name that produced this sighting (the *original* observer, even after relay — see below). |
| `relayed` | bool \| nil | True if this row came in over the guild comm channel rather than being personally observed. |
| `relaySender` | string \| nil | Which guildmate's client relayed it (may differ from `reporter` if it passed through someone else first — though in practice it's one hop, see Comm.lua). |
| `relayDelay` | number \| nil | Seconds between the original detection (`ts`) and this client receiving the relay. |
| `windowStart` | number | Timestamp this row's collapse window opened at — internal bookkeeping for the dedupe logic below, probably not useful downstream. |
| `reportCount` | number | How many distinct reporters have corroborated this same encounter (see "Collapse/corroboration"). |
| `reporters` | table\<string,bool\> | Set of reporter character names that corroborated this row. Lua-table-as-set shape: `{["Name1"]=true, ["Name2"]=true}` — becomes a string array or object-with-true-values in JSON depending on your converter. |

**Important:** every position field (`mapX/mapY`, `worldX/worldY`) is the
**REPORTER's own position at the moment of detection, not the sighted
player's real position.** WoW never exposes a hostile unit's actual
coordinates to an addon — this whole category of tool (this one and the
Spy addon it's modeled on) works by inferring "they were near me when I
detected them." Precision is bounded by the detection method (see below),
not exact. Treat this as a sighting/activity signal, not GPS.

## Detection methods (`method` field)

Roughly ordered by how tightly each bounds the true distance between
reporter and target at capture time — useful context for weighting data,
even though HordeWatch itself doesn't score confidence numerically (that was
deliberately removed from the design):

- **`target`** / **`mouseover`** — directly targeted/moused over. Tightest bound, get full unit data (class/race/level/guild) for free.
- **`nameplate`** — their nameplate rendered nearby. Similar precision, full unit data available.
- **`combatlog`** — the widest personal-detection net; catches any hostile player in a combat-log event even if never seen/targeted (~100yd log radius). `GetPlayerInfoByGUID` gives class/race for free but **not** guild or level — those only get backfilled if the same GUID also happens to match a currently visible target/mouseover/nameplate unit (`HW:FindUnitByGUID` in `Detection.lua`). Otherwise `guild = nil`, `level = nil`, `levelIsGuess = true`.
- **`minimap`** — a minimap tracking-blip (e.g. Hunter Track Humanoids) refreshing a player **already** confirmed hostile by one of the methods above. Widest range, can pierce line-of-sight/stealth, but only refreshes known players — doesn't mint brand-new sightings from blip text alone (blip names can't be reliably distinguished from NPCs/party members without prior confirmation).
- **`comm`** — relayed from another HordeWatch user in your guild; inherits whatever method *they* used, but the position is now doubly indirect (their position, at their detection moment, forwarded to you).

## Layer/shard fingerprint

Blizzard exposes no documented "what layer am I on" API — deliberately, it
would make cross-layer coordination trivial, and Blizzard has hotfixed prior
addon-side layer-detection tricks before. `layer` is a reverse-engineered
opaque number sampled from the `serverID` segment of a nearby non-player
GUID (target, a nameplate NPC, or your own pet — see `Position.lua`'s
`GetCurrentLayer()`). It reliably tells you "this sighting was on the same
layer as that one" apart from "a different layer," but:

- It is **not** the human-readable "Layer 1/2/3" the game shows nowhere to addons.
- It is **not guaranteed stable** across login sessions or realm restarts — don't treat two sightings with the same `layer` value from different play sessions as necessarily the same shard.
- This could stop working after a client patch; it's not an official API.

## Collapse/corroboration (why the log isn't one-row-per-detection-event)

`AddSighting` in `Data.lua` merges a new sighting into the existing row for
that player instead of always appending, when it's within
`CollapseWindowSeconds` (default 8s, user-configurable) of that row's
**first-seen** timestamp (`windowStart`) and in the same `zone`. This
prevents:

- Your own client re-detecting the same target via multiple methods within the same moment (nameplate + combat log on one GCD).
- Several guildmates all reporting/relaying one real-world encounter as separate rows.

The window origin is **fixed at first-seen, not rolling** — so a target that
lingers for minutes still produces a fresh row roughly every
`CollapseWindowSeconds`, instead of one row swallowing an entire multi-minute
visit. This matters for movement/heatmap data: expect roughly one data point
per ~8 seconds of continuous presence, not one point per raw detection event
(which could be many per second during combat) and not one point per
encounter (which would lose path/movement information entirely).

When rows merge, `reportCount`/`reporters` track corroboration, and any
field `existing` didn't have yet (or only had a guess for) gets backfilled
from the incoming record — see `mergeSighting()` in `Data.lua` for exact
precedence rules.

## Comm/relay trust model

Sightings broadcast to `GUILD` channel only (not party/raid), using
AceSerializer over an addon-message prefix (`HWatch1`), validated on receipt
(`Comm.lua`'s `validatePayload`: type/range checks on every field, class/race
whitelist). Blizzard authenticates GUILD channel membership server-side, so
a sender is at minimum a real guild member — but the *content* of what they
broadcast is still just their own client's opinion, not independently
verified. A guildmate spoofing their own sightings (not the channel/sender
identity, just the payload content) isn't prevented, so treat `relayed=true`
rows as somewhat lower-trust than personally-witnessed ones if that matters
for your use case.

## Data lifecycle

- **Retention**: rows older than `RetentionDays` (default 14, user-configurable) are pruned every 5 minutes (`PruneSightings`, a repeating timer).
- **Cap**: if the log exceeds `MaxRecords` (default 20,000, user-configurable), the single oldest row is evicted per new sighting (rolling FIFO), independent of the age-based prune.
- **Persistence**: only on logout/`/reload`/exit — see "Where the data lives" above.

## User-tunable settings that affect the data (not fixed constants)

Exposed via `/hw config` (Options.lua), stored in the **account-wide**
`HordeWatchDB` (not `HordeWatchCharDB`) — so these can differ by player and
even by profile:

- `RetentionDays`, `MaxRecords` — retention/cap, as above.
- `CollapseWindowSeconds` — the corroboration/collapse window, as above.
- `CommRateLimitSeconds` — per-player minimum gap between guild broadcasts (doesn't affect what gets logged locally, only what gets shared).
- `ShareToGuild` — whether the comm mesh is on at all; if off, `relayed` rows simply won't exist for that character.
- `FilteredZones`, `Enabled*` zone-gating toggles — whether detection runs at all in a given zone/instance type. A gap in the sighting timeline could mean "nothing happened" or "the addon was configured off there" — these settings aren't recorded per-sighting, so there's no way to distinguish the two from the data alone.

## Transport + web app (built)

Both transport options described above are now implemented:

- **In-game export string** — `HordeWatch/Export.lua` adds `/hw export` (sightings
  since the last export) and `/hw export all` (full log), shown in a copyable
  dialog. Pipeline: `AceSerializer:Serialize` → `LibDeflate:CompressZlib`
  (vendored in `HordeWatch/Libs/LibDeflate/`) → `LibDeflate:EncodeForPrint`.
  Exported rows are the full sighting record shape documented above, not the
  stripped-down comm payload.
- **Offline parser** — `tools/parse-savedvariables` (Node) walks a `WTF/Account`
  tree (or a single file) and converts `HordeWatchCharDB.Sightings` to JSON via
  `luaparse`, tagging each row with `sourceCharacter`/`sourceRealm` since `id`
  is only unique per-character.
- **Web app** — `web/` (React + Vite + TS) decodes the export string entirely
  client-side (a byte-exact JS port of LibDeflate's print encoding + AceSerializer's
  deserializer, verified against real Lua-produced output — see
  `web/scripts/manual-fixture-test.ts`) or ingests the parser's JSON, merges
  multiple imports/characters, and persists to `localStorage`. Sightings table
  (filter/sort), Guilds, Trends, History, and Data Import are all separate
  sidebar sections; Zone Map renders a real basemap per zone when one's been
  supplied locally (see "Zone map imagery" below), falling back to a plain
  scatter square otherwise.

## Zone map imagery

`worldX`/`worldY`/`continentID`/`mapX`/`mapY` are coordinates, not the
underlying map images to render them against - that's Blizzard's own game
art, which this project doesn't extract or ship (copyright/ToS territory
distinct from the gameplay-API data collection everything else here relies
on; see `web/public/maps/README.md` for the reasoning).

Instead, the web app looks for a locally-supplied image at
`web/public/maps/<mapID>.jpg` (`mapID` is the addon's stable per-zone key)
and renders it via Leaflet + `L.CRS.Simple` (the standard technique for
non-geographic/game maps - one static image, pixel coordinates, no real-world
projection) when present, falling back to the placeholder scatter square
otherwise. `web/public/maps/README.md` documents extracting your own copy
with [wow.export](https://github.com/Kruithne/wow.export) against your own
licensed client - nothing here is scraped or redistributed automatically.

The Zone Map view also has an "Outland (all zones)" toggle that plots
`worldX`/`worldY`/`continentID` on one continuous continent image instead of
one zone at a time (`web/src/components/LeafletContinentMap.tsx`,
`web/src/lib/useContinentImage.ts`), using the same locally-supplied-image
model plus a small JSON sidecar (`web/public/maps/<continent mapID>.json`)
giving just the image's pixel dimensions - see "Continent map images" in
`web/public/maps/README.md`. The `worldX`/`worldY` -> pixel conversion
itself is a 6-parameter affine transform (`OUTLAND_AFFINE` in
`LeafletContinentMap.tsx`) fit against real `/hw pos` readings at named
landmarks, not derived from any image metadata - wow.export's own stated
corners for this image turned out not to correspond to HereBeDragons'
coordinate space at all (see gap #2 below). Only Outland is wired up so
far; Eastern Kingdoms/Kalimdor would need their own continent image plus a
similarly landmark-calibrated transform following the same pattern.

Both map views also support a player-name filter, a guild filter, and a
draggable dual-handle time-range slider (`web/src/components/TimeRangeSlider.tsx`),
all combinable. Whenever the current filter narrows the plotted points down
to 10 or fewer distinct players, each of their sightings gets connected into
its own chronological trail line (`web/src/lib/trails.ts`) - dragging the
time slider scrubs that trail in and out. This is what makes "one player's
movement" or "this whole guild's movement, together" visible as an actual
path instead of a scatter of unconnected dots - the guild-fingerprint and
predicted-location ideas both build on this same mechanism.

## What's still missing (the actual gap)

1. **Real client data disproved this doc's earlier confident assumption about TBC Classic's `mapID` numbers - fixed for 6 of 7 Outland zones.** This repo initially shipped zone images under old textbook values (Hellfire Peninsula = 100, Netherstorm = 109, etc.). Real `/hw pos` readings showed this client's actual `C_Map.GetBestMapForUnit()` values are completely different: Hellfire Peninsula = 1944, Netherstorm = 1953, Shadowmoon Valley = 1948, Terokkar Forest = 1952, Nagrand = 1951, Zangarmarsh = 1946. All six zone images are renamed accordingly. Only **Blade's Edge Mountains (`104.jpg`)** is still filed under an unconfirmed guessed mapID, pending a real sighting from that zone. **Lesson: don't trust "well-documented" WoW ID numbers without checking them against this specific client's actual output** — see `web/public/maps/README.md`.
2. **The Outland continent → pixel transform is now solved and verified - abandon wow.export's stated image corners entirely.** They looked authoritative (exact numbers straight from wow.export's own export metadata) but turned out not to correspond to HereBeDragons' `worldX`/`worldY` coordinate space at all - confirmed by real sightings landing in empty space off the rendered terrain. The actual fix: collected 6 real `/hw pos` readings at named, visually unambiguous landmarks across 5 different zones (Dark Portal and Honor Hold in Hellfire Peninsula, Hand of Gul'dan in Shadowmoon Valley, Auchindoun in Terokkar Forest, Oshu'gun in Nagrand, Serpent Lake in Zangarmarsh), located each one's precise pixel position on the continent image by eye, and least-squares fit a full 6-parameter affine transform (`OUTLAND_AFFINE` in `LeafletContinentMap.tsx`) directly against that real data - no wow.export metadata involved at all. Max residual across all 6 points: ~115px on a 16384px-wide image (~0.7%), consistent with manual pixel-picking imprecision rather than a systematic error. Verified end-to-end: all 6 points render on their correct zone's landmass in the actual app.
3. **`HereBeDragons-2.0` coordinate output is otherwise unverified against a live client** — built and syntax-checked by reading the library's documented API; item 2 above is the first concrete real-client discrepancy found (in wow.export's corner metadata, not in HereBeDragons itself, which appears to be working correctly).
4. **The addon's export/JS-decode pipeline is unverified against a live client too** — round-tripped against the *real* vendored `LibDeflate.lua`/`AceSerializer-3.0.lua` under a standalone Lua interpreter (not WoW), and the JS port matches that byte-for-byte, but `/hw export` itself hasn't been run in an actual WoW client. Worth confirming the popup/edit-box UI behaves and the string pastes cleanly before relying on it. (This one's likely fine in practice — real exported data has now round-tripped through this pipeline, per items 1-2 above — but hasn't been explicitly called out as confirmed until now.)
5. **Only Outland has a continent map** — Eastern Kingdoms/Kalimdor would need their own continent image + a similarly landmark-calibrated affine transform (see "Zone map imagery" above) before the continent toggle covers them.
6. **Time-based playback is now built** (see "Zone map imagery" above) — a draggable time-range slider plus per-player trail lines on both map views, combinable with the player-name and guild filters. What's *not* built yet: actual pattern prediction ("where is this player/guild likely to be at 8pm based on history") - right now you can manually narrow the time slider to a similar hour across multiple days and eyeball the pattern, but there's no automated "most likely zone at time T" summary. That'd need bucketing historical sightings by hour-of-day/day-of-week per player or guild and surfacing the top zones for a given bucket - a natural next step on top of the same data, not yet built.

## File map (addon source, for anything not covered above)

- `HordeWatch/Core.lua` — addon bootstrap, all settings defaults, zone-gating logic, slash commands.
- `HordeWatch/Position.lua` — coordinate capture (zone-local + world), layer fingerprint.
- `HordeWatch/Detection.lua` — the five detection triggers, how each populates a record.
- `HordeWatch/Data.lua` — record shape, collapse/merge logic, retention/pruning.
- `HordeWatch/Comm.lua` — guild broadcast/receive, wire payload, validation.
- `HordeWatch/Export.lua` — builds the copy-pasteable export string (see "Transport + web app" above).
- `HordeWatch/Options.lua` — the settings panel (source of truth for every user-tunable value).
- `HordeWatch/UI.lua`, `MinimapIcon.lua` — in-game display only, not relevant to the data model.
