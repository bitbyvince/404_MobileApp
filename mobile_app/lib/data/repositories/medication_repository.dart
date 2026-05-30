// lib/data/repositories/medication_repository.dart

import 'package:dio/dio.dart';
import 'package:respiratrack/config/api_config.dart';
import 'package:respiratrack/data/models/medication_log_model.dart';
import 'package:respiratrack/data/models/patient_model.dart';
import 'package:respiratrack/services/api/api_client.dart';
import 'package:respiratrack/services/secure_storage_service.dart';

class MedicationRepository {
  MedicationRepository._();
  static final instance = MedicationRepository._();

  static final _client = ApiClient.instance;

  // ── GET today's log ────────────────────────────────────────
  // GET /api/medication-logs/my?date=YYYY-MM-DD
  Future<MedicationLogModel?> getLogByDate({required DateTime date}) async {
    final response = await _client.get(
      '/medication-logs/my',
      queryParameters: {'date': _formatDate(date)},
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw _createApiException(response);

    final body = response.data as Map<String, dynamic>;
    final payload = body['data'];

    // Backend returns null when no log exists for today
    if (payload == null) return null;

    return MedicationLogModel.fromJson(payload as Map<String, dynamic>);
  }

  // ── GET paginated history ──────────────────────────────────
  // GET /api/medication-logs/my?page=1&limit=30
  Future<MedicationHistoryResult> getHistory({
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _client.get(
      '/medication-logs/my',
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.statusCode != 200) throw _createApiException(response);
    return MedicationHistoryResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ── MARK individual drug taken ─────────────────────────────
  // POST /api/medication-logs
  // Sends the full medicines array with this one drug as Taken,
  // the rest from the patient's drug regimen as Missed.
  // Backend requires medicines array with min 1 item.
  Future<MedicationLogModel> markDrugTaken({
    required String drugName,
    required String strength,
    required DateTime takenAt,
    required List<DrugRegimenItem> fullRegimen, // patient's full drug list
  }) async {
    final patientId = await _getPatientId();

    // Build medicines array — mark only this drug as Taken,
    // keep others as their current status (Missed if no log yet)
    final medicines = fullRegimen
        .map(
          (d) => {
            'drug_name': d.drugName,
            'strength': d.strength,
            'unit': d.unit,
            'number_to_be_taken': d.numberToBeTaken,
            'status': (d.drugName == drugName && d.strength == strength)
                ? 'Taken'
                : 'Missed',
            'taken_at': (d.drugName == drugName && d.strength == strength)
                ? takenAt.toIso8601String()
                : null,
          },
        )
        .toList();

    final response = await _client.post(
      '/medication-logs',
      data: {
        'patient_id': patientId,
        'log_date': _formatDate(DateTime.now()),
        'medicines': medicines,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload =
        (body['data'] as Map<String, dynamic>?)?['log'] ??
        body['data'] as Map<String, dynamic>? ??
        body;
    return MedicationLogModel.fromJson(payload as Map<String, dynamic>);
  }

  // ── MARK all drugs taken ───────────────────────────────────
  // POST /api/medication-logs
  // Sends all drugs in the regimen with status = Taken
  Future<MedicationLogModel> markAllTaken({
    required DateTime takenAt,
    required List<DrugRegimenItem> fullRegimen,
  }) async {
    final patientId = await _getPatientId();

    final medicines = fullRegimen
        .map(
          (d) => {
            'drug_name': d.drugName,
            'strength': d.strength,
            'unit': d.unit,
            'number_to_be_taken': d.numberToBeTaken,
            'status': 'Taken',
            'taken_at': takenAt.toIso8601String(),
          },
        )
        .toList();

    final response = await _client.post(
      '/medication-logs',
      data: {
        'patient_id': patientId,
        'log_date': _formatDate(DateTime.now()),
        'medicines': medicines,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload =
        (body['data'] as Map<String, dynamic>?)?['log'] ??
        body['data'] as Map<String, dynamic>? ??
        body;
    return MedicationLogModel.fromJson(payload as Map<String, dynamic>);
  }

  // ── UPDATE existing log (patch individual drug status) ─────
  // PATCH /api/medication-logs/:logId
  Future<MedicationLogModel> updateLog({
    required String logId,
    required List<Map<String, dynamic>> medicines,
  }) async {
    final response = await _client.patch(
      '/medication-logs/$logId',
      data: {'medicines': medicines},
    );

    if (response.statusCode != 200) throw _createApiException(response);

    final body = response.data as Map<String, dynamic>;
    final payload =
        (body['data'] as Map<String, dynamic>?)?['log'] ??
        body['data'] as Map<String, dynamic>? ??
        body;
    return MedicationLogModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<String> _getPatientId() async {
    final id = await SecureStorageService.getPatientId();
    if (id == null || id.isEmpty) {
      throw Exception('Patient ID not available.');
    }
    return id;
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Exception _createApiException(Response response) {
    final message =
        (response.data as Map<String, dynamic>?)?['message'] as String? ??
        'Request failed with status ${response.statusCode}.';
    return Exception(message);
  }
}
