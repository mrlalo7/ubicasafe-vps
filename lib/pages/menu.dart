import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/pages/calificanos.dart';
import 'package:ubicasafe/pages/configuracion.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';
import 'package:ubicasafe/pages/miperfil.dart';
import 'package:ubicasafe/pages/reportarrobo.dart';
import 'package:ubicasafe/pages/ubicaciontiemporeal.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _itemFades;
  late List<Animation<Offset>> _itemSlides;

  static const int _itemCount = 6;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _itemFades = List.generate(_itemCount, (i) {
      final start = i * 0.1;
      final end = start + 0.5;
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOut),
      );
    });

    _itemSlides = List.generate(_itemCount, (i) {
      final start = i * 0.1;
      final end = start + 0.5;
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOut),
      ));
    });

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  static const List<_MenuItemData> _menuItems = [
    _MenuItemData(
      title: 'Mi Ubicación\nen Tiempo Real',
      icon: Icons.my_location_rounded,
      colors: AppColors.menuLocation,
    ),
    _MenuItemData(
      title: 'Mapa\nPredictivo',
      icon: Icons.map_rounded,
      colors: AppColors.menuMap,
    ),
    _MenuItemData(
      title: 'Reportar\nIncidente',
      icon: Icons.report_gmailerrorred_rounded,
      colors: AppColors.menuReport,
    ),
    _MenuItemData(
      title: 'Mi\nPerfil',
      icon: Icons.person_rounded,
      colors: AppColors.menuProfile,
    ),
    _MenuItemData(
      title: 'Configuración',
      icon: Icons.tune_rounded,
      colors: AppColors.menuSettings,
    ),
    _MenuItemData(
      title: 'Calificanos',
      icon: Icons.star_rounded,
      colors: AppColors.menuRate,
    ),
  ];

  void _onMenuTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();

    final pages = <Widget Function()>[
      () => const UbicacionTiempoReal(),
      () => const MapaPredictivo(),
      () => const ReportarRobo(),
      () => const MiPerfilScreen(),
      () => const ConfiguracionScreen(),
      () => const CalificanosScreen(),
    ];

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => pages[index](),
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
          // ── Fondo decorativo superior ──
          Positioned(
            top: -size.height * 0.08,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentBlue.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                _buildHeader(),
                const SizedBox(height: 8),

                // ── Tarjeta de estado del área ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatusBanner(),
                ),
                const SizedBox(height: 16),

                // ── Grid de opciones ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _itemCount,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, i) {
                        return SlideTransition(
                          position: _itemSlides[i],
                          child: FadeTransition(
                            opacity: _itemFades[i],
                            child: _MenuCard(
                              item: _menuItems[i],
                              onTap: () => _onMenuTap(context, i),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),

      // ── Botón SOS flotante ──
      floatingActionButton: _SosFab(
        onPressed: () {
          HapticFeedback.heavyImpact();
          _mostrarEmergenciaRapida(context);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.accentBlue, AppColors.accentBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: AppShadows.blueGlow,
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UbicaSafe', style: AppTextStyles.headline3),
              Text(
                'El Alto · La Paz',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.safeGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.safeGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.safeGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Activo',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.safeGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warningAmber,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zona de Alerta Moderada',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warningAmber,
                  ),
                ),
                Text(
                  '3 reportes en las últimas 2 horas',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ],
      ),
    );
  }

  void _mostrarEmergenciaRapida(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EmergencySheet(context: context),
    );
  }
}

// ── Tarjeta de menú ──
class _MenuCard extends StatefulWidget {
  final _MenuItemData item;
  final VoidCallback onTap;

  const _MenuCard({required this.item, required this.onTap});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
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
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.item.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.item.colors.last.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Círculo decorativo de fondo
              Positioned(
                right: -16,
                bottom: -16,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // Contenido
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.item.icon, color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                    Text(
                      widget.item.title,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botón SOS con efecto de pulso ──
class _SosFab extends StatefulWidget {
  final VoidCallback onPressed;

  const _SosFab({required this.onPressed});

  @override
  State<_SosFab> createState() => _SosFabState();
}

class _SosFabState extends State<_SosFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          // Anillo pulsante
          Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentRed.withOpacity(0.18),
              ),
            ),
          ),
          // Botón
          GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accentRed, AppColors.accentRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: AppShadows.redGlow,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
                  Text(
                    'SOS',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet de emergencia ──
class _EmergencySheet extends StatelessWidget {
  final BuildContext context;

  const _EmergencySheet({required this.context});

  Widget _buildEmergencyBtn(
    String text,
    String subtitle,
    IconData icon,
    List<Color> colors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: AppColors.accentRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergencia', style: AppTextStyles.headline3),
                    Text(
                      '¿Qué tipo de emergencia?',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEmergencyBtn(
              'Policía (110)',
              'Llamar a la Policía Nacional',
              Icons.local_police_rounded,
              [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
              () {
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            _buildEmergencyBtn(
              'Bomberos (119)',
              'Llamar a los Bomberos',
              Icons.local_fire_department_rounded,
              [const Color(0xFFFF6B35), const Color(0xFFFF3B30)],
              () {
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            _buildEmergencyBtn(
              'Reportar Robo',
              'Registrar un incidente',
              Icons.report_rounded,
              [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
              () {
                Navigator.pop(ctx);
                Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => const ReportarRobo()),
                );
              },
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Data model para items del menú ──
class _MenuItemData {
  final String title;
  final IconData icon;
  final List<Color> colors;

  const _MenuItemData({
    required this.title,
    required this.icon,
    required this.colors,
  });
}
