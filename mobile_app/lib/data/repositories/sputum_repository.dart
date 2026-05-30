import 'package:respiratrack/data/models/sputum_test_model.dart';
import 'package:respiratrack/services/api/api_client.dart';

class SputumRepository {
  SputumRepository._();
  static final instance = SputumRepository._();

  static final _client = ApiClient.instance;

  // ── GET MY TESTS ──────────────────────────────────────────
  // Uses /sputum-tests/my — backend reads patient_id from JWT
  // No need to read patient_id from secure storage
  Future<List<SputumTestModel>> getMyTests() async {
    final response = await _client.get('/sputum-tests/my');
    _assertSuccess(response);

    final body = response.data['data'] as Map<String, dynamic>? ?? {};

    // Backend getPatientSputumSummary returns { tests: [...], ... }
    final rawTests =
        body['tests'] as List<dynamic>? ??
        body['sputum_tests'] as List<dynamic>? ??
        [];

    return rawTests
        .map((item) => SputumTestModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── GET SINGLE TEST ───────────────────────────────────────
  Future<SputumTestModel> getTestById(String testId) async {
    final response = await _client.get('/sputum-tests/$testId');
    _assertSuccess(response);
    final body = response.data['data'] as Map<String, dynamic>? ?? {};
    return SputumTestModel.fromJson(body);
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