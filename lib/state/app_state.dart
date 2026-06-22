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
  bool _haptics;

  AppState(this._prefs, this.ads, this.audio)
      : _sound = _prefs.sound,
        _haptics = _prefs.haptics {
    audio.enabled = _sound;
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
