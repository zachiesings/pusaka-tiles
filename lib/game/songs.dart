import 'models/song.dart';

/// Folk/children's songs transcribed from published not-angka (do=1=index3).
/// notes[] are pitch indices; beats[] is a repeating rhythm pattern (the engine
/// cycles it independently, giving a non-robotic groove). Public-domain tunes,
/// synthesized tones. Low octave: 5,=0 6,=1 7,=2.
class SongCatalog {
  SongCatalog._();

  static const List<Song> all = <Song>[
    Song(
      id: 'gundul', title: 'Gundul-Gundul Pacul', daerah: 'Jawa Tengah',
      bpm: 104, speedScale: 1.05,
      notes: [3,5,3,5,6,7,7, 9,10,9,10,9,7, 3,5,3,5,6,7,7, 9,10,9,10,9,7, 3,5,7,6,6,7,6,5,3,6,5,3],
      beats: [1,1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,1,1,1,1,1,1,2],
    ),
    Song(
      id: 'kakaktua', title: 'Burung Kakak Tua', daerah: 'Maluku',
      bpm: 100, speedScale: 1.0,
      notes: [7,7,5,3,5,4, 5,6,8,7,6,5, 7,7,5,3,5,4, 9,8,7,6,5,4,3],
      beats: [1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,2, 1,1,1,1,1,1,2],
    ),
    Song(
      id: 'cicak', title: 'Cicak-Cicak di Dinding', daerah: 'Lagu Anak',
      bpm: 96, speedScale: 0.95,
      notes: [7,5,7,5,5,6,7, 6,4,6,8,7,6,5, 8,6,8,6,8,9,10, 10,7,6,5,4,3],
      beats: [1,1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,1,2, 1,1,1,1,1,2],
    ),
    Song(
      id: 'ampar', title: 'Ampar-Ampar Pisang', daerah: 'Kalimantan Selatan',
      bpm: 108, speedScale: 1.1,
      notes: [0,3,3,2,3,4, 0,0,4,4,3,4,5, 6,4,4,5,3,3,4,4,3,2,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'cublak', title: 'Cublak-Cublak Suweng', daerah: 'Jawa Tengah',
      bpm: 100, speedScale: 1.0,
      notes: [7,7,4,5, 3,4,5,3, 4,7,5,4, 3,4,5,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'apuse', title: 'Apuse', daerah: 'Papua',
      bpm: 100, speedScale: 1.05,
      notes: [0,3,5,4,5,4,3,0, 3,5,5,4,5,6,4,0, 3,4,6,7,6,5,4,5,4,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'soleram', title: 'Soleram', daerah: 'Riau',
      bpm: 92, speedScale: 0.95,
      notes: [3,4,5,5,6,7,6,5,4, 5,6,7,7,8,7,6,8,7, 7,8,9,10,7,8,7,6,8,7,6,5,4,3],
      beats: [1,1,2],
    ),
    Song(
      id: 'kambing', title: 'Anak Kambing Saya', daerah: 'Nusa Tenggara Timur',
      bpm: 104, speedScale: 1.1,
      notes: [3,3,3,3,3,2,1,3,2,1,0, 0,4,4,4,4,3,4,5,6,5,4,3,
              6,6,6,6,6,8,8, 5,5,5,5,5,7,7, 4,4,4,4,4,7,6,5,5,4,4,3],
      beats: [1,1,1,1,2],
    ),
    Song(
      id: 'bebek', title: 'Potong Bebek Angsa', daerah: 'Nusa Tenggara Timur',
      bpm: 110, speedScale: 1.15,
      notes: [1,1,3,3,4,4,3,4,3,3,4, 1,1,4,5,6,6,5,6,7,5,6,6,
              7,9,7,5,7,6,8,6,4,6, 5,6,7,4,3,8,9,3,4,6,8],
      beats: [1,1,1,1,2],
    ),
    Song(
      id: 'bungong', title: 'Bungong Jeumpa', daerah: 'Aceh',
      bpm: 96, speedScale: 1.0,
      notes: [8,9,8,8, 8,9,8,7, 8,9,10,9,10, 8,9,8,7,5,7,8],
      beats: [1,1,2],
    ),
    Song(
      id: 'naikgunung', title: 'Naik-Naik ke Puncak Gunung', daerah: 'Maluku',
      bpm: 108, speedScale: 1.05,
      notes: [7,3,3,3,4,5,5,5,3, 6,5,4,2,3,4,3, 7,3,3,3,5,7,7,5,3, 5,4,3,2,3,4,3,
              7,8,8,6,8,7,7,7,5, 7,7,6,4,5,6,5,6,7, 7,8,8,6,8,7,7,7,5, 7,7,6,4,5,4,3],
      beats: [1,1,1,2],
    ),
    Song(
      id: 'yamko', title: 'Yamko Rambe Yamko', daerah: 'Papua',
      bpm: 120, speedScale: 1.2,
      notes: [3,7,7,8,5,7,8, 7,7,8,4,5,3],
      beats: [1,1,2],
    ),
  ];

  static Song byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
