import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ubicasafe/services/api_service.dart';
import 'dart:io';

class ReportarRobo extends StatefulWidget {
  const ReportarRobo({super.key});

  @override
  State<ReportarRobo> createState() => _ReportarRoboState();
}

class _ReportarRoboState extends State<ReportarRobo>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
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
  bool _registrandoReporte = false;
  String _contenidoReporte = '';
  Map<String, dynamic>? _stats;

  String _marcaCelular = 'Samsung';
  String _modeloCelular = 'Media gama (Redmi, Moto G, A series)';
  String _estadoCelular = 'Nuevo';
  String _colorCelular = 'Negro / Gris';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    _animController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  String get _zonaPrincipalLabel {
    final zone = _stats?['most_dangerous_zone'];
    if (zone is Map<String, dynamic>) {
      final name = zone['name'] as String?;
      if (name != null && name.isNotEmpty && name != 'Sin datos') {
        return name.length > 8 ? '${name.substring(0, 8)}...' : name;
      }
    }
    return 'Sin datos';
  }

  DateTime get _fechaHoraIncidente {
    return DateTime(
      _fechaIncidente.year,
      _fechaIncidente.month,
      _fechaIncidente.day,
      _horaIncidente.hour,
      _horaIncidente.minute,
    );
  }

  String? get _tipoArma {
    if (!_armas) return null;
    if (_armaFuego && _armaBlanca) return 'Arma de fuego y arma blanca';
    if (_armaFuego) return 'Arma de fuego';
    if (_armaBlanca) return 'Arma blanca';
    return 'Tipo no especificado';
  }

  Future<void> _cargarEstadisticas() async {
    final stats = await _apiService.getStats();
    if (!mounted || stats == null) return;
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reportar Incidente', style: AppTextStyles.headline3),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.accentBlueLight,
            ),
            onPressed: _mostrarEstadisticas,
            tooltip: 'Estadísticas',
          ),
          IconButton(
            icon: const Icon(
              Icons.save_rounded,
              color: AppColors.accentBlueLight,
            ),
            onPressed: _guardarCopiaLocal,
            tooltip: 'Guardar copia',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Estadísticas rápidas ──
                _buildEstadisticasRapidas(),
                const SizedBox(height: 16),

                // ── Sección: Tipo de incidente ──
                _buildSectionLabel('Tipo de Incidente', Icons.category_rounded),
                const SizedBox(height: 10),
                _buildTipoRoboSelector(),
                const SizedBox(height: 16),

                // ── Datos del dispositivo (condicional) ──
                if (_tipoRobo == 'Robo de celular') ...[
                  _buildSectionLabel(
                    'Datos del Dispositivo',
                    Icons.smartphone_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildSeccionDatosDispositivo(),
                  const SizedBox(height: 16),
                ],

                // ── Ubicación y Fecha ──
                _buildSectionLabel(
                  'Ubicación y Fecha',
                  Icons.location_on_rounded,
                ),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      DarkTextField(
                        controller: _ubicacionController,
                        label: 'Ubicación del Incidente',
                        hint: 'Ej: Av. 16 de Julio, cerca del mercado',
                        prefixIcon: Icons.pin_drop_outlined,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Campo obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildDatePicker()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTimePicker()),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Descripción ──
                _buildSectionLabel('Descripción', Icons.description_rounded),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: DarkTextField(
                    controller: _descripcionController,
                    label: 'Descripción del Incidente',
                    hint: 'Describa lo sucedido en detalle...',
                    maxLines: 5,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Por favor describa el incidente'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Nivel de violencia ──
                _buildSectionLabel('Nivel de Violencia', Icons.warning_rounded),
                const SizedBox(height: 10),
                _buildNivelViolenciaSelector(),
                const SizedBox(height: 16),

                // ── Checkboxes ──
                _buildSectionLabel(
                  'Detalles Adicionales',
                  Icons.checklist_rounded,
                ),
                const SizedBox(height: 10),
                _buildCheckboxes(),
                const SizedBox(height: 24),

                // ── Botón reportar ──
                _buildBotonReportar(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentBlueLight, size: 18),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: AppColors.accentBlueLight,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasRapidas() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        colors: [Color(0x18FF3B30), Color(0x08FF3B30)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: AppColors.accentRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'ESTADÍSTICAS DE HOY',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                '${_stats?['reports_today'] ?? 0}',
                'Reportes hoy',
                AppColors.accentRed,
              ),
              _buildStatChip(
                _zonaPrincipalLabel,
                'Zona riesgo',
                AppColors.warningAmber,
              ),
              _buildStatChip(
                '${_stats?['reports_week'] ?? 0}',
                'Esta semana',
                AppColors.dangerRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(color: color, fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildTipoRoboSelector() {
    final tipos = ['Robo a Persona', 'Robo de celular', 'Otro'];
    return GlassCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: tipos.map((tipo) {
          final selected = _tipoRobo == tipo;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tipoRobo = tipo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  gradient: selected ? AppGradients.headerBlue : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected ? AppShadows.blueGlow : null,
                ),
                child: Text(
                  tipo,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNivelViolenciaSelector() {
    final niveles = {
      'Bajo': AppColors.safeGreen,
      'Moderado': AppColors.warningAmber,
      'Alto': AppColors.dangerRed,
      'Extremo': const Color(0xFFFF1744),
    };

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nivel seleccionado:', style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Row(
            children: niveles.entries.map((entry) {
              final selected = _nivelViolencia == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _nivelViolencia = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? entry.value.withOpacity(0.2)
                            : AppColors.glassWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? entry.value : AppColors.glassBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        entry.key,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: selected ? entry.value : AppColors.textHint,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionDatosDispositivo() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        colors: [Color(0x18BF5AF2), Color(0x08BF5AF2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.smartphone_rounded,
                color: Color(0xFFBF5AF2),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '📱 Datos del dispositivo robado',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildDarkDropdown(
            'Marca del celular',
            _marcaCelular,
            [
              'Samsung',
              'Xiaomi',
              'Motorola',
              'Huawei',
              'iPhone',
              'Otras marcas',
            ],
            (v) => setState(() => _marcaCelular = v!),
          ),
          _buildDarkDropdown(
            'Modelo aproximado',
            _modeloCelular,
            [
              'Alta gama (Galaxy S, iPhone, Xiaomi Pro)',
              'Media gama (Redmi, Moto G, A series)',
              'Baja gama (celulares básicos o antiguos)',
            ],
            (v) => setState(() => _modeloCelular = v!),
          ),
          _buildDarkDropdown(
            'Estado del celular',
            _estadoCelular,
            ['Nuevo', 'Usado (buen estado)', 'Usado (dañado o pantalla rota)'],
            (v) => setState(() => _estadoCelular = v!),
          ),
          _buildDarkDropdown(
            'Color del dispositivo',
            _colorCelular,
            ['Negro / Gris', 'Azul', 'Blanco', 'Rojo', 'Otro'],
            (v) => setState(() => _colorCelular = v!),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDarkDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            dropdownColor: AppColors.bgCard,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            iconEnabledColor: AppColors.textSecondary,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.accentBlue,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.glassWhite,
              isDense: true,
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              '${_fechaIncidente.day}/${_fechaIncidente.month}/${_fechaIncidente.year}',
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _seleccionarHora,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              _horaIncidente.format(context),
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxes() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStyledCheckbox(
            'Hubo lesiones físicas',
            _lesiones,
            AppColors.warningAmber,
            (v) => setState(() => _lesiones = v!),
          ),
          _buildStyledCheckbox(
            'Se utilizaron armas',
            _armas,
            AppColors.dangerRed,
            (v) {
              setState(() {
                _armas = v!;
                if (!_armas) {
                  _armaFuego = false;
                  _armaBlanca = false;
                }
              });
            },
          ),
          if (_armas) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  _buildStyledCheckbox(
                    'Arma de fuego (Pistola o revólver)',
                    _armaFuego,
                    AppColors.dangerRed,
                    (v) => setState(() => _armaFuego = v!),
                    isSubItem: true,
                  ),
                  _buildStyledCheckbox(
                    'Arma blanca (Cuchillo, navaja, etc.)',
                    _armaBlanca,
                    AppColors.dangerRed,
                    (v) => setState(() => _armaBlanca = v!),
                    isSubItem: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyledCheckbox(
    String label,
    bool value,
    Color accentColor,
    Function(bool?) onChanged, {
    bool isSubItem = false,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value
                    ? accentColor.withOpacity(0.2)
                    : AppColors.glassWhite,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? accentColor : AppColors.glassBorder,
                  width: value ? 1.5 : 1,
                ),
              ),
              child: value
                  ? Icon(Icons.check_rounded, size: 14, color: accentColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style:
                    (isSubItem ? AppTextStyles.bodySmall : AppTextStyles.body)
                        .copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonReportar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientButton(
          text: _registrandoReporte ? 'Registrando...' : 'Reportar Incidente',
          icon: _registrandoReporte ? null : Icons.report_rounded,
          isLoading: _registrandoReporte,
          colors: const [AppColors.accentRed, AppColors.accentRedDark],
          shadows: AppShadows.redGlow,
          height: 58,
          onPressed: _registrandoReporte ? null : _enviarReporte,
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _mostrarEstadisticas,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.accentBlueLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ver Estadísticas',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.accentBlueLight,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaIncidente,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentBlue,
              surface: AppColors.bgCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaIncidente) {
      setState(() => _fechaIncidente = picked);
    }
  }

  void _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaIncidente,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentBlue,
              surface: AppColors.bgCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _horaIncidente) {
      setState(() => _horaIncidente = picked);
    }
  }

  void _enviarReporte() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.heavyImpact();
    setState(() => _registrandoReporte = true);

    _contenidoReporte = _generarContenidoReporte();

    try {
      final saved = await _apiService.createReport(
        reportType: _tipoRobo,
        locationText: _ubicacionController.text.trim(),
        description: _descripcionController.text.trim(),
        violenceLevel: _nivelViolencia,
        incidentDate: _fechaHoraIncidente,
        hadInjuries: _lesiones,
        hadWeapons: _armas,
        weaponType: _tipoArma,
        deviceBrand: _tipoRobo == 'Robo de celular' ? _marcaCelular : null,
        deviceModel: _tipoRobo == 'Robo de celular' ? _modeloCelular : null,
        deviceCondition: _tipoRobo == 'Robo de celular' ? _estadoCelular : null,
        deviceColor: _tipoRobo == 'Robo de celular' ? _colorCelular : null,
      );

      if (!mounted) return;

      if (saved) {
        await _cargarEstadisticas();
        _mostrarDialogoExito();
      } else {
        await _guardarReporteSilencioso();
        if (!mounted) return;
        _mostrarDialogoFalloBackend();
      }
    } catch (_) {
      await _guardarReporteSilencioso();
      if (!mounted) return;
      _mostrarDialogoFalloBackend();
    } finally {
      if (mounted) setState(() => _registrandoReporte = false);
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

    if (_armas) {
      contenido += '• Tipo de Armas:\n';
      if (_armaFuego) {
        contenido += '  - Arma de fuego\n';
      }
      if (_armaBlanca) {
        contenido += '  - Arma blanca\n';
      }
      if (!_armaFuego && !_armaBlanca) {
        contenido += '  - Tipo no especificado\n';
      }
    }

    contenido +=
        '''
📝 DESCRIPCIÓN:
${_descripcionController.text}
''';

    if (_tipoRobo == 'Robo de celular') {
      contenido +=
          '''

📱 DATOS DEL DISPOSITIVO:
• Marca: $_marcaCelular
• Modelo: $_modeloCelular
• Estado: $_estadoCelular
• Color: $_colorCelular
''';
    }

    contenido +=
        '''

📄 INFO ADICIONAL:
• Generado: ${DateTime.now()}
• App: UbicaSafe
---
Este reporte fue generado automáticamente por UbicaSafe.
''';
    return contenido;
  }

  void _mostrarDialogoFalloBackend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.warningAmber),
            const SizedBox(width: 8),
            Text(
              'No se pudo registrar',
              style: AppTextStyles.headline3.copyWith(fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'No pudimos conectar con el servidor. Guardamos una copia local del reporte para que no pierdas la información.',
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.safeGreen),
            const SizedBox(width: 8),
            Text(
              '¡Reporte Enviado!',
              style: AppTextStyles.headline3.copyWith(fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'Tu reporte fue registrado en el backend de UbicaSafe y ya puede alimentar estadísticas y consultas de IA.',
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.accentBlueLight),
            ),
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
    } catch (_) {}
  }

  Future<void> _guardarCopiaLocal() async {
    _contenidoReporte = _generarContenidoReporte();

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/reporte_robo_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(_contenidoReporte);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reporte Guardado',
          style: AppTextStyles.headline3.copyWith(fontSize: 17),
        ),
        content: Text(
          'El reporte se ha guardado exitosamente en tu dispositivo.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.accentBlueLight),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarEstadisticas() {
    _cargarEstadisticas();
    final byType = _stats?['by_type'] as Map<String, dynamic>? ?? {};
    final byViolence = _stats?['by_violence'] as Map<String, dynamic>? ?? {};
    final topZone = _stats?['most_dangerous_zone'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estadísticas de Robos', style: AppTextStyles.headline3),
            const SizedBox(height: 4),
            Text('Datos reales del backend', style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),
            _buildEstadRow(
              'Reportes Hoy',
              '${_stats?['reports_today'] ?? 0}',
              AppColors.accentBlue,
            ),
            _buildEstadRow(
              'Reportes Semana',
              '${_stats?['reports_week'] ?? 0}',
              AppColors.warningAmber,
            ),
            _buildEstadRow(
              'Reportes Totales',
              '${_stats?['reports_total'] ?? 0}',
              AppColors.safeGreen,
            ),
            _buildEstadRow(
              'Zona Más Reportada',
              topZone?['name'] as String? ?? 'Sin datos',
              AppColors.dangerRed,
            ),
            _buildEstadRow(
              'Robos a Persona',
              '${byType['Robo a Persona'] ?? 0}',
              AppColors.warningAmber,
            ),
            _buildEstadRow(
              'Robos de Celular',
              '${byType['Robo de celular'] ?? 0}',
              const Color(0xFFBF5AF2),
            ),
            _buildEstadRow(
              'Violencia Alta/Extrema',
              '${(byViolence['Alto'] ?? 0) + (byViolence['Extremo'] ?? 0)}',
              AppColors.dangerRed,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
