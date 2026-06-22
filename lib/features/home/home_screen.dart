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
import '../../game/tile_themes.dart';
import '../shop/shop_screen.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/home_decor.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../achievements/achievements_screen.dart';

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
      if (!mounted) return;
      context.read<AppState>().startHomeMusic();
      _maybeShowTutorial();
    });
  }

  void _maybeShowTutorial() {
    final app = context.read<AppState>();
    if (!app.firstRun) return;
    app.markOnboarded();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) {
        Widget step(IconData ic, String t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(children: [
                Icon(ic, color: Palette.gold, size: 22),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(t,
                        style: const TextStyle(color: Palette.cream, height: 1.3))),
              ]),
            );
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Palette.panel, Palette.bg1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Palette.violet.withOpacity(0.5), width: 1.5),
              boxShadow: Palette.glow(Palette.violet, blur: 40, a: 0.4),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const GoldTitle('Cara Bermain', size: 24),
              const SizedBox(height: 12),
              step(Icons.touch_app_rounded, 'Ketuk ubin berwarna di lajurnya, dari bawah ke atas.'),
              step(Icons.timer_rounded, 'Ketuk pas di garis untuk PERFECT — poin lebih besar.'),
              step(Icons.local_fire_department_rounded, 'Rangkai combo untuk masuk mode FEVER (×2).'),
              step(Icons.music_note_rounded, 'Ganti instrumen tradisional di Pengaturan.'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                    label: 'Mengerti!',
                    height: 52,
                    onTap: () => Navigator.of(context).pop()),
              ),
            ]),
          ),
        );
      },
    );
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
        child: Stack(
          children: [
            const Positioned(top: 0, left: 0, right: 0, child: StageCurtain()),
            SafeArea(
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
              const GoldTitle('PUSAKA TILES', size: 32, letterSpacing: 2),
              const SizedBox(height: 4),
              Text('Ketuk ubin, mainkan lagu daerah',
                  style: TextStyle(color: Palette.cream.withOpacity(0.6), letterSpacing: 0.5)),
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
              const SizedBox(height: 8),
              // Instrument selector (novel: play folk songs on traditional voices)
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 4, top: 6),
                      child: Icon(Icons.music_note_rounded, color: Palette.teal, size: 18),
                    ),
                    ...K.instruments.map((e) {
                      final sel = app.instrument == e.key;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => app.setInstrument(e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? Palette.teal : Palette.panelHi.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(e.value,
                                style: TextStyle(
                                    color: sel ? Palette.ink : Palette.cream,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
                      accent: TileTheme.active[i % TileTheme.active.length],
                      onTap: () => _play(context, s),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ShopScreen())),
                        icon: const Icon(Icons.palette),
                        label: const Text('Toko Tema'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.gold,
                          side: const BorderSide(color: Palette.gold),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AchievementsScreen())),
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Pencapaian'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.gold,
                          side: const BorderSide(color: Palette.gold),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
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
          ],
        ),
      ),
    );
  }
}

class _SongCard extends StatefulWidget {
  final Song song;
  final int best;
  final int stars;
  final Color accent;
  final VoidCallback onTap;
  const _SongCard(
      {required this.song,
      required this.best,
      required this.stars,
      required this.accent,
      required this.onTap});

  @override
  State<_SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<_SongCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Palette.panel.withOpacity(0.95), Palette.panelHi.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: a.withOpacity(0.45), width: 1),
            boxShadow: Palette.glow(a, blur: 20, a: 0.28),
          ),
          child: Row(
            children: [
              // accent gradient spine
              Container(
                width: 6,
                height: 78,
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(a, Colors.white, 0.4)!, a]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.song.title,
                          style: const TextStyle(
                              color: Palette.cream, fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(widget.song.daerah,
                          style: TextStyle(color: Palette.cream.withOpacity(0.5), fontSize: 12)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          ...List.generate(
                            3,
                            (i) => Icon(
                              i < widget.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 16,
                              color: i < widget.stars ? Palette.gold : Palette.gridLine,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (widget.best > 0)
                            Text('• ${widget.best}',
                                style: TextStyle(
                                    color: Palette.cream.withOpacity(0.55),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 46,
                height: 46,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color.lerp(a, Colors.white, 0.25)!, a]),
                  shape: BoxShape.circle,
                  boxShadow: Palette.glow(a, blur: 14, a: 0.5),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Palette.cream, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
