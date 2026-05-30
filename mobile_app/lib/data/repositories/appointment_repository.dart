import 'package:respiratrack/config/api_config.dart';
import 'package:respiratrack/data/models/appointment_model.dart';
import 'package:respiratrack/services/api/api_client.dart';

class AppointmentRepository {
  AppointmentRepository._();
  static final instance = AppointmentRepository._();

  static final _client = ApiClient.instance;

  // ── UPCOMING ──────────────────────────────────────────────
  Future<List<AppointmentModel>> getUpcoming() async {
    final response = await _client.get(
      '/appointments/my',
      queryParameters: {'status': 'Pending,Confirmed', 'upcoming': 'true'},
    );
    _assertSuccess(response);
    final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
    final rawList = data['appointments'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── PAST ──────────────────────────────────────────────────
  Future<AppointmentListResult> getPast({int page = 1, int limit = 10}) async {
    final response = await _client.get(
      '/appointments/my',
      queryParameters: {
        'status': 'Completed,Cancelled',
        'upcoming': 'false',
        'page': page,
        'limit': limit,
      },
    );
    _assertSuccess(response);
    return AppointmentListResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ── AVAILABLE SLOTS ───────────────────────────────────────
  // Backend returns slots as ["08:00", "09:00", ...] strings
  // NOT full ISO datetimes — parse accordingly
  Future<List<DateTime>> getAvailableSlots({
    required String healthCenterId,
    required DateTime date,
  }) async {
    final response = await _client.get(
      '/appointments/available-slots',
      queryParameters: {
        'barangay_id': healthCenterId,
        'date': _formatDate(date),
      },
    );
    _assertSuccess(response);
    final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
    final slots = data['slots'] as List<dynamic>? ?? [];

    return slots.map((slot) {
      final timeStr = slot as String; // e.g. "08:00"
      final parts = timeStr.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }).toList();
  }

  // ── BOOK ──────────────────────────────────────────────────
  Future<AppointmentModel> book({
    required DateTime scheduledDate,
    required String scheduledTime,
    required String purpose,
    String? notes,
  }) async {
    // Backend validator requires HH:MM 24h format e.g. "09:00"
    // SlotPicker passes back a formatted time like "9:00 AM"
    // — normalise it here before sending
    final normalised = _normaliseTime(scheduledTime);

    final response = await _client.post(
      '/appointments',
      data: {
        'purpose': purpose,
        'scheduled_date': _formatDate(scheduledDate),
        'scheduled_time': normalised,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    _assertSuccess(response);
    final body = response.data['data'] as Map<String, dynamic>? ?? {};
    final payload = body['appointment'] as Map<String, dynamic>? ?? body;
    return AppointmentModel.fromJson(payload);
  }

  // ── CANCEL ────────────────────────────────────────────────
  Future<void> cancel(String appointmentId) async {
    final response = await _client.patch('/appointments/$appointmentId/cancel');
    _assertSuccess(response);
  }

  // ── HELPERS ───────────────────────────────────────────────

  // Converts "9:00 AM" / "2:30 PM" / "09:00" → "09:00" / "14:30"
  String _normaliseTime(String time) {
    // Already HH:MM 24h format
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) return time;

    // 12h format with AM/PM
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(time.trim());

    if (match == null) return time; // return as-is if unrecognised

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String period = match.group(3)!.toUpperCase();

    if (period == 'AM' && hour == 12) hour = 0;
    if (period == 'PM' && hour != 12) hour += 12;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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
