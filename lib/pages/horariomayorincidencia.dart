import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';

class HorarioMayorIncidenciaScreen extends StatelessWidget {
  const HorarioMayorIncidenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horarios de Mayor Incidencia', style: GoogleFonts.inter()),
        backgroundColor: const Color(0XFFFF4317),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MapaPredictivo()),
              (route) => false, // ← Esto elimina TODAS las pantallas anteriores
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(),
            const SizedBox(height: 20),
            _buildHorarioItem(
              horario: '18:00 - 22:00',
              nivel: 'ALTA INCIDENCIA',
              color: Colors.red,
              descripcion:
                  'Hora pico de robos nocturnos. Oscuridad + gente returning del trabajo',
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
              color: Colors.orange,
              descripcion:
                  'Hora de almuerzo. Gente distraída y aglomeraciones en mercados',
              motivos: [
                'Aglomeraciones en comedores y mercados',
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
              color: const Color.fromARGB(255, 190, 174, 25),
              descripcion:
                  'Hora pico de transporte. Robos por distracción en micros',
              motivos: [
                'Micros y transporte público llenísimos',
                'Gente apurada yendo al trabajo',
                'Carteristas en aglomeraciones',
                'Distracción por celulares',
              ],
              zonasCriticas: [
                'Paradas de micro',
                'Terminal de buses',
                'Entradas a universidades',
                'Zonas industriales',
              ],
            ),
            const SizedBox(height: 16),
            _buildHorarioItem(
              horario: '22:00 - 06:00',
              nivel: 'BAJA INCIDENCIA',
              color: Colors.green,
              descripcion:
                  'Menor actividad delictiva. Pero mayor riesgo por poca gente',
              motivos: [
                'Poca gente en las calles',
                'Mayor vigilancia policial nocturna',
                'Menos oportunidades para delincuentes',
                'Comercios cerrados',
              ],
              zonasCriticas: [
                'Calles desoladas',
                'Zonas industriales nocturnas',
                'Áreas periféricas',
                'Vías rápidas',
              ],
            ),
            const SizedBox(height: 20),
            _buildDiasSemana(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Patrones de Incidencia por Horario - El Alto',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Datos basados en análisis de reportes policiales y patrones delictivos de los últimos 6 meses.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioItem({
    required String horario,
    required String nivel,
    required Color color,
    required String descripcion,
    required List<String> motivos,
    required List<String> zonasCriticas,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con horario y nivel
          Row(
            children: [
              Icon(Icons.access_time, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                horario,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  nivel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Descripción
          Text(descripcion, style: GoogleFonts.inter(fontSize: 14)),
          const SizedBox(height: 12),

          // Motivos
          Text(
            '🔍 Motivos principales:',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          ...motivos
              .map(
                (motivo) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $motivo',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 12),

          // Zonas críticas
          Text(
            '📍 Zonas críticas:',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          ...zonasCriticas
              .map(
                (zona) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $zona',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildDiasSemana() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Días de la Semana con Mayor Incidencia',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildDiaItem('Viernes y Sábado', 'ALTA', Colors.red, [
            'Mayor movimiento nocturno',
            'Actividad social aumentada',
            'Consumo de alcohol en vía pública',
          ]),
          _buildDiaItem('Domingo', 'MEDIA-ALTA', Colors.orange, [
            'Mercados llenos y aglomeraciones',
            'Compras semanales familiares',
            'Robos en transporte a ferias',
          ]),
          _buildDiaItem(
            'Lunes',
            'MEDIA',
            const Color.fromARGB(255, 179, 163, 28),
            [
              'Robos a personas que cobran sueldo',
              'Movimiento bancario aumentado',
              'Gente con dinero en efectivo',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiaItem(
    String dia,
    String nivel,
    Color color,
    List<String> motivos,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(dia, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  nivel,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...motivos
              .map(
                (motivo) =>
                    Text('• $motivo', style: const TextStyle(fontSize: 12)),
              )
              .toList(),
        ],
      ),
    );
  }
}
