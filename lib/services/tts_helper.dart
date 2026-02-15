import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  static final Expando<bool> _configured = Expando<bool>('tts_configured');
  static final AudioPlayer _assetPlayer = AudioPlayer();
  static bool _assetPlayerReady = false;

  static const List<String> _preferredArabic = [
    'ar-TN',
    'ar-SA',
    'ar-EG',
    'ar',
  ];

  static Future<String?> configureArabic(
    FlutterTts tts, {
    double pitch = 1.0,
    double volume = 1.0,
    double speechRate = 0.45,
  }) async {
    if (_configured[tts] == true) {
      return null;
    }
    try {
      await tts.awaitSpeakCompletion(true);
    } catch (_) {}

    try {
      await tts.setSharedInstance(true);
    } catch (_) {}

    await tts.setPitch(pitch);
    await tts.setVolume(volume);
    await tts.setSpeechRate(speechRate);

    for (final lang in _preferredArabic) {
      try {
        final ok = await tts.isLanguageAvailable(lang);
        if (ok == true || ok == 1 || ok == 'true') {
          await tts.setLanguage(lang);
          _configured[tts] = true;
          return lang;
        }
      } catch (_) {}
    }

    try {
      await tts.setLanguage('ar-EG');
      _configured[tts] = true;
      return 'ar-EG';
    } catch (_) {
      return null;
    }
  }

  static Future<void> speak(FlutterTts tts, String text) async {
    final cleanText = _normalizeText(text);
    if (cleanText.isEmpty) return;
    try {
      if (await _playLocalVoiceIfAvailable(cleanText)) {
        return;
      }
      if (_configured[tts] != true) {
        await configureArabic(tts);
      }
      await tts.stop();
      final result = await tts.speak(cleanText);
      if (result != 1) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await tts.speak(cleanText);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TTS] speak failed: $e');
      }
    }
  }

  static Future<bool> _playLocalVoiceIfAvailable(String text) async {
    final key = _textKey(text);
    final assetSourcePath = 'voices/tts/$key.mp3';

    try {
      await _ensureAssetPlayerReady();
      await _assetPlayer.stop();
      await _assetPlayer.play(AssetSource(assetSourcePath));
      if (kDebugMode) {
        debugPrint('[TTS] local voice: $assetSourcePath <= "$text"');
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[TTS] no local voice for "$text": $e');
      return false;
    }
  }

  static Future<void> _ensureAssetPlayerReady() async {
    if (_assetPlayerReady) return;
    try {
      await _assetPlayer.setReleaseMode(ReleaseMode.stop);
      await _assetPlayer.setAudioContext(
        AudioContextConfig(
          route: AudioContextConfigRoute.speaker,
          duckAudio: true,
          respectSilence: false,
          stayAwake: false,
        ).build(),
      );
      await _assetPlayer.setVolume(1.0);
    } catch (_) {}
    _assetPlayerReady = true;
  }

  // Keep this in sync with tool/generate_tts_assets.py
  static String _textKey(String text) {
    const int fnvOffset = 0x811C9DC5;
    const int fnvPrime = 0x01000193;
    var hash = fnvOffset;
    for (final byte in utf8.encode(_normalizeText(text))) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _normalizeText(String input) {
    return input
        .replaceAll('/', ' أو ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
