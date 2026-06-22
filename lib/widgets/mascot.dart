import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

enum MascotMood { idle, happy, sad, cheer }

/// "Si Batik" — a cute Nusantara mascot drawn + animated entirely in code (a
/// blangkon-wearing little character). Idle breathing + occasional blinks; jumps
/// & throws its arms up on [cheer]/[happy], droops on [sad]. No image assets.
class MascotView extends StatefulWidget {
  final MascotMood mood;
  final double size;
  const MascotView({super.key, this.mood = MascotMood.idle, this.size = 120});

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  late final AnimationController _react =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didUpdateWidget(covariant MascotView old) {
    super.didUpdateWidget(old);
    if (widget.mood != old.mood && widget.mood != MascotMood.idle) {
      _react.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _react.dispose();
    super.dispose();
  }

  double _blink(double t) {
    final d = (t - 0.5).abs();
    return d < 0.045 ? (d / 0.045) : 1.0; // quick blink mid-cycle
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _react]),
        builder: (_, __) {
          final t = _idle.value;
          final react = Curves.easeOutBack.transform(_react.value.clamp(0.0, 1.0));
          return CustomPaint(
            painter: _MascotPainter(
              mood: widget.mood,
              breath: math.sin(2 * math.pi * t),
              blink: _blink(t),
              react: _react.isAnimating || _react.value > 0 ? react : 0,
            ),
          );
        },
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  final double breath; // -1..1
  final double blink;  // 0 closed .. 1 open
  final double react;  // 0..1 reaction progress

  _MascotPainter({required this.mood, required this.breath, required this.blink, required this.react});

  static const _skin = Color(0xFFE9C9A0);
  static const _blangkon = Color(0xFF3A2A1A);
  static const _batik = Color(0xFF7A3B2E);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;

    // Vertical motion: jump up on happy/cheer, sink on sad.
    double dy = breath * s * 0.012;
    if (mood == MascotMood.cheer || mood == MascotMood.happy) {
      dy -= math.sin(math.pi * react) * s * 0.14;
    } else if (mood == MascotMood.sad) {
      dy += react * s * 0.05;
    }
    canvas.save();
    canvas.translate(0, dy);

