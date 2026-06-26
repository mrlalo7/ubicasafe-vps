import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ubicasafe/core/app_theme.dart';
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

  final Set<Marker> _markers = {};
  BitmapDescriptor? _personIcon;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _isLoading = false;
  }

  void _createPersonIcon() async {
    if (_selectedAvatar != null) {
      try {
        BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(40, 40)),
          _selectedAvatar!,
        );
        setState(() {
          _personIcon = icon;
        });
      } catch (e) {
        setState(() {
          _personIcon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          );
        });
      }
    }
  }

  Future<void> _startLocationService() async {
    setState(() => _isLoading = true);

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

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16.0,
        ),
      );

      _startLocationUpdates();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error obteniendo ubicación';
        _showAvatarSelection = false;
      });
    }
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
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

  void _addMarker(Position position) {
    final marker = Marker(
      markerId: const MarkerId('my_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: _personIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Tú estás aquí'),
      anchor: const Offset(0.5, 0.5),
    );

    setState(() {
      _markers.clear();
      _markers.add(marker);
    });
  }

  Widget _buildAvatarSelection() {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Elige tu Avatar', style: AppTextStyles.headline3),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Text(
              'Selecciona un avatar para representarte en el mapa interactivo.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatars.length,
              itemBuilder: (context, index) {
                final avatar = _avatars[index];
                final isSelected = _selectedAvatar == avatar;

                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatar = avatar),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.accentBlue.withOpacity(0.2) : AppColors.glassWhite,
                      border: Border.all(
                        color: isSelected ? AppColors.accentBlue : AppColors.glassBorder,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected ? AppShadows.blueGlow : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(avatar, fit: BoxFit.contain),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(top: BorderSide(color: AppColors.glassBorder)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientButton(
                  text: 'Continuar al Mapa',
                  icon: Icons.map_rounded,
                  onPressed: _selectedAvatar != null
                      ? () {
                          _createPersonIcon();
                          _startLocationService();
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = null;
                      _personIcon = BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      );
                    });
                    _startLocationService();
                  },
                  child: Text(
                    'Usar marcador por defecto',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showAvatarSelection) {
      return _buildAvatarSelection();
    }

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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard.withOpacity(0.85),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: IconButton(
                icon: const Icon(Icons.person, color: AppColors.textPrimary),
                onPressed: () => setState(() => _showAvatarSelection = true),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _currentPosition != null
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.blueGlow,
              ),
              child: FloatingActionButton(
                onPressed: () {
                  if (_currentPosition != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        16.0,
                      ),
                    );
                  }
                },
                backgroundColor: AppColors.accentBlue,
                elevation: 0,
                child: const Icon(Icons.my_location_rounded, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accentBlue),
            const SizedBox(height: 16),
            Text('Obteniendo ubicación...', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, size: 48, color: AppColors.accentRed),
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Intentar nuevamente',
                icon: Icons.refresh_rounded,
                onPressed: _startLocationService,
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return Center(child: Text('Ubicación no disponible', style: AppTextStyles.body));
    }

    return GoogleMap(
      onMapCreated: (controller) {
        controller.setMapStyle(_mapStyle);
        setState(() => _mapController = controller);
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16.0,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
