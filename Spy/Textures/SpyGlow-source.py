#!/usr/bin/env python3
"""
Render the tracked-target nameplate glow for the Spy addon.

A soft rounded-rectangle halo: bright on the border, falling off outwards into
nothing and inwards into a faint wash so the enemy's health bar stays readable
through it. Drawn white so the addon can tint it with SetVertexColor.

Output: 32-bit RLE TGA, power-of-two, RGBA straight (unpremultiplied).
"""
import numpy as np
from PIL import Image

W, H = 256, 128
CORNER = 26.0        # rounded-corner radius, texture pixels
EDGE_OUT = 22.0      # how far the halo bleeds beyond the border
EDGE_IN = 7.0        # how far the bright band reaches inside the border
INNER_WASH = 0.16    # alpha of the fill inside the border
INSET = EDGE_OUT + 2  # keep the outer falloff off the texture edge


def rounded_rect_sdf(w, h, half_w, half_h, radius):
    """Signed distance to a rounded rectangle centred in a w x h grid.

    Negative inside, positive outside - the standard box SDF with the corner
    radius subtracted, which rounds the corners for free.
    """
    yy, xx = np.mgrid[0:h, 0:w]
    px = xx + 0.5 - w / 2.0
    py = yy + 0.5 - h / 2.0

    qx = np.abs(px) - (half_w - radius)
    qy = np.abs(py) - (half_h - radius)

    outside = np.sqrt(np.maximum(qx, 0.0) ** 2 + np.maximum(qy, 0.0) ** 2)
    inside = np.minimum(np.maximum(qx, qy), 0.0)
    return outside + inside - radius


def smoothstep(edge0, edge1, x):
    t = np.clip((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


d = rounded_rect_sdf(W, H, W / 2.0 - INSET, H / 2.0 - INSET, CORNER)

# Bright band straddling the border: ramps up from EDGE_IN inside the edge to
# the edge itself, then decays over EDGE_OUT outside it.
rim_in = smoothstep(-EDGE_IN, 0.0, d)
rim_out = 1.0 - smoothstep(0.0, EDGE_OUT, d)
rim = rim_in * rim_out
# square the outward decay so the halo reads as light rather than as a fat line
rim = rim * (rim_out ** 1.6)

# Faint wash across the interior so the whole plate lifts slightly.
wash = (1.0 - smoothstep(-EDGE_IN, 0.0, d)) * INNER_WASH

alpha = np.clip(rim + wash, 0.0, 1.0)

rgba = np.zeros((H, W, 4), dtype=np.float64)
rgba[:, :, 0] = 1.0
rgba[:, :, 1] = 1.0
rgba[:, :, 2] = 1.0
rgba[:, :, 3] = alpha

img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), mode="RGBA")
img.save("SpyGlow.tga", compression="tga_rle")
print(f"wrote SpyGlow.tga  {W}x{H}")

# preview on a dark background, roughly how it looks over the world
bg = np.zeros((H, W, 3)) + 0.10
comp = bg * (1 - alpha[:, :, None]) + np.array([1.0, 0.32, 0.28]) * alpha[:, :, None]
Image.fromarray((np.clip(comp, 0, 1) * 255).astype(np.uint8)).resize(
    (W * 2, H * 2), Image.LANCZOS
).save("glow_preview.png")
print("wrote glow_preview.png")
