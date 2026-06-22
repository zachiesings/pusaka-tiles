#!/usr/bin/env python3
"""Premium 'Panggung Malam' app icon — cool indigo radial stage glow + a glowing
batik tile + a gold music note. Pure stdlib, no PIL."""
import os, zlib, struct, math

W = H = 1024
buf = bytearray(W * H * 4)

def lerp(a, b, t): return tuple(int(a[i] + (b[i]-a[i]) * t) for i in range(3))
def setpx(x, y, rgb, a=255):
    if 0 <= x < W and 0 <= y < H:
        i = (y*W + x) * 4; sa = a/255
        for k in range(3): buf[i+k] = int(buf[i+k]*(1-sa) + rgb[k]*sa)
        buf[i+3] = 255

BG_IN = (0x2A, 0x22, 0x60)   # indigo glow center
BG_OUT = (0x0B, 0x09, 0x18)  # deep night edge
VIOLET = (0x7E, 0x55, 0xC6)
INDIGO = (0x5B, 0x4B, 0xC4)
TEAL = (0x2F, 0xA9, 0x87)
GOLD = (0xF2, 0xB7, 0x3C)
GOLD_LT = (0xFC, 0xD6, 0x75)
CREAM = (0xF2, 0xEE, 0xFA)
cx = cy = W / 2

# radial indigo stage glow
for y in range(H):
    for x in range(W):
        d = min(1, math.hypot(x-cx, y-cy)/(W*0.6))
        rgb = lerp(BG_IN, BG_OUT, d ** 1.25)
        i = (y*W + x)*4
        buf[i], buf[i+1], buf[i+2], buf[i+3] = rgb[0], rgb[1], rgb[2], 255

# vertical spotlight beams (subtle)
for bx, col in [(0.30, INDIGO), (0.5, TEAL), (0.70, VIOLET)]:
    topx = bx * W
    for y in range(0, int(H*0.8)):
        spread = 30 + y * 0.22
        a = int(34 * (1 - y/(H*0.8)))
        for x in range(int(topx - spread), int(topx + spread)):
            setpx(x, y, col, a)

def rrect(x0, y0, x1, y1, r, rgb_top, rgb_bot, a=255):
    for y in range(int(y0), int(y1)):
        ty = (y - y0) / (y1 - y0)
        rgb = lerp(rgb_top, rgb_bot, ty)
        for x in range(int(x0), int(x1)):
            dx = min(x - x0, x1 - 1 - x); dy = min(y - y0, y1 - 1 - y)
            if dx < r and dy < r and (r-dx)**2 + (r-dy)**2 > r*r: continue
            setpx(x, y, rgb, a)

# glow behind tile
for rr in range(360, 300, -1):
    a = int(70 * (360-rr)/60)
    for ang in range(0, 360, 2):
        pass

# glowing tile (rounded square, violet->indigo gradient)
ts = 300
rrect(cx-ts, cy-ts*1.15, cx+ts, cy+ts*1.15, 90, lerp(VIOLET, CREAM, 0.25), INDIGO, 255)
# top sheen
rrect(cx-ts, cy-ts*1.15, cx+ts, cy-ts*0.2, 90, (255,255,255), VIOLET, 70)
# gold rim
def rim(x0,y0,x1,y1,r,color,a):
    for y in range(int(y0), int(y1)):
        for x in range(int(x0), int(x1)):
            dx = min(x-x0, x1-1-x); dy = min(y-y0, y1-1-y)
            if dx < r and dy < r and (r-dx)**2+(r-dy)**2 > r*r: continue
            edge = min(dx, dy)
            if edge < 8: setpx(x,y,color,a)
rim(cx-ts, cy-ts*1.15, cx+ts, cy+ts*1.15, 90, GOLD_LT, 200)

def disc(ccx, ccy, r, rgb, a=255):
    for y in range(int(ccy-r), int(ccy+r)):
        for x in range(int(ccx-r), int(ccx+r)):
            if math.hypot(x-ccx, y-ccy) <= r: setpx(x,y,rgb,a)

# gold eighth note: head + stem + flag
disc(cx-70, cy+150, 78, GOLD, 255)
disc(cx-70, cy+150, 78, GOLD_LT, 60)
# stem
for y in range(int(cy-220), int(cy+150)):
    for x in range(int(cx+0), int(cx+30)):
        setpx(x, y, GOLD, 255)
# flag
for i in range(120):
    y = int(cy - 220 + i)
    w = int(70 * (1 - i/160))
    for x in range(int(cx+30), int(cx+30+w)):
        setpx(x, y + int((x-cx-30)*0.5), GOLD_LT, 255)

def write_png(path):
    raw = bytearray(); stride = W*4
    for y in range(H):
        raw.append(0); raw.extend(buf[y*stride:(y+1)*stride])
    comp = zlib.compress(bytes(raw), 9)
    def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I', zlib.crc32(t+d)&0xffffffff)
    with open(path,'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',W,H,8,6,0,0,0))+chunk(b'IDAT',comp)+chunk(b'IEND',b''))

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(here, 'assets', 'icon', 'app_icon.png')
os.makedirs(os.path.dirname(out), exist_ok=True)
write_png(out)
print('wrote', out)
