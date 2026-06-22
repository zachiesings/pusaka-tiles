import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../game/engine/tiles_engine.dart';
import '../game/models/song.dart';
import 'app_state.dart';

/// Drives a Pusaka Tiles session: owns the engine, runs the per-frame clock via
/// a [Ticker], routes taps to notes, and records the best score on game over.
class TilesGameController extends ChangeNotifier {
  final AppState app;
  final Song song;

  late TilesEngine engine;
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool isNewBest = false;
  bool _scored = false;

  TilesGameController(this.app, this.song) {
    _begin();
  }

  void _begin() {
    engine = TilesEngine(song: song);
    _last = Duration.zero;
    isNewBest = false;
    _scored = false;
    _ticker?.dispose();
    _ticker = Ticker(_onTick)..start();
  }

  void restart() {
    _begin();
    notifyListeners();
  }

  /// Resume after a rewarded ad: clear the loss, restart the (stopped) clock.
  void reviveAfterAd() {
    engine.revive();
    _scored = false;
    _last = Duration.zero;
    if (!(_ticker?.isActive ?? false)) _ticker?.start();
    notifyListeners();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;
    final wasOver = engine.gameOver;
    engine.tick(dt.clamp(0.0, 0.05)); // clamp to avoid huge jumps after stalls
    if (engine.gameOver && !wasOver) {
      app.playWrong();
      _finish();
    }
    notifyListeners();
  }

  void tap(int col) {
    if (engine.gameOver) return;
    final note = engine.tapColumn(col);
    if (note >= 0) {
      app.playNote(note);
      if (app.haptics) HapticFeedback.selectionClick();
    } else {
      app.playWrong();
      if (app.haptics) HapticFeedback.mediumImpact();
      _finish();
    }
    notifyListeners();
  }

  void _finish() {
    if (_scored) return;
    _scored = true;
    _ticker?.stop();
    isNewBest = app.submitScore(song.id, engine.score);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
