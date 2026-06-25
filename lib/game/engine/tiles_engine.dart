import 'dart:math';
import '../../core/constants.dart';
import '../chart.dart';

/// tapColumn() return sentinels (note indices are always 0..12, so negatives are
/// safe out-of-band signals). >= 0 == the note to play on a successful hit.
const int kTapWrong = -1; // wrong lane → run ends (unless no-fail)
const int kTapEarly = -2; // too far ahead of the line → ignored (tile not used)

/// One scrolling tile, resolved from a [ChartNote] at an absolute beat position.
/// Taller tiles = longer notes, so the melody scrolls in real rhythm. [kind]
/// carries the note vocabulary (hold/slide/flick/chord); every kind is still
/// clearable with a correctly-timed tap on its lane.
class TileRow {
  final int activeColumn;
  final int noteIndex;
  final double beats;     // visual height = the note's musical duration
  final double startBeat; // absolute onset from the start of the run
  final NoteKind kind;
  final int dir;          // flick/slide swipe sense (-1/0/+1)
  final int chordLane;    // chord's 2nd lane, else -1
  bool tapped;
  TileRow(this.activeColumn, this.noteIndex, this.beats, this.startBeat,
      {this.kind = NoteKind.tap, this.dir = 0, this.chordLane = -1})
      : tapped = false;
}

/// Pure beat-based game logic, driven by a precomputed [Chart]. Time (via [tick])
/// advances [scroll] in beats; rendering reads tiles by their beat span. No
/// Flutter dependency. Supports finite (one pass), looping (endless), and no-fail
/// (practice) play.
class TilesEngine {
  final int columns;
  final Chart chart;
  final bool finite;  // stop after one full pass, then complete
  final bool loop;    // wrap the chart endlessly (ignored when finite)
  final bool noFail;  // misses / wrong taps don't end the run

  /// Device timing correction (ms). Converted to beats at the live speed each tap
  /// — a positive value shifts judging later, compensating a player who taps late.
  double offsetMs;

  final List<TileRow> rows = <TileRow>[];
  double scroll = 0;      // beats scrolled past the hit line
  int nextTap = 0;        // index of the lowest un-tapped tile
  int score = 0;          // count of cleared tiles
  int missCount = 0;      // tiles missed (no-fail mode keeps going)
  bool started = false;
  bool gameOver = false;
  bool completed = false; // finite song fully cleared (a win)
  double lastTiming = 0;  // signed beats: (scroll - tile.startBeat) at tap time
  late double speed;      // beats per second
  final double _step;
  final double _maxSpeed;
  int _idx = 0;           // index into the (possibly looped) chart stream

  TilesEngine({
    required this.chart,
    this.columns = 4,
    this.finite = false,
    this.loop = false,
    this.noFail = false,
    this.offsetMs = 0,
    double? startSpeed,
    double? speedStep,
    double? maxSpeed,
  })  : _step = speedStep ?? K.speedStep,
        _maxSpeed = maxSpeed ?? K.maxSpeed {
    speed = startSpeed ?? K.startSpeed;
    _ensureAhead(16);
  }

  /// Live offset expressed in beats (depends on the current speed).
  double get _offsetBeats => offsetMs / 1000.0 * speed;

  bool get _exhausted => !loop && _idx >= chart.length;

  void _genRow() {
    if (chart.length == 0) return;
    if (_exhausted) return; // finite/non-loop: nothing more to place
    final ci = loop ? _idx % chart.length : _idx;
    final base = loop ? (_idx ~/ chart.length) * chart.totalBeats : 0.0;
    final cn = chart.notes[ci];
    // For looping, onsets are chart-relative + a per-lap base; a single pass uses
    // cn.beat directly (base == 0).
    final startBeat = cn.beat + base;
    rows.add(TileRow(cn.lane, cn.pitch, cn.dur, startBeat,
        kind: cn.kind, dir: cn.dir, chordLane: cn.chordLane));
    _idx++;
  }

  void _ensureAhead(int n) {
    while (rows.length < nextTap + n) {
      final before = rows.length;
      _genRow();
      if (rows.length == before) break; // generation exhausted (finite mode)
    }
  }

  void tick(double dt) {
    if (gameOver || completed || !started) return;
    scroll += speed * dt;
    _ensureAhead(16);
    if (nextTap >= rows.length) {
      if (finite || _exhausted) completed = true; // every tile passed/tapped
      return;
    }
    final t = rows[nextTap];
    // Miss: the next tile's far (top) edge scrolled fully past the hit line
    // (offset-compensated, so a late-tapping device isn't failed early).
    if (scroll - _offsetBeats > t.startBeat + t.beats) {
      if (noFail) {
        missCount++;
        nextTap++; // skip the missed tile and keep going
      } else {
        gameOver = true;
      }
    }
  }

  /// Ad-rewarded revive: clear the loss, drop the next tile back to the line.
  void revive() {
    gameOver = false;
    started = false;
    if (nextTap < rows.length) scroll = rows[nextTap].startBeat;
    _ensureAhead(16);
  }

  /// Tap [col]. Returns the note index (>=0) to play on a successful hit, or
  /// [kTapWrong] (wrong lane) / [kTapEarly] (too far ahead — ignored).
  int tapColumn(int col) {
    if (gameOver || completed) return kTapWrong;
    _ensureAhead(6);
    if (nextTap >= rows.length) {
      if (finite || _exhausted) completed = true;
      return kTapWrong;
    }
    final t = rows[nextTap];
    // A chord clears from either of its two lanes (the 2nd lane is bonus feel).
    final matches =
        col == t.activeColumn || (t.kind == NoteKind.chord && col == t.chordLane);
    if (!matches) {
      if (noFail) return kTapWrong; // practice: a wrong tap is harmless
      gameOver = true;
      return kTapWrong;
    }
    // Offset-compensated timing: 0 = the tile's bottom edge is on the hit line.
    final timing = (scroll - t.startBeat) - _offsetBeats;
    // Too early: the tile is still well above the hittable window — whiff (the
    // tile is not consumed), so you can't pre-tap a whole song.
    if (timing < -Judge.bad) return kTapEarly;
    started = true;
    t.tapped = true;
    lastTiming = timing;
    score++;
    nextTap++;
    speed = min(_maxSpeed, speed + _step);
    if (finite && nextTap >= chart.length) completed = true;
    return t.noteIndex;
  }
}
