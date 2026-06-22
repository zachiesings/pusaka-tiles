import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/achievements.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';
import '../../widgets/soft_card.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final done = kAchievements.where((a) => a.met(app)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Pencapaian')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Text('$done / ${kAchievements.length} terbuka',
                    style: TextStyle(
                        color: Palette.cream.withOpacity(0.7),
                        fontSize: 14,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 14),
              ...kAchievements.map((a) {
                final unlocked = a.met(app);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SoftCard(
                    glow: unlocked ? Palette.gold : null,
                    child: Opacity(
                      opacity: unlocked ? 1 : 0.5,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: unlocked ? Palette.brand : null,
                              color: unlocked ? null : Palette.panel,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(unlocked ? a.icon : Icons.lock_rounded,
                                color: unlocked ? Palette.ink : Palette.goldSoft, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title,
                                    style: const TextStyle(
                                        color: Palette.cream,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                Text(a.desc,
                                    style: TextStyle(
                                        color: Palette.cream.withOpacity(0.6), fontSize: 12)),
                              ],
                            ),
                          ),
                          if (unlocked)
                            const Icon(Icons.check_circle_rounded, color: Palette.gold),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
