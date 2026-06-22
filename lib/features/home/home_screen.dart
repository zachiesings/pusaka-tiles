import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/models/song.dart';
import '../../game/songs.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _play(BuildContext context, Song song) {
    final app = context.read<AppState>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TilesGameController>(
          create: (_) => TilesGameController(app, song),
          child: const TilesGameScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: BatikBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Palette.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Palette.gold, width: 2),
                ),
                child: const Icon(Icons.piano, size: 50, color: Palette.gold),
              ),
              const SizedBox(height: 12),
              const Text('PUSAKA TILES',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2, color: Palette.cream)),
              const Text('Ketuk ubin, mainkan lagu daerah',
                  style: TextStyle(color: Palette.goldSoft)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  itemCount: SongCatalog.all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = SongCatalog.all[i];
                    return _SongCard(
                      song: s,
                      best: app.bestForSong(s.id),
                      onTap: () => _play(context, s),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        icon: const Icon(Icons.settings),
                        label: const Text('Pengaturan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.cream,
                          side: const BorderSide(color: Palette.goldSoft),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AboutScreen())),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Tentang'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.cream,
                          side: const BorderSide(color: Palette.goldSoft),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
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

class _SongCard extends StatelessWidget {
  final Song song;
  final int best;
  final VoidCallback onTap;
  const _SongCard({required this.song, required this.best, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.music_note, color: Palette.gold),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title,
                        style: const TextStyle(
                            color: Palette.cream, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(song.daerah, style: const TextStyle(color: Palette.goldSoft, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$best', style: const TextStyle(color: Palette.gold, fontWeight: FontWeight.w900)),
                  const Text('terbaik', style: TextStyle(color: Palette.goldSoft, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.play_circle_fill, color: Palette.gold, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
