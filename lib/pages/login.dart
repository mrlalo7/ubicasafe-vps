import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ubicasafe/widgets/custom_button.dart';
import 'package:ubicasafe/pages/logeo.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ubicasafe/services/user_service.dart';

// Importa la página de registro Y el servicio de autenticación
import 'package:ubicasafe/pages/simple_registro_page.dart';
import 'package:ubicasafe/pages/menu.dart';
import 'package:ubicasafe/services/simple_auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final SimpleAuthService _authService = SimpleAuthService();

  @override
  void initState() {
    super.initState();
    _forzarLogout();
  }

  void _forzarLogout() async {
    await _authService.logout();
    print('✅ Sesión cerrada forzadamente');
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      print('🔄 Iniciando Google Sign-In...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (googleUser == null) {
        print('Usuario canceló la selección de cuenta');
        return;
      }

      print('✅ Cuenta seleccionada: ${googleUser.email}');
      _irAlMenuDirectamente(context, googleUser);
    } catch (e) {
      print('❌ Error en selección de cuenta: $e');

      if (!context.mounted) return;
      Navigator.of(context).pop();
      _irAlMenuDirectamente(context, null);
    }
  }

  void _irAlMenuDirectamente(
    BuildContext context,
    GoogleSignInAccount? user,
  ) async {
    print('🚀 Navegando directamente al menú...');

    if (user != null) {
      // ✅ USAR EL NUEVO MÉTODO DEL SimpleAuthService
      await _authService.saveGoogleUser(
        user.displayName ?? 'Usuario Google',
        user.email ?? 'usuario@google.com',
      );
      print('✅ Usuario de Google guardado: ${user.displayName}');
    } else {
      // Usuario genérico (por si hay error)
      await _authService.saveGoogleUser('Usuario', 'usuario@email.com');
      print('✅ Usuario genérico guardado');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('android/assets/img/portadasinnada.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  CustomButton(
                    color: const Color(0XFFFF4317),
                    iconVisible: false,
                    text: "Login",
                    textColor: const Color.fromARGB(255, 255, 255, 255),
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Logeo()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    icon: SvgPicture.asset(
                      'android/assets/icons/google.svg',
                      width: 24,
                      height: 24,
                    ),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    iconVisible: true,
                    text: "      Continuar con Google",
                    textColor: const Color.fromARGB(255, 0, 0, 0),
                    onPressed: () => _handleGoogleSignIn(context),
                  ),
                  const SizedBox(height: 20),

                  // ✅ SOLUCIÓN: TextButton con RichText como child
                  TextButton(
                    onPressed: () {
                      print('🔄 Navegando a SimpleRegistroPage...');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SimpleRegistroPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, // Quitar padding por defecto
                      minimumSize: Size.zero, // Tamaño mínimo cero
                      tapTargetSize: MaterialTapTargetSize
                          .shrinkWrap, // Reducir área de tap
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '¿No tienes cuenta? ',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              shadows: [
                                Shadow(
                                  blurRadius: 3.0,
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(1.0, 1.0),
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'Regístrate aquí',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64B5F6),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 3.0,
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(1.0, 1.0),
                                ),
                              ],
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF64B5F6),
                              decorationThickness: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      text: " ",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: "",
                          style: GoogleFonts.inter(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
