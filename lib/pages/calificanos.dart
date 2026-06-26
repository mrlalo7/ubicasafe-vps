import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CalificanosScreen extends StatefulWidget {
  const CalificanosScreen({super.key});

  @override
  State<CalificanosScreen> createState() => _CalificanosScreenState();
}

class _CalificanosScreenState extends State<CalificanosScreen> {
  int _calificacion = 0;
  final TextEditingController _sugerenciaController = TextEditingController();
  bool _enviandoCorreo = false;

  // Textos para la calificación con estrellas
  final List<Map<String, dynamic>> _nivelesCalificacion = [
    {'texto': 'Pésimo', 'valor': 1},
    {'texto': 'Malo', 'valor': 2},
    {'texto': 'Regular', 'valor': 3},
    {'texto': 'Bueno', 'valor': 4},
    {'texto': 'Excelente', 'valor': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Califica Nuestra App',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 57, 91, 251),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título principal
            Center(
              child: Column(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 60),
                  const SizedBox(height: 10),
                  Text(
                    '¡Tu opinión es muy importante!',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0XFFFF4317),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Ayúdanos a mejorar UbicaSafe',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Sección de calificación con estrellas
            Text(
              '¿Cómo calificarías tu experiencia?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),

            // Calificación con estrellas
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // Widget de estrellas
                  _buildStarRating(),
                  const SizedBox(height: 15),
                  Text(
                    _calificacion > 0
                        ? '${_nivelesCalificacion[_calificacion - 1]['texto']} - $_calificacion/5 Estrellas'
                        : 'Toca las estrellas para calificar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: _calificacion > 0
                          ? const Color(0XFFFF4317)
                          : Colors.grey,
                      fontWeight: _calificacion > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Indicador numérico
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _calificacion > 0
                          ? const Color(0XFFFF4317).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _calificacion > 0
                            ? const Color(0XFFFF4317)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      _calificacion > 0 ? '$_calificacion/5' : '0/5',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _calificacion > 0
                            ? const Color(0XFFFF4317)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Caja de sugerencias
            Text(
              '¿Tienes alguna sugerencia?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _sugerenciaController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'Escribe aquí tus comentarios, sugerencias o mejoras...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Botón de enviar calificación
            if (_calificacion > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviandoCorreo ? null : _enviarCalificacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 57, 91, 251),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _enviandoCorreo
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Abriendo Gmail...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ENVIAR CALIFICACIÓN',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

            const SizedBox(height: 20),

            // Botón de llenar encuesta
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _abrirEncuestaGoogle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0XFFFF4317)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment, color: const Color(0XFFFF4317)),
                    const SizedBox(width: 8),
                    Text(
                      'LLENAR ENCUESTA COMPLETA',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0XFFFF4317),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tu calificación y sugerencias serán enviadas a nuestro equipo de desarrollo para seguir mejorando UbicaSafe.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir el sistema de calificación con estrellas
  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _calificacion = starNumber;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starNumber <= _calificacion ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 40,
            ),
          ),
        );
      }),
    );
  }

  // ✅ CORREGIDO: Usar mailto como en reportarrobo.dart
  Future<void> _enviarCalificacion() async {
    if (_calificacion == 0) {
      _mostrarMensaje('Por favor selecciona una calificación');
      return;
    }

    setState(() {
      _enviandoCorreo = true;
    });

    try {
      final String calificacionTexto =
          _nivelesCalificacion[_calificacion - 1]['texto'];
      final String sugerencia = _sugerenciaController.text.isEmpty
          ? 'No se proporcionaron sugerencias'
          : _sugerenciaController.text;

      // ✅ GENERAR CONTENIDO COMO EN REPORTARROBO.DART
      final contenido = _generarContenidoCalificacion(
        calificacionTexto,
        sugerencia,
      );

      final subject = Uri.encodeComponent(
        '⭐ Calificación UbicaSafe - $_calificacion/5 Estrellas',
      );
      final body = Uri.encodeComponent(contenido);

      // ✅ USAR EL MISMO FORMATO QUE EN REPORTARROBO.DART
      final mailtoUrl =
          'mailto:ubicasafeapp@gmail.com?subject=$subject&body=$body';

      print('🔄 Intentando abrir correo para calificación...');

      bool correoAbierto = false;

      // Método 1: mailto estándar con verificación
      if (await canLaunchUrl(Uri.parse(mailtoUrl))) {
        print('✅ Método 1 (mailto) disponible para calificación');
        try {
          await launchUrl(
            Uri.parse(mailtoUrl),
            mode: LaunchMode.externalApplication,
          );
          correoAbierto = true;
          print('✅ Correo abierto con método 1 para calificación');
        } catch (e) {
          print('❌ Error método 1 calificación: $e');
        }
      }

      // Método 2: Intentar sin verificación
      if (!correoAbierto) {
        print('🔄 Probando método 2 (sin verificación) para calificación...');
        try {
          await launchUrl(
            Uri.parse(mailtoUrl),
            mode: LaunchMode.externalApplication,
          );
          correoAbierto = true;
          print('✅ Correo abierto con método 2 para calificación');
        } catch (e) {
          print('❌ Error método 2 calificación: $e');
        }
      }

      // MOSTRAR RESULTADO
      if (correoAbierto) {
        _mostrarDialogoExito();
      } else {
        _mostrarDialogoGmailNoAbrio(contenido);
      }
    } catch (e) {
      print('❌ Error general en calificación: $e');
      _mostrarDialogoGmailNoAbrio(
        _generarContenidoCalificacion(
          _nivelesCalificacion[_calificacion - 1]['texto'],
          _sugerenciaController.text,
        ),
      );
    } finally {
      setState(() {
        _enviandoCorreo = false;
      });
    }
  }

  // ✅ GENERAR CONTENIDO COMO EN REPORTARROBO.DART
  String _generarContenidoCalificacion(
    String calificacionTexto,
    String sugerencia,
  ) {
    return '''
⭐ CALIFICACIÓN UBICASAFE ⭐
============================

📊 CALIFICACIÓN:
• Puntuación: $_calificacion/5 Estrellas
• Nivel: $calificacionTexto

💡 SUGERENCIAS Y COMENTARIOS:
$sugerencia

📄 INFORMACIÓN ADICIONAL:
• Fecha de calificación: ${DateTime.now()}
• Aplicación: UbicaSafe
• Tipo: Feedback de Usuario

---
Esta calificación ha sido generada automáticamente por UbicaSafe.
¡Gracias por tu feedback! 🚀
''';
  }

  // ✅ MÉTODO PARA ABRIR ENCUESTA - CORREGIDO
  Future<void> _abrirEncuestaGoogle() async {
    const String url =
        'https://docs.google.com/forms/d/e/1FAIpQLSe6pmGQX4RyTRVfNd34MPEqCeSteeozHRvE1wMgP5yiEfUHiw/viewform';

    try {
      print('🔄 Intentando abrir encuesta Google...');

      // Método directo como en reportarrobo.dart
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

      print('✅ Encuesta Google abierta exitosamente');
    } catch (e) {
      print('❌ Error abriendo encuesta: $e');
      _mostrarError('No se pudo abrir la encuesta. Error: $e');
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Gmail Abierto'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Se abrió Gmail con tu calificación.'),
            SizedBox(height: 8),
            Text(
              'Solo presiona "ENVIAR" para completar tu feedback.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Limpiar formulario después de éxito
              _sugerenciaController.clear();
              setState(() {
                _calificacion = 0;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoGmailNoAbrio(String contenido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Gmail no se pudo abrir'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para enviar tu calificación manualmente:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Abre Gmail manualmente\n'
                '2. Envía un correo a: ubicasafeapp@gmail.com\n'
                '3. Usa el asunto: ⭐ Calificación UbicaSafe\n'
                '4. Copia y pega el siguiente contenido:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  contenido,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _abrirGmailManualmente();
            },
            child: const Text('Abrir Gmail'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _abrirGmailManualmente() async {
    try {
      // Intentar abrir Gmail específicamente
      const gmailUrl = 'https://mail.google.com/';
      if (await canLaunchUrl(Uri.parse(gmailUrl))) {
        await launchUrl(Uri.parse(gmailUrl));
      }
    } catch (e) {
      print('Error al abrir Gmail manualmente: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _sugerenciaController.dispose();
    super.dispose();
  }
}
