# Ping — backlog

_(Renamed from Spy to **Ping**. The rename is done — item 2 below is kept as a record of what it touched.)_

Work that is agreed but not started. Newest ideas at the bottom of each section.

---

## 1. Finish out themes

Six palettes exist (Classic Gold, Midnight, Horde, Alliance, Emerald, Monochrome).
As of the theme fix they set the window background, title bar, border, title text,
healer marker and cooldown color — the background and title bar are what make the
change visible.

Still to do:

- **Class bars are not themed.** They are the dominant visual element of every row
  and currently stay at their stock class colors under every theme. Options: leave
  them (class identity is information, not decoration — a strong argument), or let a
  theme apply a saturation/tint pass over them.
- **Bar texture and font** are not themed at all; they sit in Rows & Text as
  independent settings. Decide whether a theme should set them.
- **Preview / undo.** Picking a theme applies immediately with no way to see it
  first and no revert beyond picking another. Worth capturing the pre-theme colors
  so a single "revert" is possible.
- **Custom themes.** Save current colors as a named theme, export/import as a
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

## 3. Import data from the original Spy — **DONE**

Shipped as its own **Data → Spy Import** tab, backed by `Ping:ImportSpyData` and
`Ping:GetSpyImportStatus` in `List.lua`. Reads `SpyPerCharDB` — players, KoS with
reasons, ignore list — merges rather than replaces (higher win/loss count wins, the
newer sighting wins, an exact level beats a guess), never writes back to Spy, and
prints what it did. There are two buttons: everything, or KoS only. Both are
disabled outright when `SpyPerCharDB` is absent, with the tab saying why.

Spy's own settings are deliberately not carried: the config has diverged far enough
that a fresh profile is the better default.

---

## 4. Healer spell list as a proper list widget — **DONE**

Shipped as `Ping/SpellListWidget.lua`, an AceGUI widget registered as
`PingSpellList` and attached to both lists with `dialogControl`. One row per spell:
icon, name, spell id (plus the duration for cooldowns), and an X to remove it, with
an add box and Add button underneath. Rows carry a spell tooltip on hover.

Two decisions worth knowing about:

- **The stored value did not change.** It is still the same newline-separated text,
  so `BuildHealerSpellNames`, `BuildCooldownLookup`, the reset buttons and the
  transfer code all work untouched. It also means AceConfigDialog falls back to the
  plain multiline box on its own if the widget ever fails to load, so a bug here
  cannot cost anybody their list.
- **Untouched rows are written back verbatim.** The cooldown list uses a trailing
  `= 120` to override a duration and allows `--` comments; rebuilding lines from
  parsed fields would have quietly dropped both.

Adding accepts a shift-clicked spell link, a bare id, or a typed name, and refuses
duplicates by either id or name. A line whose id the client cannot resolve is kept
and shown in red with a question-mark icon rather than dropped — that is the signal
that a line is not matching anything.

Still open: there is no longer a raw-text view of either list. Moving a list between
characters goes through **Data → Transfer** instead, which covers it, but a
"paste a list" mode would be cheaper for bulk edits.

---

## Unfiled

- _(nothing yet)_
