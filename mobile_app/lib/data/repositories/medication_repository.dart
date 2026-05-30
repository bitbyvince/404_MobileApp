import 'package:dio/dio.dart';
import 'package:respiratrack/data/models/medication_log_model.dart';
import 'package:respiratrack/services/api/api_client.dart';
import 'package:respiratrack/services/secure_storage_service.dart';

class MedicationRepository {
  MedicationRepository._();
  static final instance = MedicationRepository._();
  static final _client = ApiClient.instance;

  // ── GET LOG BY DATE ───────────────────────────────────────
  // GET /medication-logs/my?date=YYYY-MM-DD
  Future<MedicationLogModel?> getLogByDate({required DateTime date}) async {
    final response = await _client.get(
      '/medication-logs/my',
      queryParameters: {'date': _formatDate(date)},
    );
    if (response.statusCode == 404) return null;
    _assertSuccess(response);
    final payload = response.data['data'];
    if (payload == null) return null;
    return MedicationLogModel.fromJson(payload as Map<String, dynamic>);
  }

  // ── GET HISTORY ───────────────────────────────────────────
  // GET /medication-logs/my?page=1&limit=30
  Future<MedicationHistoryResult> getHistory({
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _client.get(
      '/medication-logs/my',
      queryParameters: {'page': page, 'limit': limit},
    );
    _assertSuccess(response);
    return MedicationHistoryResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ── SUBMIT / MARK ALL TAKEN ───────────────────────────────
  // POST /medication-logs
  // Called by provider.markAllTaken() and medication_screen.dart
  // medicines list is built from the patient's drug_regimen,
  // each entry: { drug_name, strength, unit, number_to_be_taken, status }
  Future<MedicationLogModel> submitLog({
    required List<Map<String, dynamic>> medicines,
  }) async {
    final patientId = await _getPatientId();
    final response = await _client.post(
      '/medication-logs',
      data: {
        'patient_id': patientId,
        'log_date': _formatDate(DateTime.now()),
        'medicines': medicines,
      },
    );
    _assertSuccess(response);
    return _parseLogFromResponse(response);
  }

  // ── MARK ALL TAKEN ────────────────────────────────────────
  // Convenience wrapper — builds the medicines payload automatically
  // from today's log or uses the stored drug regimen.
  // Called by MedicationProvider.markAllTaken() and
  // compliance_calendar_screen.dart
  Future<MedicationLogModel> markAllTaken({required DateTime takenAt}) async {
    final patientId = await _getPatientId();

    // First check if a log already exists today so we can update it
    final existing = await getLogByDate(date: takenAt);

    if (existing != null) {
      // Update every medicine status to Taken
      final updatedMedicines = existing.medicines
          .map(
            (m) => {
              'drug_name': m.drugName,
              'strength': m.strength,
              'unit': m.unit,
              'number_to_be_taken': m.numberToBeTaken,
              'status': 'Taken',
              'taken_at': takenAt.toIso8601String(),
            },
          )
          .toList();
      return updateLog(logId: existing.logId, medicines: updatedMedicines);
    }

    // No log yet today — POST a new one with all medicines taken.
    // The backend's logMedication will read the patient's drug_regimen
    // and we send status=Taken for each.
    // Since we don't have the regimen here, send a minimal payload and
    // let the backend fill from the patient record.
    final response = await _client.post(
      '/medication-logs',
      data: {
        'patient_id': patientId,
        'log_date': _formatDate(takenAt),
        'medicines': <Map<String, dynamic>>[], // backend fills from regimen
        'mark_all_taken': true, // backend flag
        'taken_at': takenAt.toIso8601String(),
      },
    );
    _assertSuccess(response);
    return _parseLogFromResponse(response);
  }

  // ── MARK SINGLE DRUG TAKEN ────────────────────────────────
  // Called by MedicationProvider.markDrugTaken()
  // and medication_screen.dart's per-drug Take button
  Future<MedicationLogModel> markDrugTaken({
    required String drugName,
    required String strength,
    required DateTime takenAt,
  }) async {
    final patientId = await _getPatientId();
    final existing = await getLogByDate(date: takenAt);

    if (existing != null) {
      // Update that specific drug's status in the existing log
      final updatedMedicines = existing.medicines.map((m) {
        if (m.drugName == drugName && m.strength == strength) {
          return {
            'drug_name': m.drugName,
            'strength': m.strength,
            'unit': m.unit,
            'number_to_be_taken': m.numberToBeTaken,
            'status': 'Taken',
            'taken_at': takenAt.toIso8601String(),
          };
        }
        return {
          'drug_name': m.drugName,
          'strength': m.strength,
          'unit': m.unit,
          'number_to_be_taken': m.numberToBeTaken,
          'status': m.status,
          'taken_at': m.takenAt?.toIso8601String(),
        };
      }).toList();
      return updateLog(logId: existing.logId, medicines: updatedMedicines);
    }

    // No log yet — create one with just this drug marked taken
    final response = await _client.post(
      '/medication-logs',
      data: {
        'patient_id': patientId,
        'log_date': _formatDate(takenAt),
        'medicines': [
          {
            'drug_name': drugName,
            'strength': strength,
            'status': 'Taken',
            'taken_at': takenAt.toIso8601String(),
          },
        ],
      },
    );
    _assertSuccess(response);
    return _parseLogFromResponse(response);
  }

  // ── UPDATE LOG ────────────────────────────────────────────
  // PATCH /medication-logs/:logId
  Future<MedicationLogModel> updateLog({
    required String logId,
    required List<Map<String, dynamic>> medicines,
  }) async {
    final response = await _client.patch(
      '/medication-logs/$logId',
      data: {'medicines': medicines},
    );
    _assertSuccess(response);
    return _parseLogFromResponse(response);
  }

  // ── HELPERS ───────────────────────────────────────────────
  Future<String> _getPatientId() async {
    final id = await SecureStorageService.getPatientId();
    if (id == null || id.isEmpty) throw Exception('Patient ID not available.');
    return id;
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  MedicationLogModel _parseLogFromResponse(Response response) {
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final payload = data?['log'] ?? data ?? body;
    return MedicationLogModel.fromJson(payload as Map<String, dynamic>);
  }

  void _assertSuccess(Response response) {
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      final message = response.data is Map
          ? (response.data['message'] as String? ?? 'Request failed.')
          : 'Request failed with status $code';
      throw Exception(message);
    }
  }
}
