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
    TileTheme(
      id: 'batiktulis',
      name: 'Batik Tulis',
      desc: 'Sogan & nila klasik tulisan tangan.',
      cost: 750,
      colors: [Color(0xFF8A4B2F), Color(0xFF2C4A6E), Color(0xFFC8923A), Color(0xFF5E6B3A)],
    ),
    TileTheme(
      id: 'senja',
      name: 'Senja Nusantara',
      desc: 'Gradasi jingga–ungu langit senja.',
      cost: 900,
      colors: [Color(0xFFE8693C), Color(0xFFC9456E), Color(0xFF7E55C6), Color(0xFFF2A24B)],
    ),
    TileTheme(
      id: 'candi',
      name: 'Candi Purba',
      desc: 'Batu candi, lumut, & emas kuno.',
      cost: 1100,
      colors: [Color(0xFF6E7468), Color(0xFF3F7A6A), Color(0xFFB59A52), Color(0xFF4A4A42)],
    ),
    TileTheme(
      id: 'rimba',
      name: 'Rimba Zamrud',
      desc: 'Hijau hutan tropis yang rimbun.',
      cost: 1300,
      colors: [Color(0xFF2E8B57), Color(0xFF1F6E4A), Color(0xFF7FBF4D), Color(0xFF0F4D3A)],
    ),
    TileTheme(
      id: 'naga',
      name: 'Naga Merah',
      desc: 'Merah keraton, emas, & arang.',
      cost: 1600,
      colors: [Color(0xFFC02A36), Color(0xFFE0A93A), Color(0xFF7A1F2B), Color(0xFF2A2226)],
    ),
    TileTheme(
      id: 'kristal',
      name: 'Kristal Es',
      desc: 'Sian beku, putih, & nila kristal.',
      cost: 2000,
      colors: [Color(0xFF53C6D4), Color(0xFFEAF6FF), Color(0xFF6C7BD6), Color(0xFF2E7C8A)],
    ),
  ];

  static TileTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}
