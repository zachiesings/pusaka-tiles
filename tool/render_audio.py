#!/usr/bin/env python3
"""Render Pusaka Tiles audio from a license-clear SoundFont (FluidR3_GM, shipped
in Debian main as `fluid-soundfont-gm`, DFSG-free / redistributable) using
fluidsynth + mido. Real recorded samples replace the old additive synth, so
tapped notes are bright and cut through (fixes the 'mendem'/muffled problem).

Outputs (existing paths kept → drop-in, no Dart change needed for these):
  assets/audio/<instr>/note_XX.wav   piano · gamelan · angklung · suling (13 ea)
  assets/audio/note_XX.wav           default melody voice (= piano)
  assets/audio/tap.wav, wrong.wav
  assets/audio/bgm_home.wav          short humanized gamelan loop
New:
  assets/audio/backing/<songid>.mp3  per-song humanized groove bed (C-major)

Traditional instruments have no true samples in any free GM set, so they use the
closest General-MIDI program — FLAGGED in AUDIO-CREDITS.md:
  gamelan → Vibraphone (11) · angklung → Marimba (12) · suling → Pan Flute (75)
"""
import os, re, sys, subprocess, random

import mido
from mido import Message, MidiFile, MidiTrack, MetaMessage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
AUD = os.path.join(ROOT, "assets", "audio")
SF2 = os.environ.get("SF2", "/usr/share/sounds/sf2/FluidR3_GM.sf2")
SR = 44100
TPB = 480  # ticks per beat

# diatonic table (matches the legacy FREQS) → MIDI note numbers, G3..E5
NOTE_MIDI = [55, 57, 59, 60, 62, 64, 65, 67, 69, 71, 72, 74, 76]
PROG = {"piano": 0, "gamelan": 11, "angklung": 12, "suling": 75}

random.seed(20260624)  # reproducible humanization (no wall-clock)


