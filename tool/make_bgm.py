#!/usr/bin/env python3
"""Generate an original looping gamelan background track -> assets/audio/bgm_home.wav

Pure stdlib. Layered slendro-pentatonic gamelan: gong + kempul pulse, a saron
melody, and a faster peking ostinato. Seamless loop (integer beats). No samples.
"""
import os, wave, struct, math

SR = 22050
BPM = 96
BEAT = 60.0 / BPM           # seconds per beat
BEATS = 32                  # loop length in beats (seamless)
TOTAL = int(SR * BEAT * BEATS)
buf = [0.0] * TOTAL

# slendro-ish pentatonic (Hz)
S = {'1': 294.0, '2': 330.0, '3': 392.0, '5': 440.0, '6': 494.0,
     '1h': 588.0, '2h': 660.0, '3h': 784.0, 'low5': 220.0, 'low6': 247.0,
     'gong': 110.0, 'kempul': 165.0}


def add(freq, start, dur, gain=0.5, decay=6.0, partials=(1.0, 0.5, 0.25, 0.12)):
    n0 = int(SR * start)
    n = int(SR * dur)
    for i in range(n):
        idx = n0 + i
        if idx >= TOTAL:
            idx -= TOTAL          # wrap → seamless loop tail
        t = i / SR
        env = math.exp(-decay * t) * (1 - math.exp(-200 * t))  # soft attack
        s = 0.0
        for kk, amp in enumerate(partials, start=1):
            s += amp * math.sin(2 * math.pi * freq * kk * (1 + 0.0007 * kk) * t)
        buf[idx] += gain * env * s


# Gong every 8 beats (deep), kempul on the off 4-beats
for b in range(0, BEATS, 8):
    add(S['gong'], b * BEAT, 4.0, gain=0.55, decay=1.2)
for b in range(4, BEATS, 8):
    add(S['kempul'], b * BEAT, 2.0, gain=0.4, decay=2.0)

# Saron melody — a calm repeating slendro phrase (one bar = 8 beats)
phrase = ['3', '5', '6', '5', '3', '2', '1', '2']
for bar in range(BEATS // 8):
    for i, note in enumerate(phrase):
        add(S[note], (bar * 8 + i) * BEAT, BEAT * 0.9, gain=0.32, decay=4.5)

# Peking ostinato — faster, higher, gentle (two notes per beat)
ost = ['1h', '2h', '1h', '6']
for b in range(BEATS):
    for j in range(2):
        add(S[ost[(b * 2 + j) % len(ost)]], (b + j * 0.5) * BEAT, BEAT * 0.45,
            gain=0.14, decay=7.0)

# normalize
peak = max(abs(x) for x in buf) or 1.0
buf = [x / peak * 0.82 for x in buf]

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(here, 'assets', 'audio', 'bgm_home.wav')
os.makedirs(os.path.dirname(out), exist_ok=True)
with wave.open(out, 'w') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x)) * 32000)) for x in buf))
print('wrote', out, f'({TOTAL/SR:.1f}s loop)')
