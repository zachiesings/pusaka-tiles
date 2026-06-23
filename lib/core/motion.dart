import 'package:flutter/material.dart';

/// "Panggung" page transition — our own cool, night-stage motion (deliberately
/// distinct from Blast's warm Pendopo wipe). The incoming page rises a touch,
/// scales up from 0.97 and fades in behind a brief violet spotlight; the
/// outgoing page eases back and dims. Applied app-wide via [PageTransitionsTheme].
class PanggungPageTransitionsBuilder extends PageTransitionsBuilder {
  const PanggungPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final inCurve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final outCurve =
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic);

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, _) {
        final t = inCurve.value; // 0 -> 1 entering
        final s = outCurve.value; // 0 -> 1 leaving (covered)
        final scale = (0.97 + 0.03 * t) * (1 - 0.03 * s);
        final dy = (1 - t) * 26.0;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Stack(
        children: [
          child,
          // a quick violet spotlight that fades away as the page settles
          IgnorePointer(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.5, end: 0.0).animate(inCurve),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.1,
                    colors: [Color(0x337E55C6), Color(0x00000000)],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// App-wide transitions theme using the Panggung builder on every platform.
const panggungPageTransitionsTheme = PageTransitionsTheme(builders: {
  TargetPlatform.android: PanggungPageTransitionsBuilder(),
  TargetPlatform.iOS: PanggungPageTransitionsBuilder(),
  TargetPlatform.macOS: PanggungPageTransitionsBuilder(),
  TargetPlatform.windows: PanggungPageTransitionsBuilder(),
  TargetPlatform.linux: PanggungPageTransitionsBuilder(),
  TargetPlatform.fuchsia: PanggungPageTransitionsBuilder(),
});

/// Cross-fade + gentle rise used when switching home tabs (keeps each tab's
/// state alive via an IndexedStack underneath, while this animates the swap).
class TabSwapTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const TabSwapTransition({super.key, required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final t = c.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
        );
      },
    );
  }
}
