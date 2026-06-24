import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'mascot.dart' show MascotMood; // reuse the mood enum

/// "Roh Gamelan" — Pusaka Tiles' OWN mascot: a luminous temple-dancer spirit
/// that HOVERS (no feet), with a tall wayang/gunungan crown, a glowing indigo
/// robe, and Javanese dance-pose arms. Deliberately a different silhouette from
/// Blast's standing blangkon kid (Guideline 4.3 differentiation). All code-drawn.
class TilesMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  const TilesMascot({super.key, this.mood = MascotMood.idle, this.size = 120});

  @override
  State<TilesMascot> createState() => _TilesMascotState();
}

class _TilesMascotState extends State<TilesMascot> with TickerProviderStateMixin {
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
  late final AnimationController _react =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didUpdateWidget(covariant TilesMascot old) {
    super.didUpdateWidget(old);
    if (widget.mood != old.mood && widget.mood != MascotMood.idle) _react.forward(from: 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _react]),
        builder: (_, __) => CustomPaint(
          painter: _SpiritPainter(
            mood: widget.mood,
            bob: math.sin(2 * math.pi * _idle.value),
            sway: math.sin(2 * math.pi * _idle.value + 1.0),
            react: Curves.easeOutBack.transform(_react.value.clamp(0.0, 1.0)),
          ),
        ),
      ),
    );
  }
}

class _SpiritPainter extends CustomPainter {
  final MascotMood mood;
  final double bob, sway, react;
  _SpiritPainter({required this.mood, required this.bob, required this.sway, required this.react});

  static const _robe = Color(0xFF5B4BC4);   // wedelan indigo
  static const _robe2 = Color(0xFF7E55C6);  // violet
  static const _skin = Color(0xFFF3E7D2);   // luminous pale
  static const _gold = Palette.gold;

  bool get _up => mood == MascotMood.cheer || mood == MascotMood.happy;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final lift = _up ? math.sin(math.pi * react) * s * 0.10 : 0.0;
    final cy = size.height * 0.52 + bob * s * 0.03 - lift; // hovers, gently bobbing

