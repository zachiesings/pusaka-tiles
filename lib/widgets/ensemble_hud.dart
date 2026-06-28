import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../game/ensemble.dart';
import '../state/game_controller.dart';

/// The visible half of "The Ensemble Awakens": a row of four instrument chips
/// that light up as their layer wakes, with the next-to-wake chip pulsing as the
/// combo approaches its threshold (wordless teaching, §4.8). Reads the live
/// [EnsembleDirector] on the controller; rebuilds each tick with the controller.
class EnsembleBar extends StatelessWidget {
  final TilesGameController gc;
  final bool reduceMotion;
  const EnsembleBar({super.key, required this.gc, this.reduceMotion = false});

  static const _meta = <_LayerMeta>[
    _LayerMeta(EnsembleLayer.lead, 'Saron', Icons.music_note_rounded),
    _LayerMeta(EnsembleLayer.bonang, 'Bonang', Icons.bubble_chart_rounded),
    _LayerMeta(EnsembleLayer.colotomic, 'Kenong', Icons.adjust_rounded),
    _LayerMeta(EnsembleLayer.kendang, 'Kendang', Icons.album_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final d = gc.ensemble;
    final next = d.nextSleeping;
    // Proximity of the combo to the next layer's threshold (0..1) — grows the
    // telegraph pulse so the player feels the next instrument about to wake.
    final proximity = next == null
        ? 0.0
        : (gc.combo / d.comboFor(next)).clamp(0.0, 1.0);
    final breath = reduceMotion ? 0.0 : d.gongBreath;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final m in _meta)
            _Chip(
              meta: m,
              gain: d.gainOf(m.layer),
              isNext: m.layer == next,
              proximity: proximity,
              breath: breath,
            ),
        ],
      ),
    );
  }
}

class _LayerMeta {
  final EnsembleLayer layer;
  final String label;
  final IconData icon;
  const _LayerMeta(this.layer, this.label, this.icon);
}

class _Chip extends StatelessWidget {
  final _LayerMeta meta;
  final double gain; // 0..1 audible/awake level of this layer
  final bool isNext; // the next instrument to earn (telegraphed)
  final double proximity; // 0..1 combo progress toward the next threshold
  final double breath; // 0..1 gong breathing phase (0 if reduced motion)
  const _Chip({
    required this.meta,
    required this.gain,
    required this.isNext,
    required this.proximity,
    required this.breath,
  });

  @override
  Widget build(BuildContext context) {
    final awake = gain > 0.5;
    // Asleep chips dim; the next one brightens toward its threshold and pulses.
    final telegraph = isNext ? proximity : 0.0;
    final lit = awake ? 1.0 : (0.25 + 0.55 * telegraph);
    final pulse = isNext ? (0.5 + 0.5 * breath) * telegraph : 0.0;
    final color = Color.lerp(Palette.cream, Palette.gold, awake ? 1.0 : telegraph)!;
    final scale = 1.0 + 0.08 * pulse;
    return Opacity(
      opacity: lit.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (awake ? Palette.gold : Palette.panel)
                    .withOpacity(awake ? 0.18 : 0.5),
                border: Border.all(
                  color: color.withOpacity(awake ? 0.9 : 0.4),
                  width: awake ? 1.6 : 1.0,
                ),
                boxShadow: awake || pulse > 0.05
                    ? [
                        BoxShadow(
                          color: Palette.gold.withOpacity(0.5 * (awake ? gain : pulse)),
                          blurRadius: 10 + 8 * (awake ? gain : pulse),
                        ),
                      ]
                    : null,
              ),
              child: Icon(meta.icon, size: 18, color: color),
            ),
            const SizedBox(height: 2),
            Text(meta.label,
                style: Typo.small.copyWith(
                    color: color, fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// The colour-temperature arc: a warm gold wash that grows with the ensemble's
/// fullness (indigo when sparse → gold at the full stack). Sits over the board,
/// taps pass through. Intensity halves under reduced motion.
class EnsembleGlow extends StatelessWidget {
  final TilesGameController gc;
  final bool reduceMotion;
  const EnsembleGlow({super.key, required this.gc, this.reduceMotion = false});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GlowPainter(
          fullness: gc.ensemble.fullness,
          breath: reduceMotion ? 0.0 : gc.ensemble.gongBreath,
          max: reduceMotion ? 0.10 : 0.20,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// A floating banner shown while an imbal call is active: it names the moment,
/// shows answer progress as dots, and — the first time — teaches wordlessly
/// ("watch… then answer"). Pulses with the gong breath.
class ImbalBanner extends StatelessWidget {
  final TilesGameController gc;
  final bool reduceMotion;
  const ImbalBanner({super.key, required this.gc, this.reduceMotion = false});

  @override
  Widget build(BuildContext context) {
    if (!gc.imbalActive) return const SizedBox.shrink();
    final breath = reduceMotion ? 0.5 : gc.ensemble.gongBreath;
    final total = gc.imbalTotal;
    final answered = gc.imbalAnswered;
    final label = gc.imbalTeaching ? 'IMBAL · tirukan iramanya' : 'IMBAL · jawab!';
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.82),
        child: Transform.scale(
          scale: 1.0 + 0.05 * breath,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Palette.violet.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Palette.violet.withOpacity(0.5 + 0.3 * breath),
                    blurRadius: 14 + 8 * breath),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hearing_rounded, size: 16, color: Palette.cream),
                const SizedBox(width: 8),
                Text(label,
                    style: Typo.chip.copyWith(color: Palette.cream, fontSize: 12)),
                const SizedBox(width: 10),
                for (var i = 0; i < total; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < answered ? Palette.goldLt : Palette.cream.withOpacity(0.3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A one-shot gold flourish that fires when [event] changes (a nailed imbal).
/// Stateless: re-keying on [event] restarts the [TweenAnimationBuilder].
class ImbalFlourish extends StatelessWidget {
  final int event;
  const ImbalFlourish({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    if (event == 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(event),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeOut,
          builder: (_, t, __) {
            final opacity = (t < 0.2 ? t / 0.2 : (1 - (t - 0.2) / 0.8)).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 0.7 + 0.6 * t,
                child: Text('IMBAL!',
                    style: Typo.judge.copyWith(
                      color: Palette.goldLt,
                      shadows: [
                        Shadow(color: Palette.gold.withOpacity(0.7), blurRadius: 24),
                      ],
                    )),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double fullness; // 0..1 ensemble fullness
  final double breath; // 0..1 gong breathing
  final double max; // peak opacity at full stack
  _GlowPainter({required this.fullness, required this.breath, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    if (fullness <= 0.01) return;
    final a = (max * fullness * (0.85 + 0.15 * breath)).clamp(0.0, max);
    final rect = Offset.zero & size;
    // Warm light blooming up from the hit line (bottom 80%) — the stage warming.
    final shader = RadialGradient(
      center: const Alignment(0, 0.6),
      radius: 1.1,
      colors: [
        Palette.goldLt.withOpacity(a),
        Palette.gold.withOpacity(a * 0.5),
        Palette.gold.withOpacity(0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) =>
      old.fullness != fullness || old.breath != breath || old.max != max;
}
