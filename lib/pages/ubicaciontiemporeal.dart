import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:ubicasafe/core/app_theme.dart';

class UbicacionTiempoReal extends StatefulWidget {
  const UbicacionTiempoReal({super.key});

  @override
  State<UbicacionTiempoReal> createState() => _UbicacionTiempoRealState();
}

class _UbicacionTiempoRealState extends State<UbicacionTiempoReal> {
  final fm.MapController _mapController = fm.MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  bool _showAvatarSelection = true;
  String _errorMessage = '';
  String? _selectedAvatar;
  StreamSubscription<Position>? _positionSubscription;

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

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _isLoading = false;
  }

  void _createPersonIcon() {}

  Future<void> _startLocationService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationError(
        'Activa el GPS o la ubicación del dispositivo e intenta nuevamente.',
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showLocationError('Permiso de ubicación denegado.');
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationError(
        'El permiso de ubicación está bloqueado. Actívalo desde ajustes de la app.',
      );
      return;
    }

    await _getCurrentLocation();
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
      _showAvatarSelection = false;
    });
  }

  void _moveMapTo(Position position, {double zoom = 16}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(ll.LatLng(position.latitude, position.longitude), zoom);
    });
  }

  Future<Position?> _getBestKnownPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
    } on TimeoutException {
      return Geolocator.getLastKnownPosition();
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      rethrow;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _getBestKnownPosition();
      if (position == null) {
        _showLocationError(
          'No se pudo obtener tu ubicación. Sal al exterior o revisa el GPS.',
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _errorMessage = '';
        _showAvatarSelection = false;
      });

      _moveMapTo(position);
      _startLocationUpdates();
    } catch (e) {
      _showLocationError(
        'Error obteniendo ubicación. Revisa permisos, GPS e intenta nuevamente.',
      );
    }
  }

  void _startLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _moveMapTo(position);
      }
    }, onError: (_) {});
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
                  if (_currentPosition != null) {
                    _mapController.move(
                      ll.LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      16,
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

    final position = ll.LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    return fm.FlutterMap(
      mapController: _mapController,
      options: fm.MapOptions(initialCenter: position, initialZoom: 16),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ubicasafe',
          retinaMode: fm.RetinaMode.isHighDensity(context),
        ),
        fm.MarkerLayer(
          markers: [
            fm.Marker(
              point: position,
              width: 76,
              height: 76,
              alignment: Alignment.center,
              child: _UserLocationMarker(avatarPath: _selectedAvatar),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker({required this.avatarPath});

  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentBlue.withValues(alpha: 0.10),
          ),
        ),
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentBlueLight.withValues(alpha: 0.55),
              width: 2,
            ),
          ),
        ),
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: AppShadows.blueGlow,
          ),
          child: avatarPath == null
              ? const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.accentBlueLight,
                  size: 28,
                )
              : ClipOval(child: Image.asset(avatarPath!, fit: BoxFit.cover)),
        ),
        Positioned(
          right: 9,
          bottom: 10,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.safeGreen,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bgDark, width: 3),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}
