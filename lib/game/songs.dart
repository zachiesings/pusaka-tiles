import 'models/song.dart';

/// Folk/children's songs transcribed from published not-angka (do=1=index3).
/// Each note carries a duration in beats → real rhythm (held notes at phrase
/// ends), not a constant pulse. Public-domain tunes; tones synthesized.
class SongCatalog {
  SongCatalog._();

  static const List<Song> all = <Song>[
    // Gundul-Gundul Pacul — 1 3 1 3 4 5 5 / 7 1'7 1'7 5 / ... (Jawa Tengah)
    Song(
      id: 'gundul',
      title: 'Gundul-Gundul Pacul',
      daerah: 'Jawa Tengah',
      bpm: 104,
      speedScale: 1.05,
      notes: [3,5,3,5,6,7,7, 9,10,9,10,9,7, 3,5,3,5,6,7,7, 9,10,9,10,9,7, 3,5,7,6,6,7,6,5,3,6,5,3],
      beats: [1,1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,1,1,1,1,1,1,2],
    ),
    // Burung Kakak Tua — 5 5 3 1 3 2 / 3 4 6 5 4 3 / 5 5 3 1 3 2 / 7 6 5 4 3 2 1 (Maluku)
    Song(
      id: 'kakaktua',
      title: 'Burung Kakak Tua',
      daerah: 'Maluku',
      bpm: 100,
      speedScale: 1.0,
      notes: [7,7,5,3,5,4, 5,6,8,7,6,5, 7,7,5,3,5,4, 9,8,7,6,5,4,3],
      beats: [1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,1,2],
    ),
    // Cicak-Cicak di Dinding — 5 3 5 3 3 4 5 / 4 2 4 6 5 4 3 / 6 4 6 4 6 7 1' / 1' 5 4 3 2 1
    Song(
      id: 'cicak',
      title: 'Cicak-Cicak di Dinding',
      daerah: 'Lagu Anak Nusantara',
      bpm: 96,
      speedScale: 0.95,
      notes: [7,5,7,5,5,6,7, 6,4,6,8,7,6,5, 8,6,8,6,8,9,10, 10,7,6,5,4,3],
      beats: [1,1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,2],
    ),
    // Ampar-Ampar Pisang — 5 1 1 7, 1 2 / 5 5 2 2 1 2 3 / 4 2 2 3 1 1 2 2 1 7, 1 (Kalsel)
    Song(
      id: 'ampar',
      title: 'Ampar-Ampar Pisang',
      daerah: 'Kalimantan Selatan',
      bpm: 108,
      speedScale: 1.1,
      notes: [7,3,3,2,3,4, 7,7,4,4,3,4,5, 6,4,4,5,3,3,4,4,3,2,3],
      beats: [1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,1,1,1,1,1,2],
    ),
    // Cublak-Cublak Suweng — dolanan Jawa Tengah (notasi angka, frasa berulang)
    Song(
      id: 'cublak',
      title: 'Cublak-Cublak Suweng',
      daerah: 'Jawa Tengah',
      bpm: 100,
      speedScale: 1.0,
      notes: [7,7,4,5, 3,4,5,3, 4,7,5,4, 3,4,5,3],
      beats: [1,1,1,2, 1,1,1,2, 1,1,1,2, 1,1,1,2],
    ),
  ];

  static Song byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
