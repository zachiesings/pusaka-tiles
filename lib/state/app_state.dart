import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../game/chart.dart';
import '../game/missions.dart';
import '../game/progression.dart';
import '../game/songs.dart';
import '../game/tile_themes.dart';
import '../services/storage/prefs.dart';
import '../services/ads/ads_service.dart';
import '../services/audio/audio_service.dart';

/// What one finished run handed back to the player — surfaced on the result card.
class RunReward {
  final int xpGained;
  final bool leveledUp;
  final int newLevel;
  final int coinsGained;
  final List<String> missionsCompleted; // labels of missions finished this run
  const RunReward({
    this.xpGained = 0,
    this.leveledUp = false,
    this.newLevel = 0,
    this.coinsGained = 0,
    this.missionsCompleted = const [],
  });
}

/// App-wide persisted state: per-song best scores + settings.
class AppState extends ChangeNotifier {
  final Prefs _prefs;
  final AdsService ads;
  final AudioService audio;

  bool _sound;
  bool _music;
  String _inGameMusic;
  bool _haptics;
  bool _reduceMotion;
  bool _colorblind;
  bool _ensemble;
  bool _imbal;
  double _scrollSpeed;
  double _audioOffsetMs;
  double _touchOffsetMs;
  int _xp;
  // Today's missions (regenerated on a new calendar day) + their progress.
  int _missionDay = 0;
  List<Mission> _missions = const [];
  List<int> _missionProgress = const [0, 0, 0];
  List<bool> _missionClaimed = const [false, false, false];
  int _overCount = 0;
  int _coins;
  late Set<String> _unlockedThemes;
  late String _selectedTheme;
  late int _campaignUnlocked;
  late List<int> _stageStars;

