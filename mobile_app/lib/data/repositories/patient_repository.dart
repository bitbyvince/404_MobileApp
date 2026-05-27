import 'package:dio/dio.dart';
import 'package:respiratrack/config/api_config.dart';
import 'package:respiratrack/data/models/patient_model.dart';
import 'package:respiratrack/services/api/api_client.dart';

class PatientRepository {
  PatientRepository._();
  static final instance = PatientRepository._();

  static final _client = ApiClient.instance;

  Future<PatientModel> getMyProfile() async {
    final response = await _client.get(ApiConfig.myProfile);
    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return PatientModel.fromJson(payload);
  }

  Future<PatientModel> updateContactInfo({
    String? phoneNumber,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      data['phone_number'] = phoneNumber.trim();
    }
    if (email != null && email.isNotEmpty) {
      data['email'] = email.trim();
    }

    final response = await _client.patch(ApiConfig.updateMyContact, data: data);

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return PatientModel.fromJson(payload);
  }

  Exception _createApiException(Response response) {
    final message =
        (response.data as Map<String, dynamic>?)?['message'] as String? ??
        'Request failed with status ${response.statusCode}.';
    return Exception(message);
  }
}
