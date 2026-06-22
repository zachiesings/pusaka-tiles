import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/batik.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              Text('Pusaka Tiles',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Palette.cream)),
              SizedBox(height: 8),
              Text('Ketuk ubin mengikuti irama dan mainkan melodi lagu-lagu daerah '
                  'Nusantara (notasi angka). Nada disintesis sendiri — bukan rekaman berhak cipta.',
                  style: TextStyle(color: Palette.goldSoft, height: 1.5)),
              SizedBox(height: 24),
              Text('Privasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Palette.cream)),
              SizedBox(height: 8),
              Text('Game menampilkan iklan (AdMob) non-personalisasi. Skor terbaik '
                  'disimpan hanya di perangkatmu.',
                  style: TextStyle(color: Palette.goldSoft, height: 1.5)),
              SizedBox(height: 24),
              Text('Versi 1.0.0', style: TextStyle(color: Palette.gold)),
            ],
          ),
        ),
      ),
    );
  }
}
