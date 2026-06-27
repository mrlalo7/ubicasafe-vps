import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/data/risk_zones.dart';
import 'package:ubicasafe/pages/chat_ia.dart';
import 'package:ubicasafe/pages/configuracion.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';
import 'package:ubicasafe/pages/mapariesgo.dart';
import 'package:ubicasafe/pages/miperfil.dart';
import 'package:ubicasafe/pages/reportarrobo.dart';
import 'package:ubicasafe/pages/ubicaciontiemporeal.dart';
import 'package:ubicasafe/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  LatLng _currentPosition = RiskMapData.defaultCenter;
  List<RiskZone> _zones = RiskMapData.zones;
  bool _usingDeviceLocation = false;
  bool _usingBackendZones = false;
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

  RiskZone get _activeZone =>
      RiskMapData.effectiveZoneFor(_currentPosition, source: _zones);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _loadZones();
    _loadLocation();
  }

  Future<void> _loadZones() async {
    final zones = await ApiService().getRiskZones();
    if (!mounted || zones.isEmpty) return;
    setState(() {
      _zones = zones;
      _usingBackendZones = true;
    });
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
                      _Greeting(position: _currentPosition),
                      const SizedBox(height: 18),
                      _SecurityStatus(
                        zone: zone,
                        usingDeviceLocation: _usingDeviceLocation,
                      ),
                      const SizedBox(height: 16),
                      _MapPreview(
                        currentPosition: _currentPosition,
                        zones: _zones,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        mapStyle: _mapStyle,
                        usingBackendZones: _usingBackendZones,
                        onOpen: () => _open(const MapaRiesgo()),
                      ),
                      const SizedBox(height: 18),
                      _FeatureCards(
                        onLocation: () => _open(const UbicacionTiempoReal()),
                        onMap: () => _open(const MapaPredictivo()),
                        onReport: () => _open(const ReportarRobo()),
                      ),
                      const SizedBox(height: 18),
                      _RecommendationCarousel(zone: zone),
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
                  onSos: _showEmergencyDialog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog() {
    HapticFeedback.vibrate();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1E36),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emergency_rounded,
                    color: AppColors.accentRed,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'CENTRO DE EMERGENCIA',
                    style: AppTextStyles.headline3.copyWith(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Presiona un número para realizar una llamada de auxilio de inmediato.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildEmergencyItem(
                context,
                name: 'Policía Nacional',
                number: '110',
                icon: Icons.local_police_rounded,
                color: Colors.blueAccent,
              ),
              _buildEmergencyItem(
                context,
                name: 'Bomberos',
                number: '119',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.accentRed,
              ),
              _buildEmergencyItem(
                context,
                name: 'Emergencias Médicas',
                number: '165',
                icon: Icons.medical_services_rounded,
                color: AppColors.safeGreen,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyItem(
    BuildContext context, {
    required String name,
    required String number,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            Navigator.pop(context);
            final Uri telUri = Uri(scheme: 'tel', path: number);
            if (await canLaunchUrl(telUri)) {
              await launchUrl(telUri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Marcar $number',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.call_rounded,
                  color: AppColors.safeGreen,
                  size: 20,
                ),
              ],
            ),
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
                        color: Colors.cyanAccent,
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

class _Greeting extends StatefulWidget {
  const _Greeting({required this.position});

  final LatLng position;

  @override
  State<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends State<_Greeting> {
  String _temperature = '8°C';
  IconData _weatherIcon = Icons.wb_cloudy_rounded;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  void didUpdateWidget(covariant _Greeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final lat = widget.position.latitude;
      final lng = widget.position.longitude;
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,weather_code',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final temp = current['temperature_2m'];
        final code = current['weather_code'] as int;

        if (mounted) {
          setState(() {
            _temperature = '${temp.toStringAsFixed(0)}°C';
            _weatherIcon = _mapWeatherCodeToIcon(code);
          });
        }
      }
    } catch (_) {
      // Ignorar errores, mantiene el valor por defecto
    }
  }

  IconData _mapWeatherCodeToIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.cloud_queue_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return Icons.umbrella_rounded;
    }
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.wb_cloudy_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¡Hola, Juan!',
                style: AppTextStyles.headline2.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tu seguridad es nuestra prioridad.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_weatherIcon, color: Colors.white, size: 24),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _temperature,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'El Alto',
                    style: AppTextStyles.caption.copyWith(fontSize: 9),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          _ShieldStatus(color: zone.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estado de seguridad actual',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTextStyles.headline3.copyWith(
                    color: zone.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Riesgo ${zone.label.toLowerCase()} en ${zone.name}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      usingDeviceLocation
                          ? Icons.my_location_rounded
                          : Icons.place_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        usingDeviceLocation
                            ? 'Ubicación real'
                            : 'Referencia del mapa',
                        style: AppTextStyles.caption.copyWith(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RiskGauge(score: zone.score, color: zone.color, label: zone.label),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.currentPosition,
    required this.zones,
    required this.onMapCreated,
    required this.mapStyle,
    required this.usingBackendZones,
    required this.onOpen,
  });

  final LatLng currentPosition;
  final List<RiskZone> zones;
  final ValueChanged<GoogleMapController> onMapCreated;
  final String mapStyle;
  final bool usingBackendZones;
  final VoidCallback onOpen;

  Set<Circle> get _circles {
    return zones.map((zone) {
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
                  if (usingBackendZones) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.safeGreen.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.safeGreen.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        'VPS',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.safeGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
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

class _RecommendationCarousel extends StatefulWidget {
  const _RecommendationCarousel({required this.zone});
  final RiskZone zone;

  @override
  State<_RecommendationCarousel> createState() =>
      _RecommendationCarouselState();
}

class _RecommendationCarouselState extends State<_RecommendationCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _recommendations = [
    {
      'title': 'Recomendación del día',
      'text':
          'Evita transitar por zonas con poca iluminación durante la noche, planificando rutas concurridas.',
      'image': 'assets/img/rec_iluminacion.png',
    },
    {
      'title': 'Consejo de transporte',
      'text':
          'Guarda tu celular al estar cerca de las ventanas del auto o minibús. Evita robos al paso.',
      'image': 'assets/img/rec_celular.png',
    },
    {
      'title': 'Lugares concurridos',
      'text':
          'Mantén tu mochila al frente en zonas concurridas (ej. La Ceja) para evitar robos por distracción.',
      'image': 'assets/img/rec_mochila.png',
    },
    {
      'title': 'Perfil seguro',
      'text':
          'Evita mostrar objetos de valor como cadenas o audífonos llamativos en la vía pública.',
      'image': 'assets/img/rec_valor.png',
    },
    {
      'title': 'Compartir ruta',
      'text':
          'Comparte tu ubicación en tiempo real con familiares o contactos de confianza cuando viajes de noche.',
      'image': 'assets/img/rec_ubicacion.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _recommendations.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 126,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final rec = _recommendations[index];
                return Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.warning_amber_rounded,
                      color: index == 0 ? widget.zone.color : Colors.cyanAccent,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              rec['title']!,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Text(
                                  rec['text']!,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                      child: Image.asset(
                        rec['image']!,
                        width: 110,
                        height: 126,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              left: 64,
              bottom: 12,
              child: Row(
                children: List.generate(
                  _recommendations.length,
                  (index) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.cyanAccent
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    required this.onSos,
  });

  final VoidCallback onHome;
  final VoidCallback onProfile;
  final VoidCallback onAi;
  final VoidCallback onSettings;
  final VoidCallback onSos;

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
            icon: Icons.emergency_rounded,
            label: 'S.O.S.',
            iconColor: AppColors.accentRed,
            onTap: onSos,
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
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 0.76,
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withValues(alpha: 0.16),
          ),
          Icon(Icons.shield_rounded, color: color, size: 28),
          const Icon(Icons.check_rounded, color: AppColors.bgDark, size: 16),
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
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            height: 46,
            child: CustomPaint(painter: _GaugePainter(score: score)),
          ),
          const SizedBox(height: 2),
          Text(
            'Nivel de riesgo',
            style: AppTextStyles.caption.copyWith(fontSize: 9),
            textAlign: TextAlign.center,
          ),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
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
    final strokeWidth = size.width * 0.12;

    // Calculate radius to fit perfectly in size.width as a circle
    final radius = (size.width - strokeWidth - 4) / 2;

    // Center at the bottom, leaving a small 2px padding at the bottom of the box
    final center = Offset(size.width / 2, size.height - 2);

    // Create a perfect square rect centered at `center`
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt; // Clean flat caps for inner connections

    final colors = [
      const Color(0xFF2ECC71), // Verde bajo
      const Color(0xFF9BD85A), // Verde claro
      const Color(0xFFF1C40F), // Amarillo medio
      const Color(0xFFE67E22), // Naranja alto
      const Color(0xFFE74C3C), // Rojo crítico
    ];

    final segmentAngle = math.pi / 5;

    for (var i = 0; i < 5; i++) {
      paint.color = colors[i];
      final start = math.pi + i * segmentAngle;
      canvas.drawArc(
        rect,
        start,
        segmentAngle + 0.015, // Overlap to prevent hairline gaps
        false,
        paint,
      );
    }

    // Draw rounded cap at the start (green)
    final capPaint = Paint()..style = PaintingStyle.fill;
    capPaint.color = colors[0];
    canvas.drawCircle(
      Offset(center.dx - radius, center.dy),
      strokeWidth / 2,
      capPaint,
    );

    // Draw rounded cap at the end (red)
    capPaint.color = colors[4];
    canvas.drawCircle(
      Offset(center.dx + radius, center.dy),
      strokeWidth / 2,
      capPaint,
    );

    // Draw premium tapered pointer needle
    final baseRadius = size.width * 0.10;
    // Needle tip points to the middle-outer edge of the colored arc
    final needleLength = radius + strokeWidth * 0.2;
    final angle = math.pi + (math.pi * score.clamp(0, 1));

    final perpAngle1 = angle - math.pi / 2;
    final perpAngle2 = angle + math.pi / 2;

    final p1 = Offset(
      center.dx + math.cos(perpAngle1) * (baseRadius * 0.7),
      center.dy + math.sin(perpAngle1) * (baseRadius * 0.7),
    );
    final p2 = Offset(
      center.dx + math.cos(perpAngle2) * (baseRadius * 0.7),
      center.dy + math.sin(perpAngle2) * (baseRadius * 0.7),
    );
    final tip = Offset(
      center.dx + math.cos(angle) * needleLength,
      center.dy + math.sin(angle) * needleLength,
    );

    final needlePath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw pointer body
    canvas.drawPath(needlePath, needlePaint);

    // Draw circular base
    canvas.drawCircle(center, baseRadius, needlePaint);

    // Draw inner dark center pin
    canvas.drawCircle(
      center,
      baseRadius * 0.4,
      Paint()..color = const Color(0xFF080C18), // matching AppColors.bgDark
    );
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
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final finalColor =
        iconColor ??
        (active ? AppColors.accentBlueLight : AppColors.textSecondary);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: finalColor, size: 28),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: finalColor,
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
