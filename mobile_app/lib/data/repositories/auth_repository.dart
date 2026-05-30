import 'package:dio/dio.dart';
import 'package:respiratrack/config/api_config.dart';
import 'package:respiratrack/data/models/user_model.dart';
import 'package:respiratrack/services/api/api_client.dart';

class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  static final _client = ApiClient.instance;

  Future<Map<String, String>> patientLogin({
    required String identifier,
    required String pin,
  }) async {
    final identifierType = _detectIdentifierType(identifier);
    final response = await _client.post(
      ApiConfig.login,
      data: {
        'identifier': identifier.trim(),
        'identifier_type': identifierType.value,
        'pin': pin,
      },
    );

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    // Backend returns: { success, message, data: { accessToken, refreshToken, role } }
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return {
      'accessToken': data['accessToken'] as String? ?? '',
      'refreshToken': data['refreshToken'] as String? ?? '',
      'userId': data['userId'] as String? ?? '',
      'patientId': data['patientId'] as String? ?? '',
      'tbCaseNumber':
          data['tbCaseNumber'] as String? ??
          data['tb_case_number'] as String? ??
          '',
    };
  }

  Future<Map<String, String>> verifyOtp({
    required String phoneNumber,
    required String firebaseIdToken,
  }) async {
    final response = await _client.post(
      '/auth/otp-login',
      data: {
        'phone_number': phoneNumber.trim(),
        'firebase_id_token': firebaseIdToken,
      },
    );

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return {
      'accessToken': data['accessToken'] as String? ?? '',
      'refreshToken': data['refreshToken'] as String? ?? '',
    };
  }

  // auth_repository.dart
  Future<UserModel> getMe() async {
    // Use a dedicated /auth/me or /users/me endpoint that returns user fields
    // NOT /patients/me which returns patient clinical data
    final response = await _client.get('/auth/me');
    // or '/users/me' — whichever your backend exposes for user identity
    if (response.statusCode != 200) {
      throw _createApiException(response);
    }
    final json = response.data as Map<String, dynamic>;
    final userJson = json['data'] as Map<String, dynamic>? ?? json;
    return UserModel.fromJson(userJson);
  }

  Future<void> logout() async {
    final response = await _client.post(ApiConfig.logout);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _createApiException(response);
    }
  }

  Future<void> changePin({
    required String currentPin,
    required String newPin,
    required String confirmNewPin,
  }) async {
    final response = await _client.post(
      '/auth/change-pin',
      data: {
        'current_pin': currentPin,
        'new_pin': newPin,
        'confirm_new_pin': confirmNewPin,
      },
    );

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }
  }

  Future<Map<String, String>> refreshToken(String refreshToken) async {
    final response = await _client.post(
      ApiConfig.refreshToken,
      data: {'refresh_token': refreshToken},
    );

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return {
      'accessToken': data['accessToken'] as String? ?? '',
      'refreshToken': data['refreshToken'] as String? ?? '',
    };
  }

  // Auto-detects identifier type from the input value
  IdentifierType _detectIdentifierType(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) return IdentifierType.email;
    if (trimmed.startsWith('+63') || trimmed.startsWith('09')) {
      return IdentifierType.phoneNumber;
    }
    return IdentifierType.patientId; // PT-XXXX
  }

  Exception _createApiException(Response response) {
    final message =
        (response.data as Map<String, dynamic>?)?['message'] as String? ??
        'Request failed with status ${response.statusCode}.';
    return Exception(message);
  }
}

enum IdentifierType {
  patientId('patient_id'),
  phoneNumber('phone_number'),
  email('email');

  const IdentifierType(this.value);
  final String value;
}
