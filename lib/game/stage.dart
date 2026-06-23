import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'game_mode.dart';
import 'models/song.dart';
import 'songs.dart';

/// The kind of objective a campaign stage asks of the player. All four map
/// directly onto metrics the rhythm engine already tracks, so any song can host
/// any goal.
enum StageGoal {
  score, // reach a target score in one run
  combo, // reach a combo streak of N
  perfect, // land N Perfect-timed taps
  fullsong, // play the whole song through (Lagu Penuh) — graded
}

extension StageGoalX on StageGoal {
  IconData get icon {
    switch (this) {
      case StageGoal.score:
        return Icons.stars_rounded;
      case StageGoal.combo:
        return Icons.bolt_rounded;
      case StageGoal.perfect:
        return Icons.ads_click_rounded;
      case StageGoal.fullsong:
        return Icons.flag_rounded;
    }
  }

  String label(int target) {
    switch (this) {
      case StageGoal.score:
        return 'Raih skor $target';
      case StageGoal.combo:
        return 'Capai combo ×$target';
      case StageGoal.perfect:
        return 'Kena $target Perfect';
      case StageGoal.fullsong:
        return 'Tamatkan lagunya';
    }
  }

  String get short {
    switch (this) {
      case StageGoal.score:
        return 'Skor';
      case StageGoal.combo:
        return 'Combo';
      case StageGoal.perfect:
        return 'Perfect';
      case StageGoal.fullsong:
        return 'Penuh';
    }
  }
}

/// One campaign stage: a *pusaka* (heirloom) earned by performing a regional folk
/// song to a target, with a play mode, a coin reward, and a node colour.
@immutable
class StageSpec {
  final int index; // 1..20
  final String songId;
  final String region;
  final String title; // the heirloom being claimed
  final String motif; // a one-line flavour blurb
  final StageGoal goal;
  final int target;
  final GameMode mode;
  final int coins; // reward on first completion
  final Color accent; // node colour on the map

  const StageSpec({
    required this.index,
    required this.songId,
    required this.region,
    required this.title,
    required this.motif,
    required this.goal,
    required this.target,
    required this.mode,
    required this.coins,
    required this.accent,
  });

  Song get song => SongCatalog.byId(songId);

  /// Stars (0..3) earned for a finished run. 0 = goal not met (stage failed).
  /// 1 = met; 2 = met comfortably; 3 = mastered.
  int starsFor({
    required int points,
    required int bestCombo,
    required int perfects,
    required int total,
    required bool completed,
    required String grade,
  }) {
    switch (goal) {
      case StageGoal.score:
        if (points >= (target * 1.6).round()) return 3;
        if (points >= (target * 1.25).round()) return 2;
        if (points >= target) return 1;
        return 0;
      case StageGoal.combo:
        if (bestCombo >= target + 8) return 3;
        if (bestCombo >= target + 4) return 2;
        if (bestCombo >= target) return 1;
        return 0;
      case StageGoal.perfect:
        if (perfects >= target + 8) return 3;
        if (perfects >= target + 4) return 2;
        if (perfects >= target) return 1;
        return 0;
      case StageGoal.fullsong:
        if (!completed) return 0;
        if (grade == 'S') return 3;
        if (grade == 'A') return 2;
        return 1;
    }
  }
}

/// The 20-stage "Perjalanan Nusantara" campaign — a crafted journey west→east
/// across the archipelago. Early stages ease the player in (Santai/Klasik,
/// modest targets); the middle introduces combo & Perfect mastery; the back ten
/// demand full graded run-throughs at Cepat tempo.
class StageCatalog {
  StageCatalog._();

  static const _i = Palette.indigo;
  static const _v = Palette.violet;
  static const _t = Palette.teal;
  static const _p = Palette.pink;
  static const _c = Palette.cyan;
  static const _g = Palette.gold;

