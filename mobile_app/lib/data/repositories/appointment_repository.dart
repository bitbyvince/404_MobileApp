import 'package:dio/dio.dart';
import 'package:respiratrack/config/api_config.dart';
import 'package:respiratrack/data/models/appointment_model.dart';
import 'package:respiratrack/services/api/api_client.dart';
import 'package:respiratrack/services/secure_storage_service.dart';

class AppointmentRepository {
  AppointmentRepository._();
  static final instance = AppointmentRepository._();

  static final _client = ApiClient.instance;

  Future<List<AppointmentModel>> getUpcoming() async {
    final patientId = await _getPatientId();
    final response = await _client.get(
      ApiConfig.myAppointments(patientId),
      queryParameters: {'status': 'Pending,Confirmed', 'upcoming': 'true'},
    );

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final results = (body['data'] as Map<String, dynamic>?) ?? body;
    final rawAppointments = results['appointments'] as List<dynamic>? ?? [];
    return rawAppointments
        .map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AppointmentListResult> getPast({int page = 1, int limit = 10}) async {
    final patientId = await _getPatientId();
    final response = await _client.get(
      ApiConfig.myAppointments(patientId),
      queryParameters: {
        'status': 'Completed,Cancelled',
        'upcoming': 'false',
        'page': page,
        'limit': limit,
      },
    );

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    return AppointmentListResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<DateTime>> getAvailableSlots({
    required String healthCenterId,
    required DateTime date,
  }) async {
    final patientId = await _getPatientId();
    final response = await _client.get(
      ApiConfig.availableSlots,
      queryParameters: {
        'barangay_id': healthCenterId,
        'date': _formatDate(date),
      },
    );

    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final slots =
        (body['data'] as Map<String, dynamic>?)?['slots'] as List<dynamic>? ??
        body['slots'] as List<dynamic>? ??
        [];

    return slots.map((slot) => DateTime.parse(slot as String)).toList();
  }

  Future<AppointmentModel> book({
    required DateTime scheduledDate,
    required String scheduledTime,
    required String purpose,
    String? notes,
  }) async {
    final patientId = await _getPatientId();
    final response = await _client.post(
      ApiConfig.requestAppointment,
      data: {
        'patient_id': patientId,
        'purpose': purpose,
        'scheduled_date': _formatDate(scheduledDate),
        'scheduled_time': scheduledTime,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return AppointmentModel.fromJson(payload);
  }

  Future<void> cancel(String appointmentId) async {
    final response = await _client.patch(
      ApiConfig.cancelAppointment(appointmentId),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _createApiException(response);
    }
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
