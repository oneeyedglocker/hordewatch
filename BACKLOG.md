# Spy — backlog

Work that is agreed but not started. Newest ideas at the bottom of each section.

---

## 1. Finish out themes

Six palettes exist (Classic Gold, Midnight, Horde, Alliance, Emerald, Monochrome) and
each sets four colours: title bar, window border, healer marker, cooldown text.

Not yet done:

- **Coverage.** A theme currently touches four of the window's colours. The KoS edge
  is deliberately excluded (red-for-danger should not move between themes) but the
  class bars, row background, and window backdrop are simply not covered yet, so a
  theme changes less than it looks like it should.
- **Bar texture and font** are part of a "look" and are not themed at all — they sit
  in Rows & Text as independent settings. Decide whether a theme should set them
  (more complete, but overwrites deliberate choices) or stay colour-only.
- **Preview.** Picking a theme applies it immediately with no way to see it first
  and no undo beyond picking another. A preview swatch, or a "revert" that restores
  the colours from before the last theme was applied, would make experimenting safe.
- **Custom themes.** Save the current colours as a named theme; export/import as a
  string so a setup can be shared. This is the natural end state of the feature and
  probably where it should land.

---

## 2. Rename the addon so it can run alongside the original Spy

Right now this **is** Spy — same folder name, same addon name, same saved variables.
Installing it replaces the original, and the two can never be loaded at once.

To make them coexist, all of these have to change together:

| Thing | Current | Notes |
|---|---|---|
| Folder | `Spy/` | Determines the addon name WoW sees |
| `.toc` filename | `Spy.toc` | Must match the folder exactly |
| SavedVariables | `SpyDB`, `SpyDebugDB` | Global — collides with real Spy |
| SavedVariablesPerCharacter | `SpyPerCharDB` | Where KoS / win-loss / player data lives |
| Lua global | `Spy` | Referenced throughout every file |
| Frame names | 13 of them | `Spy_MainWindow`, `Spy_AlertWindow`, `Spy_KoSButton`, `Spy_GameTooltip`, `Spy_BarDropDownMenu`, `Spy_MapNoteList_mini`/`_world`, `Spy_DebugDumpFrame`/`Scroll`, `SpyTitleBarFrame`, `SpyResizeGripLeft`/`Right`, `SpyTempTooltip` |
| AceLocale namespace | `"Spy"` | `AceLocale:NewLocale("Spy", …)` in every locale file |
| AceDB / AceConfig registration | `"Spy"`, `"Spy Commands"` | Options panel identity |
| Slash command | `/spy` | Needs its own |
| Texture paths | `Interface\AddOns\Spy\Textures\…` | Follow the folder rename |
| AceComm prefix | `Spy.Signature` = `"[Spy]"` | Two addons must not talk over the same prefix |

**Watch out for:** the frame names and the AceComm prefix. Everything else fails
loudly at load; those two fail *quietly* — colliding frames silently overwrite each
other, and a shared comm prefix means the two addons would exchange data as if they
were the same thing.

Name still to be chosen. Once picked, this is largely a careful find-and-replace,
verifiable the same way the config restructure was: diff the set of referenced
globals before and after and confirm nothing was missed.

**Do this before item 3** — the import only makes sense once the two are separate
addons with separate saved variables.

---

## 3. Import data from the original Spy

Once renamed (item 2), a one-click import that pulls history across from a real Spy
install, so switching does not mean starting from an empty database.

What has to move, from Spy's saved variables:

- `SpyPerCharDB.KOSData` — the Kill-on-Sight list, and the reasons attached to each
- `SpyPerCharDB.PlayerData` — every player ever seen: class, level, guild, race,
  last-seen time and location, healer flag, win/loss counts
- `SpyPerCharDB.IgnoreData` — the ignore list
- `SpyDB` — profile settings, if worth carrying (optional; the config has diverged
  enough that a fresh profile may be the better default)

Design notes:

- A button in **Data → Storage**, not automatic. Importing should be a decision.
- **Merge, don't replace.** Someone may have used both. Keep the higher win/loss
  counts and the more recent last-seen; never silently discard a KoS entry.
- **Report what happened** — "imported 1,240 players, 37 KoS, 12 ignored" — rather
  than a silent success. A silent import that half-worked is indistinguishable from
  one that worked.
- Import is only possible while the original Spy is *installed*, since its saved
  variables have to be loaded for us to read them. Say so plainly in the UI if
  `SpyPerCharDB` is not present, rather than showing a button that does nothing.
- Non-destructive to the source: read only, never write back to Spy's tables.

---

## Unfiled

- _(placeholder — the fourth bullet in the original list was left empty)_
