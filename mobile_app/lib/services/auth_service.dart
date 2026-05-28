// ============================================================
// lib/services/auth_service.dart
//
// Handles all authentication logic for the patient mobile app.
//
// Responsibilities:
//   - Login via tb_case_number / phone_number / email + PIN
//   - Session check on app launch (splash screen)
//   - Token refresh
//   - Logout (clears storage + deregisters FCM token)
//
// Does NOT handle navigation — that is the authProvider's job.
// Does NOT handle OTP — that is otp_service.dart's job.
// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api/api_client.dart';
import 'secure_storage_service.dart';
import 'dart:async' show unawaited;

// ── Result type ───────────────────────────────────────────────
// Wraps success/failure so repositories never throw — they return
sealed class AuthResult {}

class AuthSuccess extends AuthResult {
  AuthSuccess({
    required this.userId,
    required this.patientId,
    required this.tbCaseNumber,
    required this.token,
    required this.refreshToken,
  });

  final String userId;
  final String patientId;
  final String tbCaseNumber;
  final String token;
  final String refreshToken;
}

class AuthFailure extends AuthResult {
  AuthFailure({required this.code, required this.message});

  final String code;
  final String message;
}

// ── Identifier type ────────────────────────────────────────────
// Matches what your Express backend expects in the login body
enum IdentifierType {
  tbCaseNumber('tb_case_number'),
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
  // POST /auth/login
  //
  // Patient logs in using one of three identifiers + 4-digit PIN.
  // On success:
  //   1. Saves JWT + refresh token to flutter_secure_storage
  //   2. Saves user identity (user_id, patient_id, tb_case_number)
  //   3. Saves the identifier for pre-fill on next login
  // ============================================================
  static Future<AuthResult> login({
    required String identifier,
    required IdentifierType identifierType,
    required String pin,
  }) async {
    try {
      // Basic client-side validation before hitting the network
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

      // ── Success path ────────────────────────────────────
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final token = data['token'] as String?;
        final refreshToken = data['refresh_token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (token == null || user == null) {
          return AuthFailure(
            code: 'INVALID_RESPONSE',
            message: 'Unexpected response from server. Please try again.',
          );
        }

        final userId = user['user_id'] as String? ?? '';
        final patientId = user['patient_id'] as String? ?? '';
        final tbCaseNumber = user['tb_case_number'] as String? ?? '';

        // Persist credentials to secure storage
        await Future.wait([
          SecureStorageService.saveJwt(token),
          if (refreshToken != null)
            SecureStorageService.saveRefreshToken(refreshToken),
          SecureStorageService.saveUserIdentity(
            userId: userId,
            patientId: patientId,
            tbCaseNumber: tbCaseNumber,
          ),
          // Save identifier so login field pre-fills next time
          SecureStorageService.saveIdentifier(identifier.trim()),
        ]);

        debugPrint('[AuthService] Login success — $tbCaseNumber');

        return AuthSuccess(
          userId: userId,
          patientId: patientId,
          tbCaseNumber: tbCaseNumber,
          token: token,
          refreshToken: refreshToken ?? '',
        );
      }

      // ── Known error responses from Express backend ──────
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
  // SESSION CHECK
  // Called by SplashScreen on every app launch.
  //
  // Checks if a valid JWT exists in secure storage.
  // If found but expired, attempts a silent refresh.
  // Returns true if a valid session is established.
  // ============================================================
  static Future<bool> checkExistingSession() async {
    try {
      final token = await SecureStorageService.getJwt();

      if (token == null || token.isEmpty) {
        debugPrint('[AuthService] No token found — redirecting to login.');
        return false;
      }

      // Verify the token is still valid with the backend
      final response = await _dio.get(ApiConfig.verifyToken);

      if (response.statusCode == 200) {
        debugPrint('[AuthService] Session valid — proceeding to dashboard.');
        return true;
      }

      // Token invalid or expired — clear and return false
      // ApiInterceptor will have already attempted a refresh.
      // If we reach here, refresh also failed.
      await SecureStorageService.wipeAll();
      return false;
    } on DioException catch (e) {
      // Network error during session check — don't force logout
      // Let the user try; requests will fail with NO_CONNECTION
      if (e.requestOptions.extra['error_code'] == 'NO_CONNECTION') {
        debugPrint('[AuthService] Offline during session check.');
        // Return true only if a token exists — allows offline access
        // to cached data while the app is open
        final token = await SecureStorageService.getJwt();
        return token != null && token.isNotEmpty;
      }

      // Session truly expired
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
  // POST /auth/logout
  //
  // 1. Tells backend to invalidate the refresh token
  // 2. Deregisters the FCM device token from Firestore
  // 3. Clears all local secure storage
  //
  // Always succeeds locally even if the network call fails —
  // the patient is logged out on the device regardless
  // ============================================================
  static Future<void> logout({String? fcmToken}) async {
    try {
      final token = await SecureStorageService.getJwt();

      if (token != null && token.isNotEmpty) {
        // Tell backend to invalidate the refresh token
        // Fire and forget — don't block logout on this
        unawaited(
          _dio.post(ApiConfig.logout).then((_) {}).catchError((dynamic e) {
            debugPrint('[AuthService] Logout backend call failed: $e');
            return null; // must return something assignable to Response
          }),
        );

        // Deregister FCM token from Firestore
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
      // Always clear local storage regardless of network result
      await SecureStorageService.wipeAll();
      ApiClient.reset();
      debugPrint('[AuthService] Logged out — storage cleared.');
    }
  }

  // ============================================================
  // GET CURRENT IDENTITY
  // Reads from secure storage — no network call.
  // Used by providers to reconstruct state after app restart.
  // ============================================================
  static Future<Map<String, String?>> getCurrentIdentity() async {
    final results = await Future.wait([
      SecureStorageService.getUserId(),
      SecureStorageService.getPatientId(),
      SecureStorageService.getTbCaseNumber(),
      SecureStorageService.getSavedIdentifier(),
    ]);

    return {
      'user_id': results[0],
      'patient_id': results[1],
      'tb_case_number': results[2],
      'saved_identifier': results[3],
    };
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  // Client-side validation before making the network call
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
      case IdentifierType.tbCaseNumber:
        // Validate PHNT-1304-071-S26-0001 format
        final tbPattern = RegExp(
          r'^PHNT-\d{4}-\d{3}-(S|DR)\d{2}-\d{4}$',
          caseSensitive: false,
        );
        if (!tbPattern.hasMatch(identifier.trim())) {
          return 'Invalid TB case number format. '
              'Example: PHNT-1304-071-S26-0001';
        }

      case IdentifierType.phoneNumber:
        // Philippine mobile number: +639XXXXXXXXX or 09XXXXXXXXX
        final phonePattern = RegExp(r'^(\+63|0)9\d{9}$');
        if (!phonePattern.hasMatch(identifier.trim())) {
          return 'Invalid phone number. '
              'Use format: 09XXXXXXXXX or +639XXXXXXXXX';
        }

      case IdentifierType.email:
        final emailPattern = RegExp(
          r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
        );
        if (!emailPattern.hasMatch(identifier.trim())) {
          return 'Invalid email address.';
        }
    }

    return null; // no errors
  }

  // Maps non-2xx HTTP responses to AuthFailure
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

  // Maps DioException types to AuthFailure
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
