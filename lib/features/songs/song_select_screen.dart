import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/chart.dart';
import '../../game/modifiers.dart';
import '../../game/models/song.dart';
import '../../game/progression.dart';
import '../../game/songs.dart';
import '../../game/tile_themes.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../../widgets/display_text.dart';
import '../game/game_screen.dart';
import '../missions/missions_screen.dart';

/// Dedicated song-select — its OWN screen (moved off the home so home stays
/// spacious). Album-art-style cards with difficulty + best/stars, category
/// tabs, and the mode + instrument pickers. Structurally distinct from Blast.
class SongSelectScreen extends StatefulWidget {
  /// Optional song to auto-launch (used by the home "Lagu Hari Ini" hook is
  /// handled directly there; this screen is the full browser).
  const SongSelectScreen({super.key});

  @override
  State<SongSelectScreen> createState() => _SongSelectScreenState();
}

/// Difficulty buckets derived from each song's speedScale.
enum _Diff { mudah, sedang, sulit }

_Diff _diffOf(Song s) {
  if (s.speedScale <= 0.97) return _Diff.mudah;
  if (s.speedScale <= 1.15) return _Diff.sedang;
  return _Diff.sulit;
}

const _diffLabel = {_Diff.mudah: 'Mudah', _Diff.sedang: 'Sedang', _Diff.sulit: 'Sulit'};
const _diffColor = {_Diff.mudah: Palette.teal, _Diff.sedang: Palette.gold, _Diff.sulit: Palette.pink};

class _SongSelectScreenState extends State<SongSelectScreen> {
  PlayMode _playMode = PlayMode.endless;
  Difficulty _difficulty = Difficulty.normal;
  final Set<SongModifier> _mods = <SongModifier>{}; // per-run challenge toggles
  int _tab = 0; // 0=Semua, 1=Mudah, 2=Sedang, 3=Sulit
  static const _tabs = ['Semua', 'Mudah', 'Sedang', 'Sulit'];

  // Modes the player can pick per song (Daily is launched from its own card).
  static const _modes = [PlayMode.endless, PlayMode.practice, PlayMode.challenge];

