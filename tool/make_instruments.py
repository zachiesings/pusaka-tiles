#!/usr/bin/env python3
"""Generate 4 selectable TRADITIONAL INSTRUMENT voices x 13 notes into
assets/audio/<instrument>/note_XX.wav. Pure stdlib synthesis — no samples.
Voices: piano (marimba-ish), angklung (shaken bamboo tremolo), gamelan (metallic
saron w/ beating), suling (breathy bamboo flute w/ vibrato)."""
import os, wave, struct, math, random

SR = 22050
FREQS = [196.00, 220.00, 246.94, 261.63, 293.66, 329.63, 349.23,
         392.00, 440.00, 493.88, 523.25, 587.33, 659.25]


def env_adsr(n, atk, dec):
    out = []
    for i in range(n):
        t = i / SR
        a = min(1.0, t / atk) if atk > 0 else 1.0
        d = math.exp(-dec * t)
        out.append(a * d)
    return out


def piano(f, dur=0.55):
    n = int(SR * dur); e = env_adsr(n, 0.004, 7.5); out = []
    for i in range(n):
        t = i / SR; s = 0
        for k, amp in enumerate((1.0, 0.45, 0.22, 0.10), 1):
            s += amp * math.sin(2 * math.pi * f * k * (1 + 0.0006 * k) * t)
        out.append(e[i] * s)
    return out


def angklung(f, dur=0.6):
    # bright bamboo with a fast shimmering tremolo (shaken)
    n = int(SR * dur); e = env_adsr(n, 0.006, 5.0); out = []
    for i in range(n):
        t = i / SR
        trem = 0.7 + 0.3 * math.sin(2 * math.pi * 7.5 * t)
        s = (math.sin(2 * math.pi * f * t)
             + 0.5 * math.sin(2 * math.pi * f * 2 * t)
             + 0.3 * math.sin(2 * math.pi * f * 1.002 * t))  # slight detune shimmer
        out.append(e[i] * trem * s)
    return out


def gamelan(f, dur=0.85):
    # metallic saron: inharmonic stretched partials + two detuned voices (ombak)
    n = int(SR * dur); e = env_adsr(n, 0.002, 3.4); out = []
    parts = ((1.0, 1.0), (0.6, 2.01), (0.35, 2.76), (0.18, 5.4))
    for i in range(n):
        t = i / SR; s = 0
        for amp, mult in parts:
            s += amp * (math.sin(2 * math.pi * f * mult * t)
                        + math.sin(2 * math.pi * f * mult * 1.003 * t))
        out.append(e[i] * s * 0.5)
    return out


def suling(f, dur=0.7):
    # breathy bamboo flute: near-sine + soft breath noise + vibrato, sustained
    n = int(SR * dur); e = env_adsr(n, 0.05, 1.6); out = []
    for i in range(n):
        t = i / SR
        vib = 1 + 0.012 * math.sin(2 * math.pi * 5.0 * t)
        s = (math.sin(2 * math.pi * f * vib * t)
             + 0.18 * math.sin(2 * math.pi * f * 2 * vib * t)
             + 0.05 * (random.random() * 2 - 1))  # breath
        out.append(e[i] * s)
    return out


VOICES = {'piano': piano, 'angklung': angklung, 'gamelan': gamelan, 'suling': suling}


def save(path, buf):
    m = max((abs(x) for x in buf), default=1.0) or 1.0
    buf = [x / m * 0.85 for x in buf]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x)) * 32000)) for x in buf))


here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
random.seed(7)
for name, fn in VOICES.items():
    for idx, f in enumerate(FREQS):
        save(os.path.join(here, 'assets', 'audio', name, f'note_{idx:02d}.wav'), fn(f))
    print('wrote', name)
print('done — 4 instruments x', len(FREQS), 'notes')
