import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// A hanging stage curtain across the top of the home — deep plum drapes with a
/// gold valance. Adds theatrical depth to the "Panggung Malam" home.
class StageCurtain extends StatelessWidget {
  const StageCurtain({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 96,
        width: double.infinity,
        child: CustomPaint(painter: _CurtainPainter()),
      ),
    );
  }
}

class _CurtainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const drapes = 7;
    final w = size.width / drapes;
    final fold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3A1B40), Color(0xFF5C2A60)],
      ).createShader(Offset.zero & size);
    // each drape = a rounded bell hanging down
    for (var i = 0; i < drapes; i++) {
      final cx = w * (i + 0.5);
      final path = Path()
        ..moveTo(w * i, -10)
        ..lineTo(w * (i + 1), -10)
        ..lineTo(w * (i + 1), size.height * 0.45)
        ..quadraticBezierTo(cx, size.height, w * i, size.height * 0.45)
        ..close();
      canvas.drawPath(path, fold);
      // shading highlight down the middle of each drape
      canvas.drawPath(
        Path()
          ..moveTo(cx, 0)
          ..quadraticBezierTo(cx, size.height * 0.5, cx, size.height * 0.9),
        Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.25,
      );
    }
    // gold valance trim along the scalloped hem
    final gold = Paint()
      ..color = Palette.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final hem = Path()..moveTo(0, size.height * 0.45);
    for (var i = 0; i < drapes; i++) {
      hem.quadraticBezierTo(w * (i + 0.5), size.height, w * (i + 1), size.height * 0.45);
    }
    canvas.drawPath(hem, gold..color = Palette.gold.withOpacity(0.5));
    // tassels
    for (var i = 0; i <= drapes; i++) {
      final x = w * i;
      canvas.drawCircle(Offset(x, size.height * 0.46), 3, Paint()..color = Palette.goldLt);
      canvas.drawLine(Offset(x, size.height * 0.46), Offset(x, size.height * 0.46 + 8),
          Paint()..color = Palette.gold..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _CurtainPainter old) => false;
}

/// A traditional joglo/pendopo roof silhouette across the top of the home —
/// dark teak with a gold ridge + hanging lanterns. For the "Pendopo Emas" home.
class PendopoRoof extends StatelessWidget {
  const PendopoRoof({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 86,
        width: double.infinity,
        child: CustomPaint(painter: _RoofPainter()),
      ),
    );
  }
}

class _RoofPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final roof = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A1A0C), Color(0xFF3A2614)],
      ).createShader(Offset.zero & size);
    // joglo roof: upturned trapezoid
    final path = Path()
      ..moveTo(-20, -10)
      ..lineTo(w + 20, -10)
      ..lineTo(w + 20, size.height * 0.4)
      ..quadraticBezierTo(w * 0.78, size.height * 0.78, w * 0.62, size.height * 0.62)
      ..lineTo(w * 0.38, size.height * 0.62)
      ..quadraticBezierTo(w * 0.22, size.height * 0.78, -20, size.height * 0.4)
      ..close();
    canvas.drawPath(path, roof);
    // gold ridge line
    canvas.drawLine(Offset(w * 0.38, size.height * 0.62), Offset(w * 0.62, size.height * 0.62),
        Paint()..color = Palette.gold..strokeWidth = 3);
    canvas.drawLine(Offset(0, size.height * 0.42), Offset(w, size.height * 0.42),
        Paint()..color = Palette.gold.withOpacity(0.4)..strokeWidth = 1.5);
    // hanging lanterns
    for (final fx in [0.2, 0.8]) {
      final x = w * fx;
      canvas.drawLine(Offset(x, size.height * 0.55), Offset(x, size.height * 0.7),
          Paint()..color = Palette.goldSoft..strokeWidth = 1.5);
      canvas.drawCircle(Offset(x, size.height * 0.78), 8,
          Paint()..color = Palette.gold.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(Offset(x, size.height * 0.78), 5, Paint()..color = Palette.goldLt);
    }
    // ridge finials
    canvas.drawCircle(Offset(w * 0.38, size.height * 0.62), 4, Paint()..color = Palette.gold);
    canvas.drawCircle(Offset(w * 0.62, size.height * 0.62), 4, Paint()..color = Palette.gold);
  }

  @override
  bool shouldRepaint(covariant _RoofPainter old) => false;
}
