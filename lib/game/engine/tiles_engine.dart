import 'dart:math';
import '../../core/constants.dart';
import '../models/song.dart';

/// tapColumn() return sentinels (note indices are always 0..12, so negatives are
/// safe out-of-band signals). >= 0 == the note to play on a successful hit.
const int kTapWrong = -1; // wrong lane → run ends
const int kTapEarly = -2; // too far ahead of the line → ignored (tile not used)

/// One scrolling tile. Occupies the beat-span [startBeat, startBeat+beats] in a
/// single lane; taller tiles = longer notes → the melody plays in real rhythm.
class TileRow {
  final int activeColumn;
  final int noteIndex;
  final double beats;     // duration in beats (tile height)
  final double startBeat; // cumulative position from the start of the run
  bool tapped;
  TileRow(this.activeColumn, this.noteIndex, this.beats, this.startBeat)
      : tapped = false;
}

/// Pure beat-based game logic. Time (driven via [tick]) advances [scroll] in
/// beats; rendering reads tiles by their beat span. No Flutter dependency.
class TilesEngine {
  final int columns;
  final Song song;
  final bool finite;      // "Lagu Penuh": stop after one full pass, then complete
  final Random _rng;

  /// Device timing correction (ms). Converted to beats at the live speed each tap
  /// — a positive value shifts judging later, compensating a player who taps late.
  double offsetMs;

  final List<TileRow> rows = <TileRow>[];
  double scroll = 0;      // beats scrolled past the hit line
  int nextTap = 0;        // index of the lowest un-tapped tile
  int score = 0;
  bool started = false;
  bool gameOver = false;
  bool completed = false; // finite song fully cleared (a win)
  double lastTiming = 0;  // signed beats: (scroll - tile.startBeat) at tap time
  late double speed;      // beats per second
  final double _step;
  final double _maxSpeed;
  int _songPos = 0;
  double _cursor = 0;     // cumulative beat position for the next generated tile

  TilesEngine({
    required this.song,
    this.columns = 4,
    this.finite = false,
    int? seed,
    double? startSpeed,
    double? speedStep,
    double? maxSpeed,
    this.offsetMs = 0,
    double speedScale = 1.0, // user scroll-speed preference × per-song scale
  })  : _rng = Random(seed),
        _step = (speedStep ?? K.speedStep) * speedScale,
        _maxSpeed = (maxSpeed ?? K.maxSpeed) * speedScale {
    speed = (startSpeed ?? K.startSpeed) * song.speedScale * speedScale;
    _ensureAhead(16);
  }

  /// Live offset expressed in beats (depends on the current speed).
  double get _offsetBeats => offsetMs / 1000.0 * speed;

  void _genRow() {
    if (finite && _songPos >= song.notes.length) return; // finite: no more tiles
    final col = _rng.nextInt(columns);
    final note = song.notes[_songPos % song.notes.length];
    // tolerate beats/notes length mismatch (never crash on data entry)
    final beats = song.beats[_songPos % song.beats.length];
    rows.add(TileRow(col, note, beats, _cursor));
    _cursor += beats;
    _songPos++;
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
      completed = true; // finite: every tile passed/tapped
      return;
    }
    final t = rows[nextTap];
    // Miss: the next tile's far (top) edge scrolled fully past the hit line
    // (offset-compensated, so a late-tapping device isn't failed early).
    if (scroll - _offsetBeats > t.startBeat + t.beats) {
      gameOver = true;
    }
  }

  /// Ad-rewarded revive: clear the loss, drop the next tile back to the line.
  void revive() {
    gameOver = false;
    started = false;
    scroll = rows[nextTap].startBeat;
    _ensureAhead(16);
  }

  /// Tap [col]. Returns the note index (>=0) to play on a successful hit, or
  /// [kTapWrong] (wrong lane — run ends) / [kTapEarly] (too far ahead — ignored).
  int tapColumn(int col) {
    if (gameOver || completed) return kTapWrong;
    _ensureAhead(6);
    if (nextTap >= rows.length) {
      completed = true;
      return kTapWrong;
    }
    final t = rows[nextTap];
    if (col != t.activeColumn) {
      gameOver = true;
      return kTapWrong; // wrong lane is always a mistake
    }
    // Offset-compensated timing: 0 = the tile's bottom edge is on the hit line,
    // negative = it hasn't arrived yet, positive = it's begun to pass.
    final timing = (scroll - t.startBeat) - _offsetBeats;
    // Too early: the tile is still well above the hittable window. Don't consume
    // it — the player simply whiffs and can tap again as it arrives. This is what
    // stops a player from pre-tapping a whole song to "win" without timing.
    if (timing < -Judge.bad) return kTapEarly;
    started = true;
    t.tapped = true;
    lastTiming = timing;
    score++;
    nextTap++;
    speed = min(_maxSpeed, speed + _step);
    if (finite && nextTap >= song.notes.length) completed = true;
    return t.noteIndex;
  }
}
