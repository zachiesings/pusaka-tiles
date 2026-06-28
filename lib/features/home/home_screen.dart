import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../game/game_mode.dart';
import '../../game/models/song.dart';
import '../../game/songs.dart';
import '../../game/stage.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../../widgets/batik_motif.dart';
import '../../game/tile_themes.dart';
import '../shop/shop_screen.dart';
import '../songs/song_select_screen.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/home_decor.dart';
import '../../widgets/mascot.dart';
import '../../widgets/tiles_mascot.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/display_text.dart';
import '../../widgets/effects.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../achievements/achievements_screen.dart';
import '../adventure/adventure_map_screen.dart';

/// The home is a 3-tab shell — Beranda (song list + quick play + campaign
/// herald), Perjalanan (the 20-stage map) and Profil (stats + menus) — so it's a
/// living stage, not one page.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _tabAnim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 340))
        ..value = 1;

  void _selectTab(int i) {
    if (i == _tab) return;
    setState(() => _tab = i);
    _tabAnim.forward(from: 0);
  }

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
              const DisplayText('Cara Bermain', size: 24),
              const SizedBox(height: 12),
              step(Icons.touch_app_rounded, 'Ketuk ubin berwarna di lajurnya, dari bawah ke atas.'),
              step(Icons.ads_click_rounded, 'Ketuk pas di garis untuk PERFECT — poin lebih besar.'),
              step(Icons.local_fire_department_rounded, 'Rangkai combo untuk masuk mode FEVER (×2).'),
              step(Icons.map_rounded, 'Buka Perjalanan: 20 babak pusaka lintas Nusantara.'),
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
    _tabAnim.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: TabSwapTransition(
        animation: _tabAnim,
        child: IndexedStack(
          index: _tab,
          children: [
            _BerandaTab(onOpenAdventure: () => _selectTab(1)),
            const AdventureMapScreen(embedded: true),
            const _ProfilTab(),
          ],
        ),
      ),
      bottomNavigationBar: _NavBar(index: _tab, onTap: _selectTab),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.panel.withOpacity(0.0), Palette.bg0.withOpacity(0.96)],
        ),
      ),
      padding: const EdgeInsets.only(top: 6),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: Palette.violet.withOpacity(0.30),
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: s.contains(WidgetState.selected)
                    ? Palette.gold
                    : Palette.cream.withOpacity(0.6),
              )),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: Colors.transparent,
          selectedIndex: index,
          onDestinationSelected: onTap,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Palette.goldSoft),
                selectedIcon: Icon(Icons.home_rounded, color: Palette.gold),
                label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.map_outlined, color: Palette.goldSoft),
                selectedIcon: Icon(Icons.map_rounded, color: Palette.gold),
                label: 'Perjalanan'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: Palette.goldSoft),
                selectedIcon: Icon(Icons.person_rounded, color: Palette.gold),
                label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Beranda tab — hero, wordmark, campaign herald, song list, strolling mascot.
// ===========================================================================
class _BerandaTab extends StatefulWidget {
  final VoidCallback onOpenAdventure;
  const _BerandaTab({required this.onOpenAdventure});

