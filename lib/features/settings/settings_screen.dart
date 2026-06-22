import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';
import '../../widgets/soft_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Column(
                  children: [
                    _toggle(Icons.music_note_rounded, 'Musik', 'BGM gamelan di beranda',
                        app.music, app.setMusic),
                    _divider(),
                    _toggle(Icons.volume_up_rounded, 'Suara & Nada', 'Nada lagu daerah saat mengetuk',
                        app.sound, app.setSound),
                    _divider(),
                    _toggle(Icons.vibration_rounded, 'Getaran', 'Umpan-balik getar (haptic)',
                        app.haptics, app.setHaptics),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                glow: Palette.teal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.music_note_rounded, color: Palette.gold),
                      SizedBox(width: 10),
                      Text('Instrumen',
                          style: TextStyle(
                              color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
                    Padding(
                      padding: const EdgeInsets.only(left: 34, bottom: 8),
                      child: Text('Mainkan lagu dengan suara tradisional',
                          style: TextStyle(color: Palette.cream.withOpacity(0.5), fontSize: 12)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: K.instruments.map((e) {
                        final sel = app.instrument == e.key;
                        return GestureDetector(
                          onTap: () => app.setInstrument(e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: sel ? Palette.teal : Palette.panelHi.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: sel ? Palette.teal : Palette.gold.withOpacity(0.2)),
                            ),
                            child: Text(e.value,
                                style: TextStyle(
                                    color: sel ? Palette.ink : Palette.cream,
                                    fontWeight: FontWeight.w700)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                glow: Palette.violet,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Palette.gold),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cara Bermain',
                              style: TextStyle(
                                  color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                              'Ketuk ubin berwarna paling bawah sesuai lajurnya, ikuti irama. '
                              'Jangan meleset atau terlewat! Tiap ketukan memainkan nada lagu daerah.',
                              style: TextStyle(color: Palette.cream.withOpacity(0.6), height: 1.4)),
                        ],
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

  Widget _divider() => Divider(color: Palette.cream.withOpacity(0.08), height: 1, indent: 16, endIndent: 16);

  Widget _toggle(IconData icon, String title, String sub, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: Palette.violet,
        activeTrackColor: Palette.indigo,
        secondary: Icon(icon, color: Palette.gold),
        title: Text(title,
            style: const TextStyle(color: Palette.cream, fontWeight: FontWeight.w700)),
        subtitle: Text(sub, style: TextStyle(color: Palette.cream.withOpacity(0.5), fontSize: 12)),
      );
}
