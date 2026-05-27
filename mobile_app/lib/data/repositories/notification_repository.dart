import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:respiratrack/config/api_config.dart';
import 'package:respiratrack/config/firebase_config.dart';
import 'package:respiratrack/data/models/notification_model.dart';
import 'package:respiratrack/services/api/api_client.dart';
import 'package:respiratrack/services/secure_storage_service.dart';

class NotificationRepository {
  NotificationRepository._();
  static final instance = NotificationRepository._();

  static final _client = ApiClient.instance;

  Future<NotificationListResult> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final userId = await _getUserId();
    final inboxQuery = FirebaseConfig.notificationInbox(
      userId,
    ).orderBy('created_at', descending: true).limit(page * limit + 1);

    final snapshot = await inboxQuery.get();
    final docs = snapshot.docs;
    final pageDocs = docs.skip((page - 1) * limit).take(limit).toList();

    final notifications = pageDocs.map((doc) {
      final json = Map<String, dynamic>.from(doc.data());
      json['notification_id'] = json['notification_id'] ?? doc.id;
      return NotificationModel.fromJson(json);
    }).toList();

    final hasMore = docs.length > page * limit;
    final unreadCount = await getUnreadCount();

    return NotificationListResult(
      notifications: notifications,
      hasMore: hasMore,
      total: docs.length,
      unreadCount: unreadCount,
    );
  }

  Future<int> getUnreadCount() async {
    final userId = await _getUserId();
    final snapshot = await FirebaseConfig.notificationInbox(
      userId,
    ).where('is_read', isEqualTo: false).get();
    return snapshot.docs.length;
  }

  Future<void> markAsRead(String notificationId) async {
    final response = await _client.patch(
      ApiConfig.markNotificationRead(notificationId),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _createApiException(response);
    }
  }

  Future<void> markAllAsRead() async {
    final response = await _client.post(ApiConfig.markAllNotificationsRead);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _createApiException(response);
    }
  }

  Future<void> registerFcmToken(String token) async {
    final response = await _client.post(
      ApiConfig.saveFcmToken,
      data: {
        'fcm_token': token,
        'device_type': 'mobile',
        'device_label': 'Patient Mobile App',
        'app_type': 'patient_mobile',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _createApiException(response);
    }
  }

  Future<NotificationPreferences> getPreferences() async {
    final response = await _client.get(ApiConfig.notificationPreferences);
    if (response.statusCode != 200) {
      throw _createApiException(response);
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return NotificationPreferences.fromJson(payload);
  }

  Future<void> savePreferences({
    required bool medicationReminder,
    required bool appointmentReminder,
    required bool sputumReminder,
    required bool alerts,
    required int reminderHour,
    required int reminderMinute,
  }) async {
    final response = await _client.patch(
      ApiConfig.updateNotificationPreferences,
      data: {
        'medication_reminder': medicationReminder,
        'appointment_reminder': appointmentReminder,
        'sputum_test_reminder': sputumReminder,
        'tone': alerts,
        'reminder_hour': reminderHour,
        'reminder_minute': reminderMinute,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _createApiException(response);
    }
  }

  Future<String> _getUserId() async {
    final userId = await SecureStorageService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('User ID is not available in secure storage.');
    }
    return userId;
  }

  Exception _createApiException(Response response) {
    final message =
        (response.data as Map<String, dynamic>?)?['message'] as String? ??
        'Request failed with status ${response.statusCode}.';
    return Exception(message);
  }
}

class NotificationPreferences {
  final bool medicationReminder;
  final bool appointmentReminder;
  final bool sputumReminder;
  final bool alerts;
  final int reminderHour;
  final int reminderMinute;

  NotificationPreferences({
    required this.medicationReminder,
    required this.appointmentReminder,
    required this.sputumReminder,
    required this.alerts,
    required this.reminderHour,
    required this.reminderMinute,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      medicationReminder: json['medication_reminder'] as bool? ?? true,
      appointmentReminder: json['appointment_reminder'] as bool? ?? true,
      sputumReminder: json['sputum_test_reminder'] as bool? ?? true,
      alerts: json['tone'] as bool? ?? true,
      reminderHour: json['reminder_hour'] as int? ?? 8,
      reminderMinute: json['reminder_minute'] as int? ?? 0,
    );
  }
}
