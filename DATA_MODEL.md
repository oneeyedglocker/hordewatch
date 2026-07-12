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
6. **Time-based playback is now built** (see "Zone map imagery" above) — a draggable time-range slider plus per-player trail lines on both map views, combinable with the player-name and guild filters.
7. **Automated time-of-day/day-of-week pattern prediction is now built too** (`lib/fingerprint.ts`, on the Trends page). `predictZone` buckets a subject's historical sightings by hour-of-day and day-of-week and answers "where are they most likely to be right now" via three fallback tiers (same day-of-week + hour window → any day at that hour → the subject's all-time top zone) as the matching window gets too sparse to trust. There's no manual "pick a future day/time" control anymore (removed per user feedback - it wasn't landing) - the prediction always reflects the actual current day/hour.
8. **A "Trending snapshot & predictions" narrative panel** (`lib/insights.ts`, `components/ActivityFingerprint.tsx`) replaced the old single predict-card. Picking a player or guild now generates a short list of plain-English observations - a "right now" zone prediction (reusing `predictZone`), a peak active-hours window, a zone-affinity line naming the specific real landmark they cluster nearest to (see item 9), a day-of-week + zone "schedule" signal, a 7-day activity momentum comparison, and a reporter-corroboration caveat. Every one of these is a heuristic frequency read, explicitly not a trained model, and each independently decides whether its backing sample is strong enough to state at all (skips itself rather than forcing a thin claim) - all gated behind a shared `MIN_SAMPLE` floor. Kill/death attribution (who's killed whom) is explicitly **not** buildable from the current data model - the addon only logs sightings (position + time), not combat-log kill credit; that would need a new addon-side event type, out of scope for the web dashboard alone.
9. **Real named-landmark coordinate data now exists** (`lib/zoneLandmarks.ts`), for all 6 zones with an image - so "spends most of their time near X" can name an actual verified place instead of a vague zone-level hint. This was an actual research gap, not a hard blocker: sourced from `IAmChills/HardcoreAchievements`' `CheckMapDiscovery.lua` (zone exploration sub-areas, in the same [0,1] mapX/mapY convention this app already uses) and cross-checked against `ATTWoWAddon/AllTheThings`' independently-maintained coordinate data and Dugi's Guide's `ExplorationTrackingPoints.lua` - all three agreed within ~1-2% on every landmark spot-checked. Only 6 of the ~100 landmarks across those zones also have a confirmed real worldX/worldY (the same 6 points used to fit `OUTLAND_AFFINE` - see item 2); Netherstorm has zero confirmed world anchor at all, so landmarks there intentionally have no `worldAnchor` rather than a guessed one.
10. **Fixed: synthetic test data was landing off the real terrain.** The generator used to jitter +/-800-900 world yards (or +/-0.35 map units) around one made-up "zone center" per zone - on an irregular coastline that's easily enough to place a point in open water or off the image entirely, which is exactly what got reported. The fix (see the regenerated `hordewatch-30day-testdata` script) jitters tightly (~3% of the map / ~120 world yards) around real points from `zoneLandmarks.ts` instead, and only emits worldX/worldY for sightings anchored to one of the 6 landmarks with a confirmed real world position - everything else still gets accurate mapX/mapY (so it's correct on the per-zone view) but simply doesn't appear on the continent view, the same way real addon data behaves when HereBeDragons can't resolve a world position.
11. **The insights engine now uses real (if lightweight) statistics instead of hand-picked magic-number thresholds** (`lib/confidence.ts`, consumed by `lib/insights.ts` and `predictZone` in `lib/fingerprint.ts`). Still explicitly not a trained model - every number is closed-form arithmetic - but three real techniques replace the old flat cutoffs:
    - **Wilson score confidence intervals** for every proportion-based claim (peak-hour-window share, zone/landmark share, day-of-week share) - the *lower bound* of the interval has to clear `MIN_CONFIDENCE_LOWER_BOUND` (0.25) before an insight fires, so a 75% share from 4 sightings (wide interval, low lower bound) is correctly held back while the same 75% from 100 sightings (tight interval) fires. This replaces the old separate "MIN_SAMPLE=5" + "pct>=40" style checks with one principled, sample-size-aware bar.
    - **Recency-weighted tallying** (`recencyWeight`, 14-day half-life, anchored to real wall-clock time) for every insight except the raw descriptive charts (Top zones, hour histogram, day×hour heatmap, which intentionally stay unweighted as historical record). A guild's abandoned Tuesday-8pm raid slot from two months ago no longer out-votes their current Thursday-8pm one.
    - **A log-rate-ratio z-approximation** for the momentum insight, replacing the flat "must differ by ≥25%" cutoff - correctly suppresses a 150% swing between 2 and 5 sightings (noise) while firing on a 30% swing between 200 and 260 (real signal backed by a much bigger sample).
    - A **"Show details" verbose toggle** on the Trending Snapshot panel reveals the raw numbers behind every bullet (sample size, weighted sample size, observed share, Wilson lower bound, confidence tier, which fallback tier won) - built for auditing a claim, not just trusting it.
    - Deliberately **not** done: circular (von Mises) statistics for time-of-day, a proper two-proportion z-test for the schedule insight's "more concentrated than usual" check, Bayesian hierarchical modeling, or any actual clustering/ML for landmark detection (nearest-neighbor against the *curated real* landmark list in `zoneLandmarks.ts` is deliberately preferred over k-means or similar, since an algorithmic cluster centroid isn't tied to a real named place the way a matched landmark is). These were considered and left out as disproportionate complexity for a project with no labeled data to validate them against - real state-of-the-art prediction here means better use of frequency statistics, not fake ML theater.
    - **Architecture note**: every function in `insights.ts`/`fingerprint.ts` is a pure function - `(Sighting[], ...) -> result` - with no dependency on where the sightings array came from (`localStorage` today, an API response later). Moving to a shared backend (see item 12 below) is a data-loading-layer swap, not a rewrite of this engine.
