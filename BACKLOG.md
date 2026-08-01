# Ping — backlog

_(Renamed from Spy to **Ping**. The rename is done — item 2 below is kept as a record of what it touched.)_

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

## 2. Rename the addon so it can run alongside the original Spy — **DONE**

Shipped. The addon is `Ping`: own folder, `.toc`, saved variables, Lua global,
frame names, AceLocale namespace, AceConfig registrations, `/ping` slash command,
texture paths and AceComm prefix (`[Ping]`). Nothing is shared with Spy, so both
can be installed and loaded together.

Two collisions the original checklist did **not** list were caught during the
work and are worth remembering, because both would have failed silently:

- `CountFrame` — a generic global frame name in MainWindow, identical in Spy.
- `StatsDropDownMenu` — declared in the stats XML, identical in Spy.

Neither is Spy-prefixed, so a search for "Spy" would never have found them. Any
future fork should audit **all** global frame names, not just the ones carrying
the addon's name.

Left deliberately unchanged: the CurseForge URL in `UpgradeAvailable` still
points at `addons/spy-tbc`, since no Ping page exists. Two upstream locale typos
(`PREIST` in deDE, `DEATHKNIGHt` in frFR) were left alone — they predate this
work and are dead keys nothing reads.

---

## 3. Import data from the original Spy

Now that the rename is done, a one-click import that pulls history across from a real Spy
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
  not the data side — the data is already a parsed list and `Ping:BuildHealerSpellNames`
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
