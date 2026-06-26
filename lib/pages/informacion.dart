import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ubicasafe/pages/login.dart';
import 'dart:async';

class Informacion extends StatefulWidget {
  const Informacion({super.key});

  @override
  State<Informacion> createState() => _InformacionState();
}

class _InformacionState extends State<Informacion> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Configurar el carrusel automático - velocidad más lenta
    _timer = Timer.periodic(const Duration(milliseconds: 800), (Timer timer) {
      if (_currentPage < 3) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500), // Transición más visible
          curve: Curves.easeInOut,
        );
      }
    });

    // Navegar después de 10 segundos
    Future.delayed(const Duration(seconds: 10), () {
      _timer.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carrusel de fondos
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildBackgroundImage('assets/img/fondoinfo.png'),
              _buildBackgroundImage('assets/img/fondoinfo2.png'),
              _buildBackgroundImage('assets/img/fondoinfo3.png'),
              _buildBackgroundImage('assets/img/fondoinfo4.png'),
            ],
          ),

          // Contenido sobrepuesto
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bienvenido a UbicaSafe',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '¿Cansado de mirar por encima del hombro para que no te roben? Con UbicaSafe, tu celular se convierte en tu compañero más vivo. Te avisa si entras a una zona roja, guarda tu ubicación al vuelo y, si te roban, activa al instante una red de ayuda. La calle es más segura cuando vamos seguros y cuidados por la comunidad.',
                      style: GoogleFonts.inter(
                        fontSize: MediaQuery.of(context).size.width > 550
                            ? 15
                            : 13,
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Imágenes de hombre y chica en la parte inferior
          Positioned(
            bottom: 0, // Ubicadas en la parte inferior
            left: 0,
            right: 0,
            child: Container(
              height:
                  MediaQuery.of(context).size.height *
                  0.35, // 35% de la altura de la pantalla
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment:
                    CrossAxisAlignment.end, // Alineadas al fondo
                children: [
                  // Imagen del hombre (lado izquierdo)
                  Image.asset(
                    'assets/img/hombre.png',
                    width:
                        MediaQuery.of(context).size.width *
                        0.4, // 40% del ancho (más grande)
                    height:
                        MediaQuery.of(context).size.height *
                        0.5, // 30% de la altura
                    fit: BoxFit.contain,
                  ),
                  // Imagen de la chica (lado derecho)
                  Image.asset(
                    'android/assets/img/chica.png',
                    width:
                        MediaQuery.of(context).size.width *
                        0.4, // 40% del ancho (más grande)
                    height:
                        MediaQuery.of(context).size.height *
                        0.5, // 30% de la altura
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.fill,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
