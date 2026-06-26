// services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'emailjs_service.dart';

class AuthService {
  // ✅ Se llama AuthService, no GoogleAuthService
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  final EmailJSService _emailService = EmailJSService();

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Enviar email de bienvenida
      final emailSent = await _emailService.sendWelcomeEmail(
        userEmail: googleUser.email,
        userName: googleUser.displayName ?? 'Usuario',
      );

      return {
        'name': googleUser.displayName,
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl,
        'id': googleUser.id,
        'email_sent': emailSent,
      };
    } catch (e) {
      print('❌ Error en Google Sign-In: $e');
      return null;
    }
  }
}
