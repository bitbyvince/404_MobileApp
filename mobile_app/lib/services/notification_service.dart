// lib/services/notification_service.dart

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/alert.model.dart';
import '../utils/jwt_helper.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ─── INITIALIZE ──────────────────────────────────────────────────────────

  // Call once in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    // Request notification permission from the user
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get the FCM token and register it with the backend
    final fcmToken = await _fcm.getToken();
    if (fcmToken != null) {
      await registerFcmToken(fcmToken);
    }

    // Re-register whenever the FCM token refreshes
    _fcm.onTokenRefresh.listen((newToken) async {
      await registerFcmToken(newToken);
    });

    // Handle notification tapped while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Handle notification received while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }

  // ─── REGISTER FCM TOKEN WITH BACKEND ─────────────────────────────────────

  Future<bool> registerFcmToken(String fcmToken) async {
    final token = await JwtHelper.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.saveFcmToken),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({'fcm_token': fcmToken}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─── GET ALERTS FROM BACKEND ─────────────────────────────────────────────

  Future<List<Alert>> getAlerts(String userId) async {
    final token = await JwtHelper.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.notifications}/logs/$userId'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['alerts'] ?? [];
      return list.map((e) => Alert.fromJson(e)).toList();
    }
    throw Exception('Failed to load alerts.');
  }

  // ─── GET UNREAD COUNT ────────────────────────────────────────────────────

  Future<int> getUnreadCount(String userId) async {
    final alerts = await getAlerts(userId);
    return alerts.where((a) => !a.isRead).length;
  }

  // ─── HANDLE INCOMING MESSAGE ─────────────────────────────────────────────

  void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];

    // You can extend this switch to navigate to specific screens
    // based on the notification type sent from the backend
    switch (type) {
      case 'medication_reminder':
        // TODO: Navigate to treatment calendar screen
        break;
      case 'missed_dose_alert':
        // TODO: Navigate to patient detail screen
        break;
      case 'low_stock_alert':
        // TODO: Navigate to inventory screen
        break;
      default:
        break;
    }
  }

  // ─── GET FCM TOKEN ───────────────────────────────────────────────────────

  // Use this for debugging — prints your device's FCM token to the console
  Future<String?> getDeviceToken() async {
    final token = await _fcm.getToken();
    return token;
  }
}
