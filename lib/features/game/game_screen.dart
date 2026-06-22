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
                              child: Text('${e.score}',
                                  key: ValueKey<int>(e.score),
                                  style: const TextStyle(
                                      color: Palette.gold,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900)),
                            ),
                            Text('Terbaik $best',
                                style: const TextStyle(color: Palette.goldSoft, fontSize: 12)),
                          ],
                        ),
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
              if (e.gameOver)
                _GameOverOverlay(
                  score: e.score,
                  best: best,
                  stars: gc.starsEarned,
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
  final int score, best, stars;
  final bool isNewBest;
  final VoidCallback onRevive, onRestart, onHome;
  const _GameOverOverlay({
    required this.score,
    required this.best,
    required this.stars,
    required this.isNewBest,
    required this.onRevive,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.72),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Palette.bg1,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Palette.gold.withOpacity(0.4), width: 1.5),
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
            const SizedBox(height: 10),
            Text('$score',
                style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Palette.gold)),
            Text('Terbaik: $best', style: const TextStyle(color: Palette.cream)),
            const SizedBox(height: 24),
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