def sh(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def fsynth(mid, wav, gain=0.5, room=0.2, level=0.10):
    # Conservative gain (0.5) + LIGHT reverb → the raw render keeps headroom and
    # never clips internally (hot gain + heavy reverb was the "sember" cause).
    sh(["fluidsynth", "-ni", "-g", str(gain), "-F", wav, "-r", str(SR),
        "-o", "synth.reverb.active=1", "-o", f"synth.reverb.room-size={room}",
        "-o", "synth.reverb.width=0.5", "-o", f"synth.reverb.level={level}",
        SF2, mid])


def peak_db(path):
    """Return the true sample peak of [path] in dBFS (0 = full scale)."""
    r = subprocess.run(["ffmpeg", "-i", path, "-af", "volumedetect", "-f", "null", "-"],
                       stderr=subprocess.PIPE, stdout=subprocess.DEVNULL, text=True).stderr
    m = re.search(r"max_volume:\s*(-?\d+(?:\.\d+)?) dB", r)
    return float(m.group(1)) if m else 0.0


def finish(raw, out, peak=-2.0, pre="", mp3=False, bitrate="192k"):
    """PEAK-normalise [raw] to [peak] dBFS (pure gain — no loudness target, no
    limiter pumping), AFTER reverb, then encode. We measure the real peak and
    scale strictly below 0 dBFS, so the result is guaranteed not to clip.
    WAV = 44.1kHz/16-bit PCM; MP3 = 192 kbps. Returns (raw_peak, out_peak)."""
    mv = peak_db(raw)
    gain = peak - mv
    af = (pre + "," if pre else "") + f"volume={gain:.2f}dB"
    if mp3:
        sh(["ffmpeg", "-y", "-i", raw, "-af", af, "-ar", str(SR), "-ac", "1",
            "-c:a", "libmp3lame", "-b:a", bitrate, out])
    else:
        sh(["ffmpeg", "-y", "-i", raw, "-af", af, "-ar", str(SR), "-ac", "1",
            "-c:a", "pcm_s16le", out])
    return mv, peak_db(out)


def tempo_track(tr, bpm):
    tr.append(MetaMessage("set_tempo", tempo=mido.bpm2tempo(bpm), time=0))


def add_note(tr, ch, note, start, dur, vel, prog=None, humanize=True):
    """Schedule one note. start/dur in ticks (absolute start). Returns events to
    be merged later (we build per-track absolute lists then sort)."""
    if humanize:
        vel = max(1, min(127, vel + random.randint(-10, 10)))
        start = max(0, start + random.randint(-12, 12))
    return [(start, "on", ch, note, vel, prog), (start + dur, "off", ch, note, 0, None)]


def write_track(mf, events, ch_progs):
    """events: list of (abs_tick, type, ch, note, vel, prog). Emits one track."""
    tr = MidiTrack()
    mf.tracks.append(tr)
    for ch, prog in ch_progs.items():
        if prog is not None:
            tr.append(Message("program_change", channel=ch, program=prog, time=0))
    events = sorted(events, key=lambda e: (e[0], 0 if e[1] == "off" else 1))
    last = 0
    for tick, typ, ch, note, vel, _ in events:
        dt = max(0, tick - last)
        last = tick
        if typ == "on":
            tr.append(Message("note_on", channel=ch, note=note, velocity=vel, time=dt))
        else:
            tr.append(Message("note_off", channel=ch, note=note, velocity=0, time=dt))
    return tr


# ---------- note one-shots ----------
def render_oneshots():
    # AB_ONLY → render just piano + suling (the A/B voices); leave the rest as-is.
    voices = {"piano": 0, "suling": 75} if os.environ.get("AB_ONLY") else PROG
    for instr, prog in voices.items():
        out_dir = os.path.join(AUD, instr)
        os.makedirs(out_dir, exist_ok=True)
        # light, clean tail (a touch more air for the breathy/metallic voices)
        room = 0.3 if instr in ("suling", "gamelan") else 0.18
        lvl = 0.12 if instr in ("suling", "gamelan") else 0.08
        for i, note in enumerate(NOTE_MIDI):
            try:
                mf = MidiFile(ticks_per_beat=TPB)
                tr = MidiTrack(); mf.tracks.append(tr)
                tempo_track(tr, 120)
                tr.append(Message("program_change", program=prog, time=0))
                vel = 100 if instr in ("angklung", "gamelan") else 92
                tr.append(Message("note_on", note=note, velocity=vel, time=0))
                # SHORT note so rapid taps don't pile long tails into the 5-voice
                # mix (the polyphony-clipping = "sember" cause).
                tr.append(Message("note_off", note=note, velocity=0, time=int(TPB * 1.4)))
                mid = os.path.join(out_dir, f"_n{i}.mid")
                raw = os.path.join(out_dir, f"_n{i}.raw.wav")
                out = os.path.join(out_dir, f"note_{i:02d}.wav")
                mf.save(mid)
                fsynth(mid, raw, gain=0.5, room=room, level=lvl)
                # trim leading silence, cap length, fade the tail cleanly, then
                # peak-normalise to -3 dBFS (headroom for polyphony; no clip).
                finish(raw, out, peak=-3.0,
                       pre="silenceremove=start_periods=1:start_threshold=-50dB,"
                           "atrim=0:1.5,afade=t=out:st=1.05:d=0.45")
                os.remove(mid); os.remove(raw)
            except Exception as e:  # leave the existing file in place on failure
                print(f"  ! {instr} note {i} failed: {e}")
        print(f"  one-shots: {instr} ({len(NOTE_MIDI)})")
    # default melody voice == piano
    for i in range(len(NOTE_MIDI)):
        src = os.path.join(AUD, "piano", f"note_{i:02d}.wav")
        dst = os.path.join(AUD, f"note_{i:02d}.wav")
        sh(["cp", src, dst])


# ---------- SFX ----------
def render_sfx():
    # tap: soft marimba blip
    _simple_note(os.path.join(AUD, "tap.wav"), prog=12, note=84, dur=0.18, vel=80, room=0.18)
    # wrong: low detuned thunk (Synth Bass region)
    _simple_note(os.path.join(AUD, "wrong.wav"), prog=38, note=40, dur=0.3, vel=95, room=0.15)


def _simple_note(out, prog, note, dur, vel, room=0.2, peak=-3.0):
    mf = MidiFile(ticks_per_beat=TPB)
    tr = MidiTrack(); mf.tracks.append(tr)
    tempo_track(tr, 120)
    tr.append(Message("program_change", program=prog, time=0))
    tr.append(Message("note_on", note=note, velocity=vel, time=0))
    tr.append(Message("note_off", note=note, velocity=0, time=int(TPB * dur * 2)))
    mid = out + ".mid"; raw = out + ".raw.wav"
    mf.save(mid)
    fsynth(mid, raw, gain=0.5, room=room, level=0.08)
    finish(raw, out, peak=peak,
           pre="silenceremove=start_periods=1:start_threshold=-50dB")
    os.remove(mid); os.remove(raw)


# ---------- home BGM (short humanized gamelan-ish loop) ----------
def render_home_bgm():
    bpm = 88
    bars = 4
    beat = TPB
    ev = []
    scale = [60, 62, 64, 67, 69]  # C major pentatonic (gamelan slendro-ish feel)
    # gentle vibraphone arpeggio + soft bass pad
    for b in range(bars * 4):
        t = b * beat
        n = scale[(b * 2) % len(scale)] + (12 if b % 8 >= 4 else 0)
        ev += add_note(ev_ch(11), 0, n, t, int(beat * 1.5), 64)
        if b % 2 == 0:
            ev += add_note(None, 1, 36 + (0 if b % 8 < 4 else 7), t, beat * 2, 55)
    mf = MidiFile(ticks_per_beat=TPB)
    tr = MidiTrack(); mf.tracks.append(tr); tempo_track(tr, bpm)
    write_events(mf, ev, {0: 11, 1: 32})
    mid = os.path.join(AUD, "bgm_home.mid"); raw = os.path.join(AUD, "bgm_home.raw.wav")
    out = os.path.join(AUD, "bgm_home.wav")
    mf.save(mid)
    fsynth(mid, raw, gain=0.5, room=0.3, level=0.12)
    finish(raw, out, peak=-3.0)  # clean WAV master; playback volume keeps it subtle
    os.remove(mid); os.remove(raw)


def ev_ch(_):  # tiny helpers to keep add_note signature happy
    return None


def write_events(mf, events, ch_progs):
    tr = MidiTrack(); mf.tracks.append(tr)
    for ch, prog in ch_progs.items():
        tr.append(Message("program_change", channel=ch, program=prog, time=0))
    events = sorted(events, key=lambda e: (e[0], 0 if e[1] == "off" else 1))
    last = 0
    for tick, typ, ch, note, vel, _ in events:
        dt = max(0, tick - last); last = tick
        msg = "note_on" if typ == "on" else "note_off"
        tr.append(Message(msg, channel=ch, note=note, velocity=vel, time=dt))


# ---------- per-song backing groove bed (C-major, modern, humanized) ----------
# ---------- in-game accompaniment ----------
# All Tiles songs are centred on C (do = C / index 3), so a C open-fifth (C+G,
# NO third → neither major nor minor) never clashes with diatonic OR pentatonic
# melodies. We DON'T impose a chord progression any more (that was what fought
# the tunes). Two variants the player can pick from in settings:
#   • "ambient pad"  → a single shared, tempo-independent warm drone (default)
#   • "soft groove"  → per-song, tempo-matched, root-fifth bass + light shaker
# Both render quiet so the tapped melody always dominates.

def render_pad():
    # Warm pad drone on C+G open fifth (two octaves), no rhythm, tempo-free → one
    # shared loop that fits every song. GM program 89 = Pad 2 (warm).
    beat = TPB
    bars = 8  # ~ long, gentle loop
    ev = []
    for bar in range(bars):
        base = bar * 4 * beat
        # re-voice softly each bar so the loop breathes a little (still C+G only)
        for n in (36, 48, 55):  # C2, C3, G3
            ev += add_note(None, 0, n, base, beat * 4, 46, humanize=False)
    mf = MidiFile(ticks_per_beat=TPB)
    tr = MidiTrack(); mf.tracks.append(tr); tempo_track(tr, 60)
    write_events(mf, ev, {0: 89})  # Pad 2 (warm)
    mid = os.path.join(AUD, "_pad.mid"); raw = os.path.join(AUD, "_pad.raw.wav")
    out = os.path.join(AUD, "backing_pad.mp3")
    mf.save(mid)
    fsynth(mid, raw, gain=0.5, room=0.35, level=0.14)  # soft, clean tail
    finish(raw, out, peak=-16.0, mp3=True, bitrate="192k")  # quiet clean master; sits far under melody
    os.remove(mid); os.remove(raw)
    print("  ambient pad: backing_pad.mp3")


def render_backing(songs):
    out_dir = os.path.join(AUD, "backing")
    os.makedirs(out_dir, exist_ok=True)
    ok = 0
    for sid, bpm in songs:
      try:
        bpm = max(80, min(150, int(bpm)))
        beat = TPB
        bars = 8
        ev = []
        for bar in range(bars):
            base = bar * 4 * beat
            # neutral root–fifth bass only (C2 on 1, G2 on 3) — no chords imposed
            ev += add_note(None, 0, 36, base + 0 * beat, int(beat * 0.9), 70)
            ev += add_note(None, 0, 43, base + 2 * beat, int(beat * 0.9), 64)
            # gentle timing support: soft kick on 1 & 3 + light shaker on off-beats
            for k in (0, 2):
                ev += add_note(None, 9, 36, base + k * beat, beat // 2, 74)
            for h in range(4):
                ev += add_note(None, 9, 70, base + h * beat + beat // 2, beat // 4, 34)
        mf = MidiFile(ticks_per_beat=TPB)
        tr = MidiTrack(); mf.tracks.append(tr); tempo_track(tr, bpm)
        write_events(mf, ev, {0: 33, 9: 0})  # acoustic bass + drum ch9
        mid = os.path.join(out_dir, f"_{sid}.mid")
        raw = os.path.join(out_dir, f"_{sid}.raw.wav")
        out = os.path.join(out_dir, f"{sid}.mp3")
        mf.save(mid)
        fsynth(mid, raw, gain=0.5, room=0.25, level=0.10)  # light, clean
        finish(raw, out, peak=-14.0, mp3=True, bitrate="192k")  # quiet clean master; under melody
        os.remove(mid); os.remove(raw)
        ok += 1
      except Exception as e:  # leave any prior file in place on failure
        print(f"  ! backing {sid} failed: {e}")
    print(f"  soft grooves: {ok}/{len(songs)}")


def parse_songs(path):
    txt = open(path, encoding="utf-8").read()
    out = []
    for m in re.finditer(r"id:\s*'([a-z0-9]+)'.*?bpm:\s*(\d+)", txt, re.S):
        out.append((m.group(1), int(m.group(2))))
    return out


def main():
    if not os.path.exists(SF2):
        print("SoundFont not found:", SF2); sys.exit(1)
    os.makedirs(AUD, exist_ok=True)
    songs = parse_songs(os.path.join(ROOT, "lib", "game", "songs.dart"))
    print(f"Parsed {len(songs)} songs")

    # Report OLD peak levels (clipping check) for a piano + a suling note.
    probe = [("piano", os.path.join(AUD, "piano", "note_03.wav")),
             ("suling", os.path.join(AUD, "suling", "note_03.wav"))]
    for name, p in probe:
        if os.path.exists(p):
            print(f"OLD peak {name} note_03: {peak_db(p):.2f} dBFS (WAV)")

    render_oneshots()
    if not os.environ.get("AB_ONLY"):  # full render only outside A/B mode
        render_sfx()
        render_home_bgm()
        render_pad()
        render_backing(songs)

    # Report NEW peak levels — should be ~-2 dBFS and never 0 (no clipping).
    for name, p in probe:
        if os.path.exists(p):
            print(f"NEW peak {name} note_03: {peak_db(p):.2f} dBFS (WAV 44.1k/16-bit)")
    bk = os.path.join(AUD, "backing", f"{songs[0][0]}.mp3") if songs else None
    if bk and os.path.exists(bk):
        print(f"NEW peak backing {songs[0][0]}: {peak_db(bk):.2f} dBFS (MP3 192k)")
    print("Audio render complete.")


if __name__ == "__main__":
    main()
