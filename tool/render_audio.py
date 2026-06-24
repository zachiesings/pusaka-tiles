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


def fsynth(mid, wav, gain=0.9, room=0.5, level=0.4):
    sh(["fluidsynth", "-ni", "-g", str(gain), "-F", wav, "-r", str(SR),
        "-o", "synth.reverb.active=1", "-o", f"synth.reverb.room-size={room}",
        "-o", "synth.reverb.width=0.7", "-o", f"synth.reverb.level={level}",
        SF2, mid])


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
    for instr, prog in PROG.items():
        out_dir = os.path.join(AUD, instr)
        os.makedirs(out_dir, exist_ok=True)
        room = 0.65 if instr in ("suling", "gamelan") else 0.45
        for i, note in enumerate(NOTE_MIDI):
            try:
                mf = MidiFile(ticks_per_beat=TPB)
                tr = MidiTrack(); mf.tracks.append(tr)
                tempo_track(tr, 120)
                tr.append(Message("program_change", program=prog, time=0))
                vel = 112 if instr in ("angklung", "gamelan") else 100
                tr.append(Message("note_on", note=note, velocity=vel, time=0))
                tr.append(Message("note_off", note=note, velocity=0, time=int(TPB * 2.4)))
                mid = os.path.join(out_dir, f"_n{i}.mid")
                raw = os.path.join(out_dir, f"_n{i}.raw.wav")
                out = os.path.join(out_dir, f"note_{i:02d}.wav")
                mf.save(mid)
                fsynth(mid, raw, gain=0.95, room=room, level=0.35)
                # trim leading silence, normalise so notes cut through, keep decay tail
                sh(["ffmpeg", "-y", "-i", raw,
                    "-af", "silenceremove=start_periods=1:start_threshold=-50dB,"
                           "loudnorm=I=-13:TP=-1.0:LRA=11",
                    "-ac", "1", "-ar", str(SR), out])
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
    _simple_note(os.path.join(AUD, "tap.wav"), prog=12, note=84, dur=0.18, vel=70, room=0.3, norm=-16)
    # wrong: low detuned thunk (Synth Bass region)
    _simple_note(os.path.join(AUD, "wrong.wav"), prog=38, note=40, dur=0.3, vel=90, room=0.2, norm=-14)


def _simple_note(out, prog, note, dur, vel, room=0.4, norm=-14):
    mf = MidiFile(ticks_per_beat=TPB)
    tr = MidiTrack(); mf.tracks.append(tr)
    tempo_track(tr, 120)
    tr.append(Message("program_change", program=prog, time=0))
    tr.append(Message("note_on", note=note, velocity=vel, time=0))
    tr.append(Message("note_off", note=note, velocity=0, time=int(TPB * dur * 2)))
    mid = out + ".mid"; raw = out + ".raw.wav"
    mf.save(mid)
    fsynth(mid, raw, gain=0.9, room=room, level=0.3)
    sh(["ffmpeg", "-y", "-i", raw, "-af",
        f"silenceremove=start_periods=1:start_threshold=-50dB,loudnorm=I={norm}:TP=-1.0",
        "-ac", "1", "-ar", str(SR), out])
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
    fsynth(mid, raw, gain=0.8, room=0.7, level=0.5)
    sh(["ffmpeg", "-y", "-i", raw, "-af", "loudnorm=I=-18:TP=-2.0", "-ac", "1", "-ar", str(SR), out])
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
def render_backing(songs):
    out_dir = os.path.join(AUD, "backing")
    os.makedirs(out_dir, exist_ok=True)
    # I–vi–IV–V loop in C major (safe under any C-major diatonic melody)
    chords = [[48, 52, 55], [45, 48, 52], [41, 45, 48], [43, 47, 50]]  # C Am F G
    bass_root = [36, 33, 29, 31]
    ok = 0
    for sid, bpm in songs:
      try:
        bpm = max(80, min(150, int(bpm)))
        beat = TPB
        bars = 8
        ev = []
        for bar in range(bars):
            ch = chords[bar % 4]
            root = bass_root[bar % 4]
            base = bar * 4 * beat
            # bass: root on 1 & 3, fifth on 4-and
            ev += add_note(None, 0, root, base + 0 * beat, int(beat * 0.9), 92)
            ev += add_note(None, 0, root, base + 2 * beat, int(beat * 0.9), 84)
            ev += add_note(None, 0, root + 7, base + int(3.5 * beat), int(beat * 0.5), 78)
            # soft chord stabs on the off-beats (electric piano)
            for off in (1, 3):
                for n in ch:
                    ev += add_note(None, 1, n + 12, base + off * beat + beat // 2,
                                   int(beat * 0.45), 50)
            # drums: kick 1&3, snare 2&4, closed hat eighths, shaker
            for k in (0, 2):
                ev += add_note(None, 9, 36, base + k * beat, beat // 2, 100, humanize=True)
            for s in (1, 3):
                ev += add_note(None, 9, 38, base + s * beat, beat // 2, 88)
            for h in range(8):
                ev += add_note(None, 9, 42, base + h * (beat // 2), beat // 4, 58)
                ev += add_note(None, 9, 70, base + h * (beat // 2) + beat // 4, beat // 4, 40)
        mf = MidiFile(ticks_per_beat=TPB)
        tr = MidiTrack(); mf.tracks.append(tr); tempo_track(tr, bpm)
        write_events(mf, ev, {0: 33, 1: 4, 9: 0})  # bass, e.piano, (drum ch9)
        mid = os.path.join(out_dir, f"_{sid}.mid")
        raw = os.path.join(out_dir, f"_{sid}.raw.wav")
        out = os.path.join(out_dir, f"{sid}.mp3")
        mf.save(mid)
        fsynth(mid, raw, gain=0.8, room=0.45, level=0.35)
        # mono, sit lower so the tapped melody stays on top, mp3 (iOS-friendly)
        sh(["ffmpeg", "-y", "-i", raw, "-af", "loudnorm=I=-19:TP=-2.0", "-ac", "1",
            "-c:a", "libmp3lame", "-q:a", "5", out])
        os.remove(mid); os.remove(raw)
        ok += 1
      except Exception as e:  # leave any prior file in place on failure
        print(f"  ! backing {sid} failed: {e}")
    print(f"  backing beds: {ok}/{len(songs)}")


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
    render_oneshots()
    render_sfx()
    render_home_bgm()
    render_backing(songs)
    print("Audio render complete.")


if __name__ == "__main__":
    main()
