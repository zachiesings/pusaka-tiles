import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/batik.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              const Center(child: MascotView(size: 110, mood: MascotMood.happy)),
              const SizedBox(height: 8),
              const Center(child: GoldTitle('PUSAKA TILES', size: 26, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Center(
                child: Text('Versi 1.0.0',
                    style: TextStyle(color: Palette.cream.withOpacity(0.5), letterSpacing: 1)),
              ),
              const SizedBox(height: 20),
              SoftCard(
                glow: Palette.violet,
                child: Text(
                    'Ketuk ubin mengikuti irama dan mainkan melodi lagu-lagu daerah '
                    'Nusantara (notasi angka). Nada disintesis sendiri — bukan rekaman '
                    'berhak cipta.',
                    style: TextStyle(color: Palette.cream.withOpacity(0.75), height: 1.5)),
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.shield_rounded, color: Palette.gold, size: 20),
                      SizedBox(width: 8),
                      Text('Privasi',
                          style: TextStyle(
                              color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        'Iklan (AdMob) non-personalisasi. Skor terbaik disimpan hanya di '
                        'perangkatmu. Tidak ada pelacakan lintas-aplikasi.',
                        style: TextStyle(color: Palette.cream.withOpacity(0.65), height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
