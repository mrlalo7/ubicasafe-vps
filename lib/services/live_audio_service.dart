import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  final List<Uint8List> _turnAudioChunks = <Uint8List>[];
  bool _running = false;
  bool _connected = false;
  bool _playerReady = false;
  int _turnAudioBytes = 0;
  int _playbackGeneration = 0;

  Stream<LiveAudioState> get states => _stateController.stream;
  Stream<String> get messages => _messageController.stream;
  bool get isRunning => _running;
  bool get isConnected => _connected;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _emitState(LiveAudioState.connecting);

    try {
      if (_isInsecureWebOrigin) {
        _emitMessage(
          'En navegador el micrófono requiere HTTPS o localhost. '
          'Para probar voz real usa la APK o publica el frontend con HTTPS.',
        );
        _emitState(LiveAudioState.error);
        _running = false;
        return;
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _emitMessage('Permiso de micrófono denegado.');
        _emitState(LiveAudioState.error);
        _running = false;
        return;
      }

      await _openPlayer();
      final uri = Uri.parse(_baseUrl).replace(
        scheme: Uri.parse(_baseUrl).scheme == 'https' ? 'wss' : 'ws',
        path: '/api/live',
      );

      _channel = WebSocketChannel.connect(uri);
      _socketSubscription = _channel!.stream.listen(
        _handleSocketMessage,
        onError: (Object error) {
          _emitMessage('Se perdió la conexión Live: $error');
          _emitState(LiveAudioState.error);
          _connected = false;
          _running = false;
        },
        onDone: () {
          _connected = false;
          if (_running) {
            _emitMessage('La llamada terminó.');
            _emitState(LiveAudioState.idle);
          }
          _running = false;
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
    } catch (error) {
      _emitMessage('No pude iniciar Gemini Live: $error');
      _emitState(LiveAudioState.error);
      _running = false;
      _connected = false;
      await _recordingSubscription?.cancel();
      _recordingSubscription = null;
      await _recorder.stop();
      await _channel?.sink.close();
      _channel = null;
    }
  }

  bool get _isInsecureWebOrigin {
    if (!kIsWeb) return false;
    final uri = Uri.base;
    if (uri.scheme == 'https') return false;
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') return false;
    return true;
  }

  Future<bool> sendText(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return true;

    if (!_running) {
      await start();
    }
    final channel = _channel;
    if (channel == null) {
      _emitMessage('Gemini Live no está conectado.');
      _emitState(LiveAudioState.error);
      return false;
    }

    try {
      channel.sink.add(jsonEncode({'type': 'text', 'text': cleanText}));
      _emitMessage('Tú: $cleanText');
      _emitState(LiveAudioState.speaking);
      return true;
    } catch (_) {
      _emitMessage('No pude enviar el mensaje por la llamada en vivo.');
      _emitState(LiveAudioState.error);
      return false;
    }
  }

  Future<void> stop() async {
    _running = false;
    _connected = false;
    muted = false;
    try {
      _channel?.sink.add(jsonEncode({'type': 'stop'}));
    } catch (_) {}
    await _recordingSubscription?.cancel();
    _recordingSubscription = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _recorder.stop();
    await _channel?.sink.close();
    _channel = null;
    await _player.stopPlayer();
    _clearAudioBuffer();
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

  Future<void> _openPlayer() async {
    if (!_playerReady) {
      await _player.openPlayer();
      _playerReady = true;
    }
  }

  void _enqueueAudio(Uint8List data) {
    if (data.isEmpty) return;
    _turnAudioChunks.add(data);
    _turnAudioBytes += data.length;
  }

  Future<void> _playBufferedTurnAudio() async {
    if (_turnAudioChunks.isEmpty || _turnAudioBytes == 0) {
      _emitState(LiveAudioState.listening);
      return;
    }

    final generation = ++_playbackGeneration;
    final audio = Uint8List(_turnAudioBytes);
    var offset = 0;
    for (final chunk in _turnAudioChunks) {
      audio.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    _clearAudioBuffer();
    await _openPlayer();
    await _player.stopPlayer();
    _emitState(LiveAudioState.speaking);

    await _player.startPlayer(
      fromDataBuffer: audio,
      codec: Codec.pcm16,
      sampleRate: 24000,
      numChannels: 1,
      whenFinished: () {
        if (generation == _playbackGeneration) {
          _emitState(LiveAudioState.listening);
        }
      },
    );
  }

  void _clearAudioBuffer() {
    _turnAudioChunks.clear();
    _turnAudioBytes = 0;
  }

  Future<void> _handleSocketMessage(dynamic raw) async {
    if (raw is! String) return;
    final message = jsonDecode(raw) as Map<String, dynamic>;
    final type = message['type'] as String?;

    switch (type) {
      case 'ready':
        _connected = true;
        _emitMessage('Llamada en vivo conectada.');
        break;
      case 'audio':
        final data = base64Decode(message['data'] as String);
        _enqueueAudio(data);
        _emitState(LiveAudioState.speaking);
        break;
      case 'interrupted':
        _playbackGeneration++;
        await _player.stopPlayer();
        _clearAudioBuffer();
        _emitState(LiveAudioState.listening);
        break;
      case 'complete':
        unawaited(_playBufferedTurnAudio());
        break;
      case 'input_transcript':
        final text = (message['text'] as String? ?? '').trim();
        if (text.isNotEmpty) {
          _emitMessage('Tú: $text');
        }
        break;
      case 'output_transcript':
        final text = (message['text'] as String? ?? '').trim();
        if (text.isNotEmpty) {
          _emitMessage(text);
        }
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
