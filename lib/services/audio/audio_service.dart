import 'package:audioplayers/audioplayers.dart';

/// Plays the synthesized note tones + SFX. A round-robin pool lets fast
/// successive notes overlap naturally. Gated by [enabled] (the sound setting).
class AudioService {
  final List<AudioPlayer> _pool;
  int _next = 0;
  bool enabled = true;

  final AudioPlayer _bgm = AudioPlayer();
  final AudioPlayer _backing = AudioPlayer(); // per-song groove bed under gameplay
  bool musicEnabled = true;
  bool _bgmPlaying = false;
  bool _backingPlaying = false;
  String? _backingSong;
  String instrument = 'piano'; // selected traditional voice folder

  AudioService({int voices = 8}) : _pool = List.generate(voices, (_) => AudioPlayer()) {
    for (final p in _pool) {
      p.setReleaseMode(ReleaseMode.stop);
      // lowLatency = SoundPool (Android) / preloaded buffer path: the lowest-
      // latency playback audioplayers exposes. Notes must fire the instant a
      // tile is struck, so every voice uses it.
      p.setPlayerMode(PlayerMode.lowLatency);
    }
    _bgm.setReleaseMode(ReleaseMode.loop);
    _backing.setReleaseMode(ReleaseMode.loop);
  }

  /// In-game accompaniment mode (separate from the home BGM): off | pad | groove.
  String inGameMode = 'pad';

  /// Start the in-game accompaniment for [songId], honouring [inGameMode]:
  ///  • off    → silence (the player's taps are the music)
  ///  • pad    → a shared, harmonically-neutral ambient drone (very quiet)
  ///  • groove → the song's tempo-matched soft groove (quiet)
  /// Either way it sits well below the tapped melody. Independent of home BGM.
  Future<void> startBacking(String songId) async {
    if (inGameMode == 'off') {
      await stopBacking();
      return;
    }
    final asset = inGameMode == 'pad'
        ? 'audio/backing_pad.mp3'
        : 'audio/backing/$songId.mp3';
    final volume = inGameMode == 'pad' ? 0.16 : 0.30; // always under the melody
    if (_backingPlaying && _backingSong == asset) return;
    _backingSong = asset;
    _backingPlaying = true;
    try {
      await _backing.stop();
      await _backing.play(AssetSource(asset), volume: volume);
    } catch (_) {
      _backingPlaying = false; // asset missing (render skipped) → melody-only, fine
    }
  }

  Future<void> stopBacking() async {
    _backingPlaying = false;
    _backingSong = null;
    try {
      await _backing.stop();
    } catch (_) {}
  }

  /// Start the looping home background music (gamelan). No-op if music is off.
  Future<void> startBgm() async {
    if (!musicEnabled || _bgmPlaying) return;
    _bgmPlaying = true;
    try {
      await _bgm.play(AssetSource('audio/bgm_home.wav'), volume: 0.55);
    } catch (_) {
      _bgmPlaying = false;
    }
  }

  Future<void> stopBgm() async {
    _bgmPlaying = false;
    try {
      await _bgm.stop();
    } catch (_) {}
  }

  void setMusicEnabled(bool v) {
    // Home BGM only — the in-game accompaniment is controlled separately by
    // [inGameMode] (the "Musik saat bermain" setting).
    musicEnabled = v;
    if (!v) stopBgm();
  }

  void _play(String asset, {double volume = 0.9}) {
    if (!enabled) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    // No pre-`stop()`: in lowLatency mode calling play() retriggers the voice
    // directly. The old stop()→play() round-trip added perceptible lag to every
    // note; the 8-voice round-robin already lets rapid notes overlap. Fire-and-
    // forget so the tap handler never awaits the audio platform channel.
    p.play(AssetSource(asset), volume: volume).catchError((_) {});
  }

  /// Play melody note by table index using the selected instrument voice.
  /// Volume 0.6 (not 0.9) leaves headroom: the 5-voice pool overlaps rapid taps,
  /// and hot/long notes summing past 0 dBFS was a cause of the harsh mix.
  void playNote(int index) {
    final i = index < 0 ? 0 : (index > 12 ? 12 : index);
    _play('audio/$instrument/note_${i.toString().padLeft(2, '0')}.wav', volume: 0.6);
  }

  void playWrong() => _play('audio/wrong.wav', volume: 0.8);
  void playTap() => _play('audio/tap.wav', volume: 0.6);

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _bgm.dispose();
    _backing.dispose();
  }
}
