import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';

class NivelesRiesgoScreen extends StatefulWidget {
  const NivelesRiesgoScreen({super.key});

  @override
  State<NivelesRiesgoScreen> createState() => _NivelesRiesgoScreenState();
}

class _NivelesRiesgoScreenState extends State<NivelesRiesgoScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MapaPredictivo()),
              (route) => false,
            );
          },
        ),
        title: Text('Niveles de Riesgo', style: AppTextStyles.headline3),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(),
            const SizedBox(height: 32),
            _buildNivelRiesgo(
              color: AppColors.dangerRed,
              icon: Icons.error_rounded,
              nivel: 'ALTO RIESGO',
              puntos: '70-100 pts',
              descripcion:
                  'Zona de peligro extremo. Evitar transitar solo. Alta probabilidad de robos reportados.',
              recomendaciones: [
                'Evitar transitar solo',
                'No mostrar dispositivos electrónicos',
                'Buscar rutas alternativas',
                'Transitar en horas diurnas',
              ],
            ),
            const SizedBox(height: 16),
            _buildNivelRiesgo(
              color: AppColors.warningAmber,
              icon: Icons.warning_rounded,
              nivel: 'RIESGO MEDIO',
              puntos: '40-69 pts',
              descripcion:
                  'Zona con incidentes esporádicos. Precaución moderada requerida.',
              recomendaciones: [
                'Mantener alerta en el entorno',
                'Evitar horarios nocturnos',
                'Guardar objetos de valor',
                'Circular por áreas iluminadas',
              ],
            ),
            const SizedBox(height: 16),
            _buildNivelRiesgo(
              color: AppColors.accentBlueLight,
              icon: Icons.info_rounded,
              nivel: 'BAJO RIESGO',
              puntos: '20-39 pts',
              descripcion:
                  'Zona relativamente segura con pocos incidentes reportados.',
              recomendaciones: [
                'Mantener precauciones básicas',
                'Evitar calles oscuras',
                'Estar atento al entorno',
              ],
            ),
            const SizedBox(height: 16),
            _buildNivelRiesgo(
              color: AppColors.safeGreen,
              icon: Icons.verified_user_rounded,
              nivel: 'MUY BAJO RIESGO',
              puntos: '0-19 pts',
              descripcion:
                  'Zona segura con patrullaje regular y vigilancia comunitaria.',
              recomendaciones: [
                'Precauciones normales de ciudad',
                'Disfrutar del espacio público',
              ],
            ),
            const SizedBox(height: 32),
            _buildFactoresCalculo(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.accentBlueLight, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sistema de Evaluación',
                  style: AppTextStyles.headline3.copyWith(color: AppColors.accentBlueLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nuestro modelo predictivo analiza múltiples factores para determinar el nivel de riesgo de cada zona en tiempo real.',
            style: AppTextStyles.body.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNivelRiesgo({
    required Color color,
    required IconData icon,
    required String nivel,
    required String puntos,
    required String descripcion,
    required List<String> recomendaciones,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nivel,
                      style: AppTextStyles.headline3.copyWith(color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      puntos,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(descripcion, style: AppTextStyles.body),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Recomendaciones',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recomendaciones.map((recomendacion) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.textHint,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(recomendacion, style: AppTextStyles.bodySmall),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactoresCalculo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Factores de Cálculo', style: AppTextStyles.headline2),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFactorItem('Historial delictivo (30 pts)', 'Número y frecuencia de robos reportados', Icons.history_rounded),
              const Divider(color: AppColors.glassBorder, height: 24),
              _buildFactorItem('Horario (25 pts)', 'Riesgo nocturno vs. diurno, horarios críticos', Icons.access_time_rounded),
              const Divider(color: AppColors.glassBorder, height: 24),
              _buildFactorItem('Entorno físico (20 pts)', 'Iluminación, visibilidad, comercios', Icons.location_city_rounded),
              const Divider(color: AppColors.glassBorder, height: 24),
              _buildFactorItem('Densidad poblacional (15 pts)', 'Aglomeraciones vs. solitarias', Icons.groups_rounded),
              const Divider(color: AppColors.glassBorder, height: 24),
              _buildFactorItem('Movilidad (10 pts)', 'Facilidad de escape, rutas alternativas', Icons.directions_walk_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFactorItem(String titulo, String descripcion, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accentBlue, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(descripcion, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
