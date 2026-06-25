import 'dart:math';
import 'models/song.dart';

/// The interactive vocabulary of a tile. Beyond a plain [tap], a chart can ask
/// the player to hold a long note, swipe (slide/flick), or strike two lanes at
/// once (chord). EVERY kind is still clearable by a correctly-timed tap on its
/// lane — the gesture/extra lane only adds feel + score — so a chart can never
/// become unbeatable. (Device-verified gesture bonuses are a later pass.)
enum NoteKind { tap, hold, slide, flick, chord }

/// Difficulty tiers. The SAME melody is rendered four ways: each tier widens the
/// note vocabulary, the lane-jump range, and the tempo. Onsets always stay
/// locked to the melody (see [ChartGenerator]), only the decoration changes.
enum Difficulty { mudah, normal, sulit, master }

class DifficultySpec {
  final String label;
  final double speedMul;       // tempo multiplier (on top of song + user speed)
  final int maxJump;           // max lane distance between consecutive notes
  final Set<NoteKind> kinds;   // which note kinds may be generated
  const DifficultySpec(this.label, this.speedMul, this.maxJump, this.kinds);
}

const Map<Difficulty, DifficultySpec> kDifficulty = {
  Difficulty.mudah:
      DifficultySpec('Mudah', 0.9, 1, {NoteKind.tap}),
  Difficulty.normal:
      DifficultySpec('Normal', 1.0, 2, {NoteKind.tap, NoteKind.hold}),
  Difficulty.sulit: DifficultySpec(
      'Sulit', 1.12, 3, {NoteKind.tap, NoteKind.hold, NoteKind.flick, NoteKind.slide}),
  Difficulty.master: DifficultySpec('Master', 1.28, 3,
      {NoteKind.tap, NoteKind.hold, NoteKind.flick, NoteKind.slide, NoteKind.chord}),
};

/// How a session plays out (independent of difficulty):
/// • practice  — loop the song, no-fail, slower: learn the chart.
/// • endless   — loop forever, tempo ramps, one life: chase a high score.
/// • challenge — one full pass, one life, graded.
/// • daily     — one full pass of the day's deterministic pick, one life.
enum PlayMode { practice, endless, challenge, daily }

class PlayModeSpec {
  final String label;
  final bool loop;     // wrap the chart endlessly
  final bool finite;   // ends after exactly one pass
  final bool noFail;   // misses/wrong taps don't end the run
  final bool ramp;     // tempo rises per hit
  final double speedMul;
  const PlayModeSpec(this.label,
      {this.loop = false,
      this.finite = false,
      this.noFail = false,
      this.ramp = false,
      this.speedMul = 1.0});
}

const Map<PlayMode, PlayModeSpec> kPlayModes = {
  PlayMode.practice:
      PlayModeSpec('Latihan', loop: true, noFail: true, speedMul: 0.8),
  PlayMode.endless: PlayModeSpec('Tanpa Henti', loop: true, ramp: true),
  PlayMode.challenge: PlayModeSpec('Tantangan', finite: true),
  PlayMode.daily: PlayModeSpec('Harian', finite: true),
};

/// One placed note in a generated chart. [beat] is the onset (cumulative beats
/// from the song start); [dur] is the musical length (tile height + how far the
/// onset advances). Holds reuse [dur] as their sustain. [chordLane] is the
/// second simultaneous lane for a chord (-1 = none); [dir] is the swipe sense
/// for slide/flick (-1 left, +1 right, 0 up).
class ChartNote {
  final double beat;
  final double dur;
  final int lane;
  final int pitch;
  final NoteKind kind;
  final int dir;
  final int chordLane;
  const ChartNote({
    required this.beat,
    required this.dur,
    required this.lane,
    required this.pitch,
    this.kind = NoteKind.tap,
    this.dir = 0,
    this.chordLane = -1,
  });
}

/// A fully-resolved playable chart: the ordered notes of one pass + the total
/// beat length (used to wrap the stream in looping modes).
class Chart {
  final List<ChartNote> notes;
  final double totalBeats;
  final Difficulty difficulty;
  const Chart(this.notes, this.totalBeats, this.difficulty);
  int get length => notes.length;
}

