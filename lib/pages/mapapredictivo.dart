import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/pages/horariomayorincidencia.dart';
import 'package:ubicasafe/pages/mapariesgo.dart';
import 'package:ubicasafe/pages/menu.dart';
import 'package:ubicasafe/pages/nivelesriesgo.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MapaPredictivo extends StatefulWidget {
  const MapaPredictivo({super.key});

  @override
  State<MapaPredictivo> createState() => _MapaPredictivoState();
}

class _MapaPredictivoState extends State<MapaPredictivo> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  final List<String> _imagePaths = [
    'assets/img/12octubre.jpg',
    'assets/img/16dejulio.jpg',
    'assets/img/altolima.jpg',
    'assets/img/ceja.jpg',
    'assets/img/senkata.jpg',
    'assets/img/mercedario.jpg',
  ];

  final List<String> _imageTitles = [
    '12 de Octubre',
    'Zona 16 de Julio',
    'Alto Lima',
    'Ceja El Alto',
    'Senkata',
    'Mercadario',
  ];

  final List<String> _imageDescriptions = [
    'Alto riesgo por robos - Evitar después de las 8pm',
    'Riesgo moderado - Mantenerse alerta en horas pico',
    'Bajo riesgo - Zona recomendada para transitar',
    'Alto riesgo por robos - Evitar después de las 8pm',
    'Alto riesgo por robos - Evitar después de las 8pm',
    'Riesgo moderado - Mantenerse alerta en horas pico',
  ];

  VideoPlayerController? _videoController1;
  VideoPlayerController? _videoController2;
  VideoPlayerController? _videoController3;
  ChewieController? _chewieController1;
  ChewieController? _chewieController2;
  ChewieController? _chewieController3;

  bool _videosInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _startAutoScroll();
    _initializeLocalVideos();
  }

  void _initializeLocalVideos() async {
    try {
      await _initializeSingleVideo(0, 'assets/videos/prevencion.mp4');
      await _initializeSingleVideo(1, 'assets/videos/autoproteccion.mp4');
      await _initializeSingleVideo(2, 'assets/videos/primeros_auxilios.mp4');

      if (!mounted || _isDisposed) {
        _disposeVideoControllers();
        return;
      }

      setState(() {
        _videosInitialized = true;
      });
    } catch (e) {
      setState(() {
        _videosInitialized = true;
      });
    }
  }

  Future<void> _initializeSingleVideo(int index, String path) async {
    try {
      VideoPlayerController controller = VideoPlayerController.asset(path);
      await controller.initialize();

      if (!mounted || _isDisposed) {
        controller.dispose();
        return;
      }

      ChewieController chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowMuting: true,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.accentBlueLight,
          handleColor: AppColors.accentBlue,
          backgroundColor: AppColors.glassWhite,
          bufferedColor: AppColors.glassBorder,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.accentBlue),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.accentRed, size: 40),
                  const SizedBox(height: 10),
                  Text('Error de video', style: AppTextStyles.body),
                ],
              ),
            ),
          );
        },
      );

      switch (index) {
        case 0:
          _videoController1 = controller;
          _chewieController1 = chewieController;
          break;
        case 1:
          _videoController2 = controller;
          _chewieController2 = chewieController;
          break;
        case 2:
          _videoController3 = controller;
          _chewieController3 = chewieController;
          break;
      }
    } catch (e) {}
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && !_isDisposed) {
        final nextPage = (_currentImageIndex + 1) % _imagePaths.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
        _startAutoScroll();
      }
    });
  }

  void _disposeVideoControllers() {
    _chewieController1?.dispose();
    _chewieController2?.dispose();
    _chewieController3?.dispose();

    _videoController1?.dispose();
    _videoController2?.dispose();
    _videoController3?.dispose();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController.dispose();
    _disposeVideoControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('Mapa Predictivo', style: AppTextStyles.headline3),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MenuScreen()),
              );
            },
          ),
        ],
      ),
      drawer: const _DarkDrawer(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner a Mapa de Riesgo ──
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MapaRiesgo()),
                );
              },
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/img/mapariesgo.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.map_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Ver Mapa de Riesgo',
                              style: AppTextStyles.headline3.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explora las zonas con mayor incidencia',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Zonas de riesgo ──
            Row(
              children: [
                const Icon(Icons.warning_rounded, color: AppColors.warningAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ZONAS DE RIESGO ESTA SEMANA',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.warningAmber,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Carrusel de imágenes
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _imagePaths.length,
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                      }

                      return Center(
                        child: SizedBox(
                          height: Curves.easeOut.transform(value) * 220,
                          width: Curves.easeOut.transform(value) * MediaQuery.of(context).size.width,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.card,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          _imagePaths[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.bgSurface,
                              child: const Icon(Icons.image_not_supported, color: AppColors.textHint, size: 50),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Indicadores
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_imagePaths.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentImageIndex == index ? AppColors.accentBlue : AppColors.glassBorder,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Info de la imagen actual
            _buildImageInfo(),
            const SizedBox(height: 32),

            // ── Videos de Prevención ──
            Row(
              children: [
                const Icon(Icons.play_circle_rounded, color: AppColors.accentBlueLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  'VIDEOS DE PREVENCIÓN',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.accentBlueLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVideoSection('Prevención de robos', 'Consejos para evitar ser víctima en la calle', 0),
            const SizedBox(height: 12),
            _buildVideoSection('Autoprotección', 'Técnicas básicas para protegerte', 1),
            const SizedBox(height: 12),
            _buildVideoSection('Primeros auxilios', 'Qué hacer en emergencias médicas', 2),
            const SizedBox(height: 32),

            // ── Números de Emergencia ──
            Row(
              children: [
                const Icon(Icons.phone_in_talk_rounded, color: AppColors.safeGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'NÚMEROS DE EMERGENCIA',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.safeGreen,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEmergencyNumber('Policía Nacional', '110', Icons.local_police_rounded, const Color(0xFF2563EB)),
            _buildEmergencyNumber('Bomberos', '119', Icons.local_fire_department_rounded, AppColors.accentRed),
            _buildEmergencyNumber('Emergencias Médicas', '165', Icons.medical_services_rounded, AppColors.safeGreen),
            _buildEmergencyNumber('Línea de Seguridad', '800-14-0060', Icons.security_rounded, AppColors.warningAmber),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImageInfo() {
    final color = _getRiskColor(_currentImageIndex);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _imageTitles[_currentImageIndex],
                style: AppTextStyles.headline3,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _getRiskLevel(_currentImageIndex),
                      style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _imageDescriptions[_currentImageIndex],
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getRiskLevel(int index) {
    switch (index) {
      case 0:
      case 3:
      case 4:
        return 'Alto Riesgo';
      case 1:
      case 5:
        return 'Moderado';
      case 2:
        return 'Bajo Riesgo';
      default:
        return 'Variable';
    }
  }

  Color _getRiskColor(int index) {
    switch (index) {
      case 0:
      case 3:
      case 4:
        return AppColors.dangerRed;
      case 1:
      case 5:
        return AppColors.warningAmber;
      case 2:
        return AppColors.safeGreen;
      default:
        return AppColors.textHint;
    }
  }

  Widget _buildVideoSection(String title, String description, int videoIndex) {
    return GestureDetector(
      onTap: () => _showVideoDialog(context, videoIndex),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 100,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildVideoThumbnail(videoIndex),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(description, style: AppTextStyles.caption),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: AppColors.accentBlueLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(int videoIndex) {
    if (!_videosInitialized) return _buildLoadingThumbnail();

    VideoPlayerController? controller;
    switch (videoIndex) {
      case 0:
        controller = _videoController1;
        break;
      case 1:
        controller = _videoController2;
        break;
      case 2:
        controller = _videoController3;
        break;
      default:
        return _buildErrorThumbnail();
    }

    if (controller == null || !controller.value.isInitialized) {
      return _buildErrorThumbnail();
    }

    return FutureBuilder<bool>(
      future: _isVideoReady(controller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingThumbnail();
        if (snapshot.hasError || !snapshot.data!) return _buildErrorThumbnail();

        return Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller!),
            Container(color: Colors.black.withOpacity(0.4)),
            const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 32)),
          ],
        );
      },
    );
  }

  Future<bool> _isVideoReady(VideoPlayerController? controller) async {
    if (controller == null) return false;
    await Future.delayed(const Duration(milliseconds: 100));
    return controller.value.isInitialized;
  }

  Widget _buildLoadingThumbnail() {
    return Container(
      color: AppColors.bgSurface,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textHint),
        ),
      ),
    );
  }

  Widget _buildErrorThumbnail() {
    return Container(
      color: AppColors.bgSurface,
      child: const Center(child: Icon(Icons.videocam_off_outlined, color: AppColors.textHint)),
    );
  }

  void _showVideoDialog(BuildContext context, int videoIndex) {
    if (!mounted || _isDisposed) return;

    ChewieController? chewieController;
    switch (videoIndex) {
      case 0:
        chewieController = _chewieController1;
        break;
      case 1:
        chewieController = _chewieController2;
        break;
      case 2:
        chewieController = _chewieController3;
        break;
      default:
        return;
    }

    if (chewieController == null || !chewieController.videoPlayerController.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video no disponible')),
      );
      return;
    }

    _pauseAllVideos();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          height: 260,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Chewie(controller: chewieController!),
          ),
        ),
      ),
    ).then((_) {
      if (chewieController != null && !_isDisposed) chewieController.pause();
    });
  }

  void _pauseAllVideos() {
    _chewieController1?.pause();
    _chewieController2?.pause();
    _chewieController3?.pause();
  }

  Widget _buildEmergencyNumber(String name, String number, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _launchCaller(context, number),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(number, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.safeGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_rounded, color: AppColors.safeGreen, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchCaller(BuildContext context, String number) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Llamar', style: AppTextStyles.headline3.copyWith(fontSize: 18)),
        content: Text('¿Deseas llamar al $number?', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          GradientButton(
            text: 'Llamar',
            height: 40,
            icon: Icons.phone_in_talk,
            onPressed: () async {
              Navigator.pop(context);
              final Uri telUri = Uri(scheme: 'tel', path: number);
              if (await canLaunchUrl(telUri)) {
                await launchUrl(telUri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Drawer lateral con estilo Dark ──
class _DarkDrawer extends StatelessWidget {
  const _DarkDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bgDark,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppGradients.headerBlue,
              boxShadow: AppShadows.blueGlow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.explore_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text('Menú', style: AppTextStyles.headline2.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(context, 'Mapa de Riesgo', Icons.map_rounded, const MapaRiesgo()),
                _buildDrawerItem(context, 'Niveles de Riesgo', Icons.dangerous_rounded, const NivelesRiesgoScreen()),
                _buildDrawerItem(context, 'Horarios Incidencia', Icons.access_time_filled_rounded, const HorarioMayorIncidenciaScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, Widget targetPage) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentBlueLight),
      title: Text(title, style: AppTextStyles.body),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: () {
        Navigator.pop(context); // Cerrar drawer
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
    );
  }
}