  Future<void> _launch(Song song, {PlayMode? play, Difficulty? difficulty, int? dailySeed}) async {
    final app = context.read<AppState>();
    app.stopHomeMusic();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TilesGameController>(
          create: (_) => TilesGameController(
            app,
            song,
            play: play ?? _playMode,
            difficulty: difficulty ?? _difficulty,
            dailySeed: dailySeed,
            // Daily is a fair, fixed challenge — no modifiers on it.
            modifiers: dailySeed != null ? const <SongModifier>{} : _mods,
          ),
          child: const TilesGameScreen(),
        ),
      ),
    );
    if (mounted) {
      app.startHomeMusic();
      setState(() {}); // refresh best/stars after a run
    }
  }

  void _launchDaily() {
    final app = context.read<AppState>();
    final pick = app.dailyPickToday();
    _launch(SongCatalog.all[pick.songIndex],
        play: PlayMode.daily, difficulty: pick.difficulty, dailySeed: pick.seed);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final songs = SongCatalog.all.where((s) {
      if (_tab == 0) return true;
      return _diffOf(s) == _Diff.values[_tab - 1];
    }).toList();

    return Scaffold(
      body: BatikBackground(
        child: SafeArea(
          child: Column(
            children: [
              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Palette.cream, size: 18),
                    ),
                    const Expanded(child: DisplayText('Pilih Lagu', size: 22)),
                    _LevelChip(level: app.level, progress: app.levelProgress),
                    IconButton(
                      tooltip: 'Misi',
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MissionsScreen())),
                      icon: const Icon(Icons.flag_rounded, color: Palette.gold),
                    ),
                  ],
                ),
              ),
              // mode + instrument pickers
              _PickerRow(
                label: 'Mode',
                children: _modes.map((m) {
                  final sel = _playMode == m;
                  return _Chip(
                    text: kPlayModes[m]!.label,
                    selected: sel,
                    color: Palette.gold,
                    onTap: () => setState(() => _playMode = m),
                  );
                }).toList(),
              ),
              _PickerRow(
                label: 'Tingkat',
                children: Difficulty.values.map((d) {
                  final sel = _difficulty == d;
                  return _Chip(
                    text: kDifficulty[d]!.label,
                    selected: sel,
                    color: Palette.pink,
                    onTap: () => setState(() => _difficulty = d),
                  );
                }).toList(),
              ),
              _PickerRow(
                label: 'Tantangan',
                children: SongModifier.values.map((m) {
                  final sel = _mods.contains(m);
                  return _Chip(
                    text: kModifiers[m]!.label,
                    selected: sel,
                    color: Palette.violet,
                    onTap: () => setState(() {
                      if (!_mods.add(m)) _mods.remove(m); // toggle
                    }),
                  );
                }).toList(),
              ),
              _PickerRow(
                label: 'Suara',
                children: K.instruments.map((e) {
                  final sel = app.instrument == e.key;
                  return _Chip(
                    text: e.value,
                    selected: sel,
                    color: Palette.teal,
                    onTap: () => app.setInstrument(e.key),
                  );
                }).toList(),
              ),
              // category tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final sel = _tab == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: sel ? Palette.violet : Palette.panel.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: sel ? Palette.gold.withOpacity(0.6) : Colors.transparent),
                          ),
                          child: Text(_tabs[i],
                              textAlign: TextAlign.center,
                              style: Typo.small.copyWith(
                                  color: sel ? Palette.cream : Palette.cream.withOpacity(0.6),
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _DailyCard(
                  streak: app.dailyStreak,
                  playedToday: app.dailyPlayedToday,
                  best: app.dailyBest,
                  onPlay: _launchDaily,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final s = songs[i];
                    final idx = SongCatalog.all.indexOf(s);
                    return _AlbumCard(
                      song: s,
                      diff: _diffOf(s),
                      best: app.bestForSong(s.id),
                      stars: app.bestStars(s.id),
                      mastery: app.songMasteryTier(s.id),
                      accent: TileTheme.active[idx % TileTheme.active.length],
                      onTap: () => _launch(s),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _PickerRow({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Text(label, style: Typo.small.copyWith(color: Palette.goldSoft)),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              child: Row(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact player-level chip with a thin XP ring, shown in the header.
class _LevelChip extends StatelessWidget {
  final int level;
  final double progress;
  const _LevelChip({required this.level, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Palette.panel.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.gold.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                backgroundColor: Palette.gridLine,
                valueColor: const AlwaysStoppedAnimation(Palette.gold),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text('Lv $level',
            style: Typo.chip.copyWith(color: Palette.goldLt, fontSize: 13)),
      ]),
    );
  }
}

/// "Lagu Hari Ini" — the deterministic Daily challenge with its streak.
class _DailyCard extends StatelessWidget {
  final int streak, best;
  final bool playedToday;
  final VoidCallback onPlay;
  const _DailyCard({
    required this.streak,
    required this.best,
    required this.playedToday,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Palette.violet, Palette.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: Palette.glow(Palette.violet, blur: 16, a: 0.3),
        ),
        child: Row(
          children: [
            const Icon(Icons.today_rounded, color: Palette.goldLt, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lagu Hari Ini',
                      style: TextStyle(
                          color: Palette.cream,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  Text(
                      playedToday
                          ? 'Selesai hari ini · skor $best'
                          : 'Tantangan harian — sekali coba!',
                      style: TextStyle(
                          color: Palette.cream.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
            if (streak > 0) ...[
              const Icon(Icons.local_fire_department_rounded,
                  color: Palette.gold, size: 18),
              const SizedBox(width: 3),
              Text('$streak',
                  style: const TextStyle(
                      color: Palette.gold, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Icon(playedToday ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
                color: Palette.goldLt, size: 30),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip({required this.text, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : Palette.panel.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(text,
              style: TextStyle(
                  color: selected ? Palette.ink : Palette.cream,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
      ),
    );
  }
}

/// Album-art-style song card: a code-generated cover thumbnail + title, region,
/// difficulty badge, stars and best score.
class _AlbumCard extends StatefulWidget {
  final Song song;
  final _Diff diff;
  final int best, stars;
  final MasteryTier mastery;
  final Color accent;
  final VoidCallback onTap;
  const _AlbumCard({
    required this.song,
    required this.diff,
    required this.best,
    required this.stars,
    required this.mastery,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Palette.panel.withOpacity(0.95), Palette.panelHi.withOpacity(0.55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: a.withOpacity(0.4), width: 1),
            boxShadow: Palette.glow(a, blur: 18, a: 0.22),
          ),
          child: Row(
            children: [
              // code-generated "album art"
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(a, Colors.white, 0.35)!, a, Color.lerp(a, Colors.black, 0.25)!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: Palette.glow(a, blur: 12, a: 0.4),
                ),
                child: Center(
                  child: Text(
                    widget.song.title.substring(0, 1).toUpperCase(),
                    style: Typo.score.copyWith(color: Palette.cream.withOpacity(0.92), fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Typo.title.copyWith(color: Palette.cream, fontSize: 16)),
                    Text(widget.song.daerah,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Typo.small.copyWith(color: Palette.cream.withOpacity(0.5))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _diffColor[widget.diff]!.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _diffColor[widget.diff]!.withOpacity(0.5)),
                          ),
                          child: Text(_diffLabel[widget.diff]!,
                              style: Typo.small.copyWith(
                                  color: _diffColor[widget.diff]!, fontSize: 9.5, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(
                          3,
                          (i) => Icon(
                            i < widget.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 15,
                            color: i < widget.stars ? Palette.gold : Palette.gridLine,
                          ),
                        ),
                        if (widget.best > 0) ...[
                          const SizedBox(width: 8),
                          Text('${widget.best}',
                              style: Typo.small.copyWith(color: Palette.cream.withOpacity(0.55))),
                        ],
                        if (widget.mastery != MasteryTier.pemula) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.workspace_premium_rounded,
                              size: 13, color: Palette.goldLt),
                          const SizedBox(width: 2),
                          Text(Mastery.tierLabel[widget.mastery.index],
                              style: Typo.small.copyWith(
                                  color: Palette.goldLt,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.5)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color.lerp(a, Colors.white, 0.25)!, a]),
                  shape: BoxShape.circle,
                  boxShadow: Palette.glow(a, blur: 12, a: 0.5),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Palette.cream, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
