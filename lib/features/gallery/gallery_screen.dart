import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/motifs.dart';
import '../../game/songs.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';
import '../../widgets/batik_motif.dart';

/// "Koleksi Pusaka" — the motif gallery. Clear a song with grade A or better to
/// unlock its signature motif; tap an unlocked motif to equip it as the
/// background theme. Locked motifs show as silhouettes with their unlock hint.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final motifs = MotifCatalog.all;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koleksi Pusaka'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${app.unlockedMotifCount}/${app.totalMotifs}',
                  style: const TextStyle(
                      color: Palette.gold, fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: BatikBackground(
        child: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: motifs.length,
            itemBuilder: (context, i) {
              final m = motifs[i];
              final unlocked = app.motifUnlocked(m.songId);
              final equipped = app.isMotifEquipped(m.songId);
              final title = SongCatalog.byId(m.songId).title;
              return GestureDetector(
                onTap: () {
                  if (unlocked) {
                    app.equipMotif(m.songId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(app.isMotifEquipped(m.songId)
                            ? 'Motif ${m.daerah} terpasang'
                            : 'Motif dilepas'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Juarai "$title" dengan grade A untuk membuka'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Palette.panel.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: equipped
                          ? Palette.gold
                          : (unlocked ? m.color.withOpacity(0.5) : Palette.gridLine),
                      width: equipped ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: unlocked
                            ? BatikMotifView(
                                color: m.color,
                                petals: m.petals,
                                rings: m.rings,
                                size: 64)
                            : Icon(Icons.lock_rounded,
                                color: Palette.gridLine.withOpacity(0.9), size: 30),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unlocked ? m.daerah : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: unlocked
                                ? Palette.cream
                                : Palette.cream.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        equipped
                            ? 'Terpasang ✓'
                            : unlocked
                                ? 'Ketuk untuk pasang'
                                : 'Terkunci',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: equipped
                                ? Palette.gold
                                : Palette.cream.withOpacity(0.35),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
