import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final PageController _pageController = PageController(viewportFraction: 0.8);

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
    _startAutoScroll();
    _initializeLocalVideos();
  }

  // ✅ CORREGIDO: Mejor inicialización de videos
  void _initializeLocalVideos() async {
    try {
      print('🔄 Inicializando videos...');

      // Inicializar cada video por separado para mejor control de errores
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

      print('✅ Todos los videos inicializados correctamente');
    } catch (e) {
      print('❌ Error inicializando videos: $e');
      // Aún así marcamos como inicializado para mostrar las miniaturas de error
      setState(() {
        _videosInitialized = true;
      });
    }
  }

  Future<void> _initializeSingleVideo(int index, String path) async {
    try {
      print('🔄 Inicializando video $index: $path');

      VideoPlayerController controller;
      controller = VideoPlayerController.asset(path);

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
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade400,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.red),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'Error cargando video',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  Text(
                    errorMessage,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Asignar a los controladores correspondientes
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

      print('✅ Video $index inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando video $index ($path): $e');
      // No re-lanzamos la excepción para permitir que otros videos se inicialicen
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isDisposed) {
        final nextPage = (_currentImageIndex + 1) % _imagePaths.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
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

    _chewieController1 = null;
    _chewieController2 = null;
    _chewieController3 = null;
    _videoController1 = null;
    _videoController2 = null;
    _videoController3 = null;
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
      appBar: AppBar(
        title: Text('Mapa Predictivo', style: GoogleFonts.inter()),
        backgroundColor: const Color.fromRGBO(66, 101, 253, 1.0),
        foregroundColor: Colors.white,
      ),
      drawer: const MenuLateral(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de Mapa e Información Predictiva
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MapaRiesgo()),
                  );
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/img/mapariesgo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: Center(
                      child: Text(
                        'Mapa De Riesgo',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Zonas de mayor riesgo esta semana:',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Carrusel de imágenes personalizado
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _imagePaths.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_pageController.position.haveDimensions) {
                          value = _pageController.page! - index;
                          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                        }

                        return Center(
                          child: SizedBox(
                            height: Curves.easeOut.transform(value) * 180,
                            width:
                                Curves.easeOut.transform(value) *
                                MediaQuery.of(context).size.width *
                                0.8,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            _imagePaths[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Indicadores del carrusel
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_imagePaths.length, (index) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? const Color.fromRGBO(66, 101, 253, 1.0)
                          : Colors.grey,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Información de la imagen seleccionada
              _buildImageInfo(),
              const SizedBox(height: 24),

              // Sección de Videos informativos
              Text(
                'Videos de Prevención',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildVideoSection(
                'Prevención de robos',
                'Consejos para evitar ser víctima de robos en la calle',
                0,
              ),
              const SizedBox(height: 12),
              _buildVideoSection(
                'Autoprotección',
                'Técnicas básicas para protegerte en situaciones de riesgo',
                1,
              ),
              const SizedBox(height: 12),
              _buildVideoSection(
                'Primeros auxilios',
                'Qué hacer en caso de emergencias médicas',
                2,
              ),
              const SizedBox(height: 24),

              // Sección de Números de Emergencia
              Text(
                'Números de Emergencia',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildEmergencyNumber(
                'Policía Nacional',
                '110',
                Icons.local_police,
                Colors.blue,
              ),
              _buildEmergencyNumber(
                'Bomberos',
                '119',
                Icons.fire_truck,
                Colors.red,
              ),
              _buildEmergencyNumber(
                'Emergencias Médicas',
                '165',
                Icons.medical_services,
                Colors.green,
              ),
              _buildEmergencyNumber(
                'Línea de Seguridad',
                '800-14-0060',
                Icons.security,
                Colors.orange,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MenuScreen()),
            (route) => false,
          );
        },
        backgroundColor: const Color.fromRGBO(66, 101, 253, 1.0),
        child: const Icon(Icons.home, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildImageInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _imageTitles[_currentImageIndex],
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 28, 64, 96),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _imageDescriptions[_currentImageIndex],
            style: GoogleFonts.inter(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: _getRiskColor(_currentImageIndex),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _getRiskLevel(_currentImageIndex),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: _getRiskColor(_currentImageIndex),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRiskLevel(int index) {
    switch (index) {
      case 0:
        return 'Alto Riesgo';
      case 1:
        return 'Riesgo Moderado';
      case 2:
        return 'Bajo Riesgo';
      case 3:
        return 'Alto Riesgo';
      case 4:
        return 'Alto Riesgo';
      case 5:
        return 'Riesgo Moderado';
      default:
        return 'Riesgo Variable';
    }
  }

  Color _getRiskColor(int index) {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.red;
      case 5:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildVideoSection(String title, String description, int videoIndex) {
    return GestureDetector(
      onTap: () {
        _showVideoDialog(context, videoIndex);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Miniatura del video
            Container(
              width: 100,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildVideoThumbnail(videoIndex),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.red, size: 30),
          ],
        ),
      ),
    );
  }

  // ✅ CORREGIDO: Mejor manejo de miniaturas
  Widget _buildVideoThumbnail(int videoIndex) {
    if (!_videosInitialized) {
      return _buildLoadingThumbnail();
    }

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

    // ✅ Usar FutureBuilder para mejor manejo del estado del video
    return FutureBuilder<bool>(
      future: _isVideoReady(controller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingThumbnail();
        }

        if (snapshot.hasError || !snapshot.data!) {
          return _buildErrorThumbnail();
        }

        return Stack(
          children: [
            VideoPlayer(controller!),
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ),
            ),
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
      color: Colors.grey[800],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, color: Colors.white, size: 30),
            SizedBox(height: 4),
            Text(
              'Cargando...',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorThumbnail() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.white, size: 30),
            SizedBox(height: 4),
            Text(
              'Error video',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CORREGIDO: Mejor manejo del diálogo de video
  void _showVideoDialog(BuildContext context, int videoIndex) {
    try {
      if (!mounted || _isDisposed) {
        return;
      }

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
          _showErrorDialog(context, 'Video no disponible');
          return;
      }

      if (chewieController == null ||
          !chewieController.videoPlayerController.value.isInitialized) {
        _showErrorDialog(
          context,
          'El video no está disponible o no se pudo cargar',
        );
        return;
      }

      // Pausar cualquier video que esté reproduciéndose
      _pauseAllVideos();

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Chewie(controller: chewieController!),
            ),
          ),
        ),
      ).then((_) {
        // Pausar el video cuando se cierra el diálogo
        if (chewieController != null && !_isDisposed) {
          chewieController.pause();
        }
      });
    } catch (e) {
      print('❌ Error inesperado al mostrar video: $e');
      _showErrorDialog(context, 'Error al reproducir el video: $e');
    }
  }

  void _pauseAllVideos() {
    _chewieController1?.pause();
    _chewieController2?.pause();
    _chewieController3?.pause();
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumber(
    String name,
    String number,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _launchCaller(context, number),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    number,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ VERSIÓN SIMPLIFICADA Y CONFIABLE (OPCIÓN 3)
  Future<void> _launchCaller(BuildContext context, String number) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Llamar a emergencias'),
        content: Text('¿Quieres llamar al $number?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _tryDirectCall(context, number);
            },
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  Future<void> _tryDirectCall(BuildContext context, String number) async {
    try {
      final Uri telLaunchUri = Uri(scheme: 'tel', path: number);

      if (await canLaunchUrl(telLaunchUri)) {
        await launchUrl(telLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: abrir el dialer con el número pre-marcado
        final Uri dialUri = Uri(scheme: 'tel', path: number);

        await launchUrl(dialUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Último recurso: mostrar mensaje para marcar manualmente
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Marcar manualmente'),
            content: Text('Por favor, marca manualmente: $number'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Color.fromRGBO(66, 101, 253, 1.0)),
            child: Text(
              'Menú',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: Text('Mapa de riesgo ', style: GoogleFonts.inter()),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MapaRiesgo()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dangerous_sharp),
            title: Text('Niveles de Riesgo', style: GoogleFonts.inter()),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NivelesRiesgoScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(
              'Horarios de Mayor Incidencia',
              style: GoogleFonts.inter(),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HorarioMayorIncidenciaScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
