import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ubicasafe/core/app_theme.dart';

enum RiskLevel { low, medium, high }

class RiskZone {
  const RiskZone({
    required this.name,
    required this.position,
    required this.radiusMeters,
    required this.level,
    required this.description,
    this.reportCount = 0,
  });

  final String name;
  final LatLng position;
  final double radiusMeters;
  final RiskLevel level;
  final String description;
  final int reportCount;

  factory RiskZone.fromJson(Map<String, dynamic> json) {
    return RiskZone(
      name: json['name'] as String? ?? 'Zona sin nombre',
      position: LatLng(
        (json['latitude'] as num?)?.toDouble() ?? defaultLatitude,
        (json['longitude'] as num?)?.toDouble() ?? defaultLongitude,
      ),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 250,
      level: parseLevel(json['risk_level'] as String?),
      description: json['description'] as String? ?? 'Sin descripción.',
      reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
    );
  }

  static const defaultLatitude = -16.5034;
  static const defaultLongitude = -68.1725;

  static RiskLevel parseLevel(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
      case 'alto':
        return RiskLevel.high;
      case 'medium':
      case 'medio':
      case 'moderado':
        return RiskLevel.medium;
      case 'low':
      case 'bajo':
        return RiskLevel.low;
      default:
        return RiskLevel.medium;
    }
  }

  String get label {
    switch (level) {
      case RiskLevel.high:
        return 'Alto';
      case RiskLevel.medium:
        return 'Medio';
      case RiskLevel.low:
        return 'Bajo';
    }
  }

  Color get color {
    switch (level) {
      case RiskLevel.high:
        return AppColors.dangerRed;
      case RiskLevel.medium:
        return AppColors.warningAmber;
      case RiskLevel.low:
        return AppColors.safeGreen;
    }
  }

  double get score {
    switch (level) {
      case RiskLevel.high:
        return 0.88;
      case RiskLevel.medium:
        return 0.56;
      case RiskLevel.low:
        return 0.24;
    }
  }
}

class RiskMapData {
  RiskMapData._();

  static const LatLng defaultCenter = LatLng(-16.5034, -68.1725);

  static const List<LatLng> elAltoBounds = [
    LatLng(-16.4500, -68.1200),
    LatLng(-16.4550, -68.1300),
    LatLng(-16.4600, -68.1400),
    LatLng(-16.4700, -68.1450),
    LatLng(-16.4750, -68.1500),
    LatLng(-16.4650, -68.1600),
    LatLng(-16.4600, -68.1700),
    LatLng(-16.4550, -68.1800),
    LatLng(-16.4500, -68.1900),
    LatLng(-16.4450, -68.2000),
    LatLng(-16.4500, -68.2100),
    LatLng(-16.4550, -68.2200),
    LatLng(-16.4650, -68.2300),
    LatLng(-16.4750, -68.2350),
    LatLng(-16.4850, -68.2400),
    LatLng(-16.4950, -68.2450),
    LatLng(-16.5050, -68.2500),
    LatLng(-16.5150, -68.2550),
    LatLng(-16.5250, -68.2600),
    LatLng(-16.5350, -68.2650),
    LatLng(-16.5450, -68.2700),
    LatLng(-16.5550, -68.2750),
    LatLng(-16.5650, -68.2800),
    LatLng(-16.5750, -68.2850),
    LatLng(-16.5850, -68.1900),
    LatLng(-16.5900, -68.1850),
    LatLng(-16.5950, -68.1800),
    LatLng(-16.5800, -68.1750),
    LatLng(-16.5700, -68.1700),
    LatLng(-16.5600, -68.1650),
    LatLng(-16.5500, -68.1600),
    LatLng(-16.5400, -68.1550),
    LatLng(-16.5300, -68.1500),
    LatLng(-16.5200, -68.1450),
    LatLng(-16.5100, -68.1400),
    LatLng(-16.5000, -68.1350),
    LatLng(-16.4900, -68.1300),
    LatLng(-16.4800, -68.1250),
    LatLng(-16.4700, -68.1250),
    LatLng(-16.4600, -68.1250),
    LatLng(-16.4500, -68.1200),
  ];

