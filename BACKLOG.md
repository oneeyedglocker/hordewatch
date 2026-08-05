# Ping — backlog

_(Renamed from Spy to **Ping**. The rename is done — item 2 below is kept as a record of what it touched.)_

Work that is agreed but not started. Newest ideas at the bottom of each section.

---

## 1. Finish out themes — mostly **DONE**

Fourteen themes. Each sets the window background, title bar, border, title text,
healer marker, cooldown color, the chrome icons, **and the class bars**.

Shipped since this entry was written:

- **Class bars are themed** (2.9.2). A theme supplies a pull color and a
  strength; each class is blended that far toward it from the STOCK_CLASS table,
  so tints never compound when switching themes. Strength is capped at 0.45.
  A test asserts no theme crushes any two classes below 50% of their untinted
  separation — worst case is Monochrome at 55%.
- **Fonts are themed** (2.9.2), for the seven artwork themes. `LockFont` lets
  someone keep their own face.
- **Undo** (2.9.1). One step, snapshot taken on every apply.

- **Custom themes** (2.9.3). `CustomThemes.lua`. Saves the resolved colors
  rather than the tint recipe, so a saved theme looks tomorrow as it did when
  saved. Exports through AceSerializer with a magic string and schema; imports
  are treated as hostile — only whitelisted settings of the right type survive,
  colors are clamped to 0-1, unknown branches are dropped, and a name clash is
  suffixed rather than overwritten.

- **Bar texture is themed** (2.9.7). A theme names one in `theme.settings`;
  applying or reverting repaints the rows already on screen, which it did not
  before — rows only read the texture when they are built.
- **Six more themes** (2.9.7): Slate, Graphite, Serenity, Frostbite, Void and
  Ember, color-only, taking the flat high-contrast look from the damage meters
  people already run.

Still open:

- **A `Ping:InstallTheme(name, table)` registration API**, of the kind Details!
  uses, so other addons could ship Ping themes. The custom theme format is
  already the right shape for it.

Closed as won't-do:

- ~~Tinting class bars was argued against on the grounds that class color is
  information rather than decoration.~~ Overruled deliberately: the blend
  approach preserves hue order, and the test above enforces that it stays
  readable.

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

## 5. A Guild Sightings window

Shared detections currently land in the same Nearby list as your own. That is
fine for a party or raid, who are usually standing near you, but guild-wide
sharing pulls in every enemy seen by anyone in the guild across the continent.

The problem is not clutter, it is that it **degrades the sort**. The window
draws 15 rows (`Ping.ButtonLimit`) but sorts the whole pool, and kill priority
scores KoS at +1000 against only +100 for "actively detected". So a KoS target
three zones away outranks somebody standing on top of you.

Proposal: give shared sightings their own list, alongside Nearby / Last Hour /
Ignore / Kill On Sight, reachable with the same left/right arrows.

What it would take:

- **A fifth list type.** `Ping.ListTypes` drives the arrows and the title, so
  the navigation is close to free. The list tables (`NearbyList`, `LastHourList`,
  …) are parallel, so a `GuildList` follows the same shape.
- **Route shares to it.** `CommReceived` → `AddDetected(player, time, learnt,
  source)` already carries `source`, and a non-nil source that is not us *is*
  the signal. Today that only decides the alert sound and Active vs Inactive.
- **Decide the overlap rule.** If you detect someone yourself who is also in the
  guild list, do they appear in both? Probably yes, with your own detection
  winning the Nearby row.
- **Expiry.** Guild sightings want a longer timeout than Nearby - the point is
  "somebody saw them recently", not "they are next to me".
- **Column difference.** This list wants *who reported it* and *where*, which
  Nearby does not show. That is the only real UI work.

The rest of the plumbing exists. The risk is in `RefreshCurrentList`, which
assumes list identity in a few places, and in the Statistics window, which
enumerates list types.

Alternative considered and rejected: filtering shares by zone. Cheaper, but it
throws away the cross-zone intel rather than giving it a home.

---

## Unfiled

- _(nothing yet)_
