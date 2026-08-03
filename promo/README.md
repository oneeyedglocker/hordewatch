# Ping — promo assets

Marketing material for sharing Ping. **Not shipped with the addon** — the build
zips only the `Ping/` folder, so nothing here reaches end users.

## Files

- `ping-poster.png` — the current Discord/CurseForge poster (2480×1574).
- `poster-copy.txt` — every word on the poster, one line per string. **This is
  the file you edit.**
- `poster-template.html` — the layout. Holds `{{PLACEHOLDER}}` slots the copy
  fills. Only touch this to change the design, not the words.
- `build-poster.sh` — fills the template from the copy sheet and renders the PNG.
- `shots/` — the three in-game windows cropped out of a real screenshot
  (cooldown window, artwork theme, healer row). The poster composites these.
- `ping-logo.png` — the CurseForge project avatar (800×800 radar mark).
- `logo.html` — its source; re-render the same way as the poster.

## To change the wording and re-render

1. Edit `poster-copy.txt` — change the text after any `=`.
   - Delete both lines of an `F#` block to drop that feature.
   - Titles are set in a condensed face and will not wrap — keep them short.
2. Run `./build-poster.sh` from this folder. It re-measures the content height
   so the canvas never clips or leaves a dead strip, then writes
   `ping-poster.png`.

Requires the fonts under `Ping/Fonts/` (already in the repo) and Playwright's
Chromium for the render step.

## Posting to Discord

Drag `ping-poster.png` into the channel and add a short message with the
download link. See the repo notes / chat for a suggested caption.