  static const List<StageSpec> all = <StageSpec>[
    StageSpec(index: 1, songId: 'cicak', region: 'Lagu Anak', title: 'Genta Pembuka', motif: 'Ketukan pertama — kenali iramanya pelan-pelan.', goal: StageGoal.score, target: 300, mode: GameMode.santai, coins: 15, accent: _i),
    StageSpec(index: 2, songId: 'jalijali', region: 'DKI Jakarta', title: 'Kroncong Betawi', motif: 'Petik gambang Jali-Jali, rapikan ketukmu.', goal: StageGoal.perfect, target: 6, mode: GameMode.santai, coins: 18, accent: _v),
    StageSpec(index: 3, songId: 'gundul', region: 'Jawa Tengah', title: 'Pacul Tembaga', motif: 'Gundul-gundul pacul — jaga tempo gendingnya.', goal: StageGoal.score, target: 600, mode: GameMode.klasik, coins: 22, accent: _t),
    StageSpec(index: 4, songId: 'cublak', region: 'Jawa Tengah', title: 'Suweng Permata', motif: 'Cublak-cublak suweng, rangkai combo pertama.', goal: StageGoal.combo, target: 8, mode: GameMode.klasik, coins: 24, accent: _i),
    StageSpec(index: 5, songId: 'soleram', region: 'Riau', title: 'Selendang Melayu', motif: 'Soleram mengalun lembut — kejar Perfect.', goal: StageGoal.perfect, target: 10, mode: GameMode.klasik, coins: 28, accent: _p),
    StageSpec(index: 6, songId: 'bungong', region: 'Aceh', title: 'Bungong Jeumpa', motif: 'Kembang cempaka Serambi Mekkah, mainkan utuh.', goal: StageGoal.fullsong, target: 0, mode: GameMode.penuh, coins: 36, accent: _v),
    StageSpec(index: 7, songId: 'ampar', region: 'Kalimantan Selatan', title: 'Pisang Saba', motif: 'Ampar-ampar pisang — ketukan makin rapat.', goal: StageGoal.score, target: 1000, mode: GameMode.klasik, coins: 32, accent: _t),
    StageSpec(index: 8, songId: 'sipatokaan', region: 'Sulawesi Utara', title: 'Kolintang Minahasa', motif: 'Si Patokaan melompat — sambung combo panjang.', goal: StageGoal.combo, target: 14, mode: GameMode.klasik, coins: 36, accent: _c),
    StageSpec(index: 9, songId: 'kambing', region: 'Nusa Tenggara Timur', title: 'Sasando Flobamora', motif: 'Anak kambing saya — irama lincah, fokus Perfect.', goal: StageGoal.perfect, target: 16, mode: GameMode.klasik, coins: 40, accent: _i),
    StageSpec(index: 10, songId: 'kakaktua', region: 'Maluku', title: 'Tifa Nunsaku', motif: 'Burung kakak tua — tamatkan dengan anggun.', goal: StageGoal.fullsong, target: 0, mode: GameMode.penuh, coins: 55, accent: _g),
    StageSpec(index: 11, songId: 'bebek', region: 'Nusa Tenggara Timur', title: 'Angsa Sawu', motif: 'Potong bebek angsa — tempo cepat, jaga skor.', goal: StageGoal.score, target: 1500, mode: GameMode.cepat, coins: 46, accent: _p),
    StageSpec(index: 12, songId: 'naikgunung', region: 'Maluku', title: 'Puncak Cengkih', motif: 'Naik-naik ke puncak — combo tanpa putus.', goal: StageGoal.combo, target: 20, mode: GameMode.klasik, coins: 50, accent: _t),
    StageSpec(index: 13, songId: 'rasasayange', region: 'Maluku', title: 'Rasa Sayange', motif: 'Lagu cinta Nusantara — bukti penguasaan Perfect.', goal: StageGoal.perfect, target: 22, mode: GameMode.klasik, coins: 54, accent: _v),
    StageSpec(index: 14, songId: 'apuse', region: 'Papua', title: 'Apuse Kokon Dao', motif: 'Apuse — lambaian dari Tanah Cendrawasih, mainkan utuh.', goal: StageGoal.fullsong, target: 0, mode: GameMode.penuh, coins: 64, accent: _c),
    StageSpec(index: 15, songId: 'soleram', region: 'Riau', title: 'Bintang Selat', motif: 'Soleram lagi — kini di tempo Cepat.', goal: StageGoal.score, target: 2000, mode: GameMode.cepat, coins: 58, accent: _i),
    StageSpec(index: 16, songId: 'sipatokaan', region: 'Sulawesi Utara', title: 'Maengket Agung', motif: 'Si Patokaan ngebut — combo besar di tempo Cepat.', goal: StageGoal.combo, target: 26, mode: GameMode.cepat, coins: 66, accent: _p),
    StageSpec(index: 17, songId: 'gundul', region: 'Jawa Tengah', title: 'Gamelan Sekati', motif: 'Gundul pacul versi juara — kuasai setiap ketuk.', goal: StageGoal.perfect, target: 28, mode: GameMode.cepat, coins: 70, accent: _t),
    StageSpec(index: 18, songId: 'yamko', region: 'Papua', title: 'Yamko Rambe', motif: 'Genderang perang Papua — tamatkan di tempo penuh.', goal: StageGoal.fullsong, target: 0, mode: GameMode.penuh, coins: 82, accent: _v),
    StageSpec(index: 19, songId: 'kambing', region: 'Nusa Tenggara Timur', title: 'Pusaka Flobamora', motif: 'Anak kambing ujian — combo maraton tiada henti.', goal: StageGoal.combo, target: 32, mode: GameMode.cepat, coins: 90, accent: _c),
    StageSpec(index: 20, songId: 'rasasayange', region: 'Nusantara', title: 'Pusaka Agung Nusantara', motif: 'Mahkota seluruh negeri — tamatkan sempurna, raih grade S.', goal: StageGoal.fullsong, target: 0, mode: GameMode.penuh, coins: 150, accent: _g),
  ];

  static const int count = 20;

  static StageSpec byIndex(int index) =>
      all.firstWhere((s) => s.index == index, orElse: () => all.first);
}