  static const List<RiskZone> zones = [
    RiskZone(
      name: 'UPEA - Universidad Pública de El Alto',
      position: LatLng(-16.491033, -68.193479),
      radiusMeters: 400,
      level: RiskLevel.high,
      description:
          'Sede principal de la UPEA. Múltiples reportes de robos en los alrededores.',
    ),
    RiskZone(
      name: 'Puente Vela',
      position: LatLng(-16.5975, -68.1842),
      radiusMeters: 250,
      level: RiskLevel.high,
      description: 'Peligroso a partir de las 8:00 pm en adelante.',
    ),
    RiskZone(
      name: 'Zona 12 de Octubre',
      position: LatLng(-16.5118, -68.1632),
      radiusMeters: 149,
      level: RiskLevel.high,
      description:
          'Zona peligrosa por múltiples reportes a partir de las 8:00 pm.',
    ),
    RiskZone(
      name: 'La Ceja de El Alto',
      position: LatLng(-16.5034, -68.1625),
      radiusMeters: 180,
      level: RiskLevel.high,
      description:
          'Zona comercial principal. ALTO RIESGO en el Pasaje Artesanal y áreas aledañas.',
    ),
    RiskZone(
      name: 'Feria 16 de Julio',
      position: LatLng(-16.4942, -68.1736),
      radiusMeters: 450,
      level: RiskLevel.high,
      description:
          'Alta incidencia de robos por distracción en aglomeraciones.',
    ),
    RiskZone(
      name: 'Terminal Metropolitana',
      position: LatLng(-16.52073, -68.17723),
      radiusMeters: 380,
      level: RiskLevel.high,
      description:
          'Terminal con alta afluencia. Reportes frecuentes de asaltos.',
    ),
    RiskZone(
      name: 'Senkata',
      position: LatLng(-16.5702, -68.1862),
      radiusMeters: 380,
      level: RiskLevel.high,
      description: 'Lugar alejado. Reportes frecuentes de robos.',
    ),
    RiskZone(
      name: 'Terminal de Buses Río Seco',
      position: LatLng(-16.4878, -68.2002),
      radiusMeters: 350,
      level: RiskLevel.high,
      description: 'Zona de terminal con alta incidencia delictiva.',
    ),
    RiskZone(
      name: 'Avenida 6 de Marzo',
      position: LatLng(-16.5059, -68.1631),
      radiusMeters: 100,
      level: RiskLevel.high,
      description: 'Múltiples reportes de robos al paso.',
    ),
    RiskZone(
      name: 'Mercado Satélite',
      position: LatLng(-16.5247, -68.1506),
      radiusMeters: 280,
      level: RiskLevel.medium,
      description: 'Robos ocasionales por distracción.',
    ),
    RiskZone(
      name: 'Plaza La Paz',
      position: LatLng(-16.4919, -68.1832),
      radiusMeters: 250,
      level: RiskLevel.medium,
      description: 'Incidentes esporádicos en horarios de menor tránsito.',
    ),
    RiskZone(
      name: 'Estacion Teleferico Azul',
      position: LatLng(-16.4893, -68.1931),
      radiusMeters: 250,
      level: RiskLevel.medium,
      description: 'Zona transitada, precauciones en la noche.',
    ),
    RiskZone(
      name: 'Universidad Franz Tamayo (UNIFRANZ)',
      position: LatLng(-16.5085, -68.1663),
      radiusMeters: 200,
      level: RiskLevel.medium,
      description: 'Concurrencia universitaria.',
    ),
    RiskZone(
      name: 'Universidad Técnica Privada Cosmos',
      position: LatLng(-16.5245, -68.2131),
      radiusMeters: 200,
      level: RiskLevel.medium,
      description: 'Concurrencia universitaria.',
    ),
    RiskZone(
      name: 'Universidad Salesiana de Bolivia (USB)',
      position: LatLng(-16.4770, -68.1487),
      radiusMeters: 200,
      level: RiskLevel.medium,
      description: 'Concurrencia universitaria.',
    ),
    RiskZone(
      name: 'Ballivian',
      position: LatLng(-16.4893, -68.1805),
      radiusMeters: 250,
      level: RiskLevel.medium,
      description: 'Zona transitada.',
    ),
    RiskZone(
      name: 'Estadio Municipal de El Alto',
      position: LatLng(-16.4713, -68.2018),
      radiusMeters: 250,
      level: RiskLevel.medium,
      description: 'Zona transitada, precauciones los días de partido.',
    ),
    RiskZone(
      name: 'Cementerio General Mercedario',
      position: LatLng(-16.5292, -68.2481),
      radiusMeters: 250,
      level: RiskLevel.medium,
      description: 'Zona transitada, evitar la noche.',
    ),
    RiskZone(
      name: 'Achocalla',
      position: LatLng(-16.4500, -68.1200),
      radiusMeters: 300,
      level: RiskLevel.medium,
      description: 'Área periurbana con riesgo medio.',
    ),
    RiskZone(
      name: 'Alto Lima',
      position: LatLng(-16.4765, -68.1751),
      radiusMeters: 350,
      level: RiskLevel.low,
      description: 'Urbanización. Seguridad y baja incidencia.',
    ),
    RiskZone(
      name: 'Villa Ingenio',
      position: LatLng(-16.4750, -68.2000),
      radiusMeters: 400,
      level: RiskLevel.low,
      description: 'Zona residencial tranquila.',
    ),
    RiskZone(
      name: 'Rio seco',
      position: LatLng(-16.4868, -68.2086),
      radiusMeters: 380,
      level: RiskLevel.low,
      description: 'Zona residencial organizada. Vigilancia vecinal.',
    ),
    RiskZone(
      name: 'Ciudad Satélite',
      position: LatLng(-16.5282, -68.1542),
      radiusMeters: 380,
      level: RiskLevel.low,
      description: 'Zona residencial organizada. Vigilancia vecinal.',
    ),
    RiskZone(
      name: 'Estacion Linea Morada',
      position: LatLng(-16.5221, -68.1694),
      radiusMeters: 380,
      level: RiskLevel.low,
      description: 'Zona transitada pero con vigilancia.',
    ),
  ];

  static RiskZone nearestZone(LatLng position, {List<RiskZone>? source}) {
    final sourceZones = source == null || source.isEmpty ? zones : source;
    return sourceZones.reduce((best, zone) {
      final bestDistance = distanceMeters(position, best.position);
      final zoneDistance = distanceMeters(position, zone.position);
      return zoneDistance < bestDistance ? zone : best;
    });
  }

  static RiskZone effectiveZoneFor(LatLng position, {List<RiskZone>? source}) {
    final sourceZones = source == null || source.isEmpty ? zones : source;
    final containingZones = sourceZones.where(
      (zone) => distanceMeters(position, zone.position) <= zone.radiusMeters,
    );

    if (containingZones.isEmpty) {
      return nearestZone(position, source: sourceZones);
    }

    return containingZones.reduce((a, b) => a.score >= b.score ? a : b);
  }

  static double distanceMeters(LatLng from, LatLng to) {
    const earthRadius = 6371000.0;
    final dLat = _degreesToRadians(to.latitude - from.latitude);
    final dLng = _degreesToRadians(to.longitude - from.longitude);
    final lat1 = _degreesToRadians(from.latitude);
    final lat2 = _degreesToRadians(to.latitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double value) => value * math.pi / 180;
}
