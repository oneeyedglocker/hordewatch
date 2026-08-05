# Ping — release notes

User-facing changes only. Paste the relevant section into the CurseForge
changelog box when uploading a file. Internal cleanups (comment wording,
refactors, promo assets) are deliberately left out — they mean nothing to
someone deciding whether to update.

Two sections per release, in this order: **New Features and Improvements**,
then **Bug Fixes**. Keep the order consistent so people can scan.

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
