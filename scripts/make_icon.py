#!/usr/bin/env python3
"""Draws the original Liftbook app icon (1024x1024, opaque PNG).

A white barbell resting over a mint open book on a deep teal gradient.
Pure Python (zlib only) so it runs anywhere:

    python3 scripts/make_icon.py Liftbook/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
"""
import math
import struct
import sys
import zlib

SIZE = 1024
TOP = (0x11, 0x80, 0x76)      # teal
BOTTOM = (0x05, 0x3B, 0x34)   # deep green-teal
WHITE = (0xFF, 0xFF, 0xFF)
MINT = (0x7E, 0xEB, 0xC0)


def rounded_box(px, py, cx, cy, hw, hh, r, angle=0.0):
    """Signed distance from a pixel to a (rotated) rounded rectangle."""
    dx, dy = px - cx, py - cy
    if angle:
        c, s = math.cos(angle), math.sin(angle)
        dx, dy = dx * c + dy * s, -dx * s + dy * c
    qx, qy = abs(dx) - hw + r, abs(dy) - hh + r
    outside = math.hypot(max(qx, 0.0), max(qy, 0.0))
    return outside + min(max(qx, qy), 0.0) - r


def mirrored(shapes):
    out = list(shapes)
    for (cx, cy, hw, hh, r, a) in shapes:
        out.append((SIZE - cx, cy, hw, hh, r, -a))
    return out


# (cx, cy, half-width, half-height, corner radius, rotation)
BARBELL = [(512, 400, 322, 15, 15, 0.0)] + mirrored([
    (306, 400, 12, 46, 6, 0.0),     # collar
    (258, 400, 34, 132, 22, 0.0),   # big plate
    (198, 400, 22, 92, 16, 0.0),    # small plate
])
TILT = math.radians(11)
BOOK = mirrored([(312, 700, 212, 50, 12, TILT)]) + [(512, 762, 16, 20, 4, 0.0)]  # + spine
# Two text lines per page, drawn in a darker teal on top of the mint pages.
PAGE_LINES = mirrored([
    (318, 686, 160, 5, 5, TILT),
    (322, 716, 150, 5, 5, TILT),
])
INK = (0x0B, 0x5E, 0x55)

LAYERS = [(BOOK, MINT), (PAGE_LINES, INK), (BARBELL, WHITE)]


def bbox(shape):
    cx, cy, hw, hh, _, _ = shape
    reach = math.hypot(hw, hh) + 2
    return cx - reach, cy - reach, cx + reach, cy + reach


def coverage(px, py, shapes):
    best = 0.0
    for shape in shapes:
        x0, y0, x1, y1 = bbox(shape)
        if x0 <= px <= x1 and y0 <= py <= y1:
            d = rounded_box(px, py, *shape)
            best = max(best, min(max(0.5 - d, 0.0), 1.0))
            if best >= 1.0:
                break
    return best


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def render():
    rows = []
    for y in range(SIZE):
        t = y / (SIZE - 1)
        row = bytearray(b"\x00")  # PNG filter type: none
        for x in range(SIZE):
            # Vertical gradient with a soft glow behind the barbell.
            glow = max(0.0, 1.0 - math.hypot(x - 512, y - 430) / 620) * 0.18
            color = mix(mix(TOP, BOTTOM, t), WHITE, glow)
            for shapes, fill in LAYERS:
                a = coverage(x + 0.5, y + 0.5, shapes)
                if a:
                    color = mix(color, fill, a)
            row += bytes(int(round(c)) for c in color)
        rows.append(bytes(row))
    return b"".join(rows)


def write_png(path, raw):
    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)  # 8-bit RGB
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", header))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    write_png(sys.argv[1] if len(sys.argv) > 1 else "AppIcon.png", render())
