import 'package:flutter/foundation.dart';
import '../game/songs.dart';
import '../game/tile_themes.dart';
import '../services/storage/prefs.dart';
import '../services/ads/ads_service.dart';
import '../services/audio/audio_service.dart';

/// App-wide persisted state: per-song best scores + settings.
class AppState extends ChangeNotifier {
  final Prefs _prefs;
  final AdsService ads;
  final AudioService audio;

  bool _sound;
  bool _music;
  bool _haptics;
  int _overCount = 0;
  int _coins;
  late Set<String> _unlockedThemes;
  late String _selectedTheme;
  late int _campaignUnlocked;
  late List<int> _stageStars;

  AppState(this._prefs, this.ads, this.audio)
      : _sound = _prefs.sound,
        _music = _prefs.music,
        _coins = _prefs.coins,
        _haptics = _prefs.haptics {
    audio.enabled = _sound;
    audio.musicEnabled = _music;
    audio.instrument = _prefs.instrument;
    _unlockedThemes = _prefs.unlockedThemes.toSet()..add('klasik');
    _selectedTheme = _prefs.selectedTheme;
    TileTheme.active = TileThemeCatalog.byId(_selectedTheme).colors;
    _campaignUnlocked = _prefs.campaignUnlocked;
    _stageStars = _prefs.stageStars;
  }

  // ----- Campaign ("Perjalanan Nusantara") -----
  static const int campaignCount = 20;

  int get campaignUnlocked => _campaignUnlocked;
  bool isStageUnlocked(int index) => index <= _campaignUnlocked;
  int starsForStage(int index) =>
      (index >= 1 && index <= 20) ? _stageStars[index - 1] : 0;
  int get totalStars => _stageStars.fold(0, (a, b) => a + b);
  int get stagesCleared => _stageStars.where((s) => s > 0).length;
  bool get campaignComplete => stagesCleared >= campaignCount;

  int get gamesPlayed => _prefs.gamesPlayed;
  void incGamesPlayed() => _prefs.setGamesPlayed(_prefs.gamesPlayed + 1);

  /// Record a finished campaign stage. Persists the best star count, unlocks the
  /// next stage, and grants [coins] on the FIRST clear only. Returns true if this
  /// was the stage's first-ever clear (for the reward animation).
  bool recordStageResult(int index, int stars, int coins) {
    if (index < 1 || index > 20 || stars <= 0) return false;
    final prev = _stageStars[index - 1];
    final firstClear = prev == 0;
    if (stars > prev) {
      _stageStars[index - 1] = stars;
      _prefs.setStageStars(_stageStars);
    }
    if (firstClear) addCoins(coins);
    if (index == _campaignUnlocked && index < campaignCount) {
      _campaignUnlocked = index + 1;
      _prefs.setCampaignUnlocked(_campaignUnlocked);
    }
    notifyListeners();
    return firstClear;
  }

  // ----- Coins & tile themes -----
  int get coins => _coins;
  void addCoins(int n) {
    if (n <= 0) return;
    _coins += n;
    _prefs.setCoins(_coins);
    notifyListeners();
  }

  /// Watch a rewarded ad for +50 coins. Returns true if granted.
  Future<bool> rewardedCoins() async {
    final ok = await ads.showRewarded(RewardKind.bonusCoins);
    if (ok) addCoins(50);
    return ok;
  }

  String get selectedTheme => _selectedTheme;
  bool isThemeUnlocked(String id) => _unlockedThemes.contains(id);
  int get unlockedThemeCount => _unlockedThemes.length;
  int get totalThemes => TileThemeCatalog.all.length;

  bool buyTheme(TileTheme t) {
    if (_unlockedThemes.contains(t.id)) return false;
    if (_coins < t.cost) return false;
    _coins -= t.cost;
    _prefs.setCoins(_coins);
    _unlockedThemes.add(t.id);
    _prefs.setUnlockedThemes(_unlockedThemes.toList());
    selectTheme(t.id);
    return true;
  }

  void selectTheme(String id) {
    if (!_unlockedThemes.contains(id)) return;
    _selectedTheme = id;
    _prefs.setSelectedTheme(id);
    TileTheme.active = TileThemeCatalog.byId(id).colors;
    notifyListeners();
  }

  String get instrument => audio.instrument;
  void setInstrument(String id) {
    audio.instrument = id;
    _prefs.setInstrument(id);
    if (_sound) audio.playNote(7); // preview "sol"
    notifyListeners();
  }

  bool get music => _music;
  void setMusic(bool v) {
    _music = v;
    audio.setMusicEnabled(v);
    if (v) audio.startBgm();
    _prefs.setMusic(v);
    notifyListeners();
  }

  void startHomeMusic() => audio.startBgm();
  void stopHomeMusic() => audio.stopBgm();

  /// Show an interstitial on roughly every 2nd game-over (called on restart).
  Future<void> maybeShowInterstitial() async {
    _overCount++;
    if (_overCount % 2 == 0) await ads.maybeShowInterstitial();
  }

  bool get sound => _sound;
  bool get haptics => _haptics;
  bool get firstRun => _prefs.firstRun;

  int bestForSong(String id) => _prefs.songBest(id);
  int bestStars(String id) => _prefs.songStars(id);

  /// Returns true if [score] beat the song's stored best.
  bool submitScore(String songId, int score) {
    if (score > _prefs.songBest(songId)) {
      _prefs.setSongBest(songId, score);
      notifyListeners();
      return true;
    }
    return false;
  }

  void submitStars(String songId, int stars) {
    if (stars > _prefs.songStars(songId)) {
      _prefs.setSongStars(songId, stars);
      notifyListeners();
    }
  }

  // ----- Achievement stats -----
  int get bestCombo => _prefs.bestCombo;
  void submitBestCombo(int c) {
    if (c > _prefs.bestCombo) {
      _prefs.setBestCombo(c);
      notifyListeners();
    }
  }

  int get songsWithAnyStar =>
      SongCatalog.all.where((s) => _prefs.songStars(s.id) >= 1).length;
  int get songsWithThreeStars =>
      SongCatalog.all.where((s) => _prefs.songStars(s.id) >= 3).length;
  int get totalSongs => SongCatalog.all.length;

  void playNote(int index) {
    if (_sound) audio.playNote(index);
  }

  void playWrong() {
    if (_sound) audio.playWrong();
  }

  void playTap() {
    if (_sound) audio.playTap();
  }

  void setSound(bool v) {
    _sound = v;
    audio.enabled = v;
    _prefs.setSound(v);
    notifyListeners();
  }

  void setHaptics(bool v) {
    _haptics = v;
    _prefs.setHaptics(v);
    notifyListeners();
  }

  void markOnboarded() => _prefs.setFirstRunDone();
}
