import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ubicasafe/core/app_theme.dart';
import '../services/simple_auth_service.dart';

class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen>
    with SingleTickerProviderStateMixin {
  String _userName = 'Usuario';
  String _userEmail = 'email@ejemplo.com';
  String _userRole = 'user';
  bool _isLoading = true;

  final SimpleAuthService _authService = SimpleAuthService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _loadUserData();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final name = await _authService.getCurrentUserName();
    final email = await _authService.getCurrentUserEmail();
    final role = await _authService.getCurrentUserRole();

    setState(() {
      _userName = name;
      _userEmail = email;
      _userRole = role;
      _isLoading = false;
    });
  }

  void _editarNombre() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar Nombre', style: AppTextStyles.headline3.copyWith(fontSize: 18)),
        content: DarkTextField(
          controller: controller,
          label: 'Nombre',
          prefixIcon: Icons.person_outline,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          GestureDetector(
            onTap: () {
              if (controller.text.isNotEmpty) {
                _actualizarNombre(controller.text);
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppGradients.headerBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Guardar', style: AppTextStyles.button.copyWith(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Future<void> _actualizarNombre(String nuevoNombre) async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      user['nombre'] = nuevoNombre;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario_actual', json.encode(user));
    }
    setState(() => _userName = nuevoNombre);
    _mostrarMensaje('Nombre actualizado');
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: AppTextStyles.body.copyWith(color: Colors.white)),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }

    final initials = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mi Perfil', style: AppTextStyles.headline3),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // ── Header con avatar ──
              GlassCard(
                padding: const EdgeInsets.all(28),
                gradient: const LinearGradient(
                  colors: [Color(0x204060F5), Color(0x104060F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  children: [
                    // Avatar con iniciales
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.headerBlue,
                        boxShadow: AppShadows.blueGlow,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.headline1.copyWith(fontSize: 36),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('¡Bienvenido/a!', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text(_userName, style: AppTextStyles.headline2),
                    const SizedBox(height: 4),
                    Text(_userEmail, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('15', 'Reportes'),
                        _buildDivider(),
                        _buildStatCard('4.8★', 'Rating'),
                        _buildDivider(),
                        _buildStatCard('120', 'Puntos'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Info del perfil ──
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoItem(Icons.person_outline, 'Nombre de usuario', _userName),
                    _buildDividerLine(),
                    _buildInfoItem(Icons.email_outlined, 'Correo electrónico', _userEmail),
                    _buildDividerLine(),
                    _buildInfoItem(Icons.verified_user_outlined, 'Rol', _userRole.toUpperCase()),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: 'Editar Perfil',
                      icon: Icons.edit_outlined,
                      onPressed: _editarNombre,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Tarjeta de logros ──
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: AppColors.warningAmber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'LOGROS',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.warningAmber,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLogro(Icons.shield_outlined, 'Ciudadano\nActivo', AppColors.accentBlue),
                        _buildLogro(Icons.location_on_rounded, 'Guardián\nLocal', AppColors.safeGreen),
                        _buildLogro(Icons.star_rounded, 'Top\nReportero', AppColors.warningAmber),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accentBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.accentBlueLight,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(title, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.glassBorder,
    );
  }

  Widget _buildDividerLine() {
    return Container(
      height: 1,
      color: AppColors.glassBorder,
    );
  }

  Widget _buildLogro(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
