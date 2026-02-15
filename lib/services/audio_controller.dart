import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioController {
  AudioController._internal();

  static final AudioController instance = AudioController._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  bool _initialized = false;
  final ValueNotifier<bool> isMusicOn = ValueNotifier<bool>(true);
  static const double _onVolume = 0.2;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.setVolume(_onVolume);
    await _bgPlayer.play(AssetSource('voices/music.mp3'));
  }

  Future<void> toggleMusic() async {
    final next = !isMusicOn.value;
    isMusicOn.value = next;
    await _bgPlayer.setVolume(next ? _onVolume : 0.0);
  }

  Future<void> setMusicOn(bool on) async {
    isMusicOn.value = on;
    await _bgPlayer.setVolume(on ? _onVolume : 0.0);
  }

  Future<void> pause() async {
    await _bgPlayer.pause();
  }

  Future<void> resume() async {
    if (!_initialized) {
      await init();
    } else {
      await _bgPlayer.resume();
      await _bgPlayer.setVolume(isMusicOn.value ? _onVolume : 0.0);
    }
  }
}
