import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ubicasafe/pages/menu.dart';

class UbicacionTiempoReal extends StatefulWidget {
  const UbicacionTiempoReal({super.key});

  @override
  State<UbicacionTiempoReal> createState() => _UbicacionTiempoRealState();
}

class _UbicacionTiempoRealState extends State<UbicacionTiempoReal> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _showAvatarSelection = true;
  String _errorMessage = '';
  String? _selectedAvatar;

  // Lista de avatares disponibles
  final List<String> _avatars = [
    'assets/icons/avatar1.png',
    'assets/icons/avatar2.png',
    'assets/icons/avatar3.png',
    'assets/icons/avatar4.png',
    'assets/icons/avatar5.png',
    'assets/icons/avatar6.png',
    'assets/icons/avatar7.png',
    'assets/icons/avatar8.png',
    'assets/icons/avatar9.png',
    'assets/icons/avatar10.png',
    'assets/icons/avatar11.png',
    'assets/icons/avatar12.png',
    'assets/icons/avatar13.png',
    'assets/icons/avatar14.png',
    'assets/icons/avatar15.png',
    'assets/icons/avatar16.png',
  ];

  // Marcador para tu ubicación
  final Set<Marker> _markers = {};

  // Icono personalizado para tu ubicación
  BitmapDescriptor? _personIcon;

  @override
  void initState() {
    super.initState();
    // No solicitamos permisos inmediatamente, esperamos a que el usuario seleccione avatar
    _isLoading = false;
  }

  // Crear icono personalizado de persona basado en el avatar seleccionado
  void _createPersonIcon() async {
    if (_selectedAvatar != null) {
      try {
        BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(30, 30)),
          _selectedAvatar!,
        );
        setState(() {
          _personIcon = icon;
        });
      } catch (e) {
        // Si hay error con el avatar personalizado, usar uno por defecto
        setState(() {
          _personIcon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          );
        });
      }
    }
  }

  // Solicitar permisos de ubicación y iniciar mapa
  Future<void> _startLocationService() async {
    setState(() {
      _isLoading = true;
    });

    final status = await Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Permiso de ubicación denegado';
        _showAvatarSelection = false;
      });
    }
  }

  // Obtener ubicación actual
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _showAvatarSelection = false;
        _addMarker(position);
      });

      // Mover la cámara a la ubicación actual
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );

      // Escuchar actualizaciones de ubicación en tiempo real
      _startLocationUpdates();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error obteniendo ubicación: $e';
        _showAvatarSelection = false;
      });
    }
  }

  // Iniciar seguimiento de ubicación en tiempo real
  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _addMarker(position);
        });
      }
    });
  }

  // Agregar marcador en la ubicación
  void _addMarker(Position position) {
    final marker = Marker(
      markerId: const MarkerId('my_location'),
      position: LatLng(position.latitude, position.longitude),
      icon:
          _personIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Mi Ubicación'),
      anchor: const Offset(0.5, 0.5), // Centrar el icono
    );

    setState(() {
      _markers.clear();
      _markers.add(marker);
    });
  }

  // Widget para selección de avatar
  Widget _buildAvatarSelection() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu Avatar'),
        backgroundColor: const Color.fromRGBO(66, 101, 253, 1.0),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              '¿Cómo quieres aparecer en el mapa?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Selecciona un avatar para representar tu ubicación',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Grid de avatares
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.9,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  final isSelected = _selectedAvatar == avatar;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatar;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? const Color.fromRGBO(66, 101, 253, 1.0)
                              : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              image: DecorationImage(
                                image: AssetImage(avatar),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: const Color.fromARGB(255, 28, 64, 96),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Botón para continuar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedAvatar != null
                    ? () {
                        _createPersonIcon();
                        _startLocationService();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 28, 64, 96),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continuar al Mapa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Opción para usar marcador por defecto
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedAvatar = null;
                  _personIcon = BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  );
                });
                _startLocationService();
              },
              child: Text(
                'Usar marcador por defecto',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar selección de avatar primero
    if (_showAvatarSelection) {
      return _buildAvatarSelection();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación en Tiempo Real'),
        backgroundColor: const Color.fromARGB(255, 28, 64, 96),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Centrar en mi ubicación',
          ),
          // Botón para cambiar avatar
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              setState(() {
                _showAvatarSelection = true;
              });
            },
            tooltip: 'Cambiar avatar',
          ),
        ],
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: const Color.fromARGB(255, 28, 64, 96),
        child: const Icon(Icons.gps_fixed, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando mapa...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startLocationService,
              child: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      );
    }

    if (_currentPosition == null) {
      return const Center(child: Text('No se pudo obtener la ubicación'));
    }

    return GoogleMap(
      onMapCreated: (controller) {
        setState(() {
          _mapController = controller;
        });
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 15.0,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      zoomControlsEnabled: false,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
