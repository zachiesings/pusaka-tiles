import 'dart:math';
import '../../core/constants.dart';
import '../models/song.dart';

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
  })  : _rng = Random(seed),
        _step = speedStep ?? K.speedStep,
        _maxSpeed = maxSpeed ?? K.maxSpeed {
    speed = (startSpeed ?? K.startSpeed) * song.speedScale;
    _ensureAhead(16);
  }

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
    // Miss: the next tile's far (top) edge scrolled fully past the hit line.
    if (scroll > t.startBeat + t.beats) {
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

  /// Tap [col]. Returns the note index to play on success, or -1 on a wrong tap.
  int tapColumn(int col) {
    if (gameOver || completed) return -1;
    _ensureAhead(6);
    if (nextTap >= rows.length) {
      completed = true;
      return -1;
    }
    final t = rows[nextTap];
    if (col == t.activeColumn) {
      started = true;
      t.tapped = true;
      lastTiming = scroll - t.startBeat; // 0 = bang on the hit line
      score++;
      nextTap++;
      speed = min(_maxSpeed, speed + _step);
      if (finite && nextTap >= song.notes.length) completed = true;
      return t.noteIndex;
    }
    gameOver = true;
    return -1;
  }
}
