import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ReportarRobo extends StatefulWidget {
  const ReportarRobo({super.key});

  @override
  State<ReportarRobo> createState() => _ReportarRoboState();
}

class _ReportarRoboState extends State<ReportarRobo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  String _tipoRobo = 'Robo a Persona';
  String _nivelViolencia = 'Bajo';
  DateTime _fechaIncidente = DateTime.now();
  TimeOfDay _horaIncidente = TimeOfDay.now();
  bool _lesiones = false;
  bool _armas = false;
  bool _armaFuego = false;
  bool _armaBlanca = false;
  bool _enviandoCorreo = false;
  String _contenidoReporte = '';

  // NUEVAS VARIABLES PARA DATOS DEL DISPOSITIVO
  String _marcaCelular = 'Samsung';
  String _modeloCelular = 'Media gama (Redmi, Moto G, A series)';
  String _estadoCelular = 'Nuevo';
  String _colorCelular = 'Negro / Gris';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reportar Robo', style: GoogleFonts.inter()),
        backgroundColor: const Color.fromRGBO(66, 101, 253, 1.0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _mostrarEstadisticas,
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _guardarReporte),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Estadísticas Rápidas
            _buildEstadisticasRapidas(),
            const SizedBox(height: 20),

            // Formulario de Reporte
            _buildFormularioReporte(),
            const SizedBox(height: 20),

            // Botones de Acción
            _buildBotonesAccion(),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasRapidas() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Hoy',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTarjetaEstadistica('Reportes Hoy', '15', Colors.blue),
                _buildTarjetaEstadistica(
                  'Zona Más Peligrosa',
                  'Ceja',
                  Colors.red,
                ),
                _buildTarjetaEstadistica('Tendencia', '+5%', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaEstadistica(String titulo, String valor, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.assessment, color: color),
        ),
        const SizedBox(height: 5),
        Text(
          valor,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          titulo,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormularioReporte() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reportar Incidente',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Tipo de Robo
              _buildDropdown(
                'Tipo de Robo',
                _tipoRobo,
                ['Robo a Persona', 'Robo de celular', 'Otro'],
                (value) => setState(() => _tipoRobo = value!),
              ),

              // Mostrar sección de datos del dispositivo solo si es robo de celular
              if (_tipoRobo == 'Robo de celular') ...[
                _buildSeccionDatosDispositivo(),
                const SizedBox(height: 12),
              ],

              // Ubicación
              _buildTextField(
                'Ubicación del Incidente',
                _ubicacionController,
                'Ej: Av. 16 de Julio, cerca del mercado',
              ),

              // Fecha y Hora
              Row(
                children: [
                  Expanded(child: _buildDatePicker()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTimePicker()),
                ],
              ),

              // Descripción
              _buildTextArea(
                'Descripción del Incidente',
                _descripcionController,
                'Describa lo sucedido en detalle...',
              ),

              // Nivel de Violencia
              _buildDropdown(
                'Nivel de Violencia',
                _nivelViolencia,
                ['Bajo', 'Moderado', 'Alto', 'Extremo'],
                (value) => setState(() => _nivelViolencia = value!),
              ),

              // Checkboxes
              _buildCheckboxes(),
            ],
          ),
        ),
      ),
    );
  }

  // NUEVA SECCIÓN: DATOS DEL DISPOSITIVO
  Widget _buildSeccionDatosDispositivo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📱 Datos del dispositivo',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 28, 64, 96),
            ),
          ),
          const SizedBox(height: 16),

          // Marca del celular
          _buildDropdownDispositivo(
            '5. Marca del celular:',
            _marcaCelular,
            [
              'Samsung',
              'Xiaomi',
              'Motorola',
              'Huawei',
              'iPhone',
              'Otras marcas',
            ],
            (value) => setState(() => _marcaCelular = value!),
          ),

          // Modelo aproximado
          _buildDropdownDispositivo(
            '6. Modelo aproximado:',
            _modeloCelular,
            [
              'Alta gama (Galaxy S, iPhone, Xiaomi Pro)',
              'Media gama (Redmi, Moto G, A series)',
              'Baja gama (celulares básicos o antiguos)',
            ],
            (value) => setState(() => _modeloCelular = value!),
          ),

          // Estado del celular
          _buildDropdownDispositivo(
            '7. Estado del celular antes del robo:',
            _estadoCelular,
            ['Nuevo', 'Usado (buen estado)', 'Usado (dañado o pantalla rota)'],
            (value) => setState(() => _estadoCelular = value!),
          ),

          // Color del dispositivo
          _buildDropdownDispositivo(
            '8. Color del dispositivo:',
            _colorCelular,
            ['Negro / Gris', 'Azul', 'Blanco', 'Rojo', 'Otro'],
            (value) => setState(() => _colorCelular = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownDispositivo(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.inter(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          isExpanded: true,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTextArea(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint,
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor describa el incidente';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha del Incidente',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: _seleccionarFecha,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_fechaIncidente.day}/${_fechaIncidente.month}/${_fechaIncidente.year}',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hora del Incidente',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: _seleccionarHora,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  _horaIncidente.format(context),
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxes() {
    return Column(
      children: [
        CheckboxListTile(
          title: Text('Hubo lesiones físicas', style: GoogleFonts.inter()),
          value: _lesiones,
          onChanged: (value) => setState(() => _lesiones = value!),
        ),
        CheckboxListTile(
          title: Text('Se utilizaron armas', style: GoogleFonts.inter()),
          value: _armas,
          onChanged: (value) {
            setState(() {
              _armas = value!;
              // Si se desmarca "Se utilizaron armas", desmarcar también los tipos específicos
              if (!_armas) {
                _armaFuego = false;
                _armaBlanca = false;
              }
            });
          },
        ),

        // NUEVOS CHECKBOXES PARA TIPOS DE ARMAS (solo se muestran si _armas es true)
        if (_armas) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: [
                CheckboxListTile(
                  title: Text(
                    '☐ Arma de fuego (Pistola o revólver)',
                    style: GoogleFonts.inter(),
                  ),
                  value: _armaFuego,
                  onChanged: (value) => setState(() => _armaFuego = value!),
                ),
                CheckboxListTile(
                  title: Text(
                    '☐ Arma blanca (Cuchillo, navaja, etc.)',
                    style: GoogleFonts.inter(),
                  ),
                  value: _armaBlanca,
                  onChanged: (value) => setState(() => _armaBlanca = value!),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBotonesAccion() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: _enviandoCorreo
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.report),
                label: _enviandoCorreo
                    ? const Text('Enviando...')
                    : const Text('Reportar Incidente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _enviandoCorreo ? null : _enviarReporte,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text('Estadísticas'),
                onPressed: _mostrarEstadisticas,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaIncidente,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaIncidente) {
      setState(() => _fechaIncidente = picked);
    }
  }

  void _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaIncidente,
    );
    if (picked != null && picked != _horaIncidente) {
      setState(() => _horaIncidente = picked);
    }
  }

  void _enviarReporte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _enviandoCorreo = true;
    });

    // Generar el contenido primero
    _contenidoReporte = _generarContenidoReporte();

    try {
      final subject = Uri.encodeComponent('🚨 Reporte de Robo - UbicaSafe');
      final body = Uri.encodeComponent(_contenidoReporte);

      // ✅ CORREO ACTUALIZADO AQUÍ
      final mailtoUrl =
          'mailto:ubicasafeapp@gmail.com?subject=$subject&body=$body';

      print('🔄 Intentando abrir correo...');

      // INTENTAR MÚLTIPLES MÉTODOS
      bool correoAbierto = false;

      // Método 1: mailto estándar con verificación
      if (await canLaunchUrl(Uri.parse(mailtoUrl))) {
        print('✅ Método 1 (mailto) disponible');
        try {
          await launchUrl(
            Uri.parse(mailtoUrl),
            mode: LaunchMode.externalApplication,
          );
          correoAbierto = true;
          print('✅ Correo abierto con método 1');
        } catch (e) {
          print('❌ Error método 1: $e');
        }
      }

      // Método 2: Intentar sin verificación (a veces canLaunchUrl falla)
      if (!correoAbierto) {
        print('🔄 Probando método 2 (sin verificación)...');
        try {
          await launchUrl(
            Uri.parse(mailtoUrl),
            mode: LaunchMode.externalApplication,
          );
          correoAbierto = true;
          print('✅ Correo abierto con método 2');
        } catch (e) {
          print('❌ Error método 2: $e');
        }
      }

      // MOSTRAR RESULTADO
      if (correoAbierto) {
        _mostrarDialogoExito();
      } else {
        _mostrarDialogoGmailNoAbrio();
      }
    } catch (e) {
      print('❌ Error general: $e');
      _mostrarDialogoGmailNoAbrio();
    } finally {
      setState(() {
        _enviandoCorreo = false;
      });
    }
  }

  String _generarContenidoReporte() {
    String contenido =
        '''
REPORTE DE ROBO - UBICASAFE
============================

📋 INFORMACIÓN DEL INCIDENTE:
• Tipo de Robo: $_tipoRobo
• Ubicación: ${_ubicacionController.text}
• Fecha: ${_fechaIncidente.day}/${_fechaIncidente.month}/${_fechaIncidente.year}
• Hora: ${_horaIncidente.format(context)}
• Nivel de Violencia: $_nivelViolencia
• Lesiones Físicas: ${_lesiones ? "Sí" : "No"}
• Uso de Armas: ${_armas ? "Sí" : "No"}
''';

    // Añadir información de tipos de armas si se utilizaron armas
    if (_armas) {
      contenido += '• Tipo de Armas Utilizadas:\n';
      if (_armaFuego) contenido += '  - Arma de fuego (Pistola o revólver)\n';
      if (_armaBlanca)
        contenido += '  - Arma blanca (Cuchillo, navaja, etc.)\n';
      if (!_armaFuego && !_armaBlanca)
        contenido += '  - Tipo no especificado\n';
    }

    contenido +=
        '''
📝 DESCRIPCIÓN DETALLADA:
${_descripcionController.text}
''';

    // Añadir sección de datos del dispositivo solo si es robo de celular
    if (_tipoRobo == 'Robo de celular') {
      contenido +=
          '''

📱 DATOS DEL DISPOSITIVO:
• Marca del celular: $_marcaCelular
• Modelo aproximado: $_modeloCelular
• Estado del celular: $_estadoCelular
• Color del dispositivo: $_colorCelular
''';
    }

    contenido +=
        '''

📄 INFORMACIÓN ADICIONAL:
• Reporte generado el: ${DateTime.now()}
• Aplicación: UbicaSafe

---
Este reporte ha sido generado automáticamente por UbicaSafe.
''';

    return contenido;
  }

  void _mostrarDialogoGmailNoAbrio() {
    // Guardar el reporte primero
    _guardarReporteSilencioso();

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
                'Para enviar el reporte manualmente:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Abre Gmail manualmente\n'
                '2. Envía un correo a: ubicasafeapp@gmail.com\n' // ✅ CORREO ACTUALIZADO
                '3. Usa el asunto: 🚨 Reporte de Robo - UbicaSafe\n'
                '4. Copia y pega el contenido del reporte guardado',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'El reporte ya fue guardado en tu dispositivo.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                'Ruta: /storage/emulated/0/Android/data/com.example.ubicasafe/cache/',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
            Text('Se abrió Gmail con tu reporte.'),
            SizedBox(height: 8),
            Text(
              'Solo presiona "ENVIAR" para completar el reporte.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarReporteSilencioso() async {
    try {
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/reporte_robo_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(_contenidoReporte);
      print('📁 Reporte guardado en: ${file.path}');
    } catch (e) {
      print('Error guardando reporte: $e');
    }
  }

  // Método para el botón de guardar
  Future<void> _guardarReporte() async {
    _contenidoReporte = _generarContenidoReporte();

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/reporte_robo_${DateTime.now().millisecondsSinceEpoch}.txt',
    );

    await file.writeAsString(_contenidoReporte);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reporte Guardado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El reporte se ha guardado exitosamente.'),
            const SizedBox(height: 10),
            Text(
              'Ubicación: ${file.path}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _mostrarEstadisticas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Robos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEstadisticaSimple('Reportes Hoy', '15', Colors.blue),
              _buildEstadisticaSimple(
                'Zona Más Peligrosa',
                'Ceja El Alto',
                Colors.red,
              ),
              _buildEstadisticaSimple('Robos a Persona', '65%', Colors.orange),
              _buildEstadisticaSimple('Robos a Vivienda', '20%', Colors.green),
              _buildEstadisticaSimple('Robos a Vehículo', '15%', Colors.purple),
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

  Widget _buildEstadisticaSimple(String titulo, String valor, Color color) {
    return ListTile(
      leading: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(titulo),
      trailing: Text(
        valor,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
