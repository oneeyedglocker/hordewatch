#!/usr/bin/env python3
"""Stitches a numbered grid of wow.export zone map tiles into one image.

Blizzard splits larger zone maps into a grid of same-size tiles (commonly
256x256) named `<prefix><n>.png`, numbered left-to-right then top-to-bottom
starting at 1 - see web/public/maps/README.md for the full extraction
workflow this fits into.

wow.export's map tiles are RGBA - the margins around the parchment/border art
are genuinely transparent (alpha=0, not solid black), meant to blend with
whatever's behind the map panel in-game. This preserves that transparency;
flattening it to RGB turns those margins into an opaque black block instead.

Usage:
    python3 stitch.py <tiles_dir> <prefix> <cols> <rows> <output_path>

Example:
    python3 stitch.py ~/Downloads/hellfire-tiles hellfire 4 3 web/public/maps/108.png
"""
import sys
from pathlib import Path

from PIL import Image


def main() -> None:
    if len(sys.argv) != 6:
        print(__doc__)
        sys.exit(1)

    tiles_dir = Path(sys.argv[1])
    prefix = sys.argv[2]
    cols = int(sys.argv[3])
    rows = int(sys.argv[4])
    output_path = Path(sys.argv[5])

    tiles = []
    for i in range(1, cols * rows + 1):
        candidates = list(tiles_dir.glob(f"{prefix}{i}.png")) or list(tiles_dir.glob(f"{prefix}{i}.PNG"))
        if not candidates:
            print(f"Missing tile: {prefix}{i}.png in {tiles_dir}")
            sys.exit(1)
        tiles.append(Image.open(candidates[0]).convert("RGBA"))

    tile_w, tile_h = tiles[0].size
    for i, tile in enumerate(tiles, start=1):
        if tile.size != (tile_w, tile_h):
            print(f"Warning: tile {i} is {tile.size}, expected {(tile_w, tile_h)} (using tile 1's size)")

    canvas = Image.new("RGBA", (cols * tile_w, rows * tile_h))
    for idx, tile in enumerate(tiles):
        col, row = idx % cols, idx // cols
        canvas.paste(tile, (col * tile_w, row * tile_h))

    is_jpeg = output_path.suffix.lower() in (".jpg", ".jpeg")
    if is_jpeg:
        # JPEG has no alpha channel - flatten onto white rather than silently
        # losing transparency to black. Prefer a .png output path instead.
        print("Warning: JPEG can't hold transparency - flattening margins to white. Use a .png output path to keep them transparent.")
        flattened = Image.new("RGB", canvas.size, (255, 255, 255))
        flattened.paste(canvas, mask=canvas.split()[-1])
        canvas = flattened

    output_path.parent.mkdir(parents=True, exist_ok=True)
    save_kwargs = {"quality": 92} if is_jpeg else {}
    canvas.save(output_path, **save_kwargs)
    print(f"Wrote {canvas.size[0]}x{canvas.size[1]} -> {output_path}")


if __name__ == "__main__":
    main()
