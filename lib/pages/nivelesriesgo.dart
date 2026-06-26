import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';

class NivelesRiesgoScreen extends StatelessWidget {
  const NivelesRiesgoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Niveles de Riesgo', style: GoogleFonts.inter()),
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
            _buildNivelRiesgo(
              color: Colors.red,
              nivel: 'ALTO RIESGO',
              puntos: '70-100 puntos',
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
              color: Colors.orange,
              nivel: 'RIESGO MEDIO',
              puntos: '40-69 puntos',
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
              color: const Color.fromARGB(255, 170, 153, 1),
              nivel: 'BAJO RIESGO',
              puntos: '20-39 puntos',
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
              color: Colors.green,
              nivel: 'MUY BAJO RIESGO',
              puntos: '0-19 puntos',
              descripcion:
                  'Zona segura con patrullaje regular y vigilancia comunitaria.',
              recomendaciones: [
                'Precauciones normales de ciudad',
                'Disfrutar del espacio público',
              ],
            ),
            const SizedBox(height: 20),
            _buildFactoresCalculo(),
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
            '📊 Sistema de Evaluación de Riesgo',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nuestro modelo predictivo analiza múltiples factores para determinar el nivel de riesgo de cada zona en tiempo real.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNivelRiesgo({
    required Color color,
    required String nivel,
    required String puntos,
    required String descripcion,
    required List<String> recomendaciones,
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
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nivel,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ),
              Text(
                puntos,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(descripcion, style: GoogleFonts.inter(fontSize: 14)),
          const SizedBox(height: 12),
          Text(
            '✅ Recomendaciones:',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          ...recomendaciones
              .map(
                (recomendacion) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $recomendacion',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildFactoresCalculo() {
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
            '📋 Factores de Cálculo',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildFactorItem(
            'Historial delictivo (30 pts)',
            'Número y frecuencia de robos reportados',
          ),
          _buildFactorItem(
            'Horario (25 pts)',
            'Riesgo nocturno vs. diurno, horarios críticos',
          ),
          _buildFactorItem(
            'Entorno físico (20 pts)',
            'Iluminación, visibilidad, presencia de comercios',
          ),
          _buildFactorItem(
            'Densidad poblacional (15 pts)',
            'Aglomeraciones vs. zonas solitarias',
          ),
          _buildFactorItem(
            'Movilidad (10 pts)',
            'Facilidad de escape, rutas alternativas',
          ),
        ],
      ),
    );
  }

  Widget _buildFactorItem(String titulo, String descripcion) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  descripcion,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
