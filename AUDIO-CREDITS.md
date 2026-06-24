# Audio Credits & Licensing — Pusaka Tiles

All in-app audio is **rendered originals** produced by `tool/render_audio.py` in
CI (`.github/workflows/audio.yml`). No copyrighted recordings are used.

## Melodies
Every song is a **public-domain** folk melody (lagu daerah) or a classical work
whose composer died >70 years ago. Only the note data is used; nothing is sampled
from any recording. See `lib/game/songs.dart`.

## Instrument sound source — SoundFont
- **FluidR3_GM** by Frank Wen.
- Obtained via the Debian package **`fluid-soundfont-gm`** (Debian *main* →
  DFSG-free). The license permits redistribution and the use of rendered audio in
  applications, including commercial ones.
- Path on the runner: `/usr/share/sounds/sf2/FluidR3_GM.sf2`.

Notes are rendered as per-note one-shots (real recorded samples) with a short
reverb tail and loudness normalisation, replacing the previous pure-synthesis
tones — this fixes the muffled/"mendem" problem and lets the melody cut through.

## ⚠️ General-MIDI fallbacks (no true free samples exist for these)
There is **no license-clear sampled set** for these traditional Indonesian
instruments in any free GM SoundFont, so each uses the closest GM program:

| In-app voice | GM program used | Note |
|---|---|---|
| piano | Acoustic Grand Piano (0) | real piano, no fallback |
| **gamelan** | **Vibraphone (11)** | closest metallic tone to a saron — FALLBACK |
| **angklung** | **Marimba (12)** | closest bamboo/wood pitched tone — FALLBACK |
| **suling** | **Pan Flute (75)** | closest bamboo-flute tone — FALLBACK |

If a license-clear sampled gamelan/angklung/suling set is sourced later, drop it
in and update the program map in `tool/render_audio.py`.

## Backing tracks
`assets/audio/backing/<songid>.mp3` — a humanized, tempo-matched modern groove bed
(bass + light percussion + soft electric-piano chords) in **C major**. All songs
are transposed to C-major diatonic, so the bed never clashes; the player's tapped
melody layers crisply on top. Generated programmatically per song from
`songs.dart` (tempo per song), with velocity + micro-timing humanization.

## Block 3 additions (2026-06-24) — public-domain works

Own simplified C-major arrangements (note data only; rendered via fluidsynth).
No copyrighted recordings or third-party arrangements were used.

### Classical (composer died >70 years ago → public domain)
| Song | Composer | Died | Status |
|------|----------|------|--------|
| Nocturne Op.9 No.2 | Frédéric Chopin | 1849 | Public domain |
| Turkish March (Rondo alla Turca) | W. A. Mozart | 1791 | Public domain |
| Prelude in C (BWV 846) | J. S. Bach | 1750 | Public domain |
| Clair de Lune | Claude Debussy | 1918 | Public domain |
| Gymnopédie No.1 | Erik Satie | 1925 | Public domain |
| Swan Lake (theme) | P. I. Tchaikovsky | 1893 | Public domain |
| Morning Mood | Edvard Grieg | 1907 | Public domain |

### Lagu daerah (traditional / anonymous → public domain)
| Song | Region | Status |
|------|--------|--------|
| O Ina Ni Keke | Sulawesi Utara (Minahasa) | Traditional, public domain |
| Tokecang | Jawa Barat (Sunda) | Traditional, public domain |
| Lir-Ilir | Jawa Tengah (attr. Sunan Kalijaga, ~15th c.) | Traditional, public domain |

Each new song also gets a per-song backing track (own key/tempo/mood, mixed under
the melody) rendered by `render_backing()` in `tool/render_audio.py`.
