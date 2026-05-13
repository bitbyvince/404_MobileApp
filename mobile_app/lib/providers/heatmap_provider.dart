// lib/providers/heatmap_provider.dart

import 'package:flutter/material.dart';
import '../models/heatmap_zone.model.dart';
import '../services/heatmap_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import '../theme/app_theme.dart';

class HeatmapProvider extends ChangeNotifier {
  final HeatmapService _service = HeatmapService();

  List<HeatmapZone> _zones = [];
  List<HeatmapZone> _nearbyZones = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedRiskFilter; // null = show all

  // ─── GETTERS ──────────────────────────────────────────────────────────────

  List<HeatmapZone> get zones => _selectedRiskFilter == null
      ? _zones
      : _zones.where((z) => z.riskLevel.value == _selectedRiskFilter).toList();

  List<HeatmapZone> get nearbyZones => _nearbyZones;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedRisk => _selectedRiskFilter;

  // ─── FETCH ALL ZONES ──────────────────────────────────────────────────────

  Future<void> fetchZones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _zones = await _service.getHeatmapZones();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── FETCH NEARBY ZONES ───────────────────────────────────────────────────

  Future<void> fetchNearbyZones(double lat, double lng) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _nearbyZones = await _service.getNearbyZones(lat, lng);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── FILTER ───────────────────────────────────────────────────────────────

  void setRiskFilter(String? riskLevel) {
    _selectedRiskFilter = riskLevel;
    notifyListeners();
  }

  void clearFilter() {
    _selectedRiskFilter = null;
    notifyListeners();
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  // Returns the highest risk level among all zones
  String get overallRiskLevel {
    if (_zones.isEmpty) return 'Low';
    const priority = {'Critical': 4, 'High': 3, 'Moderate': 2, 'Low': 1};
    return _zones
        .reduce(
          (a, b) => (priority[a.riskLevel] ?? 0) >= (priority[b.riskLevel] ?? 0)
              ? a
              : b,
        )
        .riskLevel
        .value;
  }

  // Count zones by risk level for dashboard summary
  int countByRisk(String riskLevel) =>
      _zones.where((z) => z.riskLevel.value == riskLevel).length;
}

// Used by HeatmapScreen to watch zones as CircleMarkers directly
final heatmapZonesProvider = FutureProvider<List<CircleMarker>>((ref) async {
  final service = HeatmapService();
  final zones = await service.getHeatmapZones();

  return zones.map((zone) {
    final color = _zoneColor(zone.riskLevel.value);
    return CircleMarker(
      point: zone.center,
      radius: zone.radiusMeters,
      color: color.withOpacity(0.25),
      borderColor: color,
      borderStrokeWidth: 1.5,
      useRadiusInMeter: true,
    );
  }).toList();
});

Color _zoneColor(String riskLevel) {
  switch (riskLevel) {
    case 'Critical':
      return AppColors.riskHigh;
    case 'High':
      return AppColors.riskModerate;
    case 'Moderate':
      return AppColors.riskLow;
    default:
      return AppColors.riskNone;
  }
}
