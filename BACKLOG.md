# Ping — backlog

_(The addon is being renamed from Spy to **Ping** — see item 2.)_

Work that is agreed but not started. Newest ideas at the bottom of each section.

---

## 1. Finish out themes

Six palettes exist (Classic Gold, Midnight, Horde, Alliance, Emerald, Monochrome).
As of the theme fix they set the window background, title bar, border, title text,
healer marker and cooldown colour — the background and title bar are what make the
change visible.

Still to do:

- **Class bars are not themed.** They are the dominant visual element of every row
  and currently stay at their stock class colours under every theme. Options: leave
  them (class identity is information, not decoration — a strong argument), or let a
  theme apply a saturation/tint pass over them.
- **Bar texture and font** are not themed at all; they sit in Rows & Text as
  independent settings. Decide whether a theme should set them.
- **Preview / undo.** Picking a theme applies immediately with no way to see it
  first and no revert beyond picking another. Worth capturing the pre-theme colours
  so a single "revert" is possible.
- **Custom themes.** Save current colours as a named theme, export/import as a
  string. The natural end state.

---

## 2. Rename the addon so it can run alongside the original Spy

Right now this **is** Spy — same folder name, same addon name, same saved variables.
Installing it replaces the original, and the two can never be loaded at once.

To make them coexist, all of these have to change together:

| Thing | Current | Notes |
|---|---|---|
| Folder | `Spy/` → `Ping/` | Determines the addon name WoW sees |
| `.toc` filename | `Spy.toc` → `Ping.toc` | Must match the folder exactly |
| SavedVariables | `SpyDB`, `SpyDebugDB` | Global — collides with real Spy |
| SavedVariablesPerCharacter | `SpyPerCharDB` | Where KoS / win-loss / player data lives |
| Lua global | `Spy` | Referenced throughout every file |
| Frame names | 13 of them | `Spy_MainWindow`, `Spy_AlertWindow`, `Spy_KoSButton`, `Spy_GameTooltip`, `Spy_BarDropDownMenu`, `Spy_MapNoteList_mini`/`_world`, `Spy_DebugDumpFrame`/`Scroll`, `SpyTitleBarFrame`, `SpyResizeGripLeft`/`Right`, `SpyTempTooltip` |
| AceLocale namespace | `"Spy"` | `AceLocale:NewLocale("Spy", …)` in every locale file |
| AceDB / AceConfig registration | `"Spy"`, `"Spy Commands"` | Options panel identity |
| Slash command | `/spy` → `/ping` | Needs its own |
| Texture paths | `Interface\AddOns\Spy\Textures\…` | Follow the folder rename |
| AceComm prefix | `Spy.Signature` = `"[Spy]"` | Two addons must not talk over the same prefix |

**Watch out for:** the frame names and the AceComm prefix. Everything else fails
loudly at load; those two fail *quietly* — colliding frames silently overwrite each
other, and a shared comm prefix means the two addons would exchange data as if they
were the same thing.

**Name chosen: `Ping`.** This is largely a careful find-and-replace,
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

## 4. Healer spell list as a proper list widget

Currently a multiline text box. Wanted instead: a scrolling list like
BetterBlizzFrames' aura filter — one row per spell with its icon, name, spell id,
and an X to remove it, plus an "Add" box underneath.

Notes for whoever builds it:

- AceConfig has no list-of-rows widget, so this needs a **custom AceGUI widget**
  (or a plain frame embedded via `dialogControl`). That is the bulk of the work,
  not the data side — the data is already a parsed list and `Spy:BuildHealerSpellNames`
  already handles names, ids and links.
- Icons come from `GetSpellTexture(id)`. The current list stores NAMES, not ids, so
  either store ids alongside (better for icons) or resolve name → id at display
  time, which is not reliable in reverse.
- The same widget should serve the **cooldown watch list**, which has the identical
  shape (spell rows + add box). Build it once, use it twice.
- Keep the text box as an import/export escape hatch, or a "paste a list" mode —
  it is the only practical way to move a list between profiles or characters.

---

## Unfiled

- _(nothing yet)_
