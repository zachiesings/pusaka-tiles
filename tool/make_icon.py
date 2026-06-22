#!/usr/bin/env python3
"""Generate assets/icon/app_icon.png — a batik piano-tiles mark (pure stdlib)."""
import os
import zlib
import struct

W = H = 1024
buf = bytearray(W * H * 4)

BG = (0x1F, 0x18, 0x10)
LANE_A = (0x2E, 0x23, 0x16)
LANE_B = (0x26, 0x1D, 0x12)
GOLD = (0xE3, 0xB2, 0x3C)
CREAM = (0xF3, 0xE5, 0xC8)
TILES = [(0x7A, 0x3B, 0x2E), (0x1F, 0x4E, 0x5F), (0xB5, 0x83, 0x2E), (0x4A, 0x6B, 0x3A)]


def put(x, y, rgb, a=255):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 4
        sa = a / 255.0
        for k in range(3):
            buf[i + k] = int(buf[i + k] * (1 - sa) + rgb[k] * sa)
        buf[i + 3] = 255


def fill(rgb):
    for y in range(H):
        for x in range(W):
            i = (y * W + x) * 4
            buf[i] = rgb[0]; buf[i + 1] = rgb[1]; buf[i + 2] = rgb[2]; buf[i + 3] = 255


def rect(x0, y0, x1, y1, rgb, a=255):
    for y in range(int(max(0, y0)), int(min(H, y1))):
        for x in range(int(max(0, x0)), int(min(W, x1))):
            put(x, y, rgb, a)


def rounded_rect(x0, y0, x1, y1, r, rgb, a=255):
    for y in range(int(y0), int(y1)):
        for x in range(int(x0), int(x1)):
            dx = min(x - x0, x1 - 1 - x)
            dy = min(y - y0, y1 - 1 - y)
            if dx < r and dy < r and (r - dx) ** 2 + (r - dy) ** 2 > r * r:
                continue
            put(x, y, rgb, a)


def diamond(cx, cy, s, rgb, a):
    for y in range(int(cy - s), int(cy + s)):
        for x in range(int(cx - s), int(cx + s)):
            if abs(x - cx) + abs(y - cy) <= s:
                put(x, y, rgb, a)


def tile(cx, cy, w, h, color):
    rounded_rect(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, w * 0.2, color)
    rounded_rect(cx - w / 2, cy - h / 2, cx + w / 2, cy, w * 0.2, (255, 255, 255), a=28)
    diamond(cx, cy, w * 0.24, CREAM, 70)
    diamond(cx, cy, w * 0.17, color, 255)
    diamond(cx, cy, w * 0.06, CREAM, 90)


fill(BG)
# gold frame ring first, so lanes/tiles sit inside it
rounded_rect(70, 70, W - 70, H - 70, 150, GOLD)
rounded_rect(92, 92, W - 92, H - 92, 132, BG)

# 4 lanes
inset = 150
lane_w = (W - 2 * inset) / 4
for c in range(4):
    x0 = inset + c * lane_w
    rect(x0, inset, x0 + lane_w, H - inset, LANE_A if c % 2 == 0 else LANE_B)

# staggered tiles (like falling piano tiles)
positions = [(0, 0.30), (2, 0.50), (1, 0.70), (3, 0.40)]
tw = lane_w * 0.74
th = (H - 2 * inset) * 0.2
for (lane, fy) in positions:
    cx = inset + (lane + 0.5) * lane_w
    cy = inset + fy * (H - 2 * inset)
    tile(cx, cy, tw, th, TILES[lane])


def write_png(path):
    raw = bytearray()
    stride = W * 4
    for y in range(H):
        raw.append(0)
        raw.extend(buf[y * stride:(y + 1) * stride])
    comp = zlib.compress(bytes(raw), 9)

    def chunk(typ, data):
        return (struct.pack('>I', len(data)) + typ + data +
                struct.pack('>I', zlib.crc32(typ + data) & 0xffffffff))

    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)
    with open(path, 'wb') as f:
        f.write(sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', comp) + chunk(b'IEND', b''))


here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(here, 'assets', 'icon', 'app_icon.png')
os.makedirs(os.path.dirname(out), exist_ok=True)
write_png(out)
print('wrote', out)