  @override
  State<_BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<_BerandaTab> {
  GameMode _mode = GameMode.klasik;

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
    if (mounted) app.startHomeMusic();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = SongCatalog.all;
    final doy = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final daily = all[doy % all.length];
    return BatikBackground(
      child: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: StageCurtain()),
          const Positioned.fill(child: SparkleField(count: 20)),
          // Equipped Pusaka motif — a faint background "theme" watermark.
          if (app.activeMotif != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.06,
                  child: CustomPaint(
                    painter: BatikMotifPainter(
                      bloom: 1,
                      color: app.activeMotif!.color,
                      petals: app.activeMotif!.petals,
                      rings: app.activeMotif!.rings,
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                // ---- Clean header (coins + music) ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 14, 0),
                  child: _TopBar(
                    coins: app.coins,
                    music: app.music,
                    onMusic: () => app.setMusic(!app.music),
                  ),
                ),
                // ---- Spacious hero + primary actions ----
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const TilesMascot(size: 136, mood: MascotMood.idle),
                        const SizedBox(height: 6),
                        const ShimmerSweep(
                          child: DisplayText('PUSAKA TILES', size: 32, weight: 800, letterSpacing: 3),
                        ),
                        const SizedBox(height: 6),
                        Text('Ketuk ubin, mainkan lagu daerah',
                            style: TextStyle(
                                color: Palette.cream.withOpacity(0.6),
                                letterSpacing: 0.5,
                                fontSize: 13)),
                        const SizedBox(height: 32),
                        // PRIMARY CTA → dedicated song-select screen
                        _MainCta(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SongSelectScreen())),
                        ),
                        const SizedBox(height: 16),
                        // Daily hook — song of the day
                        _DailyCard(song: daily, onTap: () => _play(context, daily)),
                        const SizedBox(height: 16),
                        // Campaign (secondary)
                        _CampaignHerald(
                          unlocked: app.campaignUnlocked,
                          stars: app.totalStars,
                          complete: app.campaignComplete,
                          onTap: widget.onOpenAdventure,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The campaign call-to-action herald on Beranda.
class _CampaignHerald extends StatelessWidget {
  final int unlocked, stars;
  final bool complete;
  final VoidCallback onTap;
  const _CampaignHerald({
    required this.unlocked,
    required this.stars,
    required this.complete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cur = StageCatalog.byIndex(unlocked.clamp(1, StageCatalog.count));
    final accent = cur.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.32), Palette.panel.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Palette.gold.withOpacity(0.45), width: 1.2),
          boxShadow: Palette.glow(accent, blur: 22, a: 0.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: Palette.brand,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: Palette.glow(accent, blur: 14, a: 0.3),
                  ),
                  child: Icon(complete ? Icons.workspace_premium_rounded : cur.goal.icon,
                      color: Palette.cream, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complete ? 'PERJALANAN' : 'LANJUTKAN',
                          style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                      const SizedBox(height: 2),
                      Text(complete ? 'Nusantara Tuntas' : cur.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Palette.cream, fontSize: 17, fontWeight: FontWeight.w900)),
                      Text(
                          complete
                              ? 'Semua pusaka diraih'
                              : '${cur.region} • ${cur.goal.label(cur.target)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Palette.cream.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Palette.gold, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (unlocked - 1) / StageCatalog.count,
                      minHeight: 6,
                      backgroundColor: Palette.bg1.withOpacity(0.7),
                      color: Palette.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.star_rounded, color: Palette.gold, size: 15),
                const SizedBox(width: 3),
                Text('$stars',
                    style: const TextStyle(
                        color: Palette.gold, fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(width: 8),
                Text('${(unlocked - 1).clamp(0, StageCatalog.count)}/${StageCatalog.count}',
                    style: TextStyle(
                        color: Palette.cream.withOpacity(0.7),
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Top utility bar on Beranda — coins and the music toggle.
class _TopBar extends StatelessWidget {
  final int coins;
  final bool music;
  final VoidCallback onMusic;
  const _TopBar({required this.coins, required this.music, required this.onMusic});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Palette.panel.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.gold.withOpacity(0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.monetization_on_rounded, color: Palette.gold, size: 17),
            const SizedBox(width: 5),
            Text('$coins',
                style: const TextStyle(
                    color: Palette.gold, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onMusic,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Palette.panel.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Palette.gold.withOpacity(0.35)),
            ),
            child: Icon(music ? Icons.music_note_rounded : Icons.music_off_rounded,
                color: music ? Palette.gold : Palette.goldSoft, size: 20),
          ),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiniButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.gold,
        side: BorderSide(color: Palette.gold.withOpacity(0.7)),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );
  }
}

/// The big primary "MAIN" call-to-action on the decluttered home.
class _MainCta extends StatelessWidget {
  final VoidCallback onTap;
  const _MainCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: Palette.brand,
          borderRadius: BorderRadius.circular(22),
          boxShadow: Palette.glow(Palette.violet, blur: 24, a: 0.45),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded, color: Palette.cream, size: 30),
              const SizedBox(width: 8),
              Text('MAIN',
                  style: Typo.h1.copyWith(color: Palette.cream, fontSize: 22, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Lagu Hari Ini" — a daily hook (song of the day, rotates by date).
class _DailyCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  const _DailyCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.teal.withOpacity(0.28), Palette.panel.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Palette.teal.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: Palette.teal.withOpacity(0.25), shape: BoxShape.circle),
              child: const Icon(Icons.today_rounded, color: Palette.teal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAGU HARI INI',
                      style: Typo.small.copyWith(
                          color: Palette.teal,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                          fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Typo.title.copyWith(color: Palette.cream, fontSize: 16)),
                  Text(song.daerah,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Typo.small.copyWith(color: Palette.cream.withOpacity(0.5))),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill_rounded, color: Palette.teal, size: 34),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Profil tab — lifetime stats + menu shortcuts.
// ===========================================================================
class _ProfilTab extends StatelessWidget {
  const _ProfilTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final rows = <(IconData, String, String)>[
      (Icons.map_rounded, 'Babak Selesai', '${app.stagesCleared}/${StageCatalog.count}'),
      (Icons.star_rounded, 'Total Bintang', '${app.totalStars}/${StageCatalog.count * 3}'),
      (Icons.bolt_rounded, 'Combo Terbaik', '${app.bestCombo}'),
      (Icons.library_music_rounded, 'Lagu Berbintang', '${app.songsWithAnyStar}/${app.totalSongs}'),
      (Icons.workspace_premium_rounded, 'Lagu 3 Bintang', '${app.songsWithThreeStars}/${app.totalSongs}'),
      (Icons.sports_esports_rounded, 'Total Main', '${app.gamesPlayed}'),
      (Icons.palette_rounded, 'Tema Dimiliki', '${app.unlockedThemeCount}/${app.totalThemes}'),
      (Icons.monetization_on_rounded, 'Koin', '${app.coins}'),
    ];
    return BatikBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            const Center(child: DisplayText('Profil', size: 26)),
            const SizedBox(height: 14),
            _LevelHeader(stars: app.totalStars, coins: app.coins),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [for (final r in rows) _StatCard(icon: r.$1, label: r.$2, value: r.$3)],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _MiniButton(
                    icon: Icons.palette_rounded,
                    label: 'Toko Tema',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ShopScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniButton(
                    icon: Icons.emoji_events_rounded,
                    label: 'Pencapaian',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AchievementsScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniButton(
                    icon: Icons.settings_rounded,
                    label: 'Pengaturan',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniButton(
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen())),
                  ),
                ),
              ],
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

/// Premium profile header — a level ring (derived from total stars), title,
/// progress to next level, and coins.
class _LevelHeader extends StatelessWidget {
  final int stars, coins;
  const _LevelHeader({required this.stars, required this.coins});

  @override
  Widget build(BuildContext context) {
    final level = 1 + stars ~/ 5;
    final into = stars % 5;
    final prog = into / 5;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Palette.violet.withOpacity(0.35), Palette.panel.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.gold.withOpacity(0.4)),
        boxShadow: Palette.glow(Palette.violet, blur: 24, a: 0.25),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: prog,
                    strokeWidth: 5,
                    backgroundColor: Palette.bg1,
                    color: Palette.gold,
                  ),
                ),
                Text('$level', style: Typo.score.copyWith(color: Palette.cream, fontSize: 26)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Penari Pusaka', style: Typo.title.copyWith(color: Palette.cream, fontSize: 16)),
                Text('Level $level • ${5 - into} bintang ke Level ${level + 1}',
                    style: Typo.small.copyWith(color: Palette.cream.withOpacity(0.6))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Palette.gold, size: 16),
                    const SizedBox(width: 4),
                    Text('$coins', style: Typo.chip.copyWith(color: Palette.gold, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact stat card for the profile grid.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.panel.withOpacity(0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.gold.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(gradient: Palette.brand, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Palette.cream, size: 19),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Typo.score.copyWith(color: Palette.gold, fontSize: 22)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.small.copyWith(color: Palette.cream.withOpacity(0.65))),
            ],
          ),
        ],
      ),
    );
  }
}
