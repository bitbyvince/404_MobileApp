import 'package:dio/dio.dart';
import 'package:respiratrack/config/api_config.dart';
import 'package:respiratrack/data/models/medication_log_model.dart';
import 'package:respiratrack/services/api/api_client.dart';
import 'package:respiratrack/services/secure_storage_service.dart';

class MedicationRepository {
  MedicationRepository._();
  static final instance = MedicationRepository._();

  static final _client = ApiClient.instance;

  Future<MedicationLogModel?> getLogByDate({required DateTime date}) async {
    final patientId = await _getPatientId();
    final response = await _client.get(
      '/patients/$patientId/medication-logs',
      queryParameters: {'date': _formatDate(date)},
    );

    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return MedicationLogModel.fromJson(payload);
  }

  Future<MedicationHistoryResult> getHistory({
    int page = 1,
    int limit = 30,
  }) async {
    final patientId = await _getPatientId();
    final response = await _client.get(
      '/patients/$patientId/medication-logs',
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    return MedicationHistoryResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<MedicationLogModel> markDrugTaken({
    required String drugName,
    required String strength,
    required DateTime takenAt,
  }) async {
    final patientId = await _getPatientId();
    final response = await _client.post(
      ApiConfig.submitMedicationLog(patientId),
      data: {
        'action': 'mark_drug_taken',
        'drug_name': drugName,
        'strength': strength,
        'taken_at': takenAt.toIso8601String(),
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return MedicationLogModel.fromJson(payload);
  }

  Future<MedicationLogModel> markAllTaken({required DateTime takenAt}) async {
    final patientId = await _getPatientId();
    final response = await _client.post(
      ApiConfig.submitMedicationLog(patientId),
      data: {'action': 'mark_all_taken', 'taken_at': takenAt.toIso8601String()},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return MedicationLogModel.fromJson(payload);
  }

  Future<String> _getPatientId() async {
    final patientId = await SecureStorageService.getPatientId();
    if (patientId == null || patientId.isEmpty) {
      throw Exception('Patient ID is not available in secure storage.');
    }
    return patientId;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Exception _createApiException(Response response) {
    final message =
        (response.data as Map<String, dynamic>?)?['message'] as String? ??
        'Request failed with status ${response.statusCode}.';
    return Exception(message);
  }
}
