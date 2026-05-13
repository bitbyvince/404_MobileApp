// lib/services/heatmap_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/heatmap_zone.model.dart';
import '../utils/jwt_helper.dart';

class HeatmapService {
  // ─── GET ALL HEATMAP ZONES ───────────────────────────────────────────────

  Future<List<HeatmapZone>> getHeatmapZones() async {
    final token = await JwtHelper.getToken();

    final response = await http.get(
      Uri.parse(ApiConfig.heatmapZones),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['zones'] ?? [];
      return list.map((e) => HeatmapZone.fromJson(e)).toList();
    }
    throw Exception('Failed to load heatmap zones.');
  }

  // ─── GET NEARBY ZONES ────────────────────────────────────────────────────

  // Returns zones near the user's current GPS location
  Future<List<HeatmapZone>> getNearbyZones(double lat, double lng) async {
    final token = await JwtHelper.getToken();

    final uri = Uri.parse(
      ApiConfig.heatmapNearby,
    ).replace(queryParameters: {'lat': lat.toString(), 'lng': lng.toString()});

    final response = await http.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['zones'] ?? [];
      return list.map((e) => HeatmapZone.fromJson(e)).toList();
    }
    throw Exception('Failed to load nearby zones.');
  }

  // ─── GET ZONE BY BARANGAY ────────────────────────────────────────────────

  Future<HeatmapZone?> getZoneByBarangay(String barangayId) async {
    final token = await JwtHelper.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.heatmapZones}/barangay/$barangayId'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return HeatmapZone.fromJson(data['zone']);
    }
    if (response.statusCode == 404) return null;
    throw Exception('Failed to load zone for barangay.');
  }
}
