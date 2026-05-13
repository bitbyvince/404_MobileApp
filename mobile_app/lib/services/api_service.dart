import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  // ─── Get JWT token from secure storage ───────────────────────────────────────
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    return await get('/users/me');
  }

  // ─── Build headers ────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── GET ──────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET $endpoint failed: $e');
    }
  }

  // ─── POST ─────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST $endpoint failed: $e');
    }
  }

  // ─── PUT ──────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT $endpoint failed: $e');
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.delete(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE $endpoint failed: $e');
    }
  }

  // ─── Response Handler ─────────────────────────────────────────────────────────
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Surface the backend's message if available
    final message =
        body['message'] ?? 'Request failed (${response.statusCode})';
    throw Exception(message);
  }

  // ─── Token helpers (called by auth_service.dart) ──────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
