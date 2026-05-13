// ─── heatmap_zone.model.dart ──────────────────────────────────────────────────

import 'package:latlong2/latlong.dart';

class HeatmapZone {
  final String id;
  final String barangayId;
  final String? barangayName;
  final ZoneRiskLevel riskLevel;
  final int activeCases;
  final LatLng center;
  final double radiusKm;
  final DateTime updatedAt;

  HeatmapZone({
    required this.id,
    required this.barangayId,
    this.barangayName,
    required this.riskLevel,
    required this.activeCases,
    required this.center,
    required this.radiusKm,
    required this.updatedAt,
  });

  factory HeatmapZone.fromJson(Map<String, dynamic> json) {
    // center.coordinates is [longitude, latitude] in GeoJSON
    final coords = json['center']['coordinates'] as List<dynamic>;
    final lng = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    // barangay_id may be a raw string or a populated object
    final barangayRaw = json['barangay_id'];
    final barangayId = barangayRaw is Map
        ? barangayRaw['_id'] as String
        : barangayRaw as String;
    final barangayName = barangayRaw is Map
        ? barangayRaw['name'] as String?
        : null;

    return HeatmapZone(
      id: json['_id'] as String,
      barangayId: barangayId,
      barangayName: barangayName,
      riskLevel: ZoneRiskLevel.fromString(json['risk_level'] as String),
      activeCases: (json['active_cases'] as num?)?.toInt() ?? 0,
      center: LatLng(lat, lng),
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 0.5,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'barangay_id': barangayId,
    'risk_level': riskLevel.value,
    'active_cases': activeCases,
    'center': {
      'type': 'Point',
      'coordinates': [center.longitude, center.latitude],
    },
    'radius_km': radiusKm,
    'updated_at': updatedAt.toIso8601String(),
  };

  // Radius in meters — used by flutter_map CircleLayer
  double get radiusMeters => radiusKm * 1000;
}

enum ZoneRiskLevel {
  low('Low'),
  moderate('Moderate'),
  high('High'),
  critical('Critical');

  const ZoneRiskLevel(this.value);
  final String value;

  static ZoneRiskLevel fromString(String value) {
    return ZoneRiskLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ZoneRiskLevel.low,
    );
  }
}
