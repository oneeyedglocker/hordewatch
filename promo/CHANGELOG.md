# Ping — release notes

User-facing changes only. Paste the relevant section into the CurseForge
changelog box when uploading a file. Internal cleanups (comment wording,
refactors, promo assets) are deliberately left out — they mean nothing to
someone deciding whether to update.

Two sections per release, in this order: **New Features and Improvements**,
then **Bug Fixes**. Keep the order consistent so people can scan.

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
