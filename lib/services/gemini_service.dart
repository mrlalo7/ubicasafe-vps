import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ubicasafe/services/api_service.dart';

class GeminiService {
  GeminiService({
    http.Client? client,
    String? apiKey,
    this.model = 'gemini-2.5-flash',
    ApiService? apiService,
  }) : _client = client ?? http.Client(),
       _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
       _apiService = apiService ?? ApiService();

  final http.Client _client;
  final String _apiKey;
  final String model;
  final ApiService _apiService;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  /// Send message via the RAG backend (pgvector + Gemini).
  /// Falls back to direct Gemini API if the backend is unreachable.
  Future<String> sendRagMessage({
    required String message,
    List<String> recentMessages = const [],
  }) async {
    // Try RAG backend first
    final ragResponse = await _apiService.sendChatMessage(
      message: message,
      recentMessages: recentMessages,
    );

    if (ragResponse.fromRag) {
      return _cleanAssistantText(ragResponse.answer);
    }

    // Si el backend de la VPS respondió pero con un error de servidor (ej: 500, 400),
    // mostramos ese error directamente para que sea visible y diagnosticable.
    if (!ragResponse.error && ragResponse.answer.isNotEmpty) {
      return _cleanAssistantText(ragResponse.answer);
    }

    // Gemini debe vivir en el backend/RAG. En Flutter no pedimos API key para
    // evitar exponer secretos en la app y para que siempre use datos reales.
    return 'No pude conectar con el backend de UbicaSafe. Revisa la conexión a internet, CORS o que la VPS esté disponible.';
  }

  String _cleanAssistantText(String value) {
    return value
        .replaceAll('**', '')
        .replaceAll(RegExp(r'\bMEDIUM\b', caseSensitive: false), 'MEDIO')
        .replaceAll(RegExp(r'\bHIGH\b', caseSensitive: false), 'ALTO')
        .replaceAll(RegExp(r'\bLOW\b', caseSensitive: false), 'BAJO')
        .replaceAll(RegExp(r'\bCRITICAL\b', caseSensitive: false), 'CRITICO')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  Future<String> sendSafetyMessage({
    required String message,
    List<String> recentMessages = const [],
  }) async {
    if (!isConfigured) {
      return 'Falta configurar la API key de Gemini. Ejecuta la app con --dart-define=GEMINI_API_KEY=TU_CLAVE.';
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
      {'key': _apiKey},
    );

    final prompt = _buildPrompt(message, recentMessages);
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {
              'text':
                  'Eres IA+ de UbicaSafe, asistente de seguridad ciudadana para El Alto y La Paz. Responde en español claro, breve y útil. Si hay peligro inmediato, recomienda llamar al 110 y buscar un lugar seguro. No inventes reportes ni afirmes contacto real con autoridades. Guia al usuario para reportar, consultar riesgo o recibir consejos preventivos.',
            },
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 180},
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'No pude conectar con Gemini (${response.statusCode}). Revisa que la clave sea una API key válida y que tenga acceso al modelo.';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return 'Gemini no devolvió una respuesta. Intenta reformular tu consulta.';
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts
        ?.map((part) => (part as Map<String, dynamic>)['text'])
        .whereType<String>()
        .join('\n')
        .trim();

    if (text == null || text.isEmpty) {
      return 'Recibí una respuesta vacía de Gemini. Intenta otra consulta.';
    }

    return text;
  }

  String _buildPrompt(String message, List<String> recentMessages) {
    final history = recentMessages.take(4).join('\n');
    return '''
Contexto de app:
- Producto: UbicaSafe
- Ciudad foco: El Alto, Bolivia
- Funciones disponibles: reportar robo/incidente, mapa predictivo, ubicación en tiempo real, consejos de seguridad.

Historial reciente:
$history

Usuario:
$message
''';
  }
}
