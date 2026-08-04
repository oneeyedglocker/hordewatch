# Ping — release notes

User-facing changes only. Paste the relevant section into the CurseForge
changelog box when uploading a file. Internal cleanups (comment wording,
refactors, promo assets) are deliberately left out — they mean nothing to
someone deciding whether to update.

---

## 2.8.9

**Fixed: the list lagged behind in busy fights**

Ping was re-checking your own map position on every single combat log
detection — several API calls each time, all returning the same answer. In a
battleground that ran hundreds of times a second and left the list visibly
behind. Your position is now resolved once a second and reused, so coordinates
stay current at a fraction of the cost.

**Added: title text color**

*Look → Window → Title text color* now sets the color and opacity of the window
title. Previously you could style the title bar but not the text on it.
