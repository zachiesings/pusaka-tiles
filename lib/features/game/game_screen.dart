import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/stage.dart';
import '../../services/ads/ads_service.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../../widgets/mascot.dart';
import '../../widgets/tiles_mascot.dart';
import '../../widgets/tiles_board.dart';

class TilesGameScreen extends StatelessWidget {
  const TilesGameScreen({super.key});

  Future<void> _revive(BuildContext context, TilesGameController gc, AppState app) async {
    // The button is only visible when an ad is loaded, so this presents a REAL
    // ad and grants the revive ONLY when the reward is earned. No ad → no grant.
    final ok = await app.ads.showRewarded(RewardKind.revive);
    if (!context.mounted) return;
    if (ok) gc.reviveAfterAd();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<TilesGameController>();
    final app = context.watch<AppState>();
    app.ads.preloadRewarded(); // warm up the revive ad (idempotent) so the button is instant
    final e = gc.engine;
    final best = app.bestForSong(gc.song.id);

    return Scaffold(
      body: BatikBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // ---- Top bar: back · song · live accuracy ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 14, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new, color: Palette.cream, size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gc.song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Typo.title.copyWith(color: Palette.cream)),
                              Text(gc.song.daerah,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Typo.small.copyWith(color: Palette.goldSoft)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _AccuracyChip(perfect: gc.perfectCount, total: gc.totalTaps),
                      ],
                    ),
                  ),
                  // ---- Score (big, kinetic count-up) + combo pill ----
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: gc.points.toDouble()),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                          builder: (_, v, __) => Text(
                            v.round().toString(),
                            style: Typo.score.copyWith(
                              color: gc.feverActive ? Palette.pink : Palette.gold,
                              shadows: [
                                Shadow(
                                    color: (gc.feverActive ? Palette.pink : Palette.gold)
                                        .withOpacity(0.45),
                                    blurRadius: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _ComboPill(combo: gc.combo, best: best, fever: gc.feverActive),
                      ],
                    ),
                  ),
                  // ---- Fever meter (slim, labelled) ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: gc.feverActive ? Palette.pink : Palette.teal),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: gc.feverActive
                                  ? (gc.feverTimeLeft / 6).clamp(0.0, 1.0)
                                  : gc.feverMeter,
                              minHeight: 7,
                              backgroundColor: Palette.panel,
                              color: gc.feverActive ? Palette.pink : Palette.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Campaign objective bar (only when playing a stage)
                  if (gc.stage != null) _ObjectiveBar(gc: gc),
                  // "Lagu Penuh" progress to the end of the song
                  if (gc.isFinite)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded, color: Palette.gold, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: gc.songProgress,
                                minHeight: 5,
                                backgroundColor: Palette.panel,
                                color: Palette.gold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('${(gc.songProgress * 100).round()}%',
                              style: const TextStyle(
                                  color: Palette.goldSoft, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  // Board + tap lanes
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                                painter: TilesBoardPainter(
                                    engine: e, flashLane: gc.flashLane, flashT: gc.flashT)),
                            // Rich pooled particle bursts / ripples / flash per tap
                            // (shares the board's coordinate space; taps pass through).
                            Positioned.fill(child: _GameFxLayer(gc: gc)),
                            Row(
                              children: List.generate(
                                K.columns,
                                (i) => Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (_) => gc.tap(i),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ),
                            if (!e.started && !e.gameOver)
                              const IgnorePointer(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 60),
                                    child: Text('Ketuk ubin terbawah\nuntuk mulai',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Palette.cream,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // ---- Per-tap judgment (PERFECT / GREAT / GOOD), near the hit-line ----
              if (gc.flashT > 0.05 && gc.lastJudge > 0 && !e.gameOver)
                IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, 0.42),
                    child: Opacity(
                      opacity: gc.flashT.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.85 + gc.flashT * 0.35,
                        child: Builder(builder: (_) {
                          final c = gc.lastJudge == 3
                              ? Palette.gold
                              : gc.lastJudge == 2
                                  ? Palette.teal
                                  : Palette.cyan;
                          return Text(
                            gc.lastJudge == 3 ? 'PERFECT' : gc.lastJudge == 2 ? 'GREAT' : 'GOOD',
                            style: Typo.judge.copyWith(
                              color: c,
                              shadows: [Shadow(color: c.withOpacity(0.55), blurRadius: 18)],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              // ---- FEVER cinematic: full-screen state + particle storm + entrance ----
              if (gc.feverActive && !e.gameOver) _FeverCinematic(gc: gc),
              if (e.gameOver || e.completed)
                _GameOverOverlay(
                  score: gc.points,
                  best: best,
                  stars: gc.stage != null ? gc.stageStars : gc.starsEarned,
                  grade: gc.grade,
                  perfects: gc.perfectCount,
                  total: gc.totalTaps,
                  isNewBest: gc.isNewBest,
                  won: gc.won,
                  isStage: gc.stage != null,
                  stageWon: gc.stageWon,
                  stageGoal: gc.stage == null
                      ? ''
                      : gc.stage!.goal.label(gc.stage!.target),
                  onRevive: () => _revive(context, gc, app),
                  onRestart: () async {
                    await app.maybeShowInterstitial();
                    gc.restart();
                  },
                  onHome: () => Navigator.of(context).maybePop(),
                  adReady: app.ads.rewardedReady,
                  adStatus: app.ads.adStatus,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live campaign-objective bar shown during a stage run — the goal label plus a
/// progress track that fills toward the target and turns gold once reached.
class _ObjectiveBar extends StatelessWidget {
  final TilesGameController gc;
  const _ObjectiveBar({required this.gc});

  @override
  Widget build(BuildContext context) {
    final s = gc.stage!;
    int cur, tgt;
    String text;
    switch (s.goal) {
      case StageGoal.score:
        cur = gc.points;
        tgt = s.target;
        text = 'Skor $cur / $tgt';
        break;
      case StageGoal.combo:
        cur = gc.bestCombo;
        tgt = s.target;
        text = 'Combo ×$cur / $tgt';
        break;
      case StageGoal.perfect:
        cur = gc.perfectCount;
        tgt = s.target;
        text = 'Perfect $cur / $tgt';
        break;
      case StageGoal.fullsong:
        cur = (gc.songProgress * 100).round();
        tgt = 100;
        text = 'Tamatkan lagu • $cur%';
        break;
    }
    final prog = tgt == 0 ? 0.0 : (cur / tgt).clamp(0.0, 1.0);
    final done = tgt > 0 && cur >= tgt;
    final c = done ? Palette.gold : s.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : s.goal.icon, color: c, size: 15),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: prog,
                minHeight: 5,
                backgroundColor: Palette.panel,
                color: c,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score, best, stars, perfects, total;
  final String grade;
  final bool isNewBest;
  final bool won;
  final bool isStage, stageWon;
  final String stageGoal;
  final VoidCallback onRevive, onRestart, onHome;
  final ValueListenable<bool> adReady; // gates the watch-ad button (2.1a)
  final ValueListenable<String> adStatus; // TEMP diagnostic (K.adDebug)
  const _GameOverOverlay({
    required this.score,
    required this.best,
    required this.stars,
    required this.grade,
    required this.perfects,
    required this.total,
    required this.isNewBest,
    required this.won,
    this.isStage = false,
    this.stageWon = false,
    this.stageGoal = '',
    required this.onRevive,
    required this.onRestart,
    required this.onHome,
    required this.adReady,
    required this.adStatus,
  });

  String get _headline {
    if (isStage) return stageWon ? 'Pusaka Diraih! 🎉' : 'Babak Belum Tuntas';
    if (won) return 'Lagu Selesai! 🎶';
    if (isNewBest) return 'Rekor Baru! 🎉';
    return 'Yah, Meleset!';
  }

  Color get _gradeColor => grade == 'S'
      ? Palette.gold
      : grade == 'A'
          ? Palette.teal
          : grade == 'B'
              ? Palette.cyan
              : Palette.pink;

  @override
  Widget build(BuildContext context) {
    final celebrate = stars >= 2 || won || isNewBest;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOut,
      builder: (context, t, _) {
        return Container(
          color: Colors.black.withOpacity(0.72 * t.clamp(0.0, 1.0)),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (celebrate)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ResultBurstPainter(t, stars >= 3 ? Palette.gold : Palette.violet),
                    ),
                  ),
                ),
              Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.86 + 0.14 * t,
                  child: Container(
                    margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Palette.panel, Palette.bg1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Palette.violet.withOpacity(0.5), width: 1.5),
          boxShadow: Palette.glow(stars >= 2 ? Palette.gold : Palette.violet, blur: 40, a: 0.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_headline,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Palette.cream)),
            if (isStage && stageGoal.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Target: $stageGoal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: stageWon ? Palette.gold : Palette.cream.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 40,
                  color: i < stars ? Palette.gold : Palette.gridLine,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Big performance grade
            if (grade.isNotEmpty)
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gradeColor, width: 3),
                  boxShadow: Palette.glow(_gradeColor, blur: 26, a: 0.5),
                ),
                alignment: Alignment.center,
                child: Text(grade,
                    style: TextStyle(
                        fontSize: 52, fontWeight: FontWeight.w900, color: _gradeColor, height: 1)),
              ),
            if (total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('$perfects/$total PERFECT',
                    style: TextStyle(
                        color: Palette.cream.withOpacity(0.6),
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: score.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (_, v, __) => Text(v.round().toString(),
                  style: Typo.score.copyWith(color: Palette.gold, fontSize: 48)),
            ),
            Text('Terbaik: $best', style: const TextStyle(color: Palette.cream)),
            const SizedBox(height: 22),
            // Watch-ad button shows ONLY when a real rewarded ad is loaded (2.1a):
            // no ad → no button, the player just uses Ulangi / Pilih Lagu below.
            if (!won)
              ValueListenableBuilder<bool>(
                valueListenable: adReady,
                builder: (context, ready, _) {
                  if (!ready) {
                    // TEMP diagnostic: when no ad is ready, show why (K.adDebug).
                    if (K.adDebug) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ValueListenableBuilder<String>(
                          valueListenable: adStatus,
                          builder: (_, s, __) => Text(
                            'iklan: $s',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Palette.goldSoft, fontSize: 11),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onRevive,
                          icon: const Icon(Icons.play_circle_fill),
                          label: const Text('Lanjut — Tonton Iklan'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onHome,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.cream,
                    side: const BorderSide(color: Palette.goldSoft),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isStage ? 'Peta' : 'Pilih Lagu'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRestart,
                  child: const Text('Ulangi'),
                ),
              ),
            ]),
          ],
        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── in-game HUD pieces ───────────────────────────

/// Live perfect-accuracy chip (top-right of the HUD).
class _AccuracyChip extends StatelessWidget {
  final int perfect, total;
  const _AccuracyChip({required this.perfect, required this.total});

  @override
  Widget build(BuildContext context) {
    final acc = total == 0 ? 0 : (100 * perfect / total).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Palette.panel.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.gold.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$acc%', style: Typo.chip.copyWith(color: Palette.gold, fontSize: 16)),
          Text('AKURASI',
              style: Typo.small.copyWith(color: Palette.cream.withOpacity(0.5), fontSize: 8.5)),
        ],
      ),
    );
  }
}

/// Combo pill under the score — scales/pulses, pops on 10/25/50/100 milestones.
class _ComboPill extends StatelessWidget {
  final int combo, best;
  final bool fever;
  const _ComboPill({required this.combo, required this.best, required this.fever});

  @override
  Widget build(BuildContext context) {
    if (combo < 2) {
      return Text('Terbaik  $best', style: Typo.small.copyWith(color: Palette.goldSoft));
    }
    final milestone = combo == 10 || combo == 25 || combo == 50 || combo == 100;
    final c = fever ? Palette.pink : Palette.cyan;
    final scale = 1.0 + (combo.clamp(0, 50)) * 0.004 + (milestone ? 0.2 : 0.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: scale),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (_, s, __) => Transform.scale(
        scale: s,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: c.withOpacity(0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.5)),
          ),
          child: Text('$combo  COMBO', style: Typo.combo.copyWith(color: c, fontSize: 15)),
        ),
      ),
    );
  }
}

// ─────────────────────────── FEVER cinematic ───────────────────────────

/// Full-screen Fever payoff: color-grade overlay + particle storm + a big
/// animated "FEVER!" entrance + a beat-synced pulse + a cheering mascot.
class _FeverCinematic extends StatelessWidget {
  final TilesGameController gc;
  const _FeverCinematic({required this.gc});

  @override
  Widget build(BuildContext context) {
    final t = gc.feverTimeLeft;                       // counts 6 → 0
    final entrance = ((6 - t) / 0.5).clamp(0.0, 1.0); // 0→1 over the first 0.5s
    final pulse = 0.5 + 0.5 * math.sin(t * 9);        // beat-ish pulse
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Palette.violet.withOpacity(0.10 + 0.06 * pulse),
                    Palette.pink.withOpacity(0.20 + 0.12 * pulse),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _FeverFxPainter(t))),
          Align(
            alignment: const Alignment(0, -0.42),
            child: Opacity(
              opacity: (entrance * 1.4).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: (1.9 - entrance * 0.9) * (1 + 0.04 * pulse),
                child: Text('FEVER!',
                    style: Typo.fever.copyWith(
                      color: Palette.pink,
                      shadows: [
                        Shadow(color: Palette.pink.withOpacity(0.6), blurRadius: 24),
                        const Shadow(color: Palette.cream, blurRadius: 2),
                      ],
                    )),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.78),
            child: Opacity(
              opacity: 0.92,
              child: TilesMascot(size: 96, mood: MascotMood.cheer),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeverFxPainter extends CustomPainter {
  final double t;
  _FeverFxPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (var i = 0; i < 72; i++) {
      final seed = i * 0.6180339887;
      final x = w * ((seed * 7.13) % 1.0);
      final speed = 60 + (i % 6) * 38.0;
      final y = h - (((6 - t) * speed + i * 41.0) % (h + 60));
      final r = 1.6 + (i % 3) * 1.3;
      final col = (i % 3 == 0)
          ? Palette.pink
          : (i % 3 == 1)
              ? Palette.gold
              : Palette.violet;
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * 3 + i));
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = col.withOpacity(0.5 * tw)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FeverFxPainter old) => old.t != t;
}

// ─────────────────────────── per-tap particle FX ───────────────────────────

class _P {
  double x = 0, y = 0, vx = 0, vy = 0, life = 0, max = 1, size = 2;
  Color color = Palette.gold;
  bool alive = false;
}

class _R {
  double x = 0, y = 0, t = 0, dur = 0.45, maxR = 60, width = 3;
  Color color = Palette.gold;
  bool alive = false;
}

/// Code-driven FX over the board: pooled particle bursts + ripple shockwaves +
/// a light flash on each tap (distinct per judgment) and combo-milestone bursts.
/// Shares the board's coordinate space; own ticker repaints ONLY while active.
class _GameFxLayer extends StatefulWidget {
  final TilesGameController gc;
  const _GameFxLayer({required this.gc});
  @override
  State<_GameFxLayer> createState() => _GameFxLayerState();
}

class _GameFxLayerState extends State<_GameFxLayer> with SingleTickerProviderStateMixin {
  late final _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  int _seenJudge = 0;
  int _milestone = 0;
  double _flash = 0;
  Color _flashColor = Palette.gold;
  final List<_P> _ps = List.generate(180, (_) => _P());
  final List<_R> _rs = List.generate(16, (_) => _R());
  final math.Random _rng = math.Random(11);

  @override
  void initState() {
    super.initState();
    widget.gc.addListener(_onGc);
    // Create the ticker now (in a safe context), but DON'T start it. Touching the
    // late field here forces createTicker() during initState rather than during
    // dispose(). It runs ON DEMAND only — _kick starts it after a spawn, _tick
    // stops it when idle — so a frozen/disposed screen leaves no running animation.
    _ticker.stop();
  }

  void _kick() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(_GameFxLayer old) {
    super.didUpdateWidget(old);
    if (old.gc != widget.gc) {
      old.gc.removeListener(_onGc);
      widget.gc.addListener(_onGc);
    }
  }

  @override
  void dispose() {
    widget.gc.removeListener(_onGc);
    _ticker.dispose();
    super.dispose();
  }

  void _onGc() {
    final gc = widget.gc;
    if (gc.judgeEvent != _seenJudge) {
      _seenJudge = gc.judgeEvent;
      if (gc.lastJudge > 0 && gc.flashLane >= 0) _hit(gc.flashLane, gc.lastJudge);
    }
    final c = gc.combo;
    if (c < 10) {
      _milestone = 0;
    } else if ((c == 10 || c == 25 || c == 50 || c == 100) && c != _milestone) {
      _milestone = c;
      _milestoneBurst(gc.feverActive);
    }
  }

  _P? _freeP() {
    for (final p in _ps) {
      if (!p.alive) return p;
    }
    return null;
  }

  _R? _freeR() {
    for (final r in _rs) {
      if (!r.alive) return r;
    }
    return null;
  }

  void _hit(int lane, int judge) {
    if (_size == Size.zero) return;
    final laneW = _size.width / K.columns;
    final x = (lane + 0.5) * laneW;
    final y = _size.height * 0.80; // the hit line
    final color = judge == 3 ? Palette.gold : judge == 2 ? Palette.teal : Palette.cyan;
    final count = judge == 3 ? 16 : judge == 2 ? 10 : 6;
    final spread = judge == 3 ? 1.4 : judge == 2 ? 1.0 : 0.7;
    for (var i = 0; i < count; i++) {
      final p = _freeP();
      if (p == null) break;
      final ang = -math.pi / 2 + (_rng.nextDouble() - 0.5) * math.pi * spread;
      final spd = (70 + _rng.nextDouble() * 190) * (judge == 3 ? 1.3 : 1.0);
      p
        ..alive = true
        ..x = x
        ..y = y
        ..vx = math.cos(ang) * spd
        ..vy = math.sin(ang) * spd
        ..life = 0.5 + _rng.nextDouble() * 0.4
        ..max = p.life
        ..size = laneW * (0.03 + _rng.nextDouble() * 0.05)
        ..color = color;
    }
    final r = _freeR();
    if (r != null) {
      r
        ..alive = true
        ..x = x
        ..y = y
        ..t = 0
        ..dur = 0.45
        ..maxR = laneW * (judge == 3 ? 1.7 : 1.1)
        ..width = judge == 3 ? 4 : 2.5
        ..color = color;
    }
    final f = judge == 3 ? 0.5 : judge == 2 ? 0.28 : 0.14;
    if (f > _flash) {
      _flash = f;
      _flashColor = color;
    }
    _kick();
  }

  void _milestoneBurst(bool fever) {
    if (_size == Size.zero) return;
    final x = _size.width / 2, y = _size.height * 0.55;
    final color = fever ? Palette.pink : Palette.gold;
    for (var i = 0; i < 28; i++) {
      final p = _freeP();
      if (p == null) break;
      final ang = _rng.nextDouble() * math.pi * 2;
      final spd = 90 + _rng.nextDouble() * 250;
      p
        ..alive = true
        ..x = x
        ..y = y
        ..vx = math.cos(ang) * spd
        ..vy = math.sin(ang) * spd
        ..life = 0.7 + _rng.nextDouble() * 0.5
        ..max = p.life
        ..size = _size.width * 0.012
        ..color = color;
    }
    final r = _freeR();
    if (r != null) {
      r
        ..alive = true
        ..x = x
        ..y = y
        ..t = 0
        ..dur = 0.6
        ..maxR = _size.width * 0.7
        ..width = 4
        ..color = color;
    }
    if (0.45 > _flash) {
      _flash = 0.45;
      _flashColor = color;
    }
    _kick();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 0.016 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final g = _size.height * 0.9; // gravity pulls sparks down
    var active = false;
    for (final p in _ps) {
      if (!p.alive) continue;
      active = true;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += g * dt;
      p.life -= dt;
      if (p.life <= 0) p.alive = false;
    }
    for (final r in _rs) {
      if (!r.alive) continue;
      active = true;
      r.t += dt;
      if (r.t >= r.dur) r.alive = false;
    }
    if (_flash > 0) {
      _flash = (_flash - dt * 2.5).clamp(0.0, 1.0);
      if (_flash > 0.001) active = true;
    }
    if (!active) {
      _ticker.stop(); // idle → stop the ticker entirely (no leaked animation)
      _last = Duration.zero;
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, c) {
          _size = Size(c.maxWidth, c.maxHeight);
          return RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _FxPainter(_ps, _rs, _flash, _flashColor),
            ),
          );
        },
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  final List<_P> ps;
  final List<_R> rs;
  final double flash;
  final Color flashColor;
  _FxPainter(this.ps, this.rs, this.flash, this.flashColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (flash > 0.001) {
      canvas.drawRect(Offset.zero & size, Paint()..color = flashColor.withOpacity(flash * 0.5));
    }
    for (final r in rs) {
      if (!r.alive) continue;
      final f = (r.t / r.dur).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(r.x, r.y),
        r.maxR * f,
        Paint()
          ..color = r.color.withOpacity((1 - f) * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.width * (1 - f) + 0.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
    for (final p in ps) {
      if (!p.alive) continue;
      final a = (p.life / p.max).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * (0.5 + a * 0.5),
        Paint()
          ..color = p.color.withOpacity(a * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FxPainter old) => true;
}

/// Radial confetti burst behind the results card (driven by the reveal tween).
class _ResultBurstPainter extends CustomPainter {
  final double t;
  final Color color;
  _ResultBurstPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height * 0.4;
    final prog = t.clamp(0.0, 1.0);
    for (var i = 0; i < 28; i++) {
      final ang = i * (2 * math.pi / 28);
      final dist = prog * size.shortestSide * 0.55 * (0.6 + (i % 3) * 0.18);
      final x = cx + math.cos(ang) * dist;
      final y = cy + math.sin(ang) * dist + prog * prog * 70; // light gravity
      final col = (i % 3 == 0) ? color : (i % 3 == 1) ? Palette.pink : Palette.cyan;
      canvas.drawCircle(
        Offset(x, y),
        3.6 * (1 - prog * 0.6),
        Paint()
          ..color = col.withOpacity((1 - prog).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ResultBurstPainter old) => old.t != t;
}