    // Aura glow (spirit halo) — teal→violet, pulses on cheer.
    final auraR = s * (0.42 + (mood == MascotMood.cheer ? react * 0.12 : 0));
    canvas.drawCircle(
      Offset(cx, cy),
      auraR,
      Paint()
        ..shader = RadialGradient(colors: [
          Palette.teal.withOpacity(0.28),
          Palette.violet.withOpacity(0.10),
          Palette.violet.withOpacity(0.0),
        ], stops: const [0.0, 0.6, 1.0]).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: auraR)),
    );

    // Floating wisp tail under the robe (no feet — it hovers).
    final tail = Path()
      ..moveTo(cx - s * 0.16, cy + s * 0.20)
      ..quadraticBezierTo(cx + sway * s * 0.06, cy + s * 0.44, cx, cy + s * 0.36)
      ..quadraticBezierTo(cx - sway * s * 0.06, cy + s * 0.44, cx + s * 0.16, cy + s * 0.20)
      ..close();
    canvas.drawPath(tail, Paint()..color = _robe.withOpacity(0.55));

    // Arms in a dance pose (curved, hands turned up "ngruji"). Raise on cheer.
    final armRaise = _up ? react : 0.0;
    _arm(canvas, cx, cy, s, left: true, raise: armRaise);
    _arm(canvas, cx, cy, s, left: false, raise: armRaise);

    // Robe body — a teardrop/bell in an indigo→violet gradient with a gold sash.
    final bodyTop = cy - s * 0.06;
    final body = Path()
      ..moveTo(cx, bodyTop - s * 0.04)
      ..quadraticBezierTo(cx + s * 0.22, cy, cx + s * 0.18, cy + s * 0.26)
      ..quadraticBezierTo(cx, cy + s * 0.34, cx - s * 0.18, cy + s * 0.26)
      ..quadraticBezierTo(cx - s * 0.22, cy, cx, bodyTop - s * 0.04)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_robe2, _robe],
        ).createShader(Rect.fromLTWH(cx - s * 0.22, bodyTop, s * 0.44, s * 0.4)),
    );
    // gold sash
    canvas.drawLine(Offset(cx - s * 0.16, cy + s * 0.06), Offset(cx + s * 0.16, cy + s * 0.10),
        Paint()..color = _gold..strokeWidth = s * 0.02..strokeCap = StrokeCap.round);

    // Head
    final headC = Offset(cx, cy - s * 0.18);
    final headR = s * 0.13;
    canvas.drawCircle(headC, headR, Paint()..color = _skin);

    // Wayang/gunungan crown — a tall central spike + two side prongs (gold).
    final crown = Path()
      ..moveTo(cx, headC.dy - headR * 2.4)
      ..lineTo(cx + headR * 0.55, headC.dy - headR * 0.5)
      ..lineTo(cx - headR * 0.55, headC.dy - headR * 0.5)
      ..close();
    canvas.drawPath(crown, Paint()..color = _gold);
    for (final dir in [-1.0, 1.0]) {
      final p = Path()
        ..moveTo(cx + dir * headR * 0.7, headC.dy - headR * 1.4)
        ..lineTo(cx + dir * headR * 1.1, headC.dy - headR * 0.3)
        ..lineTo(cx + dir * headR * 0.3, headC.dy - headR * 0.4)
        ..close();
      canvas.drawPath(p, Paint()..color = _gold.withOpacity(0.92));
    }
    canvas.drawCircle(Offset(cx, headC.dy - headR * 2.4), headR * 0.18,
        Paint()..color = Palette.goldLt); // crown jewel

    // Face — calm almond eyes + serene smile; happy arcs on cheer.
    final ink = Paint()..color = const Color(0xFF241C4E);
    if (_up) {
      final p = Paint()
        ..color = ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..strokeCap = StrokeCap.round;
      for (final dx in [-headR * 0.42, headR * 0.42]) {
        canvas.drawArc(Rect.fromCircle(center: Offset(cx + dx, headC.dy), radius: headR * 0.3),
            math.pi, math.pi, false, p);
      }
    } else {
      for (final dx in [-headR * 0.42, headR * 0.42]) {
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + dx, headC.dy), width: headR * 0.34, height: headR * 0.5),
            ink);
      }
    }
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, headC.dy + headR * 0.42), radius: headR * 0.34),
      0.25, math.pi - 0.5, false,
      Paint()
        ..color = ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.015
        ..strokeCap = StrokeCap.round,
    );

    // Sparkles on cheer
    if (mood == MascotMood.cheer && react > 0) {
      final sp = Paint()..color = _gold.withOpacity((1 - react).clamp(0.0, 1.0));
      for (final a in [0.4, 1.6, 2.8, 4.1, 5.4]) {
        final rr = s * (0.30 + react * 0.18);
        canvas.drawCircle(Offset(cx + math.cos(a) * rr, cy + math.sin(a) * rr), s * 0.02, sp);
      }
    }
  }

  void _arm(Canvas canvas, double cx, double cy, double s, {required bool left, required double raise}) {
    final dir = left ? -1.0 : 1.0;
    final shoulder = Offset(cx + dir * s * 0.10, cy - s * 0.04);
    // elbow out, hand turned up; raises toward the sky on cheer
    final elbow = Offset(cx + dir * s * (0.20 - raise * 0.04), cy + s * (0.04 - raise * 0.10));
    final hand = Offset(cx + dir * s * (0.24 - raise * 0.10), cy - s * (0.06 + raise * 0.16));
    final p = Paint()
      ..color = _robe2
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(elbow.dx, elbow.dy, hand.dx, hand.dy),
      p,
    );
    canvas.drawCircle(hand, s * 0.035, Paint()..color = _skin); // upturned hand
  }

  @override
  bool shouldRepaint(covariant _SpiritPainter old) =>
      old.bob != bob || old.sway != sway || old.react != react || old.mood != mood;
}