    // Soft shadow on the ground
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, s * 0.95 - dy * 0.4), width: s * 0.5, height: s * 0.1),
      Paint()..color = Colors.black.withOpacity(0.18),
    );

    final bodyTop = s * 0.55;
    // Arms (behind body). Raise up on cheer/happy.
    final armUp = (mood == MascotMood.cheer || mood == MascotMood.happy) ? react : 0.0;
    _arm(canvas, cx - s * 0.26, bodyTop + s * 0.04, s, armUp, left: true);
    _arm(canvas, cx + s * 0.26, bodyTop + s * 0.04, s, armUp, left: false);

    // Body (batik sarong)
    final bodyRect = Rect.fromCenter(center: Offset(cx, s * 0.70), width: s * 0.5, height: s * 0.42);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(s * 0.2)), Paint()..color = _batik);
    // batik dots on body
    final dot = Paint()..color = Palette.cream.withOpacity(0.5);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 2; j++) {
        canvas.drawCircle(Offset(cx - s * 0.12 + i * s * 0.12, s * 0.64 + j * s * 0.12), s * 0.018, dot);
      }
    }
    // feet
    final feet = Paint()..color = _blangkon;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - s * 0.11, s * 0.92), width: s * 0.14, height: s * 0.07), feet);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + s * 0.11, s * 0.92), width: s * 0.14, height: s * 0.07), feet);

    // Head
    final headC = Offset(cx, s * 0.38);
    final headR = s * 0.27;
    canvas.drawCircle(headC, headR, Paint()..color = _skin);

    // Blangkon (cap) — covers top of head + mondolan bump at back
    final capPath = Path()
      ..moveTo(cx - headR, headC.dy)
      ..arcToPoint(Offset(cx + headR, headC.dy), radius: Radius.circular(headR), clockwise: true)
      ..lineTo(cx + headR * 0.9, headC.dy - headR * 0.1)
      ..arcToPoint(Offset(cx - headR * 0.9, headC.dy - headR * 0.1),
          radius: Radius.circular(headR * 0.95), clockwise: true)
      ..close();
    canvas.drawPath(capPath, Paint()..color = _blangkon);
    canvas.drawCircle(Offset(cx + headR * 0.55, headC.dy - headR * 0.55), headR * 0.22,
        Paint()..color = _blangkon); // mondolan
    // cap batik trim
    canvas.drawArc(Rect.fromCircle(center: headC, radius: headR * 0.78), math.pi, math.pi, false,
        Paint()..color = Palette.gold..style = PaintingStyle.stroke..strokeWidth = s * 0.012);

    // Cheeks
    final cheek = Paint()..color = const Color(0xFFE08A7A).withOpacity(0.5);
    canvas.drawCircle(Offset(cx - headR * 0.5, headC.dy + headR * 0.25), headR * 0.16, cheek);
    canvas.drawCircle(Offset(cx + headR * 0.5, headC.dy + headR * 0.25), headR * 0.16, cheek);

    // Eyes
    final eyeY = headC.dy + headR * 0.02;
    final eyeDx = headR * 0.42;
    final ink = Paint()..color = const Color(0xFF1B130A);
    if (mood == MascotMood.happy || mood == MascotMood.cheer) {
      // happy ^^ arcs
      final p = Paint()..color = ink.color..style = PaintingStyle.stroke..strokeWidth = s * 0.022..strokeCap = StrokeCap.round;
      for (final sx in [cx - eyeDx, cx + eyeDx]) {
        canvas.drawArc(Rect.fromCircle(center: Offset(sx, eyeY + headR * 0.04), radius: headR * 0.14),
            math.pi, math.pi, false, p);
      }
    } else {
      final eh = headR * 0.22 * blink + headR * 0.02;
      for (final sx in [cx - eyeDx, cx + eyeDx]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(sx, eyeY), width: headR * 0.2, height: eh), ink);
      }
      if (mood == MascotMood.sad) {
        final brow = Paint()..color = ink.color..style = PaintingStyle.stroke..strokeWidth = s * 0.018..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - eyeDx - headR * 0.12, eyeY - headR * 0.22),
            Offset(cx - eyeDx + headR * 0.1, eyeY - headR * 0.12), brow);
        canvas.drawLine(Offset(cx + eyeDx + headR * 0.12, eyeY - headR * 0.22),
            Offset(cx + eyeDx - headR * 0.1, eyeY - headR * 0.12), brow);
      }
    }

    // Mouth
    final mouth = Paint()..color = ink.color..style = PaintingStyle.stroke..strokeWidth = s * 0.02..strokeCap = StrokeCap.round;
    final my = headC.dy + headR * 0.5;
    if (mood == MascotMood.sad) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, my + headR * 0.12), radius: headR * 0.18),
          math.pi + 0.4, math.pi - 0.8, false, mouth);
    } else {
      final open = mood == MascotMood.cheer ? 0.5 + react * 0.4 : 0.5;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, my), radius: headR * 0.2),
          0.3, math.pi - 0.6, false, mouth..strokeWidth = s * (0.02 + open * 0.01));
    }

    // Sparkles on cheer
    if (mood == MascotMood.cheer && react > 0) {
      final sp = Paint()..color = Palette.gold.withOpacity((1 - react).clamp(0.0, 1.0));
      for (final a in [0.3, 1.4, 2.5, 4.0, 5.2]) {
        final rr = headR * (1.3 + react * 0.6);
        final c = Offset(cx + math.cos(a) * rr, headC.dy + math.sin(a) * rr);
        _star(canvas, c, s * 0.03, sp);
      }
    }

    canvas.restore();
  }

  void _arm(Canvas canvas, double x, double y, double s, double up, {required bool left}) {
    final paint = Paint()..color = _skin..strokeWidth = s * 0.07..strokeCap = StrokeCap.round;
    final dir = left ? -1 : 1;
    final end = Offset(
      x + dir * s * 0.06 * (1 - up) + dir * s * 0.02 * up,
      y + s * 0.12 * (1 - up) - s * 0.18 * up,
    );
    canvas.drawLine(Offset(x, y), end, paint);
    canvas.drawCircle(end, s * 0.045, Paint()..color = _skin);
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      path.moveTo(c.dx, c.dy);
      path.lineTo(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      path.lineTo(c.dx + math.cos(a + 0.4) * r * 0.4, c.dy + math.sin(a + 0.4) * r * 0.4);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) =>
      old.breath != breath || old.blink != blink || old.react != react || old.mood != mood;
}
