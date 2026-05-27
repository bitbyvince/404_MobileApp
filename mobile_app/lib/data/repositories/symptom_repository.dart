import 'package:dio/dio.dart';
import 'package:respiratrack/config/api_config.dart';
import 'package:respiratrack/data/models/symptom_log_model.dart';
import 'package:respiratrack/services/api/api_client.dart';
import 'package:respiratrack/services/secure_storage_service.dart';

class SymptomRepository {
  SymptomRepository._();
  static final instance = SymptomRepository._();

  static final _client = ApiClient.instance;

  Future<SymptomLogModel?> getTodayLog() async {
    final patientId = await _getPatientId();
    final response = await _client.get(
      ApiConfig.symptomLogs(patientId),
      queryParameters: {'today': 'true'},
    );

    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return SymptomLogModel.fromJson(payload);
  }

  Future<SymptomHistoryResult> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final patientId = await _getPatientId();
    final response = await _client.get(
      ApiConfig.symptomLogs(patientId),
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    return SymptomHistoryResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SymptomLogModel> submitLog({
    required List<SymptomEntry> symptoms,
    required String freeTextNotes,
  }) async {
    final patientId = await _getPatientId();
    final response = await _client.post(
      ApiConfig.submitSymptomLog(patientId),
      data: {
        'symptoms': symptoms.map((s) => s.toJson()).toList(),
        'free_text_notes': freeTextNotes,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return SymptomLogModel.fromJson(payload);
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
