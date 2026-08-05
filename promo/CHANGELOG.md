# Ping — release notes

User-facing changes only. Paste the relevant section into the CurseForge
changelog box when uploading a file. Internal cleanups (comment wording,
refactors, promo assets) are deliberately left out — they mean nothing to
someone deciding whether to update.

Two sections per release, in this order: **New Features and Improvements**,
then **Bug Fixes**. Keep the order consistent so people can scan.

---

## 2.10.3

### New Features and Improvements

- **Row spacing is now a setting.** The gap between rows was fixed at 2 pixels;
  it's a slider under Look → Rows & text now, 0 to 10. Zero packs the rows edge
  to edge for a denser window.

---

## 2.10.2

### Bug Fixes

- **Removed the black box behind the header buttons.** Several themes drew a
  small plate behind each of the title-bar buttons; on themes with a dark
  border it read as a black square. The buttons are now just their icons,
  tinted to match the theme, sitting on the title bar the way the lighter
  themes already showed them.

---

## 2.10.1

### Bug Fixes

- **Visiting Villain HUD no longer changes the font for every theme after it.**
  A theme that names a font wrote it into your profile and nothing put it back,
  so once Villain had been picked, every theme chosen afterwards kept its face —
  and because the row and number faces fall back to the main one, all three
  went with it. Picking a theme that names no font now restores the font you
  chose by hand, or the default if you never chose one. "Keep my font" is
  unaffected and still wins over everything.

- **Removed the divider from the theme list.** It used to separate the themes
  that recolored the artwork from the ones that replaced it. Every theme is a
  recolor now, so it was separating nothing. The divider above your saved
  themes stays.

---

## 2.10.0

### New Features and Improvements

- **Themes are colors now, not artwork.** The seven "artwork" themes carried 56
  texture files between them. The five button glyphs turned out to be the *same
  file copied seven times* — already recolored at runtime — and the rest were
  flat squares with a border. All seven looks are unchanged; they are described
  by color settings instead of textures. 62 files removed.
- **One theme list.** With no artwork themes to separate, the divider in the
  theme dropdown is gone. Twenty themes, one list.
- **Themes can set the row and number fonts** (`RowFont`, `DataFont`) and ask
  for outlined text. Villain HUD uses this for the look it always had. "Keep my
  font" still overrides all of it.

### Bug Fixes

- **The window background color finally works.** It was registered against the
  frame's backdrop, which Ping removes whenever the border is off — the default
  for every theme since 2.9.6 — so the color painted nothing and you saw an
  untinted Blizzard texture instead. Every theme's background color has been
  inert. This is why themes looked more alike than their palettes suggested.
- **Switching away from a theme that set fonts no longer keeps them.** Going to
  Blacked Out skipped the reset that clears them.

---

## 2.9.8

### New Features and Improvements

- **The Look page is now four tabs** — **Theme**, **Title bar**, **Rows & text**
  and **Window** — instead of one long page whose "Window" box held 23 of the 34
  controls. Each tab fits on screen. Nothing was removed.
- **The title bar's settings are all in one place.** Its style, color, opacity
  and text color used to sit in *Window* while the four icon colors on that same
  strip were in a separate *Header controls* box at the bottom of the page.
- **Both row edge colors are together.** Kill-on-Sight edge color was on Look;
  the healer edge color was on a different page entirely (Sort Priority). The
  healer edge *toggle* stays with the other healer settings.
- **Clearer labels.** "Select a Font" and "Select the Row Height" are now
  "Font" and "Row height", and on a tab called Title bar the controls no longer
  each repeat the words "title bar".

### Bug Fixes

- **Options no longer shuffle position between sessions.** The four header icon
  colors each carried two `order` values, so they rendered on top of the title
  bar settings; the Minimap button page was tied with Alerts, leaving those two
  pages in whatever sequence they happened to come back in.

---

## 2.9.7

### New Features and Improvements

- **Six new themes**, styled after the flat, high-contrast look of the damage
  meters people already run: **Slate**, **Graphite**, **Serenity**,
  **Frostbite**, **Void** and **Ember**. All six sit in the color-only half of
  the theme list, so they recolor the window without swapping the artwork.
- **A theme can now set the bar texture.** The six new themes ask for the flat
  bar, and switching to a theme repaints the bars you already have on screen
  instead of only the next one drawn. Undo puts your old texture back.

---

## 2.9.6

### New Features and Improvements

- **No theme turns the border on any more.** Four of the artwork themes still
  asked for one on top of artwork that already draws its own edge. Every theme
  now leaves the border off; the toggle in Look is still there if you want one.

---

## 2.9.5

### New Features and Improvements

- **Header controls is now its own section** in Look, alongside Rows & text,
  instead of a box tucked inside Window.
- **Panel opacity and Window opacity** are named for what they do. Panel opacity
  fades only the background behind the list; Window opacity fades everything
  including the text.

### Bug Fixes

- **"Keep my font" did nothing under Villain HUD.** That theme sets its three
  faces directly from the artwork style rather than through the normal font
  setting, so the lock was guarding a path it never used. It is honoured there
  now. The outline and larger title stay — those belong to the artwork, not the
  typeface.

### Removed

- **Show background.** The window always has one.
- **Transparency in BGs.** It applied in dungeons and raids too, not just
  battlegrounds, and there is no reason to want a different number there. One
  transparency now applies everywhere.

---

## 2.9.4

### Bug Fixes

- **"Keep my font when changing themes" kept the wrong font.** It only stopped a
  theme writing the font, so it pinned whatever was showing — usually the last
  theme's font, not one you had chosen. Ping now remembers the font you pick in
  Rows & Text and puts that one back on every theme change. Turning the setting
  on adopts the font showing at that moment as yours.

---

## 2.9.3

### New Features and Improvements

- **Custom themes.** Tune the colors how you like, give it a name, and save it
  as a theme. Saved themes appear in the theme list under their own heading.
- **Share a theme.** Export a saved theme to a code and paste it on another
  character, or hand it to a guildmate. Importing never overwrites a theme you
  already have — a name clash gets a number.

---

## 2.9.2

### New Features and Improvements

- **Themes now color the class bars.** All fourteen themes tint the class bars
  to match. The tint is a blend, never a replacement, so Warlock stays bluer
  than Druid and Priest stays the lightest — classes remain identifiable at a
  glance under every theme.
- **Artwork themes set their own font.** The seven artwork themes now carry a
  matching typeface, the way Villain HUD already did.
- **Keep my font when changing themes.** *Look → Window* — turn it on and no
  theme will replace the font you picked in Rows & Text.

---

## 2.9.1

### New Features and Improvements

- **Undo theme.** *Look → Window → Undo theme* puts back the colors and window
  settings you had before the last theme was applied. One step, so trying a
  theme is no longer a one-way door.

---

## 2.9.0

### New Features and Improvements

- **TomTom waypoints can now be turned off.** *Radar → Map → Alt-click a name to
  set a TomTom waypoint*. The feature already worked and was on by default, but
  there was no way to reach it in the options. Greyed out if TomTom is not
  installed.

---

## 2.8.9

### New Features and Improvements

- **Title text color.** *Look → Window → Title text color* now sets the color
  and opacity of the window title. Previously the title bar could be styled but
  not the text on it.

### Bug Fixes

- **The list lagged behind in busy fights.** Ping was re-checking your own map
  position on every combat log detection — several API calls each time, all
  returning the same answer. In a battleground that ran hundreds of times a
  second. Your position is now resolved once a second and reused.
