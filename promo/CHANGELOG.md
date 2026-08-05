# Ping — release notes

User-facing changes only. Paste the relevant section into the CurseForge
changelog box when uploading a file. Internal cleanups (comment wording,
refactors, promo assets) are deliberately left out — they mean nothing to
someone deciding whether to update.

Two sections per release, in this order: **New Features and Improvements**,
then **Bug Fixes**. Keep the order consistent so people can scan.

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
