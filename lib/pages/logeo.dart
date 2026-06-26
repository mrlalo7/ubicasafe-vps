import 'package:flutter/material.dart';
import 'package:ubicasafe/pages/menu.dart';
import '../services/simple_auth_service.dart';
import 'dart:math';
import 'dart:ui' as ui;

class Logeo extends StatefulWidget {
  const Logeo({super.key});

  @override
  State<Logeo> createState() => _LogeoState();
}

class _LogeoState extends State<Logeo> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  final SimpleAuthService _authService = SimpleAuthService();
  bool _isLoading = false;

  // Variables para el CAPTCHA visual
  String _codigoGenerado = '';

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
    _generarNuevoCaptcha();
  }

  void _generarNuevoCaptcha() {
    final random = Random();
    const caracteres =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sin O,0,1,I para evitar confusión
    _codigoGenerado = '';

    // Generar código de 6 caracteres
    for (int i = 0; i < 6; i++) {
      _codigoGenerado += caracteres[random.nextInt(caracteres.length)];
    }

    setState(() {});
  }

  // Widget personalizado para el CAPTCHA visual
  Widget _buildCaptchaDisplay() {
    return CustomPaint(
      size: const Size(250, 80),
      painter: _CaptchaPainter(_codigoGenerado),
    );
  }

  void _checkIfLoggedIn() async {
    if (await _authService.isLoggedIn()) {
      _navigateToMain();
    }
  }

  bool _validarCaptcha() {
    return _captchaController.text.toUpperCase() == _codigoGenerado;
  }

  void _login() async {
    // Validar campos vacíos
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrarError('Por favor completa todos los campos');
      return;
    }

    // Validar CAPTCHA
    if (_captchaController.text.isEmpty) {
      _mostrarError('Por favor ingresa el código CAPTCHA');
      return;
    }

    if (!_validarCaptcha()) {
      _mostrarError('Código CAPTCHA incorrecto. Intenta nuevamente.');
      _generarNuevoCaptcha();
      _captchaController.clear();
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _navigateToMain();
    } else {
      _mostrarError(result['message']);
      _generarNuevoCaptcha();
      _captchaController.clear();
    }
  }

  void _navigateToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MenuScreen()),
      (route) => false,
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        backgroundColor: const Color.fromARGB(255, 64, 96, 240),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security,
                size: 80,
                color: Color.fromARGB(255, 64, 96, 240),
              ),
              const SizedBox(height: 20),
              const Text(
                'UbicaSafe',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 64, 96, 240),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Inicia sesión en tu cuenta',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Campo Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

              // Campo Contraseña
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 25),

              // ✅ CAPTCHA VISUAL PERSONALIZADO
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Título del CAPTCHA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verificación CAPTCHA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _generarNuevoCaptcha,
                          color: const Color.fromARGB(255, 64, 96, 240),
                          tooltip: 'Generar nuevo código',
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Display del CAPTCHA
                    Container(
                      height: 80,
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey[100]!,
                            Colors.grey[200]!,
                            Colors.grey[100]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Center(child: _buildCaptchaDisplay()),
                    ),
                    const SizedBox(height: 15),

                    // Campo para ingresar el CAPTCHA
                    TextField(
                      controller: _captchaController,
                      decoration: InputDecoration(
                        labelText: 'Ingresa el código de arriba',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.text_fields),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _captchaController.clear(),
                        ),
                        hintText: 'Escribe las letras/números en mayúsculas',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Texto de ayuda
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Caracteres: ${_codigoGenerado.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Distingue mayúsculas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Botón de Login
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            64,
                            96,
                            240,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Iniciar Sesión',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter para dibujar el CAPTCHA con distorsión
class _CaptchaPainter extends CustomPainter {
  final String text;
  final Random random = Random();

  _CaptchaPainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0XFFFF4317)
      ..style = PaintingStyle.fill;

    // Dibujar líneas de fondo para distracción
    for (int i = 0; i < 8; i++) {
      final linePaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 1;

      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = random.nextDouble() * size.width;
      final endY = random.nextDouble() * size.height;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
    }

    // Dibujar puntos de fondo
    for (int i = 0; i < 30; i++) {
      final dotPaint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      canvas.drawCircle(Offset(x, y), 1, dotPaint);
    }

    // Dibujar cada carácter con distorsión
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final charWidth = size.width / text.length;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // Configurar el estilo del texto con variaciones aleatorias
      final textStyle = TextStyle(
        fontSize: 28 + random.nextDouble() * 8, // 28-36px
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 64, 96, 240),
        fontFamily: 'Courier',
        letterSpacing: 0,
      );

      textPainter.text = TextSpan(text: char, style: textStyle);
      textPainter.layout();

      // Calcular posición base
      final baseX = i * charWidth + (charWidth - textPainter.width) / 2;
      final baseY = (size.height - textPainter.height) / 2;

      // Aplicar transformaciones aleatorias
      canvas.save();

      // Rotación aleatoria (-15° a +15°)
      final rotation =
          (random.nextDouble() - 0.5) * 0.5; // ±15 grados en radianes
      final rotationOffset = Offset(
        baseX + textPainter.width / 2,
        baseY + textPainter.height / 2,
      );
      canvas.translate(rotationOffset.dx, rotationOffset.dy);
      canvas.rotate(rotation);
      canvas.translate(-rotationOffset.dx, -rotationOffset.dy);

      // Desplazamiento vertical aleatorio
      final offsetY = (random.nextDouble() - 0.5) * 10; // ±5 pixels

      // Dibujar el carácter
      textPainter.paint(canvas, Offset(baseX, baseY + offsetY));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
