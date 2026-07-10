# Zone map images

The Zone Map view looks here for `<mapID>.jpg` and renders it as the real
basemap (via Leaflet + `L.CRS.Simple`) instead of the placeholder scatter
grid. `mapID` is Blizzard's `UiMapID`, already recorded on every sighting -
the Zone Map view shows you which one it's missing when a zone has no image
yet.

This project doesn't ship Blizzard's own map art (see `../../../DATA_MODEL.md`
gap #2) - it's their copyrighted asset, not something this tool extracts or
redistributes on your behalf. Get your own copy from your own licensed game
client instead:

## Extracting a zone image

1. Install [wow.export](https://github.com/Kruithne/wow.export) (the
   standard community tool for this - the same one most WoW map/asset sites
   are built on). It can pull directly from Blizzard's CDN using your own
   Battle.net login, no local install of the game required.
2. Open the **Maps** export tab and find the zone you want (e.g. "Hellfire
   Peninsula").
3. Export it as an image. wow.export renders the full stitched zone map, not
   the individual ADT tiles - that's what you want here.
4. Rename the exported file to `<mapID>.jpg` and drop it in this folder.

## Finding a zone's mapID

Open the Zone Map view in the app and pick the zone from the dropdown - if
there's no image for it yet, it tells you the exact mapID to use. (It's
Blizzard's `UiMapID`, e.g. Hellfire Peninsula is 100 in TBC Classic - but
don't hardcode that, confirm it from what your own sightings recorded, since
map IDs occasionally shift between client versions.)

## Notes

- JPG only, for simplicity - convert if wow.export gives you a PNG.
- No fixed resolution requirement; Leaflet fits it to the view and lets you
  zoom in as far as the source image supports.
- Nothing here is committed automatically - these are real image files, add
  them the normal way (`git add web/public/maps/100.jpg`).
