import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';

class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── JWT ───────────────────────────────────────────────────
  static Future<void> saveJwt(String token) =>
      _storage.write(key: Env.jwtStorageKey, value: token);

  static Future<String?> getJwt() => _storage.read(key: Env.jwtStorageKey);

  static Future<void> deleteJwt() => _storage.delete(key: Env.jwtStorageKey);

  // ── Refresh Token ─────────────────────────────────────────
  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: Env.refreshTokenKey, value: token);

  static Future<String?> readRefreshToken() =>
      _storage.read(key: Env.refreshTokenKey);

  static Future<void> deleteRefreshToken() =>
      _storage.delete(key: Env.refreshTokenKey);

  // ── User Identity ─────────────────────────────────────────
  static Future<void> saveUserIdentity({
    required String userId,
    required String patientId,
  }) async {
    await Future.wait([
      _storage.write(key: Env.userIdStorageKey, value: userId),
      _storage.write(key: Env.patientIdStorageKey, value: patientId),
    ]);
  }

  static Future<String?> getUserId() =>
      _storage.read(key: Env.userIdStorageKey);

  static Future<String?> getPatientId() =>
      _storage.read(key: Env.patientIdStorageKey);

  // ── Saved login identifier (pre-fill on next launch) ──────
  static Future<void> saveIdentifier(String identifier) =>
      _storage.write(key: Env.savedIdentifierKey, value: identifier);

  static Future<String?> getSavedIdentifier() =>
      _storage.read(key: Env.savedIdentifierKey);

  // ── PIN ───────────────────────────────────────────────────
  static Future<void> savePin(String pinHash) =>
      _storage.write(key: Env.pinStorageKey, value: pinHash);

  static Future<String?> getPin() => _storage.read(key: Env.pinStorageKey);

  static Future<void> deletePin() => _storage.delete(key: Env.pinStorageKey);

  // ── Wipe all (logout / session expired) ───────────────────
  static Future<void> wipeAll() async {
    await Future.wait([
      deleteJwt(),
      deleteRefreshToken(),
      deletePin(),
      _storage.delete(key: Env.userIdStorageKey),
      _storage.delete(key: Env.patientIdStorageKey),
      _storage.delete(key: Env.savedIdentifierKey),
    ]);
    debugPrint('[SecureStorage] Cleared all credentials.');
  }

  // ── Instance aliases (used by AuthProvider) ───────────────
  Future<String?> getAccessToken() => getJwt();

  Future<String?> getRefreshToken() => readRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([saveJwt(accessToken), saveRefreshToken(refreshToken)]);
  }

  Future<void> clearAll() => wipeAll();
}
