import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/pages/logeo.dart';
import 'package:ubicasafe/pages/menu.dart';
import 'package:ubicasafe/pages/simple_registro_page.dart';
import 'package:ubicasafe/services/simple_auth_service.dart';
import 'package:ubicasafe/services/user_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final SimpleAuthService _authService = SimpleAuthService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _forzarLogout();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _forzarLogout() async {
    await _authService.logout();
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (googleUser == null) return;

      _irAlMenuDirectamente(context, googleUser);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      _irAlMenuDirectamente(context, null);
    }
  }

  void _irAlMenuDirectamente(
    BuildContext context,
    GoogleSignInAccount? user,
  ) async {
    if (user != null) {
      await _authService.saveGoogleUser(
        user.displayName ?? 'Usuario Google',
        user.email ?? 'usuario@google.com',
      );
    } else {
      await _authService.saveGoogleUser('Usuario', 'usuario@email.com');
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MenuScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Fondo decorativo ──
          Positioned(
            top: -size.height * 0.12,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentBlue.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            right: -size.width * 0.3,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentRed.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Contenido principal ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 56),

                  // Logo y título
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.accentBlue,
                                AppColors.accentBlueDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentBlue.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('UbicaSafe', style: AppTextStyles.headline1),
                        const SizedBox(height: 6),
                        Text(
                          'Bienvenido de vuelta',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Tarjeta de acciones ──
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: GlassCard(
                        padding: const EdgeInsets.all(28),
                        borderRadius: BorderRadius.circular(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Iniciar sesión',
                              style: AppTextStyles.headline3,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Accede con tu cuenta para continuar',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),

                            // Botón Email/Contraseña
                            GradientButton(
                              text: 'Entrar con Email',
                              icon: Icons.email_outlined,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Logeo(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),

                            // Separador
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: AppColors.glassBorder,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'o continúa con',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: AppColors.glassBorder,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Botón Google
                            _GoogleSignInButton(
                              onPressed: () => _handleGoogleSignIn(context),
                            ),

                            const SizedBox(height: 24),

                            // Registro
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SimpleRegistroPage(),
                                  ),
                                );
                              },
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '¿No tienes cuenta? ',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    TextSpan(
                                      text: 'Regístrate aquí',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.accentBlueLight,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor:
                                            AppColors.accentBlueLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Pie de página
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      'Al continuar aceptas nuestros términos de uso',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'android/assets/icons/google.svg',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'Continuar con Google',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
