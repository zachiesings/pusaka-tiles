import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../game/engine/tiles_engine.dart';
import '../game/game_mode.dart';
import '../game/models/song.dart';
import '../game/stage.dart';
import 'app_state.dart';

/// Drives a Pusaka Tiles session: owns the engine, runs the per-frame clock via
/// a [Ticker], routes taps to notes, and records the best score on game over.
class TilesGameController extends ChangeNotifier {
  final AppState app;
  final Song song;
  final GameMode mode;
  final StageSpec? stage; // non-null when playing a campaign stage

  late TilesEngine engine;
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool isNewBest = false;
  bool won = false;     // finished a "Lagu Penuh" song (win, not a loss)
  int starsEarned = 0;
  bool _scored = false;
  int flashLane = -1;   // lane to flash on a correct tap
  double flashT = 0;    // flash intensity, decays each frame

  // ----- Rhythm scoring -----
  int points = 0;       // the shown score (timing + fever bonuses)
  int combo = 0;        // consecutive Perfect/Good taps
  int bestCombo = 0;
  int lastJudge = 0;    // Judge tier id (kBad..kPerfect) — for the floating popup
  int judgeEvent = 0;   // bumped each tap so the UI animates once
  double feverMeter = 0;    // 0..1, fills with good timing
  double feverTimeLeft = 0; // seconds of active Fever (2x)
  int feverEvent = 0;       // bumped the frame a Fever starts (UI burst hook)
  bool get feverActive => feverTimeLeft > 0;
  // Per-tier tallies (for accuracy + grade + all-perfect detection).
  int perfectCount = 0;
  int greatCount = 0;
  int goodCount = 0;
  int badCount = 0;
  int totalTaps = 0;
  double accuracy = 0;      // 0..1 weighted accuracy over all taps
  bool fullCombo = false;   // cleared with no combo break (no Bad / no Miss)
  bool allPerfect = false;  // cleared with every tap Perfect
  String grade = '';        // F/D/C/B/A/S/SS/SSS performance grade on game over

  // ----- Campaign result (valid after _finish when [stage] != null) -----
  int stageStars = 0;       // 0 = goal not met (stage failed)
  bool stageWon = false;
  bool stageFirstClear = false;

  TilesGameController(this.app, this.song, {this.mode = GameMode.klasik, this.stage}) {
    _begin();
  }

  void _begin() {
    final p = kModeParams[mode]!;
    engine = TilesEngine(
      song: song,
      finite: p.finite,
      startSpeed: p.startSpeed,
      speedStep: p.speedStep,
      maxSpeed: p.maxSpeed,
      offsetMs: app.judgeOffsetMs,   // device calibration
      speedScale: app.scrollSpeed,   // user note-speed preference
    );
    won = false;
    _last = Duration.zero;
    isNewBest = false;
    starsEarned = 0;
    points = 0;
    combo = 0;
    bestCombo = 0;
    lastJudge = 0;
    feverMeter = 0;
    feverTimeLeft = 0;
    perfectCount = 0;
    greatCount = 0;
    goodCount = 0;
    badCount = 0;
    totalTaps = 0;
    accuracy = 0;
    fullCombo = false;
    allPerfect = false;
    grade = '';
    stageStars = 0;
    stageWon = false;
    stageFirstClear = false;
    _scored = false;
    _ticker?.dispose();
    _ticker = Ticker(_onTick)..start();
    // Swap home gendhing → this song's humanized backing bed (under gameplay).
    app.stopHomeMusic();
    app.startSongBacking(song.id);
  }

  void restart() {
    _begin();
    notifyListeners();
  }