12. **Everything today is single-browser, local-only storage** (`lib/store.ts`, two `localStorage` keys) - which is the real blocker for sharing this with a whole guild rather than one person's browser. Every officer currently needs their own import of the same export string; nobody sees anyone else's imports. A shared backend (even something lightweight - a small hosted Postgres/SQLite + a thin API, or a serverless function) is the right direction once multiple people need to see the same data, and `mergeSightings` (`lib/store.ts`) - which already handles cross-import dedup by `sourceRealm/sourceCharacter/id` - is exactly the logic that would move server-side to become the canonical merge instead of being duplicated per-browser. This does **not** change any prediction/insight results (see the architecture note above) and hasn't been started - noted here as the next real step once the trending features have proven their value, not before.
13. **Fixed: the Zone map's player/guild filters could reference someone with zero sightings in the currently-viewed zone.** The old guild `<select>` (and the "filter by player name" free-text box) listed every guild/player in the *entire* dataset regardless of which zone or time window was actually being viewed - switching zones didn't clear or re-scope the filter, so picking (or leaving selected) a guild with no presence in the new zone silently rendered an empty map with no explanation. Replaced with `PresenceList` (`components/PresenceList.tsx`): a tabbed Players/Guilds list, populated *only* from sightings actually present in the current zone (or the continent-eligible pool) **and** the current time-range window, each row clickable to filter, with counts shown and a guild selection narrowing the Players tab to that guild's own roster. Switching zone or view now also clears any active player/guild filter, since a selection from one zone rarely makes sense in another. While investigating this, also found and fixed a real pre-existing bug in both Leaflet map components: `fitBounds()` was silently rendering every zone/continent map at ~30-50% of its actual container size (Leaflet's default `zoomSnap: 1` forces the fit onto the nearest whole zoom level, which is very often well short of what the container could actually fit) - added `zoomSnap: 0` to both `LeafletZoneMap.tsx` and `LeafletContinentMap.tsx` so `fitBounds()` can use a continuous zoom that actually fills the space. This was already broken before this session's changes; the presence-list work is what surfaced it. A follow-up also fixed `PresenceList`'s search input rendering enormous - `.text-input`'s shared `flex: 1 1 220px` is sized for a horizontal row, but `PresenceList` is a vertical flex column, so that basis was applying to height instead of width; scoped `flex: none; width: 100%; min-width: 0` to `.presence-search` instead.
14. **Time-range playback (play/pause + a sweeping trailing-window view) was built, then reverted per user feedback ("I don't think the play button does much for us")** - not worth re-attempting without a clearer idea of what would actually make it valuable. If revisited, the once-working approach was: `lib/usePlayback.ts` (rAF-driven playhead, throttled to ~150ms React commits so marker rebuilds stay cheap regardless of dataset size) + `components/PlaybackControls.tsx`, narrowing both map views to a trailing window around the playhead so old sightings age out as time sweeps forward - reusing the existing per-player trail-drawing with zero changes to either Leaflet component.

## File map (addon source, for anything not covered above)

- `HordeWatch/Core.lua` — addon bootstrap, all settings defaults, zone-gating logic, slash commands.
- `HordeWatch/Position.lua` — coordinate capture (zone-local + world), layer fingerprint.
- `HordeWatch/Detection.lua` — the five detection triggers, how each populates a record.
- `HordeWatch/Data.lua` — record shape, collapse/merge logic, retention/pruning.
- `HordeWatch/Comm.lua` — guild broadcast/receive, wire payload, validation.
- `HordeWatch/Export.lua` — builds the copy-pasteable export string (see "Transport + web app" above).
- `HordeWatch/Options.lua` — the settings panel (source of truth for every user-tunable value).
- `HordeWatch/UI.lua`, `MinimapIcon.lua` — in-game display only, not relevant to the data model.
