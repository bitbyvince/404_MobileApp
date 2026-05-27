// ============================================================
// lib/services/otp_service.dart
//
// Handles OTP-based account recovery and PIN reset flow.
//
// Flow:
//   1. Patient taps "Forgot PIN" on login screen
//   2. Enters their TB case number or phone number
//   3. Backend sends a 6-digit OTP via SMS to their
//      registered phone_number (via Firebase Auth / Twilio)
//   4. Patient enters OTP in the app
//   5. Backend verifies OTP → issues a one-time reset token
//   6. Patient sets a new 4-digit PIN
//   7. Backend hashes and saves the new PIN to MongoDB
//
// This service talks to the Express backend only.
// The OTP itself is generated and sent server-side.
// Firebase is used as the SMS delivery channel via
// Firebase Auth Phone verification (server SDK).
// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api/api_client.dart';

// ── OTP Result types ───────────────────────────────────────────
sealed class OtpResult {}

class OtpSuccess extends OtpResult {
  OtpSuccess({required this.message, this.sessionToken});
  final String message;
  // sessionToken is returned by /otp/verify
  // Required to call /otp/reset-pin in the next step
  final String? sessionToken;
}

class OtpFailure extends OtpResult {
  OtpFailure({required this.code, required this.message});
  final String code;
  final String message;
}

// ── OTP Type ───────────────────────────────────────────────────
// Matches otp_type values in your Firestore otp_sessions schema
enum OtpType {
  pinReset('pin_reset'),
  accountRecovery('account_recovery'),
  loginVerification('login_verification');

  const OtpType(this.value);
  final String value;
}

// ── Identifier type (mirrors AuthService) ─────────────────────
enum OtpIdentifierType {
  tbCaseNumber('tb_case_number'),
  phoneNumber('phone_number'),
  email('email');

  const OtpIdentifierType(this.value);
  final String value;
}

class OtpService {
  OtpService._();

  static final _dio = ApiClient.instance;

  // ── Resend cooldown tracking ───────────────────────────────
  // Prevents spamming the resend button.
  // Tracks the last resend time per identifier.
  static final Map<String, DateTime> _lastResendTime = {};
  static const _resendCooldownSeconds = 60;

