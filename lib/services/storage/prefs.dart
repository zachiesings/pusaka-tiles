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

  // ----- Feel: scroll speed + calibration offsets (all per device) -----
  double get scrollSpeed =>
      (_p.getDouble(K.kScrollSpeed) ?? K.scrollSpeedDefault)
          .clamp(K.scrollSpeedMin, K.scrollSpeedMax);
  Future<void> setScrollSpeed(double v) =>
      _p.setDouble(K.kScrollSpeed, v.clamp(K.scrollSpeedMin, K.scrollSpeedMax));

  double get audioOffsetMs =>
      (_p.getDouble(K.kAudioOffsetMs) ?? 0).clamp(K.offsetMinMs, K.offsetMaxMs);
  Future<void> setAudioOffsetMs(double v) =>
      _p.setDouble(K.kAudioOffsetMs, v.clamp(K.offsetMinMs, K.offsetMaxMs));

  double get touchOffsetMs =>
      (_p.getDouble(K.kTouchOffsetMs) ?? 0).clamp(K.offsetMinMs, K.offsetMaxMs);
  Future<void> setTouchOffsetMs(double v) =>
      _p.setDouble(K.kTouchOffsetMs, v.clamp(K.offsetMinMs, K.offsetMaxMs));

  int get bestCombo => _p.getInt(K.kBestCombo) ?? 0;
  Future<void> setBestCombo(int v) => _p.setInt(K.kBestCombo, v);

  bool get haptics => _p.getBool(K.kHaptics) ?? true;
  Future<void> setHaptics(bool v) => _p.setBool(K.kHaptics, v);

  // ----- Accessibility & the awakening ensemble (default on) -----
  bool get reduceMotion => _p.getBool(K.kReduceMotion) ?? false;
  Future<void> setReduceMotion(bool v) => _p.setBool(K.kReduceMotion, v);

  bool get colorblind => _p.getBool(K.kColorblind) ?? false;
  Future<void> setColorblind(bool v) => _p.setBool(K.kColorblind, v);

  bool get ensemble => _p.getBool(K.kEnsemble) ?? true;
  Future<void> setEnsemble(bool v) => _p.setBool(K.kEnsemble, v);

  bool get imbal => _p.getBool(K.kImbal) ?? true;
  Future<void> setImbal(bool v) => _p.setBool(K.kImbal, v);

  // Collectible Pusaka motifs: unlocked song-ids + the equipped one.
  List<String> get unlockedMotifs => _p.getStringList(K.kMotifs) ?? const [];
  Future<void> setUnlockedMotifs(List<String> v) => _p.setStringList(K.kMotifs, v);

  String get equippedMotif => _p.getString(K.kMotifEquip) ?? '';
  Future<void> setEquippedMotif(String v) => _p.setString(K.kMotifEquip, v);

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

  // ----- Progression / mastery / missions / daily -----
  int get xp => _p.getInt(K.kXp) ?? 0;
  Future<void> setXp(int v) => _p.setInt(K.kXp, v);

  int songMastery(String songId) => _p.getInt(K.songMasteryKey(songId)) ?? 0;
  Future<void> setSongMastery(String songId, int v) =>
      _p.setInt(K.songMasteryKey(songId), v);

  int get missionDay => _p.getInt(K.kMissionDay) ?? 0;
  Future<void> setMissionDay(int v) => _p.setInt(K.kMissionDay, v);

  List<int> get missionProgress => _csvInts(_p.getString(K.kMissionProg), 3);
  Future<void> setMissionProgress(List<int> v) =>
      _p.setString(K.kMissionProg, v.join(','));

  List<bool> get missionClaimed =>
      _csvInts(_p.getString(K.kMissionClaim), 3).map((e) => e != 0).toList();
  Future<void> setMissionClaimed(List<bool> v) =>
      _p.setString(K.kMissionClaim, v.map((e) => e ? 1 : 0).join(','));

  int get dailyDay => _p.getInt(K.kDailyDay) ?? 0;
  Future<void> setDailyDay(int v) => _p.setInt(K.kDailyDay, v);
  int get dailyBest => _p.getInt(K.kDailyBest) ?? 0;
  Future<void> setDailyBest(int v) => _p.setInt(K.kDailyBest, v);
  int get dailyStreak => _p.getInt(K.kDailyStreak) ?? 0;
  Future<void> setDailyStreak(int v) => _p.setInt(K.kDailyStreak, v);

  static List<int> _csvInts(String? raw, int n) {
    final list = List<int>.filled(n, 0);
    if (raw == null || raw.isEmpty) return list;
    final parts = raw.split(',');
    for (var i = 0; i < n && i < parts.length; i++) {
      list[i] = int.tryParse(parts[i]) ?? 0;
    }
    return list;
  }
}
