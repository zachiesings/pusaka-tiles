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