  AppState(this._prefs, this.ads, this.audio)
      : _sound = _prefs.sound,
        _music = _prefs.music,
        _inGameMusic = _prefs.inGameMusic,
        _coins = _prefs.coins,
        _haptics = _prefs.haptics,
        _reduceMotion = _prefs.reduceMotion,
        _colorblind = _prefs.colorblind,
        _ensemble = _prefs.ensemble,
        _imbal = _prefs.imbal,
        _scrollSpeed = _prefs.scrollSpeed,
        _audioOffsetMs = _prefs.audioOffsetMs,
        _touchOffsetMs = _prefs.touchOffsetMs,
        _xp = _prefs.xp {
    audio.enabled = _sound;
    audio.musicEnabled = _music;
    audio.inGameMode = _inGameMusic;
    audio.instrument = _prefs.instrument;
    _unlockedThemes = _prefs.unlockedThemes.toSet()..add('klasik');
    _selectedTheme = _prefs.selectedTheme;
    TileTheme.active = TileThemeCatalog.byId(_selectedTheme).colors;
    _campaignUnlocked = _prefs.campaignUnlocked;
    _stageStars = _prefs.stageStars;
    _ensureMissionsToday();
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

  /// In-game accompaniment mode ("Musik saat bermain"): 'off' | 'pad' | 'groove'.
  /// Separate from [music] (home BGM). Default 'pad'.
  String get inGameMusic => _inGameMusic;
  void setInGameMusic(String v) {
    _inGameMusic = v;
    audio.inGameMode = v;
    _prefs.setInGameMusic(v);
    if (v == 'off') audio.stopBacking(); // stop immediately if playing
    notifyListeners();
  }

  void startHomeMusic() => audio.startBgm();
  void stopHomeMusic() => audio.stopBgm();

  void startSongBacking(String songId) => audio.startBacking(songId);
  void stopSongBacking() => audio.stopBacking();

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

  /// Sound a layered ensemble note (bonang shimmer / pitched colotomic) from an
  /// explicit instrument [folder], on the dedicated ensemble pool.
  void playEnsembleNote(String folder, int index, double volume) {
    if (_sound) audio.playVoice(folder, index, volume: volume);
  }

  /// Sound a colotomic percussion one-shot ('gong' | 'kendang' | ...). Falls
  /// back to [fallback] until the dedicated ensemble samples are rendered.
  void playColotomic(String name, double volume, {String? fallback}) {
    if (_sound) audio.playPercussion(name, volume: volume, fallback: fallback);
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

  // ----- Accessibility & the awakening ensemble -----
  /// Reduced motion: degrade the heavy juice (particle storms, zoom-punch, scene
  /// breathing) to gentle fades. The gameplay-critical cues still show.
  bool get reduceMotion => _reduceMotion;
  void setReduceMotion(bool v) {
    _reduceMotion = v;
    _prefs.setReduceMotion(v);
    notifyListeners();
  }

  /// Colourblind-safe lane cues: never rely on colour alone — add shape/position
  /// markers to lanes and tiles.
  bool get colorblind => _colorblind;
  void setColorblind(bool v) {
    _colorblind = v;
    _prefs.setColorblind(v);
    notifyListeners();
  }

  /// "Ensemble Awakens" layering — the core hook. On by default; can be muted for
  /// players who want the bare melody.
  bool get ensemble => _ensemble;
  void setEnsemble(bool v) {
    _ensemble = v;
    _prefs.setEnsemble(v);
    notifyListeners();
  }

  /// Imbal call-and-response moments.
  bool get imbal => _imbal;
  void setImbal(bool v) {
    _imbal = v;
    _prefs.setImbal(v);
    notifyListeners();
  }

  // ----- Feel: scroll speed + calibration offsets -----
  double get scrollSpeed => _scrollSpeed;
  void setScrollSpeed(double v) {
    _scrollSpeed = v.clamp(K.scrollSpeedMin, K.scrollSpeedMax);
    _prefs.setScrollSpeed(_scrollSpeed);
    notifyListeners();
  }

  double get audioOffsetMs => _audioOffsetMs;
  void setAudioOffsetMs(double v) {
    _audioOffsetMs = v.clamp(K.offsetMinMs, K.offsetMaxMs);
    _prefs.setAudioOffsetMs(_audioOffsetMs);
    notifyListeners();
  }

  double get touchOffsetMs => _touchOffsetMs;
  void setTouchOffsetMs(double v) {
    _touchOffsetMs = v.clamp(K.offsetMinMs, K.offsetMaxMs);
    _prefs.setTouchOffsetMs(_touchOffsetMs);
    notifyListeners();
  }

  /// Total timing correction applied to gameplay judging. The tile is a visual
  /// cue and the tapped note is an audio cue, so a player's systematic lateness
  /// comes from BOTH paths — the calibration screen isolates each, gameplay
  /// applies the sum. Positive = the player taps late; shift judging to match.
  double get judgeOffsetMs => _audioOffsetMs + _touchOffsetMs;

  void markOnboarded() => _prefs.setFirstRunDone();

  // ───────────────────────── Progression (T4) ─────────────────────────
  int get xp => _xp;
  int get level => Progression.levelForXp(_xp);
  int get xpIntoLevel => Progression.xpIntoLevel(_xp);
  int get xpForNextLevel => Progression.xpForNext(level);
  double get levelProgress =>
      xpForNextLevel == 0 ? 0 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);

  // ───────────────────────── Mastery (T4) ─────────────────────────
  int songMastery(String id) => _prefs.songMastery(id);
  MasteryTier songMasteryTier(String id) => Mastery.tierFor(_prefs.songMastery(id));

  // ───────────────────────── Missions (T4) ─────────────────────────
  int _todayInt() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  int _yesterdayInt() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return y.year * 10000 + y.month * 100 + y.day;
  }

  /// Load today's missions, regenerating + resetting on a new calendar day.
  void _ensureMissionsToday() {
    final today = _todayInt();
    if (_missionDay == today && _missions.isNotEmpty) return;
    final n = DateTime.now();
    _missions = MissionCatalog.daily(n.year, n.month, n.day);
    if (_prefs.missionDay == today) {
      _missionProgress = List<int>.from(_prefs.missionProgress);
      _missionClaimed = List<bool>.from(_prefs.missionClaimed);
    } else {
      _missionProgress = List<int>.filled(3, 0);
      _missionClaimed = List<bool>.filled(3, false);
      _prefs.setMissionDay(today);
      _prefs.setMissionProgress(_missionProgress);
      _prefs.setMissionClaimed(_missionClaimed);
    }
    _missionDay = today;
  }

