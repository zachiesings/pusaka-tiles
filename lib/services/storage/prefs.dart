import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

/// Thin wrapper over SharedPreferences. Tracks per-song best scores + settings.
class Prefs {
  final SharedPreferences _p;
  Prefs(this._p);

  static Future<Prefs> create() async => Prefs(await SharedPreferences.getInstance());

  int songBest(String songId) => _p.getInt(K.songBestKey(songId)) ?? 0;
  Future<void> setSongBest(String songId, int v) => _p.setInt(K.songBestKey(songId), v);

  int songStars(String songId) => _p.getInt(K.songStarsKey(songId)) ?? 0;
  Future<void> setSongStars(String songId, int v) => _p.setInt(K.songStarsKey(songId), v);

  bool get sound => _p.getBool(K.kSound) ?? true;
  Future<void> setSound(bool v) => _p.setBool(K.kSound, v);

  bool get music => _p.getBool(K.kMusic) ?? true;
  Future<void> setMusic(bool v) => _p.setBool(K.kMusic, v);

  // In-game accompaniment mode, separate from home BGM: off | pad | groove.
  String get inGameMusic => _p.getString(K.kInGameMusic) ?? 'pad';
  Future<void> setInGameMusic(String v) => _p.setString(K.kInGameMusic, v);

  String get instrument => _p.getString(K.kInstrument) ?? 'piano';
  Future<void> setInstrument(String v) => _p.setString(K.kInstrument, v);

  int get bestCombo => _p.getInt(K.kBestCombo) ?? 0;
  Future<void> setBestCombo(int v) => _p.setInt(K.kBestCombo, v);

  bool get haptics => _p.getBool(K.kHaptics) ?? true;
  Future<void> setHaptics(bool v) => _p.setBool(K.kHaptics, v);

  bool get firstRun => _p.getBool(K.kFirstRun) ?? true;
  Future<void> setFirstRunDone() => _p.setBool(K.kFirstRun, false);

  int get coins => _p.getInt(K.kCoins) ?? 0;
  Future<void> setCoins(int v) => _p.setInt(K.kCoins, v);

  List<String> get unlockedThemes => _p.getStringList(K.kThemes) ?? const ['klasik'];
  Future<void> setUnlockedThemes(List<String> v) => _p.setStringList(K.kThemes, v);

  String get selectedTheme => _p.getString(K.kTheme) ?? 'klasik';
  Future<void> setSelectedTheme(String v) => _p.setString(K.kTheme, v);

  // ----- Campaign -----
  int get campaignUnlocked => _p.getInt(K.kCampaignUnlocked) ?? 1;
  Future<void> setCampaignUnlocked(int v) => _p.setInt(K.kCampaignUnlocked, v);

  /// Per-stage best stars, stored as a 20-slot CSV (index 0 -> stage 1).
  List<int> get stageStars {
    final raw = _p.getString(K.kStageStars);
    final list = List<int>.filled(20, 0);
    if (raw == null || raw.isEmpty) return list;
    final parts = raw.split(',');
    for (var i = 0; i < 20 && i < parts.length; i++) {
      list[i] = int.tryParse(parts[i]) ?? 0;
    }
    return list;
  }

  Future<void> setStageStars(List<int> v) =>
      _p.setString(K.kStageStars, v.join(','));

  int get gamesPlayed => _p.getInt(K.kGames) ?? 0;
  Future<void> setGamesPlayed(int v) => _p.setInt(K.kGames, v);
}
