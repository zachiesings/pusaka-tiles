import 'dart:math';
import '../../core/constants.dart';
import '../models/song.dart';

/// One scrolling row: exactly one lane holds the active (tappable) tile, which
/// plays [noteIndex] from the song when tapped.
class TileRow {
  final int activeColumn;
  final int noteIndex;
  bool tapped;
  TileRow(this.activeColumn, this.noteIndex) : tapped = false;
}

/// Pure game logic for the falling-tiles board. Time is driven externally via
/// [tick]; rendering reads [rows] + [scroll]. No Flutter dependency.
class TilesEngine {
  final int columns;
  final Song song;
  final Random _rng;

  final List<TileRow> rows = <TileRow>[]; // absolute index == row number
  double scroll = 0;   // rows scrolled past the bottom line (grows over time)
  int nextTap = 0;     // absolute index of the lowest un-tapped row
  int score = 0;
  bool started = false; // becomes true on the first tap (grace before moving)
  bool gameOver = false;
  late double speed;   // rows per second
  int _songPos = 0;

  TilesEngine({required this.song, this.columns = 4, int? seed})
      : _rng = Random(seed) {
    speed = K.startSpeed * song.speedScale;
    _ensureAhead(12);
  }

  void _genRow() {
    final col = _rng.nextInt(columns);
    final note = song.notes[_songPos % song.notes.length];
    _songPos++;
    rows.add(TileRow(col, note));
  }

  void _ensureAhead(int n) {
    while (rows.length < nextTap + n) {
      _genRow();
    }
  }

  /// Advance time by [dt] seconds. Tiles only move once the player has made the
  /// first tap, so the board waits politely at the start.
  void tick(double dt) {
    if (gameOver || !started) return;
    scroll += speed * dt;
    _ensureAhead(12);
    // Miss: the next tile fully scrolled past the bottom line.
    if (scroll - nextTap > 1.0) {
      gameOver = true;
    }
  }

  /// Ad-rewarded revive: clear the game-over, drop the next tile back to the
  /// bottom line and wait for the player's tap. Score is kept.
  void revive() {
    gameOver = false;
    started = false;
    scroll = nextTap.toDouble();
    _ensureAhead(12);
  }

  /// Tap [col]. Returns the note index to play on success, or -1 on a wrong tap
  /// (which ends the game).
  int tapColumn(int col) {
    if (gameOver) return -1;
    _ensureAhead(4);
    final row = rows[nextTap];
    if (col == row.activeColumn) {
      started = true;
      row.tapped = true;
      score++;
      nextTap++;
      speed = min(K.maxSpeed, speed + K.speedStep);
      return row.noteIndex;
    }
    gameOver = true;
    return -1;
  }
}
