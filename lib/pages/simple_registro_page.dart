import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ubicasafe/core/app_theme.dart';
import '../services/simple_auth_service.dart';
import 'logeo.dart';

class SimpleRegistroPage extends StatefulWidget {
  const SimpleRegistroPage({super.key});

  @override
  State<SimpleRegistroPage> createState() => _SimpleRegistroPageState();
}

class _SimpleRegistroPageState extends State<SimpleRegistroPage>
    with SingleTickerProviderStateMixin {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final SimpleAuthService _authService = SimpleAuthService();
  bool _isLoading = false;
  bool _showPassword = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.length < 4) {
      _mostrarError('La contraseña debe tener al menos 4 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.registrarUsuario(
      nombre: _nombreController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _mostrarExito(result['message']);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const Logeo(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      _mostrarError(result['message']);
    }
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

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.safeGreen, size: 20),
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
        title: Text('Crear Cuenta', style: AppTextStyles.headline3),
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
                          child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 14),
                        Text('Únete a nuestra comunidad segura', style: AppTextStyles.bodySmall),
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
                          controller: _nombreController,
                          label: 'Nombre completo',
                          hint: 'Ej: Juan Pérez',
                          prefixIcon: Icons.person_outline,
                          validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        DarkTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          hint: 'tu@email.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        DarkTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_showPassword,
                          validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
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
                  const SizedBox(height: 32),

                  // ── Botón de registro ──
                  GradientButton(
                    text: 'Registrarse',
                    icon: Icons.app_registration_rounded,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _registrar,
                    shadows: AppShadows.blueGlow,
                  ),
                  const SizedBox(height: 24),

                  // ── Enlace al login ──
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder: (_, __, ___) => const Logeo(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                      );
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(text: '¿Ya tienes cuenta? ', style: AppTextStyles.bodySmall),
                          TextSpan(
                            text: 'Inicia sesión',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accentBlueLight,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.accentBlueLight,
                            ),
                          ),
                        ],
                      ),
                    ),
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