  List<Mission> get missions {
    _ensureMissionsToday();
    return _missions;
  }

  List<int> get missionProgress {
    _ensureMissionsToday();
    return _missionProgress;
  }

  bool missionDone(int i) =>
      i >= 0 && i < _missions.length && _missionProgress[i] >= _missions[i].target;

  // ───────────────────────── Daily (T3) ─────────────────────────
  int get dailyBest => _prefs.dailyBest;
  int get dailyStreak => _prefs.dailyStreak;
  bool get dailyPlayedToday => _prefs.dailyDay == _todayInt();
  DailyPick dailyPickToday() {
    final n = DateTime.now();
    return dailyPick(n.year, n.month, n.day, SongCatalog.all.length);
  }

  void _recordDaily(int points) {
    final today = _todayInt();
    if (_prefs.dailyDay == today) {
      if (points > _prefs.dailyBest) _prefs.setDailyBest(points);
    } else {
      final newStreak = (_prefs.dailyDay == _yesterdayInt()) ? _prefs.dailyStreak + 1 : 1;
      _prefs.setDailyStreak(newStreak);
      _prefs.setDailyDay(today);
      _prefs.setDailyBest(points);
    }
  }

  /// Records a finished run: awards XP, song mastery, advances daily missions
  /// (auto-granting their rewards on completion), and updates the Daily streak.
  /// Returns what to celebrate on the result card.
  RunReward recordRun({
    required String songId,
    required Difficulty difficulty,
    required PlayMode play,
    required int points,
    required double accuracy,
    required String grade,
    required int bestCombo,
    required int perfects,
    required bool fullCombo,
    required bool allPerfect,
    required bool cleared,
  }) {
    final beforeLevel = level;
    var xpGain = Progression.runXp(
      points: points,
      accuracy: accuracy,
      difficulty: difficulty,
      fullCombo: fullCombo,
      allPerfect: allPerfect,
    );

    // Song mastery — full points on a clean clear, half otherwise.
    final mPts = Mastery.runPoints(
        difficulty: difficulty, grade: grade, fullCombo: fullCombo);
    final mAward = cleared ? mPts : (mPts ~/ 2);
    if (mAward > 0) {
      _prefs.setSongMastery(songId, _prefs.songMastery(songId) + mAward);
    }

    // Daily missions.
    _ensureMissionsToday();
    final stats = RunStats(
      score: points,
      perfects: perfects,
      bestCombo: bestCombo,
      fullCombo: fullCombo,
      cleared: cleared,
      difficultyIndex: difficulty.index,
    );
    var coinsGain = 0;
    final done = <String>[];
    for (var i = 0; i < _missions.length; i++) {
      final m = _missions[i];
      _missionProgress[i] = m.advance(_missionProgress[i], stats);
      if (m.done(_missionProgress[i]) && !_missionClaimed[i]) {
        _missionClaimed[i] = true;
        coinsGain += m.rewardCoins;
        xpGain += m.rewardXp;
        done.add(m.label);
      }
    }
    _prefs.setMissionProgress(_missionProgress);
    _prefs.setMissionClaimed(_missionClaimed);

    if (play == PlayMode.daily) _recordDaily(points);

    _xp += xpGain;
    _prefs.setXp(_xp);
    if (coinsGain > 0) addCoins(coinsGain); // persists + notifies
    final afterLevel = Progression.levelForXp(_xp);
    notifyListeners();
    return RunReward(
      xpGained: xpGain,
      leveledUp: afterLevel > beforeLevel,
      newLevel: afterLevel,
      coinsGained: coinsGain,
      missionsCompleted: done,
    );
  }
}
