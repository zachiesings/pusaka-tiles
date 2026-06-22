import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/tile_themes.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';
import '../../widgets/soft_card.dart';

/// Buy & equip tile colour themes with coins earned by playing.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Tema'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              const Icon(Icons.monetization_on, color: Palette.gold, size: 20),
              const SizedBox(width: 6),
              Text('${app.coins}',
                  style: const TextStyle(
                      color: Palette.gold, fontWeight: FontWeight.w900, fontSize: 16)),
            ]),
          ),
        ],
      ),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ...TileThemeCatalog.all.map((t) {
                final unlocked = app.isThemeUnlocked(t.id);
                final equipped = app.selectedTheme == t.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SoftCard(
                    glow: equipped ? t.colors.first : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // colour swatches
                            ...t.colors.map((c) => Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: c,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: Palette.glow(c, blur: 8, a: 0.5),
                                  ),
                                )),
                            const Spacer(),
                            if (!unlocked)
                              Row(children: [
                                const Icon(Icons.monetization_on, color: Palette.gold, size: 16),
                                const SizedBox(width: 4),
                                Text('${t.cost}',
                                    style: const TextStyle(
                                        color: Palette.gold, fontWeight: FontWeight.w800)),
                              ]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(t.name,
                            style: const TextStyle(
                                color: Palette.cream, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(t.desc,
                            style: TextStyle(color: Palette.cream.withOpacity(0.6), fontSize: 13)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: equipped
                                ? null
                                : () {
                                    if (unlocked) {
                                      app.selectTheme(t.id);
                                    } else {
                                      final ok = app.buyTheme(t);
                                      if (!ok) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Koin belum cukup — main lagi dulu!')),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  equipped ? Palette.panelHi : (unlocked ? Palette.teal : Palette.violet),
                            ),
                            child: Text(equipped
                                ? 'Terpasang ✓'
                                : unlocked
                                    ? 'Pasang'
                                    : 'Beli'),
                          ),
                        ),
                      ],
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
