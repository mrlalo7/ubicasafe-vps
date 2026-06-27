import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:ubicasafe/data/risk_zones.dart';

/// Centralized service to communicate with the UbicaSafe RAG backend.
///
/// Use the VPS backend by default for the current integration test.
/// In production this should move behind HTTPS.
/// The [baseUrl] should be configured per environment.
class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://161.153.197.171:8000',
          );

  final http.Client _client;
  final String _baseUrl;

  /// Send a chat message through the RAG pipeline.
  ///
  /// Returns the AI's answer enriched with real data from the database.
  /// Falls back to [fallbackMessage] if the backend is unreachable.
  Future<RagResponse> sendChatMessage({
    required String message,
    List<String> recentMessages = const [],
    String language = 'es',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat/');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'recent_messages': recentMessages.take(4).toList(),
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RagResponse(
          answer: data['answer'] as String? ?? 'Sin respuesta',
          reportsUsed: (data['sources']?['reports_used'] as int?) ?? 0,
          zonesUsed: (data['sources']?['zones_used'] as int?) ?? 0,
          fromRag: true,
        );
      }

      return RagResponse(
        answer:
            'Error del servidor (${response.statusCode}). Intenta nuevamente.',
        fromRag: false,
      );
    } catch (_) {
      return RagResponse(answer: '', fromRag: false, error: true);
    }
  }

  /// Submit a new incident report to the backend.
  ///
  /// Returns `true` if the report was saved successfully.
  Future<bool> createReport({
    required String reportType,
    required String locationText,
    required String description,
    required String violenceLevel,
    required DateTime incidentDate,
    double? latitude,
    double? longitude,
    bool hadInjuries = false,
    bool hadWeapons = false,
    String? weaponType,
    String? deviceBrand,
    String? deviceModel,
    String? deviceCondition,
    String? deviceColor,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/reports/');

    try {
      final body = <String, dynamic>{
        'report_type': reportType,
        'location_text': locationText,
        'description': description,
        'violence_level': violenceLevel,
        'incident_date': incidentDate.toIso8601String(),
        'had_injuries': hadInjuries,
        'had_weapons': hadWeapons,
      };

      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (weaponType != null) body['weapon_type'] = weaponType;
      if (deviceBrand != null) body['device_brand'] = deviceBrand;
      if (deviceModel != null) body['device_model'] = deviceModel;
      if (deviceCondition != null) body['device_condition'] = deviceCondition;
      if (deviceColor != null) body['device_color'] = deviceColor;

      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Fetch real-time statistics from the backend.
  Future<Map<String, dynamic>?> getStats() async {
    final uri = Uri.parse('$_baseUrl/api/stats/summary');

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Silently fail — UI will show cached/default data
    }
    return null;
  }

  /// Fetch risk zones from the backend.
  Future<List<Map<String, dynamic>>> getZones() async {
    final uri = Uri.parse('$_baseUrl/api/zones/');

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // Silently fail
    }
    return [];
  }

  /// Fetch risk zones as app model objects.
  Future<List<RiskZone>> getRiskZones() async {
    final zones = await getZones();
    return zones.map(RiskZone.fromJson).toList(growable: false);
  }

  /// Generate natural speech audio from the backend Gemini TTS endpoint.
  Future<TtsAudio?> synthesizeSpeech(String text) async {
    final uri = Uri.parse('$_baseUrl/api/tts/');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TtsAudio(
          bytes: base64Decode(data['audio_base64'] as String),
          mimeType: data['mime_type'] as String? ?? 'audio/pcm;rate=24000',
          sampleRate: data['sample_rate'] as int? ?? 24000,
          channels: data['channels'] as int? ?? 1,
        );
      }
    } catch (_) {
      // The UI will fall back to platform TTS.
    }
    return null;
  }
}

/// Response from the RAG pipeline.
class RagResponse {
  const RagResponse({
    required this.answer,
    this.reportsUsed = 0,
    this.zonesUsed = 0,
    this.fromRag = false,
    this.error = false,
  });

  final String answer;
  final int reportsUsed;
  final int zonesUsed;
  final bool fromRag;
  final bool error;
}

/// Audio returned by the backend TTS endpoint.
class TtsAudio {
  const TtsAudio({
    required this.bytes,
    required this.mimeType,
    required this.sampleRate,
    required this.channels,
  });

  final Uint8List bytes;
  final String mimeType;
  final int sampleRate;
  final int channels;
}
