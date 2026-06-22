import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/game_mode.dart';
import '../../game/models/song.dart';
import '../../game/songs.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../../widgets/banner_ad.dart';
import '../../widgets/mascot.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  GameMode _mode = GameMode.klasik;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().startHomeMusic();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final app = context.read<AppState>();
    if (state == AppLifecycleState.resumed) {
      app.startHomeMusic();
    } else if (state == AppLifecycleState.paused) {
      app.stopHomeMusic();
    }
  }

  Future<void> _play(BuildContext context, Song song) async {
    final app = context.read<AppState>();
    app.stopHomeMusic();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TilesGameController>(
          create: (_) => TilesGameController(app, song, mode: _mode),
          child: const TilesGameScreen(),
        ),
      ),
    );
    app.startHomeMusic(); // resume on return to home
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: BatikBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => app.setMusic(!app.music),
                  icon: Icon(app.music ? Icons.music_note : Icons.music_off,
                      color: app.music ? Palette.gold : Palette.goldSoft),
                ),
              ),
              const MascotView(size: 120, mood: MascotMood.idle),
              const SizedBox(height: 6),
              const Text('PUSAKA TILES',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2, color: Palette.cream)),
              const Text('Ketuk ubin, mainkan lagu daerah',
                  style: TextStyle(color: Palette.goldSoft)),
              const SizedBox(height: 12),
              // Mode selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: GameMode.values.map((m) {
                    final sel = _mode == m;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? Palette.gold : Palette.panel,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(kModeParams[m]!.label,
                              style: TextStyle(
                                  color: sel ? Palette.ink : Palette.cream,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
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
                      stars: app.bestStars(s.id),
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
              const Center(child: BannerAdBar()),
              const SizedBox(height: 6),
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
  final int stars;
  final VoidCallback onTap;
  const _SongCard({required this.song, required this.best, required this.stars, required this.onTap});

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
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        3,
                        (i) => Icon(
                          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 16,
                          color: i < stars ? Palette.gold : Palette.gridLine,
                        ),
                      ),
                    ),
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
