import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  // ignore: unused_field
  String _horarioSeleccionado = 'Todo el día';
  Position? _currentPosition;

  // LÍMITES EXTENDIDOS DE EL ALTO - CUBRIENDO TODOS LOS PUNTOS
  final List<LatLng> _limitesElAlto = [
    // EXTENDIDO HACIA EL SURESTE - ACHOCALLA
    const LatLng(-16.4500, -68.1200), // Achocalla - Punto más al sureste
    const LatLng(-16.4550, -68.1300),
    const LatLng(-16.4600, -68.1400),

    // ESTE - ZONA UNIVERSIDAD SALESIANA
    const LatLng(-16.4700, -68.1450),
    const LatLng(-16.4750, -68.1500),

    // NORESTE - ZONA ALTO LIMA
    const LatLng(-16.4650, -68.1600),
    const LatLng(-16.4600, -68.1700),
    const LatLng(-16.4550, -68.1800),

    // NORTE - ZONA VILLA ADELA / 16 DE JULIO
    const LatLng(-16.4500, -68.1900),
    const LatLng(-16.4450, -68.2000),

    // NOROESTE - ZONA VILLA FREENO / RÍO SECO
    const LatLng(-16.4500, -68.2100),
    const LatLng(-16.4550, -68.2200),

    // OESTE - EXTENDIDO HACIA PUENTE VELA Y CEMENTERIO MERCEDARIO
    const LatLng(-16.4650, -68.2300),
    const LatLng(-16.4750, -68.2350),
    const LatLng(-16.4850, -68.2400), // Cementerio General Mercedario
    const LatLng(-16.4950, -68.2450),
    const LatLng(-16.5050, -68.2500),

    // SUROESTE - EXTENDIDO HACIA PUENTE VELA
    const LatLng(-16.5150, -68.2550),
    const LatLng(-16.5250, -68.2600),
    const LatLng(-16.5350, -68.2650),
    const LatLng(-16.5450, -68.2700),
    const LatLng(-16.5550, -68.2750),
    const LatLng(-16.5650, -68.2800),
    const LatLng(-16.5750, -68.2850),
    const LatLng(-16.5850, -68.1900), // Puente Vela - Punto más al suroeste
    const LatLng(-16.5900, -68.1850),
    const LatLng(-16.5950, -68.1800), // Puente Vela
    // SUR - ZONA SENKATA / DISTRITO 8
    const LatLng(-16.5800, -68.1750),
    const LatLng(-16.5700, -68.1700),
    const LatLng(-16.5600, -68.1650),
    const LatLng(-16.5500, -68.1600),

    // SURESTE - ZONA 12 DE OCTUBRE / CIUDAD SATÉLITE
    const LatLng(-16.5400, -68.1550),
    const LatLng(-16.5300, -68.1500),
    const LatLng(-16.5200, -68.1450),
    const LatLng(-16.5100, -68.1400),
    const LatLng(-16.5000, -68.1350),
    const LatLng(-16.4900, -68.1300),
    const LatLng(-16.4800, -68.1250),

    // REGRESO AL PUNTO INICIAL - ACHOCALLA
    const LatLng(-16.4700, -68.1250),
    const LatLng(-16.4600, -68.1250),
    const LatLng(-16.4500, -68.1200),
  ];

  // ZONAS DE RIESGO (mantener igual que antes)
  final List<Map<String, dynamic>> _zonasRiesgo = [
    // 🔴 ALTO RIESGO - COORDENADAS CORREGIDAS
    {
      'nombre': 'UPEA - Universidad Pública de El Alto',
      'lat': -16.491033,
      'lng': -68.193479,
      'radio': 400,
      'riesgo': 'alto',
      'descripcion':
          'Sede principal de la UPEA. Múltiples reportes de robos en los alrededores, especialmente en horarios de entrada y salida de clases.',
    },
    {
      'nombre': 'Puente Vela ',
      'lat': -16.5975,
      'lng': -68.1842,
      'radio': 250,
      'riesgo': 'alto',
      'descripcion':
          'Puente vela limite de la paz, peligroso por el mismo motivo a partir de las 8:00 pm en adelante',
    },
    {
      'nombre': 'Zona 12 de Octubre ',
      'lat': -16.5118,
      'lng': -68.1632,
      'radio': 149,
      'riesgo': 'alto',
      'descripcion':
          'La zona 12 de octubre es una zona peligrosa por el mismo motivo que se reportaron robos, asesinatos y demas, a partir de las 8:00 pm en adelante',
    },
    {
      'nombre': 'La Ceja de El Alto',
      'lat': -16.5034,
      'lng': -68.1625,
      'radio': 180,
      'riesgo': 'alto',
      'descripcion':
          'Zona comercial principal de El Alto. ALTO RIESGO en el Pasaje Artesanal Wata Wara y áreas aledañas. Reportes frecuentes de robos.',
    },
    {
      'nombre': 'Feria 16 de Julio',
      'lat': -16.4942,
      'lng': -68.1736,
      'radio': 450,
      'riesgo': 'alto',
      'descripcion':
          'Feria más grande de El Alto. Alta incidencia de robos por distracción en aglomeraciones.',
    },
    {
      'nombre': 'Terminal Metropolitana de El Alto',
      'lat': -16.52073,
      'lng': -68.17723,
      'radio': 380,
      'riesgo': 'alto',
      'descripcion':
          'Terminal metropolitana con alta afluencia. Reportes frecuentes de robos y asaltos.',
    },
    {
      'nombre': 'Senkata ',
      'lat': -16.5702,
      'lng': -68.1862,
      'radio': 380,
      'riesgo': 'alto',
      'descripcion':
          'Senkata lugar alejado. Reportes frecuentes de robos y asaltos.',
    },
    {
      'nombre': 'Terminal de Buses Río Seco',
      'lat': -16.4878,
      'lng': -68.2002,
      'radio': 350,
      'riesgo': 'alto',
      'descripcion':
          'Zona de terminal con alta incidencia delictiva. Se recomienda extremar precauciones.',
    },
    {
      'nombre': 'Avenida 6 de Marzo',
      'lat': -16.5059,
      'lng': -68.1631,
      'radio': 100,
      'riesgo': 'alto',
      'descripcion':
          'Avenida principal con alto tráfico vehicular y peatonal. Múltiples reportes de robos al paso.',
    },

    // 🟠 RIESGO MEDIO
    {
      'nombre': 'Mercado Satélite',
      'lat': -16.5247,
      'lng': -68.1506,
      'radio': 280,
      'riesgo': 'medio',
      'descripcion':
          'Mercado local. Robos ocasionales por distracción en horas comerciales.',
    },
    {
      'nombre': 'Plaza La Paz',
      'lat': -16.4919,
      'lng': -68.1832,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion':
          'Área comercial y recreativa. Incidentes esporádicos en horarios de menor tránsito.',
    },
    {
      'nombre': 'Estacion Teleferico Azul',
      'lat': -16.4893,
      'lng': -68.1931,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion':
          'Zona transitada estacion del teleferizo azul, peligroso por concurrencia universitaria y gente en estado de ebriedad.',
    },
    {
      'nombre': 'Universidad Franz Tamayo (UNIFRANZ)',
      'lat': -16.5085,
      'lng': -68.1663,
      'radio': 200,
      'riesgo': 'medio',
      'descripcion':
          'Universidad, peligroso por concurrencia universitaria y gente en estado de ebriedad.',
    },
    {
      'nombre': 'Universidad Técnica Privada Cosmos',
      'lat': -16.5245,
      'lng': -68.2131,
      'radio': 200,
      'riesgo': 'medio',
      'descripcion':
          'Universidad, peligroso por concurrencia universitaria y gente en estado de ebriedad.',
    },
    {
      'nombre': 'Universidad Salesiana de Bolivia (USB)',
      'lat': -16.4770,
      'lng': -68.1487,
      'radio': 200,
      'riesgo': 'medio',
      'descripcion':
          'Universidad, peligroso por concurrencia universitaria y gente en estado de ebriedad.',
    },
    {
      'nombre': 'Ballivian',
      'lat': -16.4893,
      'lng': -68.1805,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion':
          'Zona transitada con ciudadanos de a pie, gente en estado de ebriedad.',
    },
    {
      'nombre': 'Estadio Municipal de El Alto',
      'lat': -16.4713,
      'lng': -68.2018,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion':
          'Zona transitada con ciudadanos de a pie, gente en estado de ebriedad por el estadio de futbol.',
    },
    {
      'nombre': 'Cementerio General Mercedario El Alto',
      'lat': -16.5292,
      'lng': -68.2481,
      'radio': 250,
      'riesgo': 'medio',
      'descripcion':
          'Zona transitada con ciudadanos de a pie pero peligroso debido a ciertas personas antisociales y borrachos.',
    },
    // 🟢 BAJO RIESGO
    {
      'nombre': 'Alto Lima',
      'lat': -16.4765,
      'lng': -68.1751,
      'radio': 350,
      'riesgo': 'bajo',
      'descripcion': 'Urbanización. Seguridad  y baja incidencia delictiva.',
    },
    {
      'nombre': 'Villa Ingenio',
      'lat': -16.4750,
      'lng': -68.2000,
      'radio': 400,
      'riesgo': 'bajo',
      'descripcion':
          'Zona residencial tranquila. Muy pocos incidentes reportados.',
    },
    {
      'nombre': 'Rio seco',
      'lat': -16.4868,
      'lng': -68.2086,
      'radio': 380,
      'riesgo': 'bajo',
      'descripcion': 'Zona residencial organizada. Vigilancia vecinal activa.',
    },
    {
      'nombre': 'Ciudad Satélite',
      'lat': -16.5282,
      'lng': -68.1542,
      'radio': 380,
      'riesgo': 'bajo',
      'descripcion': 'Zona residencial organizada. Vigilancia vecinal activa.',
    },
    {
      'nombre': 'Estacion Linea Morada',
      'lat': -16.5221,
      'lng': -68.1694,
      'radio': 380,
      'riesgo': 'bajo',
      'descripcion':
          'Zona transitada pero con vigilancia militar por estar cerca a un cuartel.',
    },
    // AGREGANDO ACHOCALLA
    {
      'nombre': 'Achocalla',
      'lat': -16.4500,
      'lng': -68.1200,
      'radio': 300,
      'riesgo': 'medio',
      'descripcion':
          'Zona de Achocalla, área periurbana con riesgo medio debido a su ubicación.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarZonasRiesgo();
    _cargarPoligonoElAlto();
    _getCurrentLocation();
  }

  // FUNCIÓN PARA OBTENER LA UBICACIÓN ACTUAL
  void _getCurrentLocation() async {
    try {
      // Verificar permisos de ubicación
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

      // Obtener la ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Agregar marcador de ubicación actual
      _agregarMarcadorUbicacion();

      // Mover la cámara a la ubicación actual
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      _mostrarErrorUbicacion('Error al obtener la ubicación: $e');
    }
  }

  void _agregarMarcadorUbicacion() {
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('mi_ubicacion'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
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
          fillColor: color.withOpacity(0.3),
          strokeColor: color,
          strokeWidth: 2,
        ),
      );
    }

    setState(() {});
  }

  void _cargarPoligonoElAlto() {
    // FONDO AZUL TRANSPARENTE DIFUMINADO CON FORMA EXTENDIDA DE EL ALTO
    _poligonosElAlto.add(
      Polygon(
        polygonId: const PolygonId('el_alto_fondo'),
        points: _limitesElAlto,
        fillColor: const Color(0x5567C8FF),
        strokeColor: Colors.transparent,
        strokeWidth: 0,
        geodesic: true,
      ),
    );

    // LÍNEA AZUL DEL CONTORNO CON FORMA EXTENDIDA DE EL ALTO
    _poligonosElAlto.add(
      Polygon(
        polygonId: const PolygonId('el_alto_limites'),
        points: _limitesElAlto,
        fillColor: Colors.transparent,
        strokeColor: const Color(0xFF0077B6),
        strokeWidth: 2,
        geodesic: true,
      ),
    );
  }

  Color _obtenerColorRiesgo(String riesgo) {
    switch (riesgo) {
      case 'alto':
        return Colors.red;
      case 'medio':
        return Colors.orange;
      case 'bajo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _mostrarInfoZona(String nombreZona) {
    final zona = _zonasRiesgo.firstWhere((z) => z['nombre'] == nombreZona);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Zona: ${zona['nombre']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _obtenerColorRiesgo(zona['riesgo']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nivel de riesgo: ${zona['riesgo']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Coordenadas: ${zona['lat']}, ${zona['lng']}'),
              const SizedBox(height: 8),
              Text(zona['descripcion'], style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                'Radio de cobertura: ${zona['radio']} metros',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Riesgo - El Alto'),
        backgroundColor: const Color.fromARGB(255, 28, 64, 96),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MapaPredictivo()),
              (route) => false,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
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

          // Leyenda de colores
          Positioned(
            top: 70,
            right: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NivelesRiesgoScreen(),
                  ),
                );
              },
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 64, 96, 240),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Área de Cobertura',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Municipio de El Alto\nLa Paz - Bolivia',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    const Text(
                      'Niveles de Riesgo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _leyendaItem(Colors.red, "Alto Riesgo"),
                    _leyendaItem(Colors.orange, "Medio Riesgo"),
                    _leyendaItem(Colors.green, "Bajo Riesgo"),
                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0x5567C8FF),
                            border: Border.all(
                              color: const Color(0xFF0077B6),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Área El Alto',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(const LatLng(-16.5000, -68.2000)),
              );
            },
            backgroundColor: const Color(0xFF0077B6),
            heroTag: "btn_centro",
            mini: true,
            child: const Icon(Icons.center_focus_strong, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _getCurrentLocation,
            backgroundColor: Colors.green,
            heroTag: "btn_ubicacion",
            child: const Icon(Icons.my_location, color: Colors.white),
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
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
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
