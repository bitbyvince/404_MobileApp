// ============================================================
// lib/services/auth_service.dart
// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api/api_client.dart';
import 'secure_storage_service.dart';
import 'dart:async' show unawaited;

// ── Result type ───────────────────────────────────────────────
sealed class AuthResult {}

class AuthSuccess extends AuthResult {
  AuthSuccess({
    required this.userId,
    required this.patientId,
    required this.token,
    required this.refreshToken,
  });

  final String userId;
  final String patientId;
  final String token;
  final String refreshToken;
}

class AuthFailure extends AuthResult {
  AuthFailure({required this.code, required this.message});

  final String code;
  final String message;
}

// ── Identifier type ────────────────────────────────────────────
enum IdentifierType {
  patientId('patient_id'),
  phoneNumber('phone_number'),
  email('email');

  const IdentifierType(this.value);
  final String value;
}

class AuthService {
  AuthService._();

  static final _dio = ApiClient.instance;

  // ============================================================
  // LOGIN
  // POST /auth/patient-login
  // ============================================================
  static Future<AuthResult> login({
    required String identifier,
    required IdentifierType identifierType,
    required String pin,
  }) async {
    try {
      final validationError = _validateLoginInput(
        identifier: identifier,
        identifierType: identifierType,
        pin: pin,
      );

      if (validationError != null) {
        return AuthFailure(code: 'VALIDATION_ERROR', message: validationError);
      }

      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'identifier': identifier.trim(),
          'identifier_type': identifierType.value,
          'pin': pin,
        },
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;

        if (data == null) {
          return AuthFailure(
            code: 'INVALID_RESPONSE',
            message: 'Unexpected response from server. Please try again.',
          );
        }

        final token = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;

        if (token == null) {
          return AuthFailure(
            code: 'INVALID_RESPONSE',
            message: 'Unexpected response from server. Please try again.',
          );
        }

        // ── FIX: await storage writes sequentially before returning ──
        // This ensures the token is fully persisted before the caller
        // (AuthProvider) attempts any follow-up requests like /auth/verify
        await SecureStorageService.saveJwt(token);
        if (refreshToken != null) {
          await SecureStorageService.saveRefreshToken(refreshToken);
        }
        await SecureStorageService.saveIdentifier(identifier.trim());

        debugPrint('[AuthService] Login success — token saved.');

        return AuthSuccess(
          userId: '',
          patientId: '',
          token: token,
          refreshToken: refreshToken ?? '',
        );
      }

