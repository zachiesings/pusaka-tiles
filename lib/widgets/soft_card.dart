import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Premium frosted panel — translucent fill, hairline gold border, soft depth.
/// The building block for cards/stats so nothing looks flat or cheap.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glow;
  final double radius;
  final Gradient? gradient;
  final Color? border;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow,
    this.radius = 22,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? Palette.panel.withOpacity(0.55) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border ?? Palette.gold.withOpacity(0.18), width: 1),
        boxShadow: [
          const BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 10)),
          if (glow != null) ...Palette.glow(glow!, blur: 24, a: 0.32),
        ],
      ),
      child: child,
    );
  }
}

/// Gold-gradient title text — the premium hero wordmark.
class GoldTitle extends StatelessWidget {
  final String text;
  final double size;
  final double letterSpacing;
  const GoldTitle(this.text, {super.key, this.size = 34, this.letterSpacing = 1});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => Palette.brand.createShader(r),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Jakarta',
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: letterSpacing,
          color: Colors.white,
          height: 1.05,
        ),
      ),
    );
  }
}
