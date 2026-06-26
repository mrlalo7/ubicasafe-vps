import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/pages/nivelesriesgo.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';

class MapaRiesgo extends StatefulWidget {
  const MapaRiesgo({super.key});

  @override
  State<MapaRiesgo> createState() => _MapaRiesgoState();
}

class _MapaRiesgoState extends State<MapaRiesgo> {
  GoogleMapController? _mapController;
  final Set<Circle> _circulosRiesgo = {};
  final Set<Polygon> _poligonosElAlto = {};
  final Set<Marker> _markers = {};
  Position? _currentPosition;

  // Estilo oscuro premium para Google Maps
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#263c3f"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6b9a76"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#38414e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#212a37"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#9ca5b3"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#746855"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#1f2835"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#f3d19c"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#17263c"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#515c6d"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#17263c"}]
    }
  ]
  ''';

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

  // ZONAS DE RIESGO
  final List<Map<String, dynamic>> _zonasRiesgo = [
    {
      'nombre': 'UPEA - Universidad Pública de El Alto',
      'lat': -16.491033,
      'lng': -68.193479,
      'radio': 400,
      'riesgo': 'alto',
      'descripcion': 'Sede principal de la UPEA. Múltiples reportes de robos en los alrededores.',
    },
    {
      'nombre': 'Puente Vela',
      'lat': -16.5975,
      'lng': -68.1842,
      'radio': 250,
      'riesgo': 'alto',
      'descripcion': 'Peligroso a partir de las 8:00 pm en adelante.',
    },
    {
      'nombre': 'Zona 12 de Octubre',
      'lat': -16.5118,
      'lng': -68.1632,
      'radio': 149,
      'riesgo': 'alto',
      'descripcion': 'Zona peligrosa por múltiples reportes a partir de las 8:00 pm.',
    },
    {
      'nombre': 'La Ceja de El Alto',
      'lat': -16.5034,
      'lng': -68.1625,
      'radio': 180,
      'riesgo': 'alto',
      'descripcion': 'Zona comercial principal. ALTO RIESGO en el Pasaje Artesanal y áreas aledañas.',
    },
    {
      'nombre': 'Feria 16 de Julio',
      'lat': -16.4942,
      'lng': -68.1736,
      'radio': 450,
      'riesgo': 'alto',
      'descripcion': 'Alta incidencia de robos por distracción en aglomeraciones.',
    },
    {
      'nombre': 'Terminal Metropolitana',
      'lat': -16.52073,
      'lng': -68.17723,
      'radio': 380,
      'riesgo': 'alto',
      'descripcion': 'Terminal con alta afluencia. Reportes frecuentes de asaltos.',
    },
    {
      'nombre': 'Senkata',
      'lat': -16.5702,
      'lng': -68.1862,
      'radio': 380,
      'riesgo': 'alto',
      'descripcion': 'Lugar alejado. Reportes frecuentes de robos.',
    },
    {
      'nombre': 'Terminal de Buses Río Seco',
      'lat': -16.4878,
      'lng': -68.2002,
      'radio': 350,
      'riesgo': 'alto',
      'descripcion': 'Zona de terminal con alta incidencia delictiva.',
    },
    {
      'nombre': 'Avenida 6 de Marzo',
      'lat': -16.5059,
      'lng': -68.1631,
      'radio': 100,
      'riesgo': 'alto',
      'descripcion': 'Múltiples reportes de robos al paso.',
    },
    // RIESGO MEDIO
    {
      'nombre': 'Mercado Satélite',
      'lat': -16.5247,
      'lng': -68.1506,
      'radio': 280,
      'riesgo': 'medio',
      'descripcion': 'Robos ocasionales por distracción.',
    },
    {
      'nombre': 'Plaza La Paz',
      'lat': -16.4919,
      'lng': -68.1832,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion': 'Incidentes esporádicos en horarios de menor tránsito.',
    },
    {
      'nombre': 'Estacion Teleferico Azul',
      'lat': -16.4893,
      'lng': -68.1931,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion': 'Zona transitada, precauciones en la noche.',
    },
    {
      'nombre': 'Universidad Franz Tamayo (UNIFRANZ)',
      'lat': -16.5085,
      'lng': -68.1663,
      'radio': 200,
      'riesgo': 'medio',
      'descripcion': 'Concurrencia universitaria.',
    },
    {
      'nombre': 'Universidad Técnica Privada Cosmos',
      'lat': -16.5245,
      'lng': -68.2131,
      'radio': 200,
      'riesgo': 'medio',
      'descripcion': 'Concurrencia universitaria.',
    },
    {
      'nombre': 'Universidad Salesiana de Bolivia (USB)',
      'lat': -16.4770,
      'lng': -68.1487,
      'radio': 200,
      'riesgo': 'medio',
      'descripcion': 'Concurrencia universitaria.',
    },
    {
      'nombre': 'Ballivian',
      'lat': -16.4893,
      'lng': -68.1805,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion': 'Zona transitada.',
    },
    {
      'nombre': 'Estadio Municipal de El Alto',
      'lat': -16.4713,
      'lng': -68.2018,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion': 'Zona transitada, precauciones los días de partido.',
    },
    {
      'nombre': 'Cementerio General Mercedario',
      'lat': -16.5292,
      'lng': -68.2481,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion': 'Zona transitada, evitar la noche.',
    },
    {
      'nombre': 'Achocalla',
      'lat': -16.4500,
      'lng': -68.1200,
      'radio': 300,
      'riesgo': 'medio',
      'descripcion': 'Área periurbana con riesgo medio.',
    },
    // BAJO RIESGO
    {
      'nombre': 'Alto Lima',
      'lat': -16.4765,
      'lng': -68.1751,
      'radio': 350,
      'riesgo': 'bajo',
      'descripcion': 'Urbanización. Seguridad y baja incidencia.',
    },
    {
      'nombre': 'Villa Ingenio',
      'lat': -16.4750,
      'lng': -68.2000,
      'radio': 400,
      'riesgo': 'bajo',
      'descripcion': 'Zona residencial tranquila.',
    },
    {
      'nombre': 'Rio seco',
      'lat': -16.4868,
      'lng': -68.2086,
      'radio': 380,
      'riesgo': 'bajo',
      'descripcion': 'Zona residencial organizada. Vigilancia vecinal.',
    },
    {
      'nombre': 'Ciudad Satélite',
      'lat': -16.5282,
      'lng': -68.1542,
      'radio': 380,
      'riesgo': 'bajo',
      'descripcion': 'Zona residencial organizada. Vigilancia vecinal.',
    },
    {
      'nombre': 'Estacion Linea Morada',
      'lat': -16.5221,
      'lng': -68.1694,
      'radio': 380,
      'riesgo': 'bajo',
      'descripcion': 'Zona transitada pero con vigilancia.',
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _cargarZonasRiesgo();
    _cargarPoligonoElAlto();
    _getCurrentLocation();
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
        _mostrarErrorUbicacion('Los permisos de ubicación están permanentemente denegados');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      _agregarMarcadorUbicacion();

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      _mostrarErrorUbicacion('Error al obtener la ubicación');
    }
  }

  void _agregarMarcadorUbicacion() {
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('mi_ubicacion'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'Mi Ubicación Actual',
            snippet: 'Estás aquí',
          ),
          consumeTapEvents: true,
        ),
      );
      setState(() {});
    }
  }

  void _mostrarErrorUbicacion(String mensaje) {
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

  void _cargarZonasRiesgo() {
    _circulosRiesgo.clear();

    for (var zona in _zonasRiesgo) {
      final Color color = _obtenerColorRiesgo(zona['riesgo']);

      _circulosRiesgo.add(
        Circle(
          circleId: CircleId(zona['nombre']),
          center: LatLng(zona['lat'], zona['lng']),
          radius: zona['radio'].toDouble(),
          fillColor: color.withOpacity(0.25),
          strokeColor: color.withOpacity(0.8),
          strokeWidth: 2,
        ),
      );
    }

    setState(() {});
  }

  void _cargarPoligonoElAlto() {
    _poligonosElAlto.add(
      Polygon(
        polygonId: const PolygonId('el_alto_fondo'),
        points: _limitesElAlto,
        fillColor: AppColors.accentBlue.withOpacity(0.08),
        strokeColor: Colors.transparent,
        strokeWidth: 0,
        geodesic: true,
      ),
    );

    _poligonosElAlto.add(
      Polygon(
        polygonId: const PolygonId('el_alto_limites'),
        points: _limitesElAlto,
        fillColor: Colors.transparent,
        strokeColor: AppColors.accentBlue.withOpacity(0.5),
        strokeWidth: 2,
        geodesic: true,
      ),
    );
  }

  Color _obtenerColorRiesgo(String riesgo) {
    switch (riesgo) {
      case 'alto':
        return AppColors.dangerRed;
      case 'medio':
        return AppColors.warningAmber;
      case 'bajo':
        return AppColors.safeGreen;
      default:
        return AppColors.textHint;
    }
  }

  void _mostrarInfoZona(String nombreZona) {
    final zona = _zonasRiesgo.firstWhere((z) => z['nombre'] == nombreZona);
    final color = _obtenerColorRiesgo(zona['riesgo']);

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
                      Text(zona['nombre'], style: AppTextStyles.headline3),
                      Text(
                        'Riesgo: ${zona['riesgo'].toString().toUpperCase()}',
                        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(zona['descripcion'], style: AppTextStyles.body),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.radar_rounded, color: AppColors.textHint, size: 16),
                const SizedBox(width: 8),
                Text('Radio: ${zona['radio']}m', style: AppTextStyles.caption),
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
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MapaPredictivo()),
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
          child: Text('Mapa de Riesgo', style: AppTextStyles.headline3.copyWith(fontSize: 16)),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              controller.setMapStyle(_mapStyle);
              setState(() {
                _mapController = controller;
              });
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(-16.5000, -68.2000),
              zoom: 13.0,
            ),
            circles: _circulosRiesgo,
            polygons: _poligonosElAlto,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (LatLng position) {
              for (var zona in _zonasRiesgo) {
                final distancia = _calcularDistancia(
                  position.latitude,
                  position.longitude,
                  zona['lat'],
                  zona['lng'],
                );

                if (distancia <= zona['radio']) {
                  _mostrarInfoZona(zona['nombre']);
                  break;
                }
              }
            },
          ),

          // Leyenda interactiva flotante
          Positioned(
            top: 100,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NivelesRiesgoScreen()),
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
                          Text('Leyenda', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
                          const Icon(Icons.info_outline, color: AppColors.textHint, size: 14),
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
                              border: Border.all(color: AppColors.accentBlue, width: 1),
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
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: AppShadows.blueGlow),
            child: FloatingActionButton(
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(const LatLng(-16.5000, -68.2000)),
                );
              },
              backgroundColor: AppColors.accentBlue,
              heroTag: "btn_centro",
              mini: true,
              elevation: 0,
              child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: AppShadows.card),
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: AppColors.bgSurface,
              heroTag: "btn_ubicacion",
              elevation: 0,
              child: const Icon(Icons.my_location_rounded, color: AppColors.accentBlue),
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

  double _calcularDistancia(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