      return _mapErrorResponse(response);
    } on DioException catch (e) {
      return _mapDioException(e);
    } catch (e) {
      debugPrint('[AuthService] Unexpected login error: $e');
      return AuthFailure(
        code: 'UNKNOWN_ERROR',
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ============================================================
  // SESSION CHECK — called by SplashScreen on app launch
  // ============================================================
  static Future<bool> checkExistingSession() async {
    try {
      final token = await SecureStorageService.getJwt();

      if (token == null || token.isEmpty) {
        debugPrint('[AuthService] No token found — redirecting to login.');
        return false;
      }

      // Use /patients/me — it's the correct authenticated profile endpoint.
      // /auth/verify doesn't accept a Bearer token in your backend.
      final response = await _dio.get(ApiConfig.myProfile);

      if (response.statusCode == 200) {
        debugPrint('[AuthService] Session valid — proceeding to dashboard.');
        return true;
      }

      await SecureStorageService.wipeAll();
      return false;
    } on DioException catch (e) {
      if (e.requestOptions.extra['error_code'] == 'NO_CONNECTION') {
        debugPrint('[AuthService] Offline during session check.');
        final token = await SecureStorageService.getJwt();
        return token != null && token.isNotEmpty;
      }

      await SecureStorageService.wipeAll();
      return false;
    } catch (e) {
      debugPrint('[AuthService] Session check error: $e');
      await SecureStorageService.wipeAll();
      return false;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  static Future<void> logout({String? fcmToken}) async {
    try {
      final token = await SecureStorageService.getJwt();

      if (token != null && token.isNotEmpty) {
        unawaited(
          _dio.post(ApiConfig.logout).then((_) {}).catchError((dynamic e) {
            debugPrint('[AuthService] Logout backend call failed: $e');
            return null;
          }),
        );

        if (fcmToken != null && fcmToken.isNotEmpty) {
          unawaited(
            _dio
                .delete(ApiConfig.removeFcmToken, data: {'fcm_token': fcmToken})
                .then((_) {})
                .catchError((dynamic e) {
                  debugPrint('[AuthService] FCM deregister failed: $e');
                  return null;
                }),
          );
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Logout error (non-fatal): $e');
    } finally {
      await SecureStorageService.wipeAll();
      ApiClient.reset();
      debugPrint('[AuthService] Logged out — storage cleared.');
    }
  }

  // ============================================================
  // GET CURRENT IDENTITY — reads from storage, no network call
  // ============================================================
  static Future<Map<String, String?>> getCurrentIdentity() async {
    final results = await Future.wait([
      SecureStorageService.getUserId(),
      SecureStorageService.getPatientId(),
      SecureStorageService.getSavedIdentifier(),
    ]);

    return {
      'user_id': results[0],
      'patient_id': results[1],
      'saved_identifier': results[2],
    };
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================
  static String? _validateLoginInput({
    required String identifier,
    required IdentifierType identifierType,
    required String pin,
  }) {
    if (identifier.trim().isEmpty) {
      return 'Please enter your login identifier.';
    }

    if (pin.isEmpty || pin.length != 4) {
      return 'PIN must be exactly 4 digits.';
    }

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      return 'PIN must contain only numbers.';
    }

    switch (identifierType) {
      case IdentifierType.patientId:
        // Format: PT-0001
        final patientPattern = RegExp(r'^PT-\d{4}$', caseSensitive: false);
        if (!patientPattern.hasMatch(identifier.trim())) {
          return 'Invalid Patient ID format. Example: PT-0001';
        }

      case IdentifierType.phoneNumber:
        // Philippine mobile: +639XXXXXXXXX or 09XXXXXXXXX
        final phonePattern = RegExp(r'^(\+63|0)9\d{9}$');
        if (!phonePattern.hasMatch(identifier.trim())) {
          return 'Invalid phone number. Use format: 09XXXXXXXXX or +639XXXXXXXXX';
        }

      case IdentifierType.email:
        final emailPattern = RegExp(
          r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
        );
        if (!emailPattern.hasMatch(identifier.trim())) {
          return 'Invalid email address.';
        }
    }

    return null;
  }

  static AuthFailure _mapErrorResponse(Response response) {
    final data = response.data as Map<String, dynamic>?;
    final code = data?['code'] as String? ?? 'ERROR';
    final message = data?['message'] as String?;

    switch (response.statusCode) {
      case 400:
        return AuthFailure(
          code: code,
          message: message ?? 'Invalid request. Please check your input.',
        );
      case 401:
        return AuthFailure(
          code: 'INVALID_CREDENTIALS',
          message:
              'Incorrect PIN or account not found. '
              'Please check your details and try again.',
        );
      case 403:
        return AuthFailure(
          code: 'ACCOUNT_INACTIVE',
          message:
              'Your account has been deactivated. '
              'Please contact your health center.',
        );
      case 429:
        return AuthFailure(
          code: 'TOO_MANY_ATTEMPTS',
          message: 'Too many login attempts. Please wait and try again.',
        );
      default:
        return AuthFailure(
          code: code,
          message: message ?? 'Login failed. Please try again.',
        );
    }
  }

  static AuthFailure _mapDioException(DioException e) {
    final code = e.requestOptions.extra['error_code'] as String?;
    final message = e.requestOptions.extra['error_message'] as String?;

    if (code == 'NO_CONNECTION') {
      return AuthFailure(
        code: 'NO_CONNECTION',
        message:
            'Cannot connect to the server. '
            'Please check your internet connection.',
      );
    }

    if (code == 'TIMEOUT') {
      return AuthFailure(
        code: 'TIMEOUT',
        message: 'The request timed out. Please try again.',
      );
    }

    return AuthFailure(
      code: code ?? 'NETWORK_ERROR',
      message: message ?? 'A network error occurred. Please try again.',
    );
  }
}