  bool get isFinite => engine.finite;
  double get songProgress => engine.finite && song.length > 0
      ? (engine.nextTap / song.length).clamp(0.0, 1.0)
      : 0.0;

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
    if (flashT > 0) flashT = (flashT - dt * 4).clamp(0.0, 1.0);
    if (feverTimeLeft > 0) feverTimeLeft = (feverTimeLeft - dt).clamp(0.0, 99.0);
    final wasOver = engine.gameOver;
    final wasDone = engine.completed;
    engine.tick(dt.clamp(0.0, 0.05)); // clamp to avoid huge jumps after stalls
    if (engine.gameOver && !wasOver) {
      app.playWrong();
      _finish();
    } else if (engine.completed && !wasDone) {
      won = true;
      _finish();
    }
    notifyListeners();
  }

  void tap(int col) {
    if (engine.gameOver) return;
    final note = engine.tapColumn(col);
    // Too early: the tile hasn't entered the hittable window. Whiff — no score,
    // no penalty, the tile stays. (Keeps timing meaningful; no pre-tapping.)
    if (note == kTapEarly) return;
    if (note >= 0) {
      flashLane = col;
      flashT = 1.0;
      // Judge timing into a 5-tier scale (offset already applied in the engine).
      final tier = Judge.tier(engine.lastTiming.abs()); // kBad..kPerfect
      lastJudge = tier;
      judgeEvent++;
      totalTaps++;
      switch (tier) {
        case Judge.kPerfect: perfectCount++; break;
        case Judge.kGreat: greatCount++; break;
        case Judge.kGood: goodCount++; break;
        default: badCount++; break;
      }
      points += Judge.points[tier]! * (feverActive ? 2 : 1);
      var feverJustStarted = false;
      if (tier >= Judge.kGood) {
        combo++;
        if (combo > bestCombo) bestCombo = combo;
        feverMeter += tier == Judge.kPerfect
            ? 0.14
            : tier == Judge.kGreat
                ? 0.09
                : 0.05;
        if (feverMeter >= 1 && !feverActive) {
          feverMeter = 0;
          feverTimeLeft = 6;
          feverJustStarted = true;
          feverEvent++; // one-shot signal for a UI burst
        }
      } else {
        combo = 0; // a Bad-timed hit breaks the combo
      }
      app.playNote(note);
      if (app.haptics) {
        if (feverJustStarted) {
          HapticFeedback.heavyImpact(); // Fever! — big thump
        } else if (tier == Judge.kPerfect) {
          HapticFeedback.lightImpact(); // crisp Perfect
        } else {
          HapticFeedback.selectionClick();
        }
      }
      if (engine.completed) {
        won = true;
        _finish();
      }
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
    isNewBest = app.submitScore(song.id, points);
    final len = song.length;
    starsEarned = points >= len * 100
        ? 3
        : points >= len * 50
            ? 2
            : points >= len * 20
                ? 1
                : 0;
    app.submitStars(song.id, starsEarned);
    app.submitBestCombo(bestCombo);
    app.addCoins(points ~/ 50); // earn coins to spend on tile themes
    app.incGamesPlayed();
    // Weighted accuracy over every tap (Perfect 1·Great .7·Good .4·Bad .1).
    accuracy = totalTaps == 0
        ? 0.0
        : (perfectCount * 1.0 +
                greatCount * 0.7 +
                goodCount * 0.4 +
                badCount * 0.1) /
            totalTaps;
    // A clean clear = reached the end of the song with no Miss (a Miss ends the
    // run, so completion already implies none). FC = no combo break (no Bad).
    final cleared = engine.completed;
    fullCombo = cleared && badCount == 0;
    allPerfect = cleared && totalTaps > 0 && perfectCount == totalTaps;
    grade = allPerfect
        ? 'SSS'
        : accuracy >= 0.97
            ? 'SS'
            : accuracy >= 0.93
                ? 'S'
                : accuracy >= 0.85
                    ? 'A'
                    : accuracy >= 0.72
                        ? 'B'
                        : accuracy >= 0.55
                            ? 'C'
                            : accuracy >= 0.40
                                ? 'D'
                                : 'F';

    // Campaign evaluation: did this run satisfy the stage's objective?
    final s = stage;
    if (s != null) {
      stageStars = s.starsFor(
        points: points,
        bestCombo: bestCombo,
        perfects: perfectCount,
        total: totalTaps,
        completed: engine.completed,
        grade: grade,
      );
      stageWon = stageStars > 0;
      if (stageWon) {
        stageFirstClear = app.recordStageResult(s.index, stageStars, s.coins);
      }
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    // Leaving the game: stop the backing bed and bring the home gendhing back.
    app.stopSongBacking();
    app.startHomeMusic();
    super.dispose();
  }
}
