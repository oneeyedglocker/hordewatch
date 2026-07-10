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
there's no image for it yet, it tells you the exact mapID to use. (It's
Blizzard's `UiMapID`, e.g. Hellfire Peninsula is 100 in TBC Classic - but
don't hardcode that, confirm it from what your own sightings recorded, since
map IDs occasionally shift between client versions.)

## Notes

- Either `.jpg` or `.png` - the app checks both, so no conversion needed.
- No fixed resolution requirement; Leaflet fits it to the view and lets you
  zoom in as far as the source image supports.
- Nothing here is committed automatically - these are real image files, add
  them the normal way (`git add web/public/maps/100.jpg`).

## Continent map images

The "Outland (all zones)" toggle on the Zone Map view plots every sighting
that has `worldX`/`worldY`/`continentID` (continuous coordinates from
HereBeDragons - see `HordeWatch/Position.lua`) on one continuous continent
image, instead of one image per zone. This needs a different kind of asset
than the per-zone parchment art above: real stitched terrain, plus a small
JSON sidecar giving the exact world-coordinate corners of the image, e.g.
`530.jpg` + `530.json` for Outland (`530` is Outland's continent-level
`UiMapID`, confirmed directly from wow.export's own export metadata, not
guessed).

To produce one:

1. In wow.export, open the **Maps** tab (not Textures - that's for the
   per-zone parchment art above) and select the continent, e.g.
   `[530] Outland (Expansion01)`.
2. Under **Terrain Texture Quality**, pick something well below "High (8k)" -
   continent-scale exports are dozens of tiles; a whole-continent stitch at
   8k/tile is enormous. "Low" or "Medium" is plenty for a web map you can
   already zoom into.
3. Leave Export WMO/M2/Foliage/Liquids/G-Objects unchecked - just the flat
   ground texture is needed.
4. Export it. wow.export writes one already-composited image (e.g.
   `expansion01_<hash>.png`) plus a `.json` sidecar with the tile grid and
   the exact world-coordinate corners it used.
5. Convert the PNG to `.jpg` if it's large (a full Outland export easily
   lands in the tens of MB as PNG; JPEG at quality ~85-90 shrinks that by
   5-6x with no visible loss for terrain - unlike the per-zone art, there's
   no transparency to preserve here).
6. Save it as `web/public/maps/<continent mapID>.jpg`, and write a matching
   `<continent mapID>.json` with this shape (trim wow.export's sidecar down
   to just these fields):
   ```json
   {
     "mapID": 530,
     "mapName": "Outland",
     "imageWidth": 16384,
     "imageHeight": 12800,
     "corners": {
       "top_left": { "world_x": 7466.67, "world_y": 10133.33 },
       "bottom_right": { "world_x": -5866.67, "world_y": -6933.33 }
     }
   }
   ```
   `imageWidth`/`imageHeight` must match the actual (possibly resized) image
   file, not necessarily wow.export's original dimensions.

Note the axis swap: WoW's world X is north/south and Y is east/west, which
is transposed relative to image row/col - see the comment on `toLatLng` in
`web/src/components/LeafletContinentMap.tsx` for the actual conversion.
