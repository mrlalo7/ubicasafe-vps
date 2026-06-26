import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/pages/menu.dart';
import '../services/simple_auth_service.dart';
import 'dart:math';
import 'dart:ui' as ui;

class Logeo extends StatefulWidget {
  const Logeo({super.key});

  @override
  State<Logeo> createState() => _LogeoState();
}

class _LogeoState extends State<Logeo> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final SimpleAuthService _authService = SimpleAuthService();
  bool _isLoading = false;
  bool _showPassword = false;

  // CAPTCHA
  String _codigoGenerado = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _checkIfLoggedIn();
    _generarNuevoCaptcha();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _generarNuevoCaptcha() {
    final random = Random();
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    _codigoGenerado = '';
    for (int i = 0; i < 6; i++) {
      _codigoGenerado += caracteres[random.nextInt(caracteres.length)];
    }
    setState(() {});
  }

  Widget _buildCaptchaDisplay() {
    return CustomPaint(
      size: const Size(250, 70),
      painter: _CaptchaPainter(_codigoGenerado),
    );
  }

  void _checkIfLoggedIn() async {
    if (await _authService.isLoggedIn()) {
      _navigateToMain();
    }
  }

  bool _validarCaptcha() {
    return _captchaController.text.toUpperCase() == _codigoGenerado;
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrarError('Por favor completa todos los campos');
      return;
    }
    if (_captchaController.text.isEmpty) {
      _mostrarError('Por favor ingresa el código CAPTCHA');
      return;
    }
    if (!_validarCaptcha()) {
      _mostrarError('Código CAPTCHA incorrecto. Intenta nuevamente.');
      _generarNuevoCaptcha();
      _captchaController.clear();
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _navigateToMain();
    } else {
      _mostrarError(result['message']);
      _generarNuevoCaptcha();
      _captchaController.clear();
    }
  }

  void _navigateToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MenuScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (route) => false,
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.accentRed, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(mensaje, style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Iniciar Sesión', style: AppTextStyles.headline3),
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Icono y subtítulo ──
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.accentBlue, AppColors.accentBlueDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: AppShadows.blueGlow,
                          ),
                          child: const Icon(Icons.lock_open_outlined, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 14),
                        Text('Ingresa tus credenciales', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Campos de formulario ──
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DarkTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          hint: 'tu@email.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        DarkTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_showPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── CAPTCHA ──
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Verificación CAPTCHA', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                            GestureDetector(
                              onTap: _generarNuevoCaptcha,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.glassWhite,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: const Icon(Icons.refresh, color: AppColors.accentBlueLight, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Display del CAPTCHA
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1025),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Center(child: _buildCaptchaDisplay()),
                        ),
                        const SizedBox(height: 14),
                        DarkTextField(
                          controller: _captchaController,
                          label: 'Ingresa el código de arriba',
                          prefixIcon: Icons.text_fields,
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            letterSpacing: 4,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _captchaController.clear(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Botón de login ──
                  GradientButton(
                    text: 'Iniciar Sesión',
                    icon: Icons.login_rounded,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _login,
                    shadows: AppShadows.blueGlow,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom Painter CAPTCHA con estilo dark ──
class _CaptchaPainter extends CustomPainter {
  final String text;
  final Random random = Random();

  _CaptchaPainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    // Líneas de ruido
    for (int i = 0; i < 8; i++) {
      final linePaint = Paint()
        ..color = AppColors.accentBlue.withOpacity(0.15)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        linePaint,
      );
    }

    // Puntos de ruido
    for (int i = 0; i < 25; i++) {
      final dotPaint = Paint()
        ..color = AppColors.accentBlueLight.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        1.5,
        dotPaint,
      );
    }

    // Caracteres
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final charWidth = size.width / text.length;

    for (int i = 0; i < text.length; i++) {
      final textStyle = TextStyle(
        fontSize: 28 + random.nextDouble() * 6,
        fontWeight: FontWeight.w800,
        color: AppColors.accentBlueLight,
        fontFamily: 'Courier',
        shadows: [
          Shadow(
            color: AppColors.accentBlue.withOpacity(0.6),
            blurRadius: 8,
          ),
        ],
      );

      textPainter.text = TextSpan(text: text[i], style: textStyle);
      textPainter.layout();

      final baseX = i * charWidth + (charWidth - textPainter.width) / 2;
      final baseY = (size.height - textPainter.height) / 2;

      canvas.save();
      final rotation = (random.nextDouble() - 0.5) * 0.4;
      final rotOffset = Offset(baseX + textPainter.width / 2, baseY + textPainter.height / 2);
      canvas.translate(rotOffset.dx, rotOffset.dy);
      canvas.rotate(rotation);
      canvas.translate(-rotOffset.dx, -rotOffset.dy);

      final offsetY = (random.nextDouble() - 0.5) * 8;
      textPainter.paint(canvas, Offset(baseX, baseY + offsetY));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
