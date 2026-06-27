import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:latlong2/latlong.dart' as ll;
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/data/risk_zones.dart';
import 'package:ubicasafe/pages/nivelesriesgo.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';
import 'package:ubicasafe/services/api_service.dart';

class MapaRiesgo extends StatefulWidget {
  const MapaRiesgo({super.key});

  @override
  State<MapaRiesgo> createState() => _MapaRiesgoState();
}

class _MapaRiesgoState extends State<MapaRiesgo> {
  final fm.MapController _mapController = fm.MapController();
  Position? _currentPosition;

  // LÍMITES EXTENDIDOS DE EL ALTO - CUBRIENDO TODOS LOS PUNTOS
  final List<LatLng> _limitesElAlto = [
    const LatLng(-16.4500, -68.1200),
    const LatLng(-16.4550, -68.1300),
    const LatLng(-16.4600, -68.1400),
    const LatLng(-16.4700, -68.1450),
    const LatLng(-16.4750, -68.1500),
    const LatLng(-16.4650, -68.1600),
    const LatLng(-16.4600, -68.1700),
    const LatLng(-16.4550, -68.1800),
    const LatLng(-16.4500, -68.1900),
    const LatLng(-16.4450, -68.2000),
    const LatLng(-16.4500, -68.2100),
    const LatLng(-16.4550, -68.2200),
    const LatLng(-16.4650, -68.2300),
    const LatLng(-16.4750, -68.2350),
    const LatLng(-16.4850, -68.2400),
    const LatLng(-16.4950, -68.2450),
    const LatLng(-16.5050, -68.2500),
    const LatLng(-16.5150, -68.2550),
    const LatLng(-16.5250, -68.2600),
    const LatLng(-16.5350, -68.2650),
    const LatLng(-16.5450, -68.2700),
    const LatLng(-16.5550, -68.2750),
    const LatLng(-16.5650, -68.2800),
    const LatLng(-16.5750, -68.2850),
    const LatLng(-16.5850, -68.1900),
    const LatLng(-16.5900, -68.1850),
    const LatLng(-16.5950, -68.1800),
    const LatLng(-16.5800, -68.1750),
    const LatLng(-16.5700, -68.1700),
    const LatLng(-16.5600, -68.1650),
    const LatLng(-16.5500, -68.1600),
    const LatLng(-16.5400, -68.1550),
    const LatLng(-16.5300, -68.1500),
    const LatLng(-16.5200, -68.1450),
    const LatLng(-16.5100, -68.1400),
    const LatLng(-16.5000, -68.1350),
    const LatLng(-16.4900, -68.1300),
    const LatLng(-16.4800, -68.1250),
    const LatLng(-16.4700, -68.1250),
    const LatLng(-16.4600, -68.1250),
    const LatLng(-16.4500, -68.1200),
  ];

