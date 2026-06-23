import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/game_mode.dart';
import '../../game/stage.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../../widgets/display_text.dart';
import '../../widgets/effects.dart';
import '../../widgets/roaming_mascot.dart';
import '../game/game_screen.dart';

/// Perjalanan Nusantara — a winding rope of the 20 campaign stages. Cleared nodes
/// light the gold trail and show their stars; region ribbons mark each new
/// island. Built as a plain scrolling Column so it can never clip, with generous
/// padding above the header and below the strolling mascot.
class AdventureMapScreen extends StatefulWidget {
  final bool embedded; // hide the back button when shown inside the home shell
  const AdventureMapScreen({super.key, this.embedded = false});

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen> {
  static const double _rowH = 138; // height of one node stop
  static const double _bannerH = 52; // region ribbon height
  static const double _topPad = 92; // clears the floating header
  static const double _botPad = 150; // clears the strolling mascot + nav bar

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Centre the viewport on the current (first uncleared) stage.
  void _jumpToCurrent() {
    if (!_scroll.hasClients) return;
    final app = context.read<AppState>();
    final idx = (app.campaignUnlocked - 1).clamp(0, StageCatalog.count - 1);
    var y = _topPad;
    String? prev;
    for (var i = 0; i <= idx; i++) {
      final s = StageCatalog.all[i];
      if (s.region != prev) {
        y += _bannerH;
        prev = s.region;
      }
      if (i < idx) y += _rowH;
    }
    final target = (y - 220).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: const Duration(milliseconds: 650), curve: Curves.easeOutCubic);
  }

  double _nodeX(double w, int i) => w / 2 + (i.isEven ? -1 : 1) * w * 0.17;

  Future<void> _playStage(BuildContext context, AppState app, StageSpec s) async {
    app.stopHomeMusic();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TilesGameController>(
          create: (_) => TilesGameController(app, s.song, mode: s.mode, stage: s),
          child: const TilesGameScreen(),
        ),
      ),
    );
    if (!mounted) return;
    app.startHomeMusic();
    setState(() {}); // refresh stars / unlocks
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return BatikBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: SparkleField(count: 18)),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final children = <Widget>[const SizedBox(height: _topPad)];
                final centers = <Offset>[];
                double y = _topPad;
                String? prevRegion;
                for (var i = 0; i < StageCatalog.count; i++) {
                  final spec = StageCatalog.all[i];
                  if (spec.region != prevRegion) {
                    children.add(_RegionRibbon(region: spec.region, height: _bannerH));
                    y += _bannerH;
                    prevRegion = spec.region;
                  }
                  final cx = _nodeX(w, i);
                  centers.add(Offset(cx, y + _rowH * 0.36));
                  children.add(SizedBox(
                    height: _rowH,
                    child: _NodeStop(
                      spec: spec,
                      cx: cx,
                      width: w,
                      unlocked: app.isStageUnlocked(spec.index),
                      stars: app.starsForStage(spec.index),
                      isCurrent: app.isStageUnlocked(spec.index) &&
                          app.starsForStage(spec.index) == 0,
                      onTap: app.isStageUnlocked(spec.index)
                          ? () => _showStageSheet(context, app, spec)
                          : null,
                    ),
                  ));
                  y += _rowH;
                }
                children.add(const SizedBox(height: _botPad));

                return SingleChildScrollView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrailPainter(
                            centers: centers,
                            unlocked: app.campaignUnlocked,
                          ),
                        ),
                      ),
                      Column(children: children),
                    ],
                  ),
                );
              },
            ),
          ),
          const Positioned(
            left: 0, right: 0, bottom: 0, height: 120,
            child: IgnorePointer(child: RoamingMascot(size: 66)),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: _Header(
                totalStars: app.totalStars,
                cleared: app.stagesCleared,
                showBack: !widget.embedded),
          ),
        ],
      ),
    );
  }

  void _showStageSheet(BuildContext context, AppState app, StageSpec s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StageSheet(
        spec: s,
        stars: app.starsForStage(s.index),
        onPlay: () {
          Navigator.of(context).pop();
          _playStage(context, app, s);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int totalStars, cleared;
  final bool showBack;
  const _Header({required this.totalStars, required this.cleared, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(showBack ? 6 : 18, 8, 14, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.bg0.withOpacity(0.85), Palette.bg0.withOpacity(0.0)],
          ),
        ),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Palette.cream),
              ),
            const Expanded(
              child: DisplayText('Perjalanan', size: 22, weight: 700, align: TextAlign.left),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Palette.panel.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Palette.gold.withOpacity(0.45)),
                boxShadow: Palette.glow(Palette.gold, blur: 12, a: 0.18),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: Palette.gold, size: 18),
                const SizedBox(width: 5),
                Text('$totalStars/${StageCatalog.count * 3}',
                    style: const TextStyle(color: Palette.gold, fontWeight: FontWeight.w900)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// A region ribbon marking the start of a new island in the journey.
class _RegionRibbon extends StatelessWidget {
  final String region;
  final double height;
  const _RegionRibbon({required this.region, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _line(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.place_rounded, color: Palette.goldSoft, size: 16),
                const SizedBox(width: 6),
                Text(region.toUpperCase(),
                    style: const TextStyle(
                        color: Palette.cream,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2)),
              ]),
            ),
            _line(),
          ],
        ),
      ),
    );
  }

  Widget _line() => Container(
        width: 34,
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Palette.gold.withOpacity(0), Palette.gold.withOpacity(0.6)]),
        ),
      );
}