  // ============================================================
  // REQUEST OTP
  // POST /otp/request
  //
  // Tells the backend to generate a 6-digit OTP and send it
  // via SMS to the patient's registered phone number.
  //
  // The backend:
  //   1. Looks up the patient by identifier in MongoDB
  //   2. Generates a 6-digit OTP and bcrypt-hashes it
  //   3. Writes the OTP session to Firestore otp_sessions
  //   4. Sends the OTP via Firebase Auth / SMS provider
  // ============================================================
  static Future<OtpResult> requestOtp({
    required String identifier,
    required OtpIdentifierType identifierType,
    required OtpType otpType,
  }) async {
    try {
      // Client-side validation
      final validationError = _validateIdentifier(
        identifier: identifier,
        identifierType: identifierType,
      );

      if (validationError != null) {
        return OtpFailure(code: 'VALIDATION_ERROR', message: validationError);
      }

      // Enforce resend cooldown
      final cooldownError = _checkCooldown(identifier);
      if (cooldownError != null) {
        return OtpFailure(code: 'COOLDOWN_ACTIVE', message: cooldownError);
      }

      final response = await _dio.post(
        ApiConfig.otpRequest,
        data: {
          'identifier': identifier.trim(),
          'identifier_type': identifierType.value,
          'otp_type': otpType.value,
        },
      );

      if (response.statusCode == 200) {
        // Record the time for cooldown enforcement
        _lastResendTime[identifier.trim()] = DateTime.now();

        final data = response.data as Map<String, dynamic>;
        final message =
            data['message'] as String? ?? 'OTP sent. Please check your phone.';

        debugPrint('[OtpService] OTP requested for ${identifierType.value}');

        return OtpSuccess(message: message);
      }

      return _mapErrorResponse(response);
    } on DioException catch (e) {
      return _mapDioException(e);
    } catch (e) {
      debugPrint('[OtpService] Unexpected requestOtp error: $e');
      return OtpFailure(
        code: 'UNKNOWN_ERROR',
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ============================================================
  // VERIFY OTP
  // POST /otp/verify
  //
  // Patient enters the 6-digit OTP they received via SMS.
  // On success the backend returns a one-time sessionToken
  // which is required to call resetPin().
  //
  // The backend:
  //   1. Reads the otp_sessions Firestore document
  //   2. Compares the submitted OTP against the stored hash
  //   3. Checks it has not expired and attempts <= max_attempts
  //   4. On success: marks is_used = true, returns session token
  //   5. On failure: increments attempts counter
  // ============================================================
  static Future<OtpResult> verifyOtp({
    required String identifier,
    required OtpIdentifierType identifierType,
    required String otpCode,
    required OtpType otpType,
  }) async {
    try {
      // Basic validation
      if (otpCode.trim().isEmpty) {
        return OtpFailure(
          code: 'VALIDATION_ERROR',
          message: 'Please enter the OTP code.',
        );
      }

      if (otpCode.trim().length != 6 ||
          !RegExp(r'^\d{6}$').hasMatch(otpCode.trim())) {
        return OtpFailure(
          code: 'VALIDATION_ERROR',
          message: 'OTP must be exactly 6 digits.',
        );
      }

      final response = await _dio.post(
        ApiConfig.otpVerify,
        data: {
          'identifier': identifier.trim(),
          'identifier_type': identifierType.value,
          'otp_code': otpCode.trim(),
          'otp_type': otpType.value,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final sessionToken = data['session_token'] as String?;
        final message =
            data['message'] as String? ?? 'OTP verified successfully.';

        debugPrint('[OtpService] OTP verified successfully.');

        return OtpSuccess(message: message, sessionToken: sessionToken);
      }

      return _mapErrorResponse(response);
    } on DioException catch (e) {
      return _mapDioException(e);
    } catch (e) {
      debugPrint('[OtpService] Unexpected verifyOtp error: $e');
      return OtpFailure(
        code: 'UNKNOWN_ERROR',
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ============================================================
  // RESET PIN
  // POST /otp/reset-pin
  //
  // Final step of the account recovery flow.
  // Uses the sessionToken returned by verifyOtp() to authorize
  // the PIN change — prevents skipping the OTP step.
  //
  // The backend:
  //   1. Validates the sessionToken
  //   2. Bcrypt-hashes the new PIN
  //   3. Updates users.pin_hash in MongoDB
  //   4. Invalidates the sessionToken
  // ============================================================
  static Future<OtpResult> resetPin({
    required String identifier,
    required OtpIdentifierType identifierType,
    required String newPin,
    required String sessionToken,
  }) async {
    try {
      // Validate new PIN
      final pinError = _validatePin(newPin);
      if (pinError != null) {
        return OtpFailure(code: 'VALIDATION_ERROR', message: pinError);
      }

      if (sessionToken.trim().isEmpty) {
        return OtpFailure(
          code: 'MISSING_SESSION_TOKEN',
          message: 'Invalid session. Please verify your OTP again.',
        );
      }

      final response = await _dio.post(
        ApiConfig.otpResetPin,
        data: {
          'identifier': identifier.trim(),
          'identifier_type': identifierType.value,
          'new_pin': newPin,
          'session_token': sessionToken.trim(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final message =
            data['message'] as String? ??
            'PIN reset successfully. Please log in with your new PIN.';

        debugPrint('[OtpService] PIN reset successful.');

        // Clear cooldown for this identifier after successful reset
        _lastResendTime.remove(identifier.trim());

        return OtpSuccess(message: message);
      }

      return _mapErrorResponse(response);
    } on DioException catch (e) {
      return _mapDioException(e);
    } catch (e) {
      debugPrint('[OtpService] Unexpected resetPin error: $e');
      return OtpFailure(
        code: 'UNKNOWN_ERROR',
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ============================================================
  // RESEND OTP
  // Convenience wrapper around requestOtp with cooldown check.
  // Returns seconds remaining if cooldown is still active.
  // ============================================================
  static Future<OtpResult> resendOtp({
    required String identifier,
    required OtpIdentifierType identifierType,
    required OtpType otpType,
  }) async {
    return requestOtp(
      identifier: identifier,
      identifierType: identifierType,
      otpType: otpType,
    );
  }

  // ============================================================
  // COOLDOWN TIMER
  // Returns remaining cooldown seconds (0 if not active)
  // Used by the UI to show "Resend in 45s" countdown
  // ============================================================
  static int getRemainingCooldown(String identifier) {
    final last = _lastResendTime[identifier.trim()];
    if (last == null) return 0;

    final elapsed = DateTime.now().difference(last).inSeconds;
    final remaining = _resendCooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  static bool isCooldownActive(String identifier) {
    return getRemainingCooldown(identifier) > 0;
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================
  static String? _validateIdentifier({
    required String identifier,
    required OtpIdentifierType identifierType,
  }) {
    if (identifier.trim().isEmpty) {
      return 'Please enter your identifier.';
    }

    switch (identifierType) {
      case OtpIdentifierType.tbCaseNumber:
        final pattern = RegExp(
          r'^PHNT-\d{4}-\d{3}-(S|DR)\d{2}-\d{4}$',
          caseSensitive: false,
        );
        if (!pattern.hasMatch(identifier.trim())) {
          return 'Invalid TB case number format. '
              'Example: PHNT-1304-071-S26-0001';
        }

      case OtpIdentifierType.phoneNumber:
        final pattern = RegExp(r'^(\+63|0)9\d{9}$');
        if (!pattern.hasMatch(identifier.trim())) {
          return 'Invalid phone number. '
              'Use format: 09XXXXXXXXX or +639XXXXXXXXX';
        }

      case OtpIdentifierType.email:
        final pattern = RegExp(
          r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
        );
        if (!pattern.hasMatch(identifier.trim())) {
          return 'Invalid email address.';
        }
    }

    return null;
  }

  static String? _validatePin(String pin) {
    if (pin.isEmpty || pin.length != 4) {
      return 'PIN must be exactly 4 digits.';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      return 'PIN must contain only numbers.';
    }
    return null;
  }

  static String? _checkCooldown(String identifier) {
    final remaining = getRemainingCooldown(identifier);
    if (remaining > 0) {
      return 'Please wait $remaining seconds before requesting another OTP.';
    }
    return null;
  }

  static OtpFailure _mapErrorResponse(Response response) {
    final data = response.data as Map<String, dynamic>?;
    final code = data?['code'] as String? ?? 'ERROR';
    final message = data?['message'] as String?;

    switch (response.statusCode) {
      case 400:
        return OtpFailure(code: code, message: message ?? 'Invalid request.');
      case 404:
        return OtpFailure(
          code: 'PATIENT_NOT_FOUND',
          message:
              'No account found with that identifier. '
              'Please contact your health center.',
        );
      case 410:
        // OTP expired
        return OtpFailure(
          code: 'OTP_EXPIRED',
          message: 'Your OTP has expired. Please request a new one.',
        );
      case 422:
        return OtpFailure(
          code: 'OTP_INVALID',
          message:
              'Incorrect OTP. '
              '${message ?? 'Please check the code and try again.'}',
        );
      case 429:
        return OtpFailure(
          code: 'MAX_ATTEMPTS',
          message:
              'Too many incorrect attempts. '
              'Please request a new OTP.',
        );
      default:
        return OtpFailure(
          code: code,
          message: message ?? 'OTP operation failed. Please try again.',
        );
    }
  }

  static OtpFailure _mapDioException(DioException e) {
    final code = e.requestOptions.extra['error_code'] as String?;
    final message = e.requestOptions.extra['error_message'] as String?;

    if (code == 'NO_CONNECTION') {
      return OtpFailure(
        code: 'NO_CONNECTION',
        message:
            'Cannot connect to the server. '
            'Please check your internet connection.',
      );
    }

    return OtpFailure(
      code: code ?? 'NETWORK_ERROR',
      message: message ?? 'A network error occurred. Please try again.',
    );
  }
}
