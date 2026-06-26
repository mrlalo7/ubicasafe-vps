import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:ubicasafe/main.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _temaOscuro = false;
  bool _notificaciones = true;
  bool _ubicacionAuto = true;
  bool _sonidos = true;
  bool _vibracion = true;
  String _idioma = 'Español';
  String _unidadesDistancia = 'Kilómetros';

  @override
  void initState() {
    super.initState();
    _cargarConfiguraciones();
  }

  Future<void> _cargarConfiguraciones() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temaOscuro = prefs.getBool('tema_oscuro') ?? false;
      _notificaciones = prefs.getBool('notificaciones') ?? true;
      _ubicacionAuto = prefs.getBool('ubicacion_auto') ?? true;
      _sonidos = prefs.getBool('sonidos') ?? true;
      _vibracion = prefs.getBool('vibracion') ?? true;
      _idioma = prefs.getString('idioma') ?? 'Español';
      _unidadesDistancia =
          prefs.getString('unidades_distancia') ?? 'Kilómetros';
    });
  }

  Future<void> _guardarConfiguracion(String clave, dynamic valor) async {
    final prefs = await SharedPreferences.getInstance();
    if (valor is bool) {
      await prefs.setBool(clave, valor);
    } else if (valor is String) {
      await prefs.setString(clave, valor);
    }
  }

  // ← Añade este import

  void _cambiarTemaOscuro(bool value) {
    setState(() {
      _temaOscuro = value;
    });
    _guardarConfiguracion('tema_oscuro', value);

    // AÑADE ESTAS 2 LÍNEAS para cambiar el tema inmediatamente:
    temaOscuroNotifier.value = value;

    _mostrarMensaje('Tema ${value ? 'oscuro' : 'claro'} activado');
  }

  void _cambiarNotificaciones(bool value) {
    setState(() {
      _notificaciones = value;
    });
    _guardarConfiguracion('notificaciones', value);
    _mostrarMensaje('Notificaciones ${value ? 'activadas' : 'desactivadas'}');
  }

  void _cambiarUbicacionAuto(bool value) {
    setState(() {
      _ubicacionAuto = value;
    });
    _guardarConfiguracion('ubicacion_auto', value);
    _mostrarMensaje(
      'Ubicación automática ${value ? 'activada' : 'desactivada'}',
    );
  }

  void _cambiarSonidos(bool value) {
    setState(() {
      _sonidos = value;
    });
    _guardarConfiguracion('sonidos', value);
    _mostrarMensaje('Sonidos ${value ? 'activados' : 'desactivados'}');
  }

  void _cambiarVibracion(bool value) {
    setState(() {
      _vibracion = value;
    });
    _guardarConfiguracion('vibracion', value);
    _mostrarMensaje('Vibración ${value ? 'activada' : 'desactivada'}');
  }

  void _cambiarIdioma(String? value) {
    if (value != null) {
      setState(() {
        _idioma = value;
      });
      _guardarConfiguracion('idioma', value);
      _mostrarMensaje('Idioma cambiado a $value');
    }
  }

  void _cambiarUnidadesDistancia(String? value) {
    if (value != null) {
      setState(() {
        _unidadesDistancia = value;
      });
      _guardarConfiguracion('unidades_distancia', value);
      _mostrarMensaje('Unidades cambiadas a $value');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
    );
  }

  void _mostrarDialogoPrivacidad() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Text('Política de Privacidad'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'En UbicaSafe respetamos tu privacidad:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildItemPrivacidad(
                '📍',
                'Tu ubicación solo se usa para mostrar zonas seguras e inseguras',
              ),
              _buildItemPrivacidad(
                '📊',
                'Los datos de reportes son anónimos y agregados',
              ),
              _buildItemPrivacidad(
                '🔒',
                'No compartimos tu información personal con terceros',
              ),
              _buildItemPrivacidad(
                '📱',
                'Puedes desactivar la ubicación en cualquier momento',
              ),
              const SizedBox(height: 10),
              const Text(
                'Para más información, visita nuestro sitio web.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _abrirSitioWeb();
            },
            child: const Text('Sitio Web'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemPrivacidad(String emoji, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }

  void _abrirSitioWeb() async {
    const url = 'https://ubicasafe.com'; // Reemplaza con tu URL real
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      _mostrarMensaje('No se pudo abrir el sitio web');
    }
  }

  void _mostrarDialogoAcercaDe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.green),
            SizedBox(width: 8),
            Text('Acerca de UbicaSafe'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(
                      66,
                      101,
                      253,
                      1.0,
                    ).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                    color: Color(0XFFFF4317),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'UbicaSafe v1.0.0',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu compañero de seguridad personal',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildInfoApp('🚀', 'Desarrollado con Flutter'),
              _buildInfoApp('📅', 'Versión: 1.0.0 (Build 25)'),
              _buildInfoApp('🏢', 'UbicaSafe Team'),
              _buildInfoApp('📧', 'ubicasafeapp@gmail.com'),
              const SizedBox(height: 16),
              const Text(
                '© 2024 UbicaSafe. Todos los derechos reservados.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _contactarSoporte();
            },
            child: const Text('Contactar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoApp(String emoji, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [Text(emoji), const SizedBox(width: 8), Text(texto)],
      ),
    );
  }

  void _contactarSoporte() async {
    final subject = Uri.encodeComponent('Soporte - UbicaSafe');
    final body = Uri.encodeComponent('''
Hola equipo de UbicaSafe,

[Escribe tu consulta o problema aquí]

---
App: UbicaSafe v1.0.0
Dispositivo: [Información del dispositivo]
    ''');

    final mailtoUrl =
        'mailto:ubicasafeapp@gmail.com?subject=$subject&body=$body';

    try {
      await launchUrl(Uri.parse(mailtoUrl));
    } catch (e) {
      _mostrarMensaje('No se pudo abrir el cliente de correo');
    }
  }

  void _mostrarDialogoEliminarDatos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Eliminar Datos'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar todos tus datos?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Esta acción:'),
            Text('• Eliminará tu historial de reportes'),
            Text('• Restablecerá todas las configuraciones'),
            Text('• No se puede deshacer'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarDatos();
            },
            child: const Text(
              'Eliminar Todo',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _eliminarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Recargar configuraciones por defecto
    _cargarConfiguraciones();

    _mostrarMensaje('Todos los datos han sido eliminados');
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0XFFFF4317),
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: Colors.grey[600]),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0XFFFF4317),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String subtitle,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return ListTile(
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: Colors.grey[600]),
      ),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionSetting(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0XFFFF4317)),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromRGBO(66, 101, 253, 1.0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // APARIENCIA
          _buildSettingSection('🎨 APARIENCIA', [
            _buildSwitchSetting(
              'Tema Oscuro',
              'Activar el modo oscuro en la aplicación',
              _temaOscuro,
              _cambiarTemaOscuro,
            ),
          ]),

          // NOTIFICACIONES
          _buildSettingSection('🔔 NOTIFICACIONES', [
            _buildSwitchSetting(
              'Notificaciones',
              'Recibir alertas y notificaciones importantes',
              _notificaciones,
              _cambiarNotificaciones,
            ),
            _buildSwitchSetting(
              'Sonidos',
              'Reproducir sonidos en las notificaciones',
              _sonidos,
              _cambiarSonidos,
            ),
            _buildSwitchSetting(
              'Vibración',
              'Vibrar en notificaciones importantes',
              _vibracion,
              _cambiarVibracion,
            ),
          ]),

          // UBICACIÓN
          _buildSettingSection('📍 UBICACIÓN', [
            _buildSwitchSetting(
              'Ubicación Automática',
              'Actualizar ubicación automáticamente',
              _ubicacionAuto,
              _cambiarUbicacionAuto,
            ),
            _buildDropdownSetting(
              'Unidades de Distancia',
              'Selecciona kilómetros o millas',
              _unidadesDistancia,
              ['Kilómetros', 'Millas'],
              _cambiarUnidadesDistancia,
            ),
          ]),

          // GENERAL
          _buildSettingSection('⚙️ GENERAL', [
            _buildDropdownSetting(
              'Idioma',
              'Selecciona el idioma de la aplicación',
              _idioma,
              ['Español', 'English', 'Português'],
              _cambiarIdioma,
            ),
          ]),

          // INFORMACIÓN
          _buildSettingSection('📋 INFORMACIÓN', [
            _buildActionSetting(
              'Política de Privacidad',
              'Cómo manejamos tus datos',
              Icons.security,
              _mostrarDialogoPrivacidad,
            ),
            _buildActionSetting(
              'Acerca de UbicaSafe',
              'Información de la aplicación',
              Icons.info,
              _mostrarDialogoAcercaDe,
            ),
            _buildActionSetting(
              'Contactar Soporte',
              '¿Necesitas ayuda? Escríbenos',
              Icons.support_agent,
              _contactarSoporte,
            ),
          ]),

          // AVANZADO
          _buildSettingSection('🔧 AVANZADO', [
            _buildActionSetting(
              'Eliminar Todos los Datos',
              'Restablecer la aplicación',
              Icons.delete_forever,
              _mostrarDialogoEliminarDatos,
            ),
          ]),

          const SizedBox(height: 20),

          // VERSIÓN
          Center(
            child: Text(
              'UbicaSafe v1.0.0',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
