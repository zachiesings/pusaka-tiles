import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';

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
              SwitchListTile(
                value: app.sound,
                onChanged: app.setSound,
                activeColor: Palette.gold,
                title: const Text('Musik & Suara', style: TextStyle(color: Palette.cream)),
                subtitle: const Text('Nada lagu daerah saat mengetuk ubin',
                    style: TextStyle(color: Palette.goldSoft)),
              ),
              SwitchListTile(
                value: app.haptics,
                onChanged: app.setHaptics,
                activeColor: Palette.gold,
                title: const Text('Getaran', style: TextStyle(color: Palette.cream)),
                subtitle: const Text('Umpan-balik getar (haptic)',
                    style: TextStyle(color: Palette.goldSoft)),
              ),
              const Divider(color: Palette.gridLine, height: 32),
              const ListTile(
                leading: Icon(Icons.lightbulb_outline, color: Palette.gold),
                title: Text('Cara Bermain', style: TextStyle(color: Palette.cream)),
                subtitle: Text(
                    'Ketuk ubin berwarna paling bawah sesuai lajurnya. Jangan sampai '
                    'meleset atau terlewat! Tiap ketukan memainkan nada lagu daerah.',
                    style: TextStyle(color: Palette.goldSoft)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
