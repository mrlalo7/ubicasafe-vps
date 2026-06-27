import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum LiveAudioState { idle, connecting, listening, speaking, error }

class LiveAudioService {
  LiveAudioService({String? baseUrl})
    : _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://161.153.197.171:8000',
          );

  final String _baseUrl;
  bool muted = false;
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final StreamController<LiveAudioState> _stateController =
      StreamController<LiveAudioState>.broadcast();
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _recordingSubscription;
  StreamSubscription? _socketSubscription;
  bool _running = false;
  bool _playerReady = false;

  Stream<LiveAudioState> get states => _stateController.stream;
  Stream<String> get messages => _messageController.stream;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _emitState(LiveAudioState.connecting);

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _emitMessage('Permiso de micrófono denegado.');
      _emitState(LiveAudioState.error);
      _running = false;
      return;
    }

    await _ensurePlayer();
    final uri = Uri.parse(_baseUrl).replace(
      scheme: Uri.parse(_baseUrl).scheme == 'https' ? 'wss' : 'ws',
      path: '/api/live',
    );

    _channel = WebSocketChannel.connect(uri);
    _socketSubscription = _channel!.stream.listen(
      _handleSocketMessage,
      onError: (_) {
        _emitMessage('Se perdió la conexión con Gemini Live.');
        _emitState(LiveAudioState.error);
      },
      onDone: () {
        if (_running) {
          _emitMessage('La llamada terminó.');
          _emitState(LiveAudioState.idle);
        }
      },
    );

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
        streamBufferSize: 640,
      ),
    );

    _recordingSubscription = stream.listen((chunk) {
      if (muted) return;
      _channel?.sink.add(
        jsonEncode({
          'type': 'audio',
          'mimeType': 'audio/pcm;rate=16000',
          'data': base64Encode(chunk),
        }),
      );
    });

    _emitMessage('Gemini Live está escuchando.');
    _emitState(LiveAudioState.listening);
  }

  Future<void> stop() async {
    _running = false;
    muted = false;
    await _recordingSubscription?.cancel();
    _recordingSubscription = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _recorder.stop();
    try {
      _channel?.sink.add(jsonEncode({'type': 'stop'}));
    } catch (_) {}
    await _channel?.sink.close();
    _channel = null;
    await _player.stopPlayer();
    _emitState(LiveAudioState.idle);
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    if (_playerReady) {
      await _player.closePlayer();
    }
    await _stateController.close();
    await _messageController.close();
  }

  Future<void> _ensurePlayer() async {
    if (!_playerReady) {
      await _player.openPlayer();
      _playerReady = true;
    }
    if (!_player.isPlaying) {
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        interleaved: true,
        numChannels: 1,
        sampleRate: 24000,
        bufferSize: 2048,
      );
    }
  }

  Future<void> _handleSocketMessage(dynamic raw) async {
    if (raw is! String) return;
    final message = jsonDecode(raw) as Map<String, dynamic>;
    final type = message['type'] as String?;

    switch (type) {
      case 'ready':
        _emitMessage('Llamada en vivo conectada.');
        break;
      case 'audio':
        await _ensurePlayer();
        final data = base64Decode(message['data'] as String);
        _player.uint8ListSink?.add(data);
        _emitState(LiveAudioState.speaking);
        break;
      case 'interrupted':
        await _player.stopPlayer();
        await _ensurePlayer();
        _emitState(LiveAudioState.listening);
        break;
      case 'complete':
        _emitState(LiveAudioState.listening);
        break;
      case 'error':
        _emitMessage(
          message['message'] as String? ?? 'Error en llamada Gemini Live.',
        );
        _emitState(LiveAudioState.error);
        break;
    }
  }

  void _emitState(LiveAudioState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void _emitMessage(String message) {
    if (!_messageController.isClosed) {
      _messageController.add(message);
    }
  }
}
