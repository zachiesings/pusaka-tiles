import 'package:flutter/material.dart';
import '../state/app_state.dart';

/// Achievement derived live from persisted stats (no extra state to sync).
class Achievement {
  final String title;
  final String desc;
  final IconData icon;
  final bool Function(AppState) met;
  const Achievement(this.title, this.desc, this.icon, this.met);
}

const List<Achievement> kAchievements = [
  Achievement('Penabuh Pertama', 'Raih bintang di 1 lagu', Icons.star_rounded, _any1),
  Achievement('Tiga Bintang', 'Raih 3 bintang di 1 lagu', Icons.auto_awesome_rounded, _three1),
  Achievement('Penjelajah Lagu', 'Raih bintang di 5 lagu', Icons.explore_rounded, _any5),
  Achievement('Maestro Nusantara', 'Raih 3 bintang di SEMUA lagu', Icons.workspace_premium_rounded, _threeAll),
  Achievement('Combo 25', 'Capai combo 25', Icons.bolt_rounded, _combo25),
  Achievement('Combo 50', 'Capai combo 50', Icons.local_fire_department_rounded, _combo50),
  Achievement('Combo 100', 'Capai combo 100', Icons.emoji_events_rounded, _combo100),
];

bool _any1(AppState a) => a.songsWithAnyStar >= 1;
bool _three1(AppState a) => a.songsWithThreeStars >= 1;
bool _any5(AppState a) => a.songsWithAnyStar >= 5;
bool _threeAll(AppState a) => a.songsWithThreeStars >= a.totalSongs;
bool _combo25(AppState a) => a.bestCombo >= 25;
bool _combo50(AppState a) => a.bestCombo >= 50;
bool _combo100(AppState a) => a.bestCombo >= 100;
