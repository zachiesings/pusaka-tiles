import 'models/song.dart';

/// Catalog of traditional Indonesian folk/children's melodies, transcribed to
/// the diatonic note table (do=3). All are public-domain tunes. Sequences loop.
class SongCatalog {
  SongCatalog._();

  static const List<Song> all = <Song>[
    Song(
      id: 'cicak',
      title: 'Cicak-Cicak di Dinding',
      daerah: 'Lagu Anak — Nusantara',
      speedScale: 1.0,
      // do do do re mi mi | re re re mi do | sol sol sol fa mi | mi re re do
      notes: [3, 3, 3, 4, 5, 5, 4, 4, 4, 5, 3, 7, 7, 7, 6, 5, 5, 4, 4, 3],
    ),
    Song(
      id: 'kakaktua',
      title: 'Burung Kakak Tua',
      daerah: 'Maluku',
      speedScale: 1.05,
      notes: [7, 5, 5, 6, 4, 4, 5, 3, 3, 4, 5, 6, 7, 7, 8, 7, 6, 5, 6, 6, 7, 6, 5, 4],
    ),
    Song(
      id: 'ampar',
      title: 'Ampar-Ampar Pisang',
      daerah: 'Kalimantan Selatan',
      speedScale: 1.15,
      notes: [3, 4, 5, 5, 5, 6, 7, 7, 7, 8, 7, 6, 5, 6, 5, 4, 3, 3, 4, 5, 6, 7, 5],
    ),
    Song(
      id: 'cublak',
      title: 'Cublak-Cublak Suweng',
      daerah: 'Jawa Tengah',
      speedScale: 1.1,
      notes: [3, 3, 4, 5, 5, 5, 4, 3, 7, 7, 8, 7, 5, 4, 5, 4, 3, 3, 4, 5, 7, 8, 7],
    ),
    Song(
      id: 'gundul',
      title: 'Gundul-Gundul Pacul',
      daerah: 'Jawa Tengah',
      speedScale: 1.2,
      notes: [7, 7, 5, 7, 8, 7, 5, 4, 3, 3, 4, 5, 5, 4, 3, 4, 3, 5, 7, 8, 7, 5],
    ),
    Song(
      id: 'cikcik',
      title: 'Cik-Cik Periuk',
      daerah: 'Kalimantan Barat',
      speedScale: 1.25,
      notes: [5, 5, 6, 5, 3, 5, 5, 6, 5, 3, 6, 6, 7, 6, 4, 5, 4, 3, 3, 5, 6, 7, 8],
    ),
  ];

  static Song byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
