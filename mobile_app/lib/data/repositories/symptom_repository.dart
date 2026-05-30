import 'package:respiratrack/data/models/symptom_log_model.dart';
import 'package:respiratrack/services/api/api_client.dart';

class SymptomRepository {
  SymptomRepository._();
  static final instance = SymptomRepository._();

  static final _client = ApiClient.instance;

  // ── TODAY'S LOG ───────────────────────────────────────────
  Future<SymptomLogModel?> getTodayLog() async {
    final response = await _client.get('/symptom-logs/today');
    if (response.statusCode == 404) return null;
    _assertSuccess(response);
    final data = response.data['data'];
    if (data == null) return null;
    return SymptomLogModel.fromJson(data as Map<String, dynamic>);
  }

  // ── HISTORY ───────────────────────────────────────────────
  Future<SymptomHistoryResult> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '/symptom-logs/history', // ← was /symptom-logs/my
      queryParameters: {'page': page, 'limit': limit},
    );
    _assertSuccess(response);
    return SymptomHistoryResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ── SUBMIT ────────────────────────────────────────────────
  Future<SymptomLogModel> submitLog({
    required List<SymptomEntry> symptoms,
    String freeTextNotes = '',
  }) async {
    final response = await _client.post(
      '/symptom-logs',
      data: {
        'symptoms': symptoms.map((s) => s.toJson()).toList(),
        'free_text_notes': freeTextNotes,
      },
    );
    _assertSuccess(response);
    return SymptomLogModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  void _assertSuccess(response) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      final message = response.data is Map
          ? (response.data['message'] as String? ?? 'Request failed.')
          : 'Request failed with status $statusCode';
      throw Exception(message);
    }
  }
}
