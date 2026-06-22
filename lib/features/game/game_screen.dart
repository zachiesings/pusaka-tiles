import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/ads/ads_service.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../../widgets/mascot.dart';
import '../../widgets/tiles_board.dart';

class TilesGameScreen extends StatelessWidget {
  const TilesGameScreen({super.key});

  Future<void> _revive(BuildContext context, TilesGameController gc, AppState app) async {
    final ok = await app.ads.showRewarded(RewardKind.revive);
    if (!context.mounted) return;
    if (ok) {
      gc.reviveAfterAd();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iklan belum siap, coba lagi sebentar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<TilesGameController>();
    final app = context.watch<AppState>();
    final e = gc.engine;
    final best = app.bestForSong(gc.song.id);

    return Scaffold(
      body: BatikBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // HUD
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new, color: Palette.cream),
                        ),
                        // Little dancer that hops on every correct tap
                        MascotView(
                          size: 56,
                          mood: gc.flashT > 0.3 ? MascotMood.happy : MascotMood.idle,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gc.song.title,
                                  style: const TextStyle(
                                      color: Palette.cream, fontWeight: FontWeight.w800)),
                              Text(gc.song.daerah,
                                  style: const TextStyle(color: Palette.goldSoft, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Text('${gc.points}',
                                  key: ValueKey<int>(gc.points),
                                  style: TextStyle(
                                      color: gc.feverActive ? Palette.pink : Palette.gold,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900)),
                            ),
                            if (gc.combo > 1)
                              Text('Combo ${gc.combo}',
                                  style: const TextStyle(
                                      color: Palette.cream, fontSize: 12, fontWeight: FontWeight.w700))
                            else
                              Text('Terbaik $best',
                                  style: const TextStyle(color: Palette.goldSoft, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Fever meter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: gc.feverActive ? (gc.feverTimeLeft / 6).clamp(0.0, 1.0) : gc.feverMeter,
                        minHeight: 6,
                        backgroundColor: Palette.panel,
                        color: gc.feverActive ? Palette.pink : Palette.teal,
                      ),
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
              // Timing judgment popup (fades with flashT)
              if (gc.flashT > 0.05 && gc.lastJudge > 0 && !e.gameOver)
                IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: gc.flashT.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.7 + gc.flashT * 0.5,
                        child: Text(
                          gc.lastJudge == 3
                              ? 'PERFECT!'
                              : gc.lastJudge == 2
                                  ? 'GOOD'
                                  : 'Telat',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: gc.lastJudge == 3
                                ? Palette.gold
                                : gc.lastJudge == 2
                                    ? Palette.teal
                                    : Palette.cream.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Fever: pulsing pink edge-glow vignette around the whole screen
              if (gc.feverActive && !e.gameOver)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.transparent,
                          Palette.pink.withOpacity(
                              0.16 + 0.12 * (0.5 + 0.5 * math.sin(gc.feverTimeLeft * 6))),
                        ],
                        stops: const [0.62, 1.0],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              if (gc.feverActive && !e.gameOver)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 70),
                      child: Transform.scale(
                        scale: 1 + 0.08 * (0.5 + 0.5 * math.sin(gc.feverTimeLeft * 8)),
                        child: const Text('🔥 FEVER ×2',
                            style: TextStyle(
                                color: Palette.pink, fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              if (e.gameOver)
                _GameOverOverlay(
                  score: gc.points,
                  best: best,
                  stars: gc.starsEarned,
                  grade: gc.grade,
                  perfects: gc.perfectCount,
                  total: gc.totalTaps,
                  isNewBest: gc.isNewBest,
                  onRevive: () => _revive(context, gc, app),
                  onRestart: () async {
                    await app.maybeShowInterstitial();
                    gc.restart();
                  },
                  onHome: () => Navigator.of(context).maybePop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score, best, stars, perfects, total;
  final String grade;
  final bool isNewBest;
  final VoidCallback onRevive, onRestart, onHome;
  const _GameOverOverlay({
    required this.score,
    required this.best,
    required this.stars,
    required this.grade,
    required this.perfects,
    required this.total,
    required this.isNewBest,
    required this.onRevive,
    required this.onRestart,
    required this.onHome,
  });

  Color get _gradeColor => grade == 'S'
      ? Palette.gold
      : grade == 'A'
          ? Palette.teal
          : grade == 'B'
              ? Palette.cyan
              : Palette.pink;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.72),
      alignment: Alignment.center,
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
            Text(isNewBest ? 'Rekor Baru! 🎉' : 'Yah, Meleset!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Palette.cream)),
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
            Text('$score',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Palette.gold)),
            Text('Terbaik: $best', style: const TextStyle(color: Palette.cream)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRevive,
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('Lanjut — Tonton Iklan'),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onHome,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.cream,
                    side: const BorderSide(color: Palette.goldSoft),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Pilih Lagu'),
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
    );
  }
}
