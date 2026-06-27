import 'dart:async';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:ubicasafe/services/api_service.dart';

class BackendTtsService {
  BackendTtsService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _playerReady = false;

  Future<bool> speak(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return true;

    final audio = await _apiService.synthesizeSpeech(cleanText);
    if (audio == null || audio.bytes.isEmpty) return false;

    await _ensurePlayer();
    final finished = Completer<void>();
    await _player.startPlayer(
      fromDataBuffer: audio.bytes,
      codec: Codec.pcm16,
      sampleRate: audio.sampleRate,
      numChannels: audio.channels,
      whenFinished: () {
        if (!finished.isCompleted) finished.complete();
      },
    );

    await finished.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () async {
        await _player.stopPlayer();
      },
    );
    return true;
  }

  Future<void> stop() async {
    if (_playerReady) {
      await _player.stopPlayer();
    }
  }

  Future<void> dispose() async {
    await stop();
    if (_playerReady) {
      await _player.closePlayer();
    }
  }

  Future<void> _ensurePlayer() async {
    if (!_playerReady) {
      await _player.openPlayer();
      _playerReady = true;
    }
  }
}
