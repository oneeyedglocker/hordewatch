# stitch-map-tiles

Stitches a numbered grid of wow.export zone map tiles into one image, for
`web/public/maps/` - see that folder's README for the full extraction
workflow this fits into.

## Usage

```sh
pip install -r requirements.txt
python3 stitch.py <tiles_dir> <prefix> <cols> <rows> <output_path>
```

Example - a zone exported as `hellfire1.png` .. `hellfire12.png` (a 4x3 grid):

```sh
python3 stitch.py ~/Downloads/hellfire-tiles hellfire 4 3 ../../web/public/maps/108.png
```

Tiles are assumed numbered left-to-right, top-to-bottom starting at 1
(Blizzard's standard order). **Check the corner label baked into the output
image before committing it under a mapID** - wow.export's internal folder
names don't always match the public zone name (e.g. its `hellfire` folder
turned out to contain Terokkar Forest's map art, not Hellfire Peninsula's).

Use a `.png` output path, not `.jpg`: the tiles have real transparency around
the parchment/border art (the margins are alpha=0, not solid black), and
JPEG can't hold transparency - it'd get flattened to opaque white instead.
