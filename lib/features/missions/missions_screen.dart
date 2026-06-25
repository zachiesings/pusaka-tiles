import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/missions.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';
import '../../widgets/soft_card.dart';

/// Daily missions + the player's level/XP. Missions auto-reward on completion,
/// so this screen is a progress board — no claim buttons to forget.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final missions = app.missions;
    final progress = app.missionProgress;
    return Scaffold(
      appBar: AppBar(title: const Text('Misi Harian')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ----- Level / XP -----
              SoftCard(
                glow: Palette.gold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.military_tech_rounded, color: Palette.gold),
                      const SizedBox(width: 10),
                      Text('Level ${app.level}',
                          style: const TextStyle(
                              color: Palette.cream,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      const Spacer(),
                      Text('${app.xpIntoLevel} / ${app.xpForNextLevel} XP',
                          style: TextStyle(
                              color: Palette.cream.withOpacity(0.6), fontSize: 12)),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: app.levelProgress,
                        minHeight: 9,
                        backgroundColor: Palette.panel,
                        color: Palette.gold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                const Icon(Icons.flag_rounded, color: Palette.gold, size: 18),
                const SizedBox(width: 8),
                const Text('Misi Hari Ini',
                    style: TextStyle(
                        color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('Reset tiap hari',
                    style: TextStyle(color: Palette.cream.withOpacity(0.45), fontSize: 11)),
              ]),
              const SizedBox(height: 10),
              for (var i = 0; i < missions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MissionTile(
                    mission: missions[i],
                    progress: i < progress.length ? progress[i] : 0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final Mission mission;
  final int progress;
  const _MissionTile({required this.mission, required this.progress});

  @override
  Widget build(BuildContext context) {
    final done = progress >= mission.target;
    final frac = mission.target == 0 ? 0.0 : (progress / mission.target).clamp(0.0, 1.0);
    return SoftCard(
      glow: done ? Palette.teal : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: done ? Palette.teal : Palette.goldSoft, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(mission.label,
                  style: TextStyle(
                      color: Palette.cream,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: done ? TextDecoration.lineThrough : null)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Palette.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('+${mission.rewardCoins}🪙 +${mission.rewardXp}XP',
                  style: const TextStyle(
                      color: Palette.goldLt, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 6,
                  backgroundColor: Palette.panel,
                  color: done ? Palette.teal : Palette.gold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$progress/${mission.target}',
                style: TextStyle(
                    color: Palette.cream.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}
