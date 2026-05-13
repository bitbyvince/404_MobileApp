// lib/utils/jwt_helper.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JwtHelper {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';

  // ─── TOKEN ───────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  // ─── USER ID ─────────────────────────────────────────────────────────────

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // ─── USER ROLE ───────────────────────────────────────────────────────────

  static Future<void> saveUserRole(String role) async {
    await _storage.write(key: _userRoleKey, value: role);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  // ─── SAVE ALL AT ONCE ────────────────────────────────────────────────────

  // Call this right after a successful login
  static Future<void> saveSession({
    required String token,
    required String userId,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userRoleKey, value: role),
    ]);
  }

  // ─── CLEAR ALL ───────────────────────────────────────────────────────────

  // Call this on logout — wipes token, userId, and role
  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userRoleKey),
    ]);
  }
}
