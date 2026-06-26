import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/data/risk_zones.dart';
import 'package:ubicasafe/pages/calificanos.dart';
import 'package:ubicasafe/pages/chat_ia.dart';
import 'package:ubicasafe/pages/configuracion.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';
import 'package:ubicasafe/pages/mapariesgo.dart';
import 'package:ubicasafe/pages/miperfil.dart';
import 'package:ubicasafe/pages/reportarrobo.dart';
import 'package:ubicasafe/pages/ubicaciontiemporeal.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  LatLng _currentPosition = RiskMapData.defaultCenter;
  bool _usingDeviceLocation = false;
  GoogleMapController? _mapController;

  static const _mapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#1f2a3a"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#1f2a3a"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
    {"featureType":"poi","stylers":[{"visibility":"off"}]}
  ]
  ''';

  RiskZone get _activeZone => RiskMapData.effectiveZoneFor(_currentPosition);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _currentPosition = latLng;
        _usingDeviceLocation = true;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    } catch (_) {
      // El home sigue funcionando con el centro real de referencia de El Alto.
    }
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final zone = _activeZone;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.darkBackground),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 126),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(onNotifications: _showAlerts),
                      const SizedBox(height: 28),
                      _Greeting(zone: zone),
                      const SizedBox(height: 18),
                      _SecurityStatus(
                        zone: zone,
                        usingDeviceLocation: _usingDeviceLocation,
                      ),
                      const SizedBox(height: 16),
                      _MapPreview(
                        currentPosition: _currentPosition,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        mapStyle: _mapStyle,
                        onOpen: () => _open(const MapaRiesgo()),
                      ),
                      const SizedBox(height: 18),
                      _FeatureCards(
                        onLocation: () => _open(const UbicacionTiempoReal()),
                        onMap: () => _open(const MapaPredictivo()),
                        onReport: () => _open(const ReportarRobo()),
                      ),
                      const SizedBox(height: 18),
                      _Recommendation(zone: zone),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomNav(
                  onHome: () {},
                  onProfile: () => _open(const MiPerfilScreen()),
                  onAi: () => _open(const ChatIaScreen()),
                  onSettings: () => _open(const ConfiguracionScreen()),
                  onRate: () => _open(const CalificanosScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlerts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlertsSheet(zone: _activeZone),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/icons/ubicasafe_shield.png',
          width: 62,
          height: 62,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Ubica', style: AppTextStyles.headline1),
                    TextSpan(
                      text: 'Safe',
                      style: AppTextStyles.headline1.copyWith(
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.textSecondary,
                    size: 17,
                  ),
                  const SizedBox(width: 4),
                  Text('El Alto, Bolivia', style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none_rounded, size: 34),
            ),
            Positioned(
              right: 5,
              top: 4,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accentRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '3',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.zone});

  final RiskZone zone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¡Hola, Juan!', style: AppTextStyles.headline1),
              const SizedBox(height: 6),
              Text(
                'Tu seguridad es nuestra prioridad.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wb_cloudy_rounded,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '8°C',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('El Alto', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecurityStatus extends StatelessWidget {
  const _SecurityStatus({
    required this.zone,
    required this.usingDeviceLocation,
  });

  final RiskZone zone;
  final bool usingDeviceLocation;

  @override
  Widget build(BuildContext context) {
    final title = switch (zone.level) {
      RiskLevel.high => 'Alerta',
      RiskLevel.medium => 'Precaución',
      RiskLevel.low => 'Zona tranquila',
    };

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          _ShieldStatus(color: zone.color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de seguridad actual',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.headline2.copyWith(color: zone.color),
                ),
                const SizedBox(height: 6),
                Text(
                  'Riesgo ${zone.label.toLowerCase()} en ${zone.name}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      usingDeviceLocation
                          ? Icons.my_location_rounded
                          : Icons.place_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        usingDeviceLocation
                            ? 'Calculado con tu ubicación real'
                            : 'Referencia del mapa de El Alto',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _RiskGauge(score: zone.score, color: zone.color, label: zone.label),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.currentPosition,
    required this.onMapCreated,
    required this.mapStyle,
    required this.onOpen,
  });

  final LatLng currentPosition;
  final ValueChanged<GoogleMapController> onMapCreated;
  final String mapStyle;
  final VoidCallback onOpen;

  Set<Circle> get _circles {
    return RiskMapData.zones.map((zone) {
      return Circle(
        circleId: CircleId(zone.name),
        center: zone.position,
        radius: zone.radiusMeters,
        fillColor: zone.color.withValues(alpha: 0.24),
        strokeColor: zone.color.withValues(alpha: 0.82),
        strokeWidth: 2,
      );
    }).toSet();
  }

  Set<Marker> get _markers {
    return {
      Marker(
        markerId: const MarkerId('current_position'),
        position: currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Ubicación de referencia'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 255,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                onMapCreated: onMapCreated,
                style: mapStyle,
                initialCameraPosition: CameraPosition(
                  target: currentPosition,
                  zoom: 12.8,
                ),
                circles: _circles,
                markers: _markers,
                polygons: {
                  Polygon(
                    polygonId: const PolygonId('el_alto_bounds'),
                    points: RiskMapData.elAltoBounds,
                    fillColor: AppColors.accentBlue.withValues(alpha: 0.06),
                    strokeColor: AppColors.accentBlue.withValues(alpha: 0.45),
                    strokeWidth: 2,
                  ),
                },
                liteModeEnabled: true,
                compassEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                onTap: (_) => onOpen(),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  const Expanded(child: _Legend()),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_full_rounded, size: 18),
                    label: const Text('Ver mapa'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      backgroundColor: AppColors.bgSurface.withValues(
                        alpha: 0.92,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
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

class _FeatureCards extends StatelessWidget {
  const _FeatureCards({
    required this.onLocation,
    required this.onMap,
    required this.onReport,
  });

  final VoidCallback onLocation;
  final VoidCallback onMap;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FeatureCard(
            icon: Icons.location_on_rounded,
            title: 'Mi ubicación',
            subtitle: 'en tiempo real',
            color: AppColors.accentBlue,
            onTap: onLocation,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FeatureCard(
            icon: Icons.map_rounded,
            title: 'Mapa',
            subtitle: 'predictivo',
            color: AppColors.accentBlueLight,
            onTap: onMap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FeatureCard(
            icon: Icons.report_rounded,
            title: 'Reportar',
            subtitle: 'robo',
            color: const Color(0xFFFF8A00),
            onTap: onReport,
          ),
        ),
      ],
    );
  }
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({required this.zone});

  final RiskZone zone;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: zone.color, size: 46),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendación del día',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  zone.level == RiskLevel.high
                      ? 'Estás cerca de una zona de alto riesgo. Evita calles con poca iluminación y comparte tu ubicación.'
                      : zone.description,
                  style: AppTextStyles.body.copyWith(height: 1.32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.onHome,
    required this.onProfile,
    required this.onAi,
    required this.onSettings,
    required this.onRate,
  });

  final VoidCallback onHome;
  final VoidCallback onProfile;
  final VoidCallback onAi;
  final VoidCallback onSettings;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.glassBorder)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.shield_rounded,
            label: 'Inicio',
            active: true,
            onTap: onHome,
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Mi perfil',
            onTap: onProfile,
          ),
          _AiButton(onTap: onAi),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Configuración',
            onTap: onSettings,
          ),
          _NavItem(
            icon: Icons.star_rounded,
            label: 'Califícanos',
            onTap: onRate,
          ),
        ],
      ),
    );
  }
}

class _ShieldStatus extends StatelessWidget {
  const _ShieldStatus({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 0.76,
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withValues(alpha: 0.16),
          ),
          Icon(Icons.shield_rounded, color: color, size: 56),
          const Icon(Icons.check_rounded, color: AppColors.bgDark, size: 30),
        ],
      ),
    );
  }
}

class _RiskGauge extends StatelessWidget {
  const _RiskGauge({
    required this.score,
    required this.color,
    required this.label,
  });

  final double score;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          SizedBox(
            width: 88,
            height: 62,
            child: CustomPaint(painter: _GaugePainter(score: score)),
          ),
          Text('Nivel de riesgo', style: AppTextStyles.caption),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.score});

  final double score;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(5, 10, size.width - 10, size.height * 1.35);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final colors = [
      AppColors.safeGreen,
      AppColors.warningAmber,
      const Color(0xFFFF8A00),
      AppColors.dangerRed,
    ];

    for (var i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        rect,
        math.pi + i * math.pi / 4,
        math.pi / 4,
        false,
        paint,
      );
    }

    final center = Offset(size.width / 2, rect.center.dy + 18);
    final angle = math.pi + (math.pi * score.clamp(0, 1));
    final end = Offset(
      center.dx + math.cos(angle) * 42,
      center.dy + math.sin(angle) * 42,
    );
    canvas.drawLine(
      center,
      end,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 134,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 46),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.bgDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.bgDark,
                    fontSize: 14,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(color: AppColors.safeGreen, label: 'Bajo'),
          _LegendItem(color: AppColors.warningAmber, label: 'Medio'),
          _LegendItem(color: Color(0xFFFF8A00), label: 'Alto'),
          _LegendItem(color: AppColors.dangerRed, label: 'Crítico'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active
                  ? AppColors.accentBlueLight
                  : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: active
                      ? AppColors.accentBlueLight
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiButton extends StatelessWidget {
  const _AiButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(38),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF785BFF), AppColors.accentBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.55),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Hablar con IA',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsSheet extends StatelessWidget {
  const _AlertsSheet({required this.zone});

  final RiskZone zone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alertas recientes', style: AppTextStyles.headline2),
          const SizedBox(height: 14),
          _AlertRow(
            icon: Icons.radar_rounded,
            color: zone.color,
            text: '${zone.name}: riesgo ${zone.label.toLowerCase()} detectado.',
          ),
          const _AlertRow(
            icon: Icons.lightbulb_rounded,
            color: AppColors.warningAmber,
            text: 'Evita rutas poco iluminadas durante la noche.',
          ),
          const _AlertRow(
            icon: Icons.my_location_rounded,
            color: AppColors.accentBlueLight,
            text: 'Activa tu ubicación en tiempo real al desplazarte.',
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

Future<void> callEmergencyNumber(BuildContext context, String number) async {
  final launched = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!context.mounted || launched) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('No se pudo iniciar la llamada al $number')),
  );
}
