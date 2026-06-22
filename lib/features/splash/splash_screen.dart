import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/batik.dart';
import '../../widgets/mascot.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeIn);
    return Scaffold(
      body: BatikBackground(
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1).animate(scale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MascotView(size: 150, mood: MascotMood.happy),
                  const SizedBox(height: 14),
                  const Text('PUSAKA TILES',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Palette.cream)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
