// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/jwt_helper.dart';

class AuthService {
  // ─── PUBLIC USER REGISTER ────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String contactNumber,
    required String password,
    String? fullName,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: ApiConfig.headers(),
      body: jsonEncode({
        'contact_number': contactNumber,
        'password': password,
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Registration failed.');
  }

  // ─── VERIFY OTP ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> verifyOtp({
    required String firebaseIdToken,
    required String userId,
    required String sessionId,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.verifyOtp),
      headers: ApiConfig.headers(),
      body: jsonEncode({
        'firebase_id_token': firebaseIdToken,
        'user_id': userId,
        'session_id': sessionId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Save token to secure storage
      await JwtHelper.saveSession(
        token: data['token'],
        userId: data['user']['id'],
        role: data['user']['role'],
      );
      return data;
    }
    throw Exception(data['message'] ?? 'OTP verification failed.');
  }

  // ─── PUBLIC USER LOGIN ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String contactNumber,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: ApiConfig.headers(),
      body: jsonEncode({'contact_number': contactNumber, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await JwtHelper.saveSession(
        token: data['token'],
        userId: data['user']['id'],
        role: data['user']['role'],
      );
      return data;
    }
    throw Exception(data['message'] ?? 'Login failed.');
  }

  // ─── STAFF LOGIN (nurse / barangay_admin / super_admin) ──────────────────

  Future<Map<String, dynamic>> staffLogin({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.staffLogin),
      headers: ApiConfig.headers(),
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await JwtHelper.saveSession(
        token: data['token'],
        userId: data['user']['id'],
        role: data['user']['role'],
      );
      return data;
    }
    throw Exception(data['message'] ?? 'Login failed.');
  }

  // ─── VERIFY TOKEN ────────────────────────────────────────────────────────

  // Call on app startup to check if the stored token is still valid
  Future<bool> isTokenValid() async {
    final token = await JwtHelper.getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.verifyToken),
        headers: ApiConfig.headers(token: token),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── SAVE FCM TOKEN ──────────────────────────────────────────────────────

  Future<void> saveFcmToken(String fcmToken) async {
    final token = await JwtHelper.getToken();
    if (token == null) return;

    await http.post(
      Uri.parse(ApiConfig.saveFcmToken),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({'fcm_token': fcmToken}),
    );
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await JwtHelper.clearSession();
  }
}
