import 'package:dio/dio.dart';
import 'package:respiratrack/config/api_config.dart';
import 'package:respiratrack/data/models/sputum_test_model.dart';
import 'package:respiratrack/services/api/api_client.dart';
import 'package:respiratrack/services/secure_storage_service.dart';

class SputumRepository {
  SputumRepository._();
  static final instance = SputumRepository._();

  static final _client = ApiClient.instance;

  Future<List<SputumTestModel>> getMyTests() async {
    final patientId = await _getPatientId();
    final response = await _client.get(ApiConfig.sputumTests(patientId));

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? body;
    final rawTests =
        data['tests'] as List<dynamic>? ??
        data['sputum_tests'] as List<dynamic>? ??
        [];
    return rawTests
        .map((item) => SputumTestModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SputumTestModel> getTestById(String testId) async {
    final response = await _client.get('/sputum-tests/$testId');

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return SputumTestModel.fromJson(payload);
  }

  Future<String> _getPatientId() async {
    final patientId = await SecureStorageService.getPatientId();
    if (patientId == null || patientId.isEmpty) {
      throw Exception('Patient ID is not available in secure storage.');
    }
    return patientId;
  }

  Exception _createApiException(Response response) {
    final message =
        (response.data as Map<String, dynamic>?)?['message'] as String? ??
        'Request failed with status ${response.statusCode}.';
    return Exception(message);
  }
}