/// Stable 32-bit FNV-1a hash. Dart's String.hashCode is salted per run, so it
/// can't seed anything that must be reproducible (e.g. the Daily chart). This is.
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// Turns a [Song] into a playable [Chart] for a [Difficulty]. Deterministic for
/// a given (song, difficulty, seed). KEY INVARIANT: note i's onset equals the
/// cumulative sum of the song's (cycled) beat durations — the chart is always
/// locked to the melody's real onsets; difficulty only changes lanes/kinds/tempo.
class ChartGenerator {
  /// [legacy] forces a taps-only chart (campaign parity — the shipped journey
  /// must keep playing exactly as before, no new note kinds).
  static Chart generate(
    Song song,
    Difficulty diff, {
    int seed = 0,
    int columns = 4,
    bool legacy = false,
  }) {
    final spec = kDifficulty[diff]!;
    final kinds = legacy ? const <NoteKind>{NoteKind.tap} : spec.kinds;
    final rng = Random(seed ^ stableHash('${song.id}|${diff.index}|$legacy'));
    final out = <ChartNote>[];
    final n = song.notes.length;
    var beat = 0.0;
    var prevLane = rng.nextInt(columns);
    var prevPitch = n > 0 ? song.notes[0] : 0;
    for (var i = 0; i < n; i++) {
      final pitch = song.notes[i];
      final dur = song.beats[i % song.beats.length].toDouble();
      final lane = _nextLane(prevLane, rng, spec.maxJump, columns);
      var kind = NoteKind.tap;
      var dir = 0;
      var chordLane = -1;

      // Long melody notes become holds (their sustain == the note's real length).
      if (kinds.contains(NoteKind.hold) && dur >= 2.0) {
        kind = NoteKind.hold;
      }
      // A deterministic minority of taps become directional swipes; the swipe
      // sense follows the melodic motion so it "feels" musical.
      if (kind == NoteKind.tap && i % 7 == 3 &&
          (kinds.contains(NoteKind.flick) || kinds.contains(NoteKind.slide))) {
        final motion = pitch == prevPitch ? 0 : (pitch > prevPitch ? 1 : -1);
        if (motion == 0 && kinds.contains(NoteKind.flick)) {
          kind = NoteKind.flick;
          dir = 0;
        } else if (motion != 0 && kinds.contains(NoteKind.slide)) {
          kind = NoteKind.slide;
          dir = motion;
        }
      }
      // Accented beats become two-lane chords on the hardest tier.
      if (kind == NoteKind.tap && kinds.contains(NoteKind.chord) && i > 0 && i % 8 == 0) {
        var cl = _nextLane(lane, rng, columns, columns);
        if (cl == lane) cl = (lane + 1) % columns;
        kind = NoteKind.chord;
        chordLane = cl;
      }

      out.add(ChartNote(
        beat: beat,
        dur: dur,
        lane: lane,
        pitch: pitch,
        kind: kind,
        dir: dir,
        chordLane: chordLane,
      ));
      beat += dur;
      prevLane = lane;
      prevPitch = pitch;
    }
    return Chart(out, beat, diff);
  }

  /// Pick a lane within [maxJump] of [prev], preferring movement off [prev].
  static int _nextLane(int prev, Random rng, int maxJump, int columns) {
    if (maxJump <= 0) return prev;
    final lo = (prev - maxJump) < 0 ? 0 : prev - maxJump;
    final hi = (prev + maxJump) >= columns ? columns - 1 : prev + maxJump;
    for (var t = 0; t < 5; t++) {
      final l = lo + rng.nextInt(hi - lo + 1);
      if (l != prev) return l;
    }
    return (prev + 1) % columns;
  }
}

/// Deterministic "Daily" pick. Same calendar day → same song + difficulty for
/// everyone, no network needed. Returns the catalog index + difficulty.
class DailyPick {
  final int songIndex;
  final Difficulty difficulty;
  final int seed;
  const DailyPick(this.songIndex, this.difficulty, this.seed);
}

int dailySeed(int year, int month, int day) =>
    stableHash('daily-$year-$month-$day');

DailyPick dailyPick(int year, int month, int day, int songCount) {
  final seed = dailySeed(year, month, day);
  final rng = Random(seed);
  final songIndex = songCount <= 0 ? 0 : rng.nextInt(songCount);
  // Bias the daily toward the middle tiers (Normal/Sulit) for a fair challenge.
  const pool = [
    Difficulty.normal,
    Difficulty.normal,
    Difficulty.sulit,
    Difficulty.master,
  ];
  final difficulty = pool[rng.nextInt(pool.length)];
  return DailyPick(songIndex, difficulty, seed);
}
