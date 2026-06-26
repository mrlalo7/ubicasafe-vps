import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailJSService {
  // Configuración de EmailJS - REEMPLAZA CON TUS DATOS REALES
  static const String _serviceId = 'service_tu_id'; // Tu Service ID
  static const String _templateId = 'template_tu_id'; // Tu Template ID
  static const String _userId = 'user_tu_id'; // Tu Public Key

  Future<bool> sendWelcomeEmail({
    // ✅ QUITAR 'static'
    required String userEmail,
    required String userName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://api.emailjs.com/api/v1.0/email/send',
        ), // ✅ 'Uri.parse' no 'url.parse'
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          // ✅ 'json.encode' no 'jsonencode'
          'service_id': _serviceId, // ✅ Variables correctas
          'template_id': _templateId,
          'user_id': _userId,
          'template_params': {
            'user_email': userEmail,
            'user_name': userName,
            'app_name': 'UbicaSafe', // ✅ Nombre correcto
            'welcome_message':
                'Te recomendamos revisar las zonas seguras en tu área y configurar tus alertas preferidas.', // ✅ Texto corregido
          },
        }),
      );

      print('📧 Status Code: ${response.statusCode}');
      print('📧 Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error enviando email: $e');
      return false;
    }
  }
}
