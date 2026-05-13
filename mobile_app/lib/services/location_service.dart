// lib/services/location_service.dart

import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/jwt_helper.dart';

class LocationService {
  // ─── PERMISSIONS ─────────────────────────────────────────────────────────

  // Call this once on app startup or before any location request
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // ─── GET CURRENT LOCATION ────────────────────────────────────────────────

  Future<Position?> getCurrentLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  // ─── POST LOCATION TO BACKEND ────────────────────────────────────────────

  // Updates the public user's last_location in MongoDB
  // Used for geofence matching against heatmap zones
  Future<bool> postLocationToBackend(double lat, double lng) async {
    final token = await JwtHelper.getToken();
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.updateLocation),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({'latitude': lat, 'longitude': lng}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─── GET LOCATION AND POST ───────────────────────────────────────────────

  // Convenience method — gets GPS then immediately posts to backend
  Future<Position?> updateLocationToBackend() async {
    final position = await getCurrentLocation();
    if (position == null) return null;

    await postLocationToBackend(position.latitude, position.longitude);
    return position;
  }

  // ─── STREAM — CONTINUOUS TRACKING ────────────────────────────────────────

  // Returns a stream of position updates
  // Use this for real-time geofence checking while the app is open
  Stream<Position> startTracking() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // only emit if user moves 50+ meters
        timeLimit: Duration(seconds: 30),
      ),
    );
  }

  // ─── DISTANCE HELPER ─────────────────────────────────────────────────────

  // Returns distance in meters between two coordinates
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Returns distance in kilometers
  double distanceBetweenKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  // ─── CHECK IF INSIDE ZONE ────────────────────────────────────────────────

  bool isInsideZone({
    required double userLat,
    required double userLng,
    required double zoneLat,
    required double zoneLng,
    required double radiusKm,
  }) {
    final distanceKm = distanceBetweenKm(userLat, userLng, zoneLat, zoneLng);
    return distanceKm <= radiusKm;
  }
}
