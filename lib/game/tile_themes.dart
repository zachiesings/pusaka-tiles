import 'package:flutter/material.dart';
import '../core/constants.dart';

/// A buyable set of 4 lane colors for the tiles. Mirrors Blast's batik skins.
class TileTheme {
  final String id;
  final String name;
  final String desc;
  final int cost;
  final List<Color> colors;
  const TileTheme({
    required this.id,
    required this.name,
    required this.desc,
    required this.cost,
    required this.colors,
  });

  /// The currently-equipped lane colors (read by the board + song cards).
  static List<Color> active = Palette.laneColors;
}

class TileThemeCatalog {
  static const List<TileTheme> all = [
    TileTheme(
      id: 'klasik',
      name: 'Panggung Malam',
      desc: 'Warna asli — nila, giok, merah jambu, sian.',
      cost: 0,
      colors: [Color(0xFF5B4BC4), Color(0xFF2FA987), Color(0xFFE76A93), Color(0xFF45C6D4)],
    ),
    TileTheme(
      id: 'emas',
      name: 'Kencana Emas',
      desc: 'Gradasi emas keraton yang mewah.',
      cost: 300,
      colors: [Color(0xFFF2B73C), Color(0xFFE0913A), Color(0xFFD9A636), Color(0xFFF2C75B)],
    ),
    TileTheme(
      id: 'pelangi',
      name: 'Pelangi Nusantara',
      desc: 'Empat warna ceria penuh semangat.',
      cost: 450,
      colors: [Color(0xFFE8643C), Color(0xFF49A6D6), Color(0xFF6BBF59), Color(0xFFE0B84E)],
    ),
    TileTheme(
      id: 'samudra',
      name: 'Samudra',
      desc: 'Biru laut dalam yang menenangkan.',
      cost: 600,
      colors: [Color(0xFF1E5A8A), Color(0xFF2FA987), Color(0xFF3A8FC4), Color(0xFF14406A)],
    ),
  ];

  static TileTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}
