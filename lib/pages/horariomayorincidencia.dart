import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';

class HorarioMayorIncidenciaScreen extends StatefulWidget {
  const HorarioMayorIncidenciaScreen({super.key});

  @override
  State<HorarioMayorIncidenciaScreen> createState() => _HorarioMayorIncidenciaScreenState();
}

class _HorarioMayorIncidenciaScreenState extends State<HorarioMayorIncidenciaScreen> {
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
        title: Text('Horarios de Incidencia', style: AppTextStyles.headline3),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(),
            const SizedBox(height: 32),
            _buildHorarioItem(
              horario: '18:00 - 22:00',
              nivel: 'ALTA INCIDENCIA',
              color: AppColors.dangerRed,
              icon: Icons.nightlight_round,
              descripcion: 'Hora pico de robos nocturnos. Oscuridad + retorno del trabajo.',
              motivos: [
                'Poca visibilidad por oscuridad',
                'Personas cansadas del trabajo',
                'Transporte público lleno',
                'Calles con menos vigilancia',
              ],
              zonasCriticas: [
                'Calles poco iluminadas',
                'Zonas residenciales oscuras',
                'Parques y plazas',
                'Terminal de buses nocturna',
              ],
            ),
            const SizedBox(height: 16),
            _buildHorarioItem(
              horario: '12:00 - 14:00',
              nivel: 'MEDIA-ALTA INCIDENCIA',
              color: AppColors.warningAmber,
              icon: Icons.wb_sunny_rounded,
              descripcion: 'Hora de almuerzo. Gente distraída y aglomeraciones comerciales.',
              motivos: [
                'Aglomeraciones en comedores',
                'Personas distraídas comiendo',
                'Mucho movimiento comercial',
                'Billeteras visibles al pagar',
              ],
              zonasCriticas: [
                'Mercado Ceja',
                'Mercado Ramos',
                'Comedores populares',
                'Calles comerciales',
              ],
            ),
            const SizedBox(height: 16),
            _buildHorarioItem(
              horario: '07:00 - 09:00',
              nivel: 'MEDIA INCIDENCIA',
              color: AppColors.accentBlueLight,
              icon: Icons.wb_twilight_rounded,
              descripcion: 'Hora pico de transporte. Robos por distracción en micros.',
              motivos: [
                'Transporte público saturado',
                'Gente apurada al trabajo',
                'Carteristas en aglomeraciones',
                'Distracción por celulares',
              ],
              zonasCriticas: [
                'Paradas de transporte',
                'Terminal de buses',
                'Entradas a universidades',
                'Zonas industriales',
              ],
            ),
            const SizedBox(height: 16),
            _buildHorarioItem(
              horario: '22:00 - 06:00',
              nivel: 'BAJA INCIDENCIA',
              color: AppColors.safeGreen,
              icon: Icons.bedtime_rounded,
              descripcion: 'Menor actividad delictiva. Mayor riesgo por zonas desoladas.',
              motivos: [
                'Poca gente en las calles',
                'Mayor vigilancia nocturna',
                'Menos oportunidades de robo',
                'Comercios cerrados',
              ],
              zonasCriticas: [
                'Calles desoladas',
                'Zonas industriales nocturnas',
                'Áreas periféricas',
                'Vías rápidas',
              ],
            ),
            const SizedBox(height: 32),
            _buildDiasSemana(),
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
              const Icon(Icons.insert_chart_outlined_rounded, color: AppColors.accentBlueLight, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Patrones por Horario',
                  style: AppTextStyles.headline3.copyWith(color: AppColors.accentBlueLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Datos basados en análisis de reportes policiales y patrones delictivos de los últimos 6 meses en El Alto.',
            style: AppTextStyles.body.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioItem({
    required String horario,
    required String nivel,
    required Color color,
    required IconData icon,
    required String descripcion,
    required List<String> motivos,
    required List<String> zonasCriticas,
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
                    Text(horario, style: AppTextStyles.headline3),
                    const SizedBox(height: 4),
                    Text(
                      nivel,
                      style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(descripcion, style: AppTextStyles.body),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Motivos', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...motivos.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  width: 4, height: 4,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(m, style: AppTextStyles.caption)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zonas Críticas', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...zonasCriticas.map((z) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  width: 4, height: 4,
                                  decoration: const BoxDecoration(color: AppColors.textHint, shape: BoxShape.circle),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(z, style: AppTextStyles.caption)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiasSemana() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Días de la Semana', style: AppTextStyles.headline2),
        const SizedBox(height: 16),
        _buildDiaItem('Viernes y Sábado', 'ALTA', AppColors.dangerRed, [
          'Mayor movimiento nocturno',
          'Actividad social aumentada',
          'Consumo de alcohol en vía pública',
        ]),
        _buildDiaItem('Domingo', 'MEDIA-ALTA', AppColors.warningAmber, [
          'Mercados llenos y aglomeraciones',
          'Compras semanales familiares',
          'Robos en transporte a ferias',
        ]),
        _buildDiaItem('Lunes', 'MEDIA', AppColors.accentBlueLight, [
          'Robos a personas que cobran sueldo',
          'Movimiento bancario aumentado',
          'Gente con dinero en efectivo',
        ]),
      ],
    );
  }

  Widget _buildDiaItem(String dia, String nivel, Color color, List<String> motivos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dia, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(nivel, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...motivos.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_rounded, color: AppColors.textHint, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m, style: AppTextStyles.caption)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
