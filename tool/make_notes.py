#!/usr/bin/env python3
"""Generate original pitched note tones + SFX into assets/audio/ (pure stdlib).

Tones are synthesized (additive partials + decay) at the frequencies in the
diatonic note table — a marimba/gamelan-like colour. No sampled audio.
"""
import os
import wave
import struct
import math

SR = 22050

FREQS = [196.00, 220.00, 246.94, 261.63, 293.66, 329.63, 349.23,
         392.00, 440.00, 493.88, 523.25, 587.33, 659.25]


def tone(freq, dur=0.5, decay=7.5, partials=(1.0, 0.45, 0.22, 0.10)):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        # soft attack to avoid clicks
        atk = min(1.0, t / 0.006)
        env = atk * math.exp(-decay * t)
        s = 0.0
        for k, amp in enumerate(partials, start=1):
            s += amp * math.sin(2 * math.pi * freq * k * (1 + 0.0006 * k) * t)
        out.append(env * s)
    return out


def noise_thud(dur=0.35):
    # short detuned low cluster for a "wrong" buzz
    out = []
    n = int(SR * dur)
    for i in range(n):
        t = i / SR
        env = math.exp(-9 * t)
        s = math.sin(2 * math.pi * 140 * t) + 0.7 * math.sin(2 * math.pi * 150 * t)
        out.append(env * s)
    return out


def normalize(buf, peak=0.85):
    m = max((abs(x) for x in buf), default=1.0) or 1.0
    return [x / m * peak for x in buf]


def save(name, buf):
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path = os.path.join(here, 'assets', 'audio', name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    buf = normalize(buf)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for x in buf:
            frames += struct.pack('<h', int(max(-1, min(1, x)) * 32000))
        w.writeframes(bytes(frames))


for idx, f in enumerate(FREQS):
    save(f'note_{idx:02d}.wav', tone(f))
save('wrong.wav', noise_thud())
save('tap.wav', tone(523.25, 0.10, decay=30.0, partials=(1.0, 0.3)))
print(f'wrote {len(FREQS)} note tones + wrong + tap')
