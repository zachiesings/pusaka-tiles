import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../game/chart.dart';
import '../game/engine/tiles_engine.dart';
import '../game/ensemble.dart';
import '../game/game_mode.dart';
import '../game/imbal.dart';
import '../game/models/song.dart';
import '../game/stage.dart';
import 'app_state.dart';

/// Drives a Pusaka Tiles session: owns the engine, runs the per-frame clock via
/// a [Ticker], routes taps to notes, and records the best score on game over.
class TilesGameController extends ChangeNotifier {
  final AppState app;
  final Song song;
  final GameMode mode;
  final Difficulty difficulty; // note vocabulary + tempo tier
  final PlayMode play;         // practice / endless / challenge / daily
  final StageSpec? stage;      // non-null when playing a campaign stage
  final int? dailySeed;        // fixes the chart for Daily mode

  late TilesEngine engine;
  late Chart chart;
  /// The awakening-ensemble director (the core hook). Drives layered companion
  /// voices + colotomic punctuation, and exposes [EnsembleDirector.activeLayers]
  /// / [EnsembleDirector.fullness] for the colour arc, icons, and result card.
  final EnsembleDirector ensemble = EnsembleDirector();
  bool _ensembleOn = true; // mirrors the app setting at run start
  bool get ensembleOn => _ensembleOn;

  /// Imbal — the call-and-response signature moment. Armed once per gongan; the
  /// player answers the ghosted figure to lock in a layer + boost FEVER.
  final ImbalManager imbal = ImbalManager();
  bool _imbalOn = true;
  int _lastGongCycle = -1; // tracks gong-cycle changes to arm calls
  List<int> _imbalCall = const []; // the armed figure's pitches (for the flourish)
  final List<int> _preEcho = <int>[]; // queued call pitches to arpeggiate (the "call")
  double _preEchoT = 0; // seconds until the next pre-echo note
  int imbalEvent = 0; // bumped on a SUCCESSFUL imbal (UI flourish hook)
  // Peak ensemble reached this run — surfaced on the result card ("fullness").
  int peakLayers = 0; // 0..3 ensemble layers beyond the lead
  double peakFullness = 0; // 0..1 fullest the ensemble got
  bool get imbalActive => _imbalOn && imbal.active;
  double get imbalProgress => imbal.progress;
  int get imbalTotal => imbal.total;
  int get imbalAnswered => imbal.answered;
  bool get imbalTeaching => imbal.teaching;
  PlayMode _effPlay = PlayMode.endless; // resolved play mode (campaign-derived)
  RunReward reward = const RunReward(); // progression rewards (valid after _finish)
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

  TilesGameController(
    this.app,
    this.song, {
    this.mode = GameMode.klasik,
    this.difficulty = Difficulty.normal,
    this.play = PlayMode.endless,
    this.stage,
    this.dailySeed,
  }) {
    _begin();
  }

