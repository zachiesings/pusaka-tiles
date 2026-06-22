import 'package:flutter/foundation.dart';
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

  AppState(this._prefs, this.ads, this.audio)
      : _sound = _prefs.sound,
        _music = _prefs.music,
        _haptics = _prefs.haptics {
    audio.enabled = _sound;
    audio.musicEnabled = _music;
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

  /// Returns true if [score] beat the song's stored best.
  bool submitScore(String songId, int score) {
    if (score > _prefs.songBest(songId)) {
      _prefs.setSongBest(songId, score);
      notifyListeners();
      return true;
    }
    return false;
  }

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