/// One stop on the trail: the gold node + heirloom label to the opposite side.
class _NodeStop extends StatefulWidget {
  final StageSpec spec;
  final double cx, width;
  final bool unlocked, isCurrent;
  final int stars;
  final VoidCallback? onTap;
  const _NodeStop({
    required this.spec,
    required this.cx,
    required this.width,
    required this.unlocked,
    required this.isCurrent,
    required this.stars,
    this.onTap,
  });

  @override
  State<_NodeStop> createState() => _NodeStopState();
}

class _NodeStopState extends State<_NodeStop> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const node = 74.0;
    final w = widget.spec;
    final locked = !widget.unlocked;
    final accent = locked ? Palette.goldSoft : w.accent;
    final labelLeft = widget.cx > widget.width / 2;
    final cy = _AdventureMapScreenState._rowH * 0.36;

    final label = _NodeLabel(spec: w, locked: locked, stars: widget.stars, alignEnd: labelLeft);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: cy - 34,
            left: labelLeft ? 14 : widget.cx + node / 2 + 10,
            right: labelLeft ? widget.width - (widget.cx - node / 2) + 10 : 14,
            child: label,
          ),
          Positioned(
            left: widget.cx - node / 2,
            top: cy - node / 2,
            width: node,
            height: node,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) {
                final glow = widget.isCurrent ? (0.3 + _pulse.value * 0.55) : 0.22;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: locked
                          ? [Palette.panel, Palette.bg1]
                          : [Color.lerp(accent, Colors.white, 0.28)!, accent],
                    ),
                    border: Border.all(
                        color: widget.isCurrent ? Palette.goldLt : Palette.gold.withOpacity(0.65),
                        width: widget.isCurrent ? 3 : 2),
                    boxShadow: locked
                        ? null
                        : [BoxShadow(color: accent.withOpacity(glow), blurRadius: 22, spreadRadius: 1)],
                  ),
                  child: child,
                );
              },
              child: Center(
                child: locked
                    ? const Icon(Icons.lock_rounded, color: Palette.goldSoft, size: 24)
                    : widget.stars > 0
                        ? Icon(w.goal.icon, color: Palette.ink, size: 26)
                        : Text('${w.index}',
                            style: const TextStyle(
                                color: Palette.ink, fontSize: 24, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeLabel extends StatelessWidget {
  final StageSpec spec;
  final bool locked, alignEnd;
  final int stars;
  const _NodeLabel({
    required this.spec,
    required this.locked,
    required this.stars,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final align = alignEnd ? TextAlign.right : TextAlign.left;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: [
        Text('BABAK ${spec.index}',
            textAlign: align,
            style: TextStyle(
                color: Palette.goldSoft.withOpacity(locked ? 0.5 : 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 1),
        Text(locked ? '???' : spec.title,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: locked ? Palette.cream.withOpacity(0.4) : Palette.cream,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        if (!locked)
          Row(
            mainAxisAlignment:
                alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: List.generate(
              3,
              (s) => Icon(
                s < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: s < stars ? Palette.gold : Palette.goldSoft.withOpacity(0.45),
              ),
            ),
          )
        else
          Icon(Icons.lock_outline_rounded,
              size: 14, color: Palette.goldSoft.withOpacity(0.5)),
      ],
    );
  }
}

/// Pre-game sheet: heirloom, region, song, objective, mode and best stars.
class _StageSheet extends StatelessWidget {
  final StageSpec spec;
  final int stars;
  final VoidCallback onPlay;
  const _StageSheet({required this.spec, required this.stars, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Palette.panel, Palette.bg1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: spec.accent.withOpacity(0.6), width: 1.5),
        boxShadow: Palette.glow(spec.accent, blur: 36, a: 0.32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: spec.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('BABAK ${spec.index} • ${spec.region.toUpperCase()}',
                style: TextStyle(
                    color: spec.accent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          const SizedBox(height: 12),
          DisplayText(spec.title, size: 24, weight: 700),
          const SizedBox(height: 6),
          Text(spec.motif,
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.cream.withOpacity(0.65), fontSize: 13, height: 1.35)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (s) => Icon(
                s < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 26,
                color: s < stars ? Palette.gold : Palette.goldSoft.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Palette.bg1.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.gold.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(spec.goal.icon, color: Palette.gold, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(spec.goal.label(spec.target),
                    style: const TextStyle(
                        color: Palette.cream, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(Icons.music_note_rounded, spec.song.title, spec.accent),
              _Chip(Icons.speed_rounded, kModeParams[spec.mode]!.label, Palette.teal),
              _Chip(Icons.monetization_on_rounded, '+${spec.coins}', Palette.gold),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(stars > 0 ? 'Main Lagi' : 'Mulai Babak'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final List<Offset> centers;
  final int unlocked; // highest unlocked stage (1-based)
  _TrailPainter({required this.centers, required this.unlocked});

  Path _build(int from, int to) {
    final p = Path()..moveTo(centers[from].dx, centers[from].dy);
    for (var i = from; i < to; i++) {
      final a = centers[i], b = centers[i + 1];
      final midY = (a.dy + b.dy) / 2;
      p.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    canvas.drawPath(
      _build(0, centers.length - 1),
      Paint()
        ..color = Palette.gold.withOpacity(0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    final litTo = (unlocked - 1).clamp(0, centers.length - 1);
    if (litTo > 0) {
      canvas.drawPath(
        _build(0, litTo),
        Paint()
          ..color = Palette.gold.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        _build(0, litTo),
        Paint()
          ..color = Palette.goldLt
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var i = 0; i < litTo; i++) {
      final mid = Offset((centers[i].dx + centers[i + 1].dx) / 2,
          (centers[i].dy + centers[i + 1].dy) / 2);
      canvas.drawCircle(mid, 3, Paint()..color = Palette.goldLt.withOpacity(0.8));
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.unlocked != unlocked || old.centers.length != centers.length;
}
