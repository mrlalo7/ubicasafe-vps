import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ubicasafe/pages/login.dart';

class Informacion extends StatefulWidget {
  const Informacion({super.key});

  @override
  State<Informacion> createState() => _InformacionState();
}

class _InformacionState extends State<Informacion> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'image': 'assets/img/onboard1.png', // <--- Imagen para la tarjeta 1
      'titlePart1': 'Tu seguridad empieza con ',
      'titleHighlight': 'información',
      'titlePart2': '',
      'descriptionPart1': 'UbicaSafe te ayuda a identificar zonas de riesgo, reportar incidentes y acceder rápidamente a ',
      'descriptionHighlight': 'asistencia',
      'descriptionPart2': ' cuando la necesites.',
      'features': [
        {'icon': Icons.location_on_rounded, 'color': Colors.blueAccent, 'text': 'Identifica\nzonas de riesgo'},
        {'icon': Icons.person_rounded, 'color': Colors.orangeAccent, 'text': 'Reporta\nincidentes'},
        {'icon': Icons.emergency_share_rounded, 'color': Colors.redAccent, 'text': 'Accede a\nasistencia rápida'},
      ]
    },
    {
      'image': 'assets/img/onboard2.png', // <--- Imagen para la tarjeta 2
      'titlePart1': 'Consulta zonas de riesgo ',
      'titleHighlight': 'antes de salir',
      'titlePart2': '',
      'descriptionPart1': 'UbicaSafe te muestra zonas con distintos niveles de riesgo para que tomes ',
      'descriptionHighlight': 'mejores decisiones',
      'descriptionPart2': ' antes de desplazarte por la ciudad.',
      'features': [
        {'icon': Icons.bar_chart_rounded, 'color': Colors.amber, 'text': 'Visualiza\nniveles de riesgo'},
        {'icon': Icons.search_rounded, 'color': Colors.blueAccent, 'text': 'Explora\nsectores'},
        {'icon': Icons.route_rounded, 'color': Colors.cyanAccent, 'text': 'Planifica rutas\nmás seguras'},
      ]
    },
    {
      'image': 'assets/img/onboard3.png', // <--- Imagen para la tarjeta 3
      'titlePart1': 'Recibe ',
      'titleHighlight': 'ayuda',
      'titlePart2': ' cuando más la necesites',
      'descriptionPart1': 'UbicaSafe te permite reportar robos, pedir ayuda y recibir orientación mediante un ',
      'descriptionHighlight': 'asistente inteligente',
      'descriptionPart2': '.',
      'features': [
        {'icon': Icons.notifications_active_rounded, 'color': Colors.redAccent, 'text': 'Activa\nalertas'},
        {'icon': Icons.phone_in_talk_rounded, 'color': Colors.greenAccent, 'text': 'Llama\nrápido'},
        {'icon': Icons.chat_bubble_rounded, 'color': Colors.blueAccent, 'text': 'Recibe\norientación'},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navegarAlLogin();
    }
  }

  void _navegarAlLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const Login(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF020A13),
      body: Stack(
        children: [
          // IMAGEN DE FONDO CON ANIMACIÓN DE DESVANECIMIENTO
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.asset(
                _onboardingData[_currentPage]['image'],
                key: ValueKey<int>(_currentPage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.topCenter,
                // Si aún no has puesto las imágenes, mostrará un contenedor oscuro para evitar que la app se rompa
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    key: ValueKey<int>(_currentPage),
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.2,
                        colors: [Color(0xFF0F2C59), Color(0xFF020A13)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.white24, size: 50)
                    ),
                  );
                },
              ),
            ),
          ),

          // DEGRADADO SOBRE LA IMAGEN PARA FUNDIR CON EL FONDO OSCURO
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF020A13).withOpacity(0.5),
                    const Color(0xFF020A13),
                  ],
                  stops: const [0.6, 0.9, 1.0],
                ),
              ),
            ),
          ),

          // LOGO UBICASAFE SUPERIOR
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/ubicasafe_shield.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(text: 'Ubica', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          TextSpan(text: 'Safe', style: TextStyle(color: Colors.cyanAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                        ]
                      )
                    )
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.location_on, color: Colors.grey, size: 14),
                     SizedBox(width: 4),
                     Text('El Alto, Bolivia', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),

          // CONTENEDOR PRINCIPAL DE TEXTO E INTERACCIÓN (PARTE INFERIOR)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PageView para el contenido de las tarjetas
                  SizedBox(
                    height: 310,
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        final data = _onboardingData[index];
                        return _buildCardContent(data);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Indicadores de puntitos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.cyanAccent
                              : Colors.grey.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Texto "1 de 3"
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${_currentPage + 1}',
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' de ${_onboardingData.length}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ]
                    )
                  ),

                  const SizedBox(height: 24),

                  // Botón grande
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0097B2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _onboardingData.length - 1 ? 'Comenzar' : 'Continuar',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF081526),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B213E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.cyanAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: data['titlePart1']),
                      TextSpan(
                        text: data['titleHighlight'],
                        style: const TextStyle(color: Colors.cyanAccent),
                      ),
                      TextSpan(text: data['titlePart2']),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.5,
              ),
              children: [
                TextSpan(text: data['descriptionPart1']),
                TextSpan(
                  text: data['descriptionHighlight'],
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: data['descriptionPart2']),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1B30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: (data['features'] as List).map<Widget>((feature) {
                return Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(feature['icon'], color: feature['color'], size: 24),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          feature['text'],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}