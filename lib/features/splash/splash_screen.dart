import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/batik.dart';
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
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Palette.panel,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Palette.gold, width: 2),
                    ),
                    child: const Icon(Icons.piano, size: 60, color: Palette.gold),
                  ),
                  const SizedBox(height: 18),
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