  List<RiskZone> _zonasRiesgo = RiskMapData.zones;
  bool _usingBackendZones = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _cargarZonasRiesgo();
    _cargarZonasDesdeBackend();
    _cargarPoligonoElAlto();
    _getCurrentLocation();
  }

  Future<void> _cargarZonasDesdeBackend() async {
    final zones = await ApiService().getRiskZones();
    if (!mounted || zones.isEmpty) return;
    setState(() {
      _zonasRiesgo = zones;
      _usingBackendZones = true;
    });
    _cargarZonasRiesgo();
  }

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mostrarErrorUbicacion('El servicio de ubicación está desactivado');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarErrorUbicacion('Permisos de ubicación denegados');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mostrarErrorUbicacion(
          'Los permisos de ubicación están permanentemente denegados',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      _agregarMarcadorUbicacion();

      _mapController.move(ll.LatLng(position.latitude, position.longitude), 15);
    } catch (e) {
      _mostrarErrorUbicacion('Error al obtener la ubicación');
    }
  }

  void _agregarMarcadorUbicacion() {
    if (_currentPosition != null) {
      setState(() {});
    }
  }

  void _mostrarErrorUbicacion(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.accentRed,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
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

  void _cargarZonasRiesgo() {
    setState(() {});
  }

  void _cargarPoligonoElAlto() {}

  ll.LatLng _point(LatLng point) {
    return ll.LatLng(point.latitude, point.longitude);
  }

  List<fm.CircleMarker> get _riskCircles {
    return _zonasRiesgo.map((zona) {
      return fm.CircleMarker(
        point: _point(zona.position),
        radius: zona.radiusMeters,
        useRadiusInMeter: true,
        color: zona.color.withValues(alpha: 0.25),
        borderColor: zona.color.withValues(alpha: 0.8),
        borderStrokeWidth: 2,
      );
    }).toList();
  }

  List<fm.Marker> get _mapMarkers {
    final position = _currentPosition;
    if (position == null) return const [];

    return [
      fm.Marker(
        point: ll.LatLng(position.latitude, position.longitude),
        width: 46,
        height: 46,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentBlueLight, width: 2),
          ),
          child: const Icon(
            Icons.my_location_rounded,
            color: AppColors.accentBlueLight,
            size: 24,
          ),
        ),
      ),
    ];
  }

  void _mostrarInfoZona(String nombreZona) {
    final zona = _zonasRiesgo.firstWhere((z) => z.name == nombreZona);
    final color = zona.color;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_rounded, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zona.name, style: AppTextStyles.headline3),
                      Text(
                        'Riesgo: ${zona.label.toUpperCase()}',
                        style: AppTextStyles.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(zona.description, style: AppTextStyles.body),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  color: AppColors.textHint,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Radio: ${zona.radiusMeters.toStringAsFixed(0)}m',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: 'Cerrar',
                height: 44,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard.withOpacity(0.85),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 18,
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapaPredictivo(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            'Mapa de Riesgo',
            style: AppTextStyles.headline3.copyWith(fontSize: 16),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          fm.FlutterMap(
            mapController: _mapController,
            options: fm.MapOptions(
              initialCenter: const ll.LatLng(-16.5000, -68.2000),
              initialZoom: 13.0,
              onTap: (_, position) {
                for (final zona in _zonasRiesgo) {
                  final distancia = _calcularDistancia(
                    position.latitude,
                  position.longitude,
                  zona.position.latitude,
                  zona.position.longitude,
                );

                if (distancia <= zona.radiusMeters) {
                  _mostrarInfoZona(zona.name);
                  break;
                  }
                }
              },
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ubicasafe',
                retinaMode: fm.RetinaMode.isHighDensity(context),
              ),
              fm.PolygonLayer(
                polygons: [
                  fm.Polygon(
                    points: _limitesElAlto.map(_point).toList(),
                    color: AppColors.accentBlue.withValues(alpha: 0.08),
                    borderColor: Colors.transparent,
                    borderStrokeWidth: 0,
                  ),
                  fm.Polygon(
                    points: _limitesElAlto.map(_point).toList(),
                    color: Colors.transparent,
                    borderColor: AppColors.accentBlue.withValues(alpha: 0.5),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              fm.CircleLayer(circles: _riskCircles),
              fm.MarkerLayer(markers: _mapMarkers),
            ],
          ),

          // Leyenda interactiva flotante
          Positioned(
            top: 100,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NivelesRiesgoScreen(),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withOpacity(0.9),
                    border: Border.all(color: AppColors.glassBorder),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Leyenda',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.textHint,
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _leyendaItem(AppColors.dangerRed, "Alto Riesgo"),
                      _leyendaItem(AppColors.warningAmber, "Medio Riesgo"),
                      _leyendaItem(AppColors.safeGreen, "Bajo Riesgo"),
                      const SizedBox(height: 8),
                      Container(height: 1, color: AppColors.glassBorder),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withOpacity(0.2),
                              border: Border.all(
                                color: AppColors.accentBlue,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Área El Alto', style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _usingBackendZones
                        ? Icons.cloud_done_rounded
                        : Icons.offline_bolt_rounded,
                    color: _usingBackendZones
                        ? AppColors.safeGreen
                        : AppColors.warningAmber,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _usingBackendZones ? 'VPS' : 'Offline',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppShadows.blueGlow,
            ),
            child: FloatingActionButton(
              onPressed: () {
                _mapController.move(const ll.LatLng(-16.5000, -68.2000), 13);
              },
              backgroundColor: AppColors.accentBlue,
              heroTag: "btn_centro",
              mini: true,
              elevation: 0,
              child: const Icon(
                Icons.center_focus_strong_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppShadows.card,
            ),
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: AppColors.bgSurface,
              heroTag: "btn_ubicacion",
              elevation: 0,
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leyendaItem(Color color, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(texto, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  double _calcularDistancia(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
