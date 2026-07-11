# Zone map images

The Zone Map view looks here for `<mapID>.jpg` (or `.png`) and renders it as the real
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
2. Open the **Textures** tab (not Maps - that tab is the 3D terrain/model
   exporter, a different asset entirely) and search for the zone, e.g.
   `hellfire`. The world map art lives under
   `interface/worldmap/<internal-zone-name>/`.
3. **Leave "Atlas Regions" unchecked** for these - they're plain standalone
   textures, not sprite-sheet atlases (that checkbox is for small bundled UI
   icon sheets, a different kind of texture). Just use "Export as PNG".
4. Larger zones are split into a numbered grid of 256x256 tiles (e.g.
   `hellfire1.png` .. `hellfire12.png` for a 4x3 grid) rather than one
   image - see "Stitching split zone maps" below if you get more than one
   file per zone.
5. **The internal folder name doesn't always match the public zone name.**
   Check the label baked into the bottom-left corner of the stitched/exported
   image before filing it under a mapID - e.g. wow.export's `hellfire` folder
   actually contains Terokkar Forest's map art, not Hellfire Peninsula's.
6. Rename the file to `<mapID>.jpg` (or `.png`, both work) and drop it in
   this folder.

## Stitching split zone maps

If a zone comes back as multiple numbered tiles instead of one image, use
`tools/stitch-map-tiles/stitch.py`:

```sh
cd tools/stitch-map-tiles
pip install pillow
python3 stitch.py /path/to/tiles hellfire 4 3 web/public/maps/100.png
```

Arguments: the folder containing the tile PNGs, the shared filename prefix
(e.g. `hellfire` for `hellfire1.png`..`hellfire12.png`), the grid width and
height in tiles, and the output path. Tiles are assumed to be numbered
left-to-right, top-to-bottom starting at 1 (Blizzard's standard order for
these) - check the output's corner label to confirm before committing it,
per the mismatch note above.

Use a `.png` output path, not `.jpg` - the tiles have real transparency
around the parchment/border art (not solid black), and JPEG can't hold
transparency, so it'd get flattened to an opaque white block instead.

## Finding a zone's mapID

Open the Zone Map view in the app and pick the zone from the dropdown - if
there's no image for it yet, it tells you the exact mapID to use. **Don't
assume "well-known" TBC Classic mapIDs are right** - this repo initially
shipped images under the commonly-cited old values (Hellfire Peninsula =
100, Netherstorm = 109, etc.), but real client data showed the actual
`C_Map.GetBestMapForUnit()` values this client returns are completely
different (Hellfire Peninsula = 1944, Netherstorm = 1953 - confirmed from
real sightings, not documentation). Always confirm from an actual
sighting's recorded `mapID`, never hardcode a number you haven't checked
against real data from this specific client.

**Current status of the committed zone images:** confirmed correct against
real sightings - `1944.jpg` (Hellfire Peninsula), `1946.jpg` (Zangarmarsh),
`1948.jpg` (Shadowmoon Valley), `1951.jpg` (Nagrand), `1952.jpg` (Terokkar
Forest), `1953.jpg` (Netherstorm). Still unverified: `104.jpg` (filed under
a guessed Blade's Edge Mountains mapID) - rename once you have a real
sighting from that zone to confirm the right number.

## Notes

- Either `.jpg` or `.png` - the app checks both, so no conversion needed.
- No fixed resolution requirement; Leaflet fits it to the view and lets you
  zoom in as far as the source image supports.
- Nothing here is committed automatically - these are real image files, add
  them the normal way (`git add web/public/maps/1944.jpg`).

## Continent map images

The "Outland (all zones)" toggle on the Zone Map view plots every sighting
that has `worldX`/`worldY`/`continentID` (continuous coordinates from
HereBeDragons - see `HordeWatch/Position.lua`) on one continuous continent
image, instead of one image per zone. This needs a different kind of asset
than the per-zone parchment art above: real stitched terrain, plus a small
JSON sidecar giving just the image's pixel dimensions - `530.jpg` +
`530.json` for Outland (`530` is Outland's continent-level `UiMapID`,
confirmed directly from wow.export's own export metadata).

To produce the image:

1. In wow.export, open the **Maps** tab (not Textures - that's for the
   per-zone parchment art above) and select the continent, e.g.
   `[530] Outland (Expansion01)`.
2. Under **Terrain Texture Quality**, pick something well below "High (8k)" -
   continent-scale exports are dozens of tiles; a whole-continent stitch at
   8k/tile is enormous. "Low" or "Medium" is plenty for a web map you can
   already zoom into.
3. Leave Export WMO/M2/Foliage/Liquids/G-Objects unchecked - just the flat
   ground texture is needed. Note this means distinct 3D structures (the
   Dark Portal's platform, buildings, etc.) may not render - only what's
   baked into the flat ground texture will show up.
4. Export it. wow.export writes one already-composited image (e.g.
   `expansion01_<hash>.png`) plus a `.json` sidecar - **ignore its stated
   world-coordinate corners** (see below for why), just note the image's
   pixel dimensions.
5. Convert the PNG to `.jpg` if it's large (a full Outland export easily
   lands in the tens of MB as PNG; JPEG at quality ~85-90 shrinks that by
   5-6x with no visible loss for terrain - unlike the per-zone art, there's
   no transparency to preserve here).
6. Save it as `web/public/maps/<continent mapID>.jpg`, and write a matching
   `<continent mapID>.json` with just:
   ```json
   {
     "mapID": 530,
     "mapName": "Outland",
     "imageWidth": 16384,
     "imageHeight": 12800
   }
   ```
   `imageWidth`/`imageHeight` must match the actual (possibly resized) image
   file, not necessarily wow.export's original dimensions.

### Calibrating the worldX/worldY -> pixel transform

**Don't use wow.export's stated image corners for this** - they look
authoritative (exact numbers straight from wow.export's own metadata) but
turned out not to correspond to HereBeDragons' `worldX`/`worldY` coordinate
space at all. Real sightings placed against a corners-derived transform
landed in empty space off the rendered terrain every time. HereBeDragons
reads from `UIMapAssignment.db2`, a different data source than wow.export's
raw ADT/WDT tile grid - the two don't share one coordinate convention.

What actually works: collect real `/hw pos` readings (see `Core.lua`) at
named, visually unambiguous landmarks - a building, ruin, or other
structure with a distinct silhouette, not open terrain - spread across
several different zones. For each reading, find that landmark's precise
pixel position on the continent image by eye, then least-squares fit a
6-parameter affine transform: `[worldX, worldY, 1] -> pixel_x` and
`-> pixel_y`, solved independently. The current Outland transform
(`OUTLAND_AFFINE` in `web/src/components/LeafletContinentMap.tsx`) was fit
against 6 such readings across 5 zones (Dark Portal and Honor Hold in
Hellfire Peninsula, Hand of Gul'dan in Shadowmoon Valley, Auchindoun in
Terokkar Forest, Oshu'gun in Nagrand, Serpent Lake in Zangarmarsh) with a
max residual of ~115px on a 16384px-wide image (~0.7%) - consistent with
manual pixel-picking imprecision, not a systematic error. 3+ points are
needed to solve for rotation as well as scale/offset; more points and a
wider spread improve accuracy further.

Note there's also a per-continentID offset to reverse before this
transform applies (`OUTLAND_OFFSETS` in the same file) - HereBeDragons
buckets most of Outland's raw coordinate space into `continentID` 0 or 1
with an offset added to `worldX`/`worldY`, and the affine fit above was
calibrated against `continentID` 530 (unmodified) readings specifically.
