#!/usr/bin/env python3
"""
Render a 3D navigation arrow to a sprite sheet for the Spy addon.

Produces FRAMES renders of a solid, shaded 3D arrow rotating about the vertical
axis, viewed from a tilted camera - the same technique TomTom uses, so the
result reads as genuinely three-dimensional rather than a rotated flat icon.

Rendered white/grey so the addon can tint it with SetVertexColor.
Output: uncompressed 32-bit TGA, power-of-two, RGBA straight (unpremultiplied).
"""
import math
import numpy as np
from PIL import Image

SHEET = 1024
COLS, ROWS = 8, 8
FRAMES = COLS * ROWS          # 64 frames -> 5.625 degrees per frame
CELL = SHEET // COLS          # 128 px
SS = 3                        # supersample factor for antialiasing
R = CELL * SS                 # render resolution per frame

CAM_TILT = math.radians(52.0)  # look down at the arrow
SCALE = 0.86                   # fill of the cell
LIGHT = np.array([-0.45, 0.82, 0.36])
LIGHT = LIGHT / np.linalg.norm(LIGHT)


def build_arrow():
    """Solid chevron arrow with a raised centre ridge, pointing +Z."""
    h = 0.34           # thickness
    ridge = 0.34       # how high the centre ridge sits above the rim
    tipz, backz, tailz = 1.02, -0.60, -0.06
    wx = 0.78

    # outline, counter-clockwise viewed from above: tip, right wing, tail notch, left wing
    outline = [(0.0, tipz), (wx, backz), (0.0, tailz), (-wx, backz)]

    verts, tris = [], []

    def add(v):
        verts.append(v)
        return len(verts) - 1

    # top surface: rim points at height h, ridge line raised
    top_rim = [add((x, h, z)) for (x, z) in outline]
    ridge_tip = add((0.0, h + ridge, tipz * 0.92))
    ridge_tail = add((0.0, h + ridge * 0.55, tailz))
    # bottom
    bot = [add((x, 0.0, z)) for (x, z) in outline]

    t_tip, t_r, t_tail, t_l = top_rim
    b_tip, b_r, b_tail, b_l = bot

    # top faces (ridge fans)
    tris += [
        (ridge_tip, t_tip, t_r), (ridge_tip, t_r, ridge_tail),
        (ridge_tail, t_r, t_tail),
        (ridge_tip, t_l, t_tip), (ridge_tip, ridge_tail, t_l),
        (ridge_tail, t_tail, t_l),
    ]
    # bottom faces (reverse winding)
    tris += [(b_tip, b_r, b_tail), (b_tip, b_tail, b_l)]
    # side walls
    for (a, b) in ((0, 1), (1, 2), (2, 3), (3, 0)):
        ta, tb = top_rim[a], top_rim[b]
        ba, bb = bot[a], bot[b]
        tris += [(ta, ba, bb), (ta, bb, tb)]

    return np.array(verts, dtype=np.float64), tris


VERTS, TRIS = build_arrow()
VERTS[:, 1] -= VERTS[:, 1].mean()
VERTS[:, 2] -= VERTS[:, 2].mean()


def render(angle):
    """Render one frame; returns float RGBA at RxR."""
    ca, sa = math.cos(angle), math.sin(angle)
    rot = np.array([[ca, 0, sa], [0, 1, 0], [-sa, 0, ca]])
    ct, st = math.cos(CAM_TILT), math.sin(CAM_TILT)
    tilt = np.array([[1, 0, 0], [0, ct, -st], [0, st, ct]])
    m = tilt @ rot

    p = VERTS @ m.T
    normals = {}
    for i, (a, b, c) in enumerate(TRIS):
        n = np.cross(p[b] - p[a], p[c] - p[a])
        ln = np.linalg.norm(n)
        normals[i] = n / ln if ln > 1e-9 else np.array([0.0, 0.0, 1.0])

    # project (orthographic, slight scale) into pixel space
    half = R / 2.0
    sx = p[:, 0] * half * SCALE + half
    sy = -p[:, 1] * half * SCALE + half
    sz = p[:, 2]

    color = np.zeros((R, R, 3), dtype=np.float64)
    alpha = np.zeros((R, R), dtype=np.float64)
    zbuf = np.full((R, R), -1e9)

    yy, xx = np.mgrid[0:R, 0:R]

    for i, (a, b, c) in enumerate(TRIS):
        x0, y0, x1, y1, x2, y2 = sx[a], sy[a], sx[b], sy[b], sx[c], sy[c]
        area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
        if abs(area) < 1e-9:
            continue
        if area > 0:      # back-face cull (screen-space winding)
            continue

        lo_x, hi_x = int(max(0, math.floor(min(x0, x1, x2)))), int(min(R - 1, math.ceil(max(x0, x1, x2))))
        lo_y, hi_y = int(max(0, math.floor(min(y0, y1, y2)))), int(min(R - 1, math.ceil(max(y0, y1, y2))))
        if lo_x > hi_x or lo_y > hi_y:
            continue

        px = xx[lo_y:hi_y + 1, lo_x:hi_x + 1] + 0.5
        py = yy[lo_y:hi_y + 1, lo_x:hi_x + 1] + 0.5

        w0 = ((x1 - x0) * (py - y0) - (px - x0) * (y1 - y0)) / area
        w1 = ((x2 - x1) * (py - y1) - (px - x1) * (y2 - y1)) / area
        w2 = 1.0 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not inside.any():
            continue

        z = w2 * sz[a] + w0 * sz[c] + w1 * sz[b]
        sub = zbuf[lo_y:hi_y + 1, lo_x:hi_x + 1]
        better = inside & (z > sub)
        if not better.any():
            continue

        n = normals[i]
        diff = max(0.0, float(np.dot(n, LIGHT)))
        spec = diff ** 22
        shade = 0.30 + 0.62 * diff + 0.38 * spec       # ambient + lambert + highlight
        shade = min(1.0, shade)
        # subtle cool-to-warm so facets separate even when tinted
        rgb = np.array([shade, shade * 0.995, shade * 0.965])

        sub[better] = z[better]
        csub = color[lo_y:hi_y + 1, lo_x:hi_x + 1]
        csub[better] = rgb
        asub = alpha[lo_y:hi_y + 1, lo_x:hi_x + 1]
        asub[better] = 1.0

    out = np.dstack([color, alpha])
    return out


def downsample(img, factor):
    h, w, c = img.shape
    img = img.reshape(h // factor, factor, w // factor, factor, c)
    return img.mean(axis=(1, 3))


sheet = np.zeros((SHEET, SHEET, 4), dtype=np.float64)
for f in range(FRAMES):
    ang = math.pi + (f / FRAMES) * 2.0 * math.pi
    cell = downsample(render(ang), SS)
    r, c = divmod(f, COLS)
    sheet[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = cell
    if f % 16 == 0:
        print(f"  frame {f}/{FRAMES}")

rgba = np.clip(sheet, 0, 1)
# un-premultiply edges so the alpha ramp doesn't darken when blended
a = rgba[:, :, 3:4]
rgb = np.divide(rgba[:, :, :3], np.maximum(a, 1e-6), where=a > 1e-6)
rgba[:, :, :3] = np.clip(rgb, 0, 1)

img = Image.fromarray((rgba * 255).astype(np.uint8), mode="RGBA")
img.save("SpyArrow.tga")
print(f"wrote SpyArrow.tga  {SHEET}x{SHEET}  {FRAMES} frames  {COLS}x{ROWS} grid  cell {CELL}px")
img.resize((512, 512), Image.LANCZOS).save("arrow_preview.png")
print("wrote arrow_preview.png")