  void _begin() {
    // Campaign keeps its shipped feel: taps-only chart (legacy) at the stage's
    // own GameMode speed; "Lagu Penuh" stages are a finite challenge, the rest
    // are endless survival. New flows use the chosen difficulty + play mode.
    final legacy = stage != null;
    final effPlay = legacy
        ? (mode == GameMode.penuh ? PlayMode.challenge : PlayMode.endless)
        : play;
    _effPlay = effPlay;
    final pm = kPlayModes[effPlay]!;
    final diffSpec = kDifficulty[difficulty]!;
    final modeP = kModeParams[mode]!;
    final spd = app.scrollSpeed;
    final diffMul = legacy ? 1.0 : diffSpec.speedMul;
    final base = modeP.startSpeed * song.speedScale * spd * diffMul * pm.speedMul;
    final mx = modeP.maxSpeed * song.speedScale * spd * diffMul;
    final step = (pm.ramp ? modeP.speedStep : 0.0) * spd * diffMul;
    chart = ChartGenerator.generate(
      song,
      difficulty,
      seed: dailySeed ?? 0,
      columns: K.columns,
      legacy: legacy,
    );
    engine = TilesEngine(
      chart: chart,
      columns: K.columns,
      finite: pm.finite,
      loop: pm.loop,
      noFail: pm.noFail,
      offsetMs: app.judgeOffsetMs, // device calibration
      startSpeed: base,
      speedStep: step,
      maxSpeed: mx,
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
    reward = const RunReward();
    _scored = false;
    // Wake the ensemble fresh for this run; honour the player's setting and the
    // song's own gong-cycle length (data-driven, defaults to 16 beats).
    _ensembleOn = app.ensemble;
    ensemble.configure(
        const EnsembleConfig().copyWith(gonganBeats: song.gonganBeats));
    ensemble.reset();
    // Imbal cadence/length by mode (spec §6): Santai gentler & rarer, Cepat
    // frequent with longer figures.
    _imbalOn = app.imbal && app.ensemble;
    imbal.configure(_imbalConfigFor(mode));
    imbal.reset();
    _lastGongCycle = -1;
    _imbalCall = const [];
    imbalEvent = 0;
    peakLayers = 0;
    peakFullness = 0;
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

  /// Imbal cadence/length per mode (spec §6).
  ImbalConfig _imbalConfigFor(GameMode m) {
    switch (m) {
      case GameMode.santai:
        return const ImbalConfig(everyGongans: 2, callLength: 4);
      case GameMode.cepat:
        return const ImbalConfig(everyGongans: 1, callLength: 8);
      case GameMode.klasik:
      case GameMode.penuh:
        return const ImbalConfig(everyGongans: 1, callLength: 6);
    }
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
    // Advance the awakening ensemble in the same beat space the engine scrolls,
    // and sound any colotomic punctuation that fell due this frame.
    if (_ensembleOn && engine.started && !engine.gameOver && !engine.completed) {
      final hits = ensemble.tick(engine.scroll, dt.clamp(0.0, 0.05));
      if (ensemble.activeLayers > peakLayers) peakLayers = ensemble.activeLayers;
      if (ensemble.fullness > peakFullness) peakFullness = ensemble.fullness;
      for (final h in hits) {
        if (h.note >= 0) {
          app.playEnsembleNote(ensemble.cfg.ensembleVoice, h.note, h.gain);
        } else {
          app.playColotomic(h.voice, h.gain, fallback: 'audio/tap.wav');
        }
      }
    }
    // Imbal: at each new gong cycle, maybe arm a call over the upcoming tiles;
    // arpeggiate the "call" so the player hears the figure before answering it.
    if (_imbalOn && engine.started && !engine.gameOver && !engine.completed) {
      final cycle = (engine.scroll / song.gonganBeats).floor();
      if (cycle != _lastGongCycle) {
        _lastGongCycle = cycle;
        final up = <int>[];
        for (var i = engine.nextTap;
            i < engine.rows.length && up.length < imbal.total;
            i++) {
          up.add(engine.rows[i].noteIndex);
        }
        final call = imbal.maybeArm(cycle, up);
        if (call != null) {
          _imbalCall = call;
          _preEcho
            ..clear()
            ..addAll(call);
          _preEchoT = 0;
        }
      }
      if (_preEcho.isNotEmpty) {
        _preEchoT -= dt;
        if (_preEchoT <= 0) {
          app.playEnsembleNote(ensemble.cfg.ensembleVoice, _preEcho.removeAt(0), 0.5);
          _preEchoT = 0.13; // ~130ms between call notes — reads as a figure
        }
      }
    }
    if (engine.gameOver && !wasOver) {
      app.playChoke(); // a missed tile chokes musically, never a buzzer
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
      // The just-cleared tile (nextTap was advanced) — richer note kinds score
      // more: holds + chords reward the extra skill/feel.
      final clearedKind = engine.rows[engine.nextTap - 1].kind;
      final kindMul = clearedKind == NoteKind.hold
          ? 1.5
          : clearedKind == NoteKind.chord
              ? 1.4
              : (clearedKind == NoteKind.flick || clearedKind == NoteKind.slide)
                  ? 1.2
                  : 1.0;
      points += (Judge.points[tier]! * kindMul).round() * (feverActive ? 2 : 1);
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
        // Grow the ensemble: a clean tap may cross a wake threshold (applied on
        // the next gong) and rings the bonang shimmer over the lead.
        if (_ensembleOn) {
          ensemble.onCombo(combo);
          final comp = ensemble.onTap(note);
          if (comp != null) {
            app.playEnsembleNote(comp.voice, comp.note, comp.gain);
          }
        }
      } else {
        combo = 0; // a Bad-timed hit breaks the combo
        // A break puts the most-recently-woken instrument back to sleep.
        if (_ensembleOn) ensemble.onBreak();
      }
      // Imbal: answer the active call. Nail the whole figure → lock a layer,
      // boost FEVER, and play an ornamented flourish (a missed figure just
      // continues, no punishment).
      if (_imbalOn && imbal.active) {
        final res = imbal.onAnswer(clean: tier >= Judge.kGood);
        if (res != null && res.success) {
          ensemble.promote();
          feverMeter += 0.4;
          if (feverMeter >= 1 && !feverActive) {
            feverMeter = 0;
            feverTimeLeft = 6;
            feverEvent++;
          }
          imbalEvent++;
          for (final p in _imbalCall.reversed) {
            app.playEnsembleNote(
                ensemble.cfg.ensembleVoice, p + 7 <= 12 ? p + 7 : p, 0.6);
          }
          if (app.haptics) {
            HapticFeedback.mediumImpact();
            HapticFeedback.heavyImpact(); // the satisfying imbal double-pulse
          }
        }
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
      app.playChoke(); // wrong lane ends the run — choke, don't buzz
      if (app.haptics) HapticFeedback.mediumImpact();
      _finish();
    }
    notifyListeners();
  }

  void _finish() {
    if (_scored) return;
    _scored = true;
    imbal.cancel();
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

    // Progression: XP, song mastery, daily missions, Daily streak.
    reward = app.recordRun(
      songId: song.id,
      difficulty: difficulty,
      play: _effPlay,
      points: points,
      accuracy: accuracy,
      grade: grade,
      bestCombo: bestCombo,
      perfects: perfectCount,
      fullCombo: fullCombo,
      allPerfect: allPerfect,
      cleared: engine.completed,
    );

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
