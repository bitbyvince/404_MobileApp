// ============================================================
// lib/services/notification_service.dart
//
// Handles all push notification concerns for the patient app.
//
// Responsibilities:
//   1. Initialize FCM and request OS permissions
//   2. Register/refresh device token in Firestore
//   3. Show local notifications when app is in foreground
//   4. Handle notification taps → deep link routing
//   5. Listen to Firestore notification inbox in real time
//
// FCM message states:
//   Foreground   — app open     → show via flutter_local_notifications
//   Background   — app running  → OS shows it, tap handled by onMessageOpenedApp
//   Terminated   — app closed   → OS shows it, tap handled by getInitialMessage
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/env.dart';
import '../config/firebase_config.dart';
import 'api/api_client.dart';
import '../config/api_config.dart';

// ── Notification model ─────────────────────────────────────────
// Lightweight representation of an inbox notification
class AppNotification {
  AppNotification({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.deepLink,
    this.escalationId,
    this.alertId,
  });

  final String notificationId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? deepLink;
  final String? escalationId;
  final String? alertId;

  factory AppNotification.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    final dataMap = data['data'] as Map<String, dynamic>? ?? {};
    return AppNotification(
      notificationId: data['notification_id'] as String? ?? docId,
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      isRead: data['is_read'] as bool? ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deepLink: dataMap['deep_link'] as String?,
      escalationId: dataMap['escalation_id'] as String?,
      alertId: dataMap['alert_id'] as String?,
    );
  }
}

class NotificationService {
  NotificationService._();

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _dio = ApiClient.instance;

  // Callback set by the router/provider to handle deep links
  // Set this in app.dart after GoRouter is initialized
  static void Function(String deepLink)? onDeepLink;

  // ============================================================
  // INITIALIZE
  // Call once from SplashScreen after Firebase is ready
  // and the user is known to be logged in
  // ============================================================
  static Future<void> initialize({required String userId}) async {
    await Future.wait([
      _initLocalNotifications(),
      _registerDeviceToken(userId: userId),
    ]);

    // Set up all three FCM message state handlers
    _handleForegroundMessages();
    _handleBackgroundTap();
    await _handleTerminatedTap();

    // Listen for token rotation and update Firestore automatically
    FirebaseConfig.onTokenRefresh.listen(
      (newToken) => _registerDeviceToken(userId: userId, newToken: newToken),
    );

    debugPrint('[NotificationService] Initialized for user $userId');
  }

  // ============================================================
  // LOCAL NOTIFICATIONS SETUP
  // Required to show notifications when the app is in foreground
  // since FCM does not auto-display them in that state
  // ============================================================
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // uses your app icon as notification icon
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true, // ← replaces requestAlertBadge
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      // Called when user taps a local notification while app is open
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    // Create the Android notification channel
    // Must match what your Express backend sends in FCM payloads
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        Env.notificationChannelId, // 'respiratrack_channel'
        Env.notificationChannelName, // 'RespiraTrack Alerts'
        description: Env.notificationChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  // ============================================================
  // FCM: FOREGROUND MESSAGES
  // App is OPEN — FCM won't show a banner automatically.
  // We show it manually via flutter_local_notifications.
  // ============================================================
  static void _handleForegroundMessages() {
    FirebaseConfig.onForegroundMessage.listen((RemoteMessage message) {
      debugPrint(
        '[FCM Foreground] type: ${message.data['type']} '
        'title: ${message.notification?.title}',
      );
      _showLocalNotification(message);
    });
  }

  // ============================================================
  // FCM: BACKGROUND TAP
  // App was running in background, user tapped the notification
  // ============================================================
  static void _handleBackgroundTap() {
    FirebaseConfig.onNotificationTap.listen((RemoteMessage message) {
      debugPrint('[FCM Background Tap] type: ${message.data['type']}');
      final deepLink = message.data['deep_link'] as String?;
      if (deepLink != null && deepLink.isNotEmpty) {
        _handleNotificationTap(deepLink);
      }
    });
  }

  // ============================================================
  // FCM: TERMINATED TAP (cold start)
  // App was fully closed, user tapped the notification to open it
  // ============================================================
  static Future<void> _handleTerminatedTap() async {
    final initial = await FirebaseConfig.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM Cold Start] type: ${initial.data['type']}');
      final deepLink = initial.data['deep_link'] as String?;
      if (deepLink != null && deepLink.isNotEmpty) {
        // Slight delay so the router is ready before navigating
        await Future.delayed(const Duration(milliseconds: 500));
        _handleNotificationTap(deepLink);
      }
    }
  }

  // ============================================================
  // SHOW LOCAL NOTIFICATION
  // Displays a system notification banner when app is foreground
  // ============================================================
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      Env.notificationChannelId,
      Env.notificationChannelName,
      channelDescription: Env.notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'RespiraTrack',
      // Use a different icon for escalation alerts to make them stand out
      icon: _isEscalationMessage(message.data)
          ? '@drawable/ic_alert'
          : '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Encode the full data map as payload so the tap handler
    // can extract the deep_link
    final payload = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'RespiraTrack',
      notification.body ?? '',
      details,
      payload: payload,
    );
  }

  // ============================================================
  // NOTIFICATION TAP → DEEP LINK
  // Parses the payload and calls the router callback
  //
  // Deep link format: "respiratrack://{screen}"
  //   respiratrack://dashboard
  //   respiratrack://medication-log
  //   respiratrack://appointments
  //   respiratrack://sputum
  //   respiratrack://notifications
  //   respiratrack://profile
  // ============================================================
  static void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      // Payload may be a JSON string (from local notifications)
      // or a direct deep link string (from FCM background tap)
      String? deepLink;

      if (payload.startsWith('{')) {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        deepLink = data['deep_link'] as String?;
      } else if (payload.startsWith('respiratrack://')) {
        deepLink = payload;
      }

      if (deepLink != null && deepLink.isNotEmpty) {
        debugPrint('[NotificationService] Deep link: $deepLink');
        onDeepLink?.call(deepLink);
      }
    } catch (e) {
      debugPrint('[NotificationService] Deep link parse error: $e');
    }
  }

  // ============================================================
  // REGISTER DEVICE TOKEN
  // Saves FCM token to Firestore via backend API.
  // Called on login and on token rotation.
  // ============================================================
  static Future<void> _registerDeviceToken({
    required String userId,
    String? newToken,
  }) async {
    try {
      final token = newToken ?? await FirebaseConfig.getDeviceToken();
      if (token == null || token.isEmpty) return;

      final deviceType = Platform.isIOS ? 'ios' : 'android';

      await _dio.post(
        ApiConfig.saveFcmToken,
        data: {
          'fcm_token': token,
          'device_type': deviceType,
          'device_label':
              '${deviceType == 'ios' ? 'iPhone' : 'Android'} Device',
          'app_type': 'patient_mobile',
        },
      );

      debugPrint('[NotificationService] FCM token registered for $userId');
    } catch (e) {
      // Non-fatal — notifications will still work until next refresh
      debugPrint('[NotificationService] Token registration failed: $e');
    }
  }

  // ============================================================
  // NOTIFICATION INBOX STREAM
  // Real-time Firestore onSnapshot for the notification inbox.
  // Returns a Stream of notification lists — Riverpod
  // notification_provider.dart listens to this.
  //
  // Usage in notification_provider.dart:
  //   final stream = NotificationService.inboxStream(userId);
  // ============================================================
  static Stream<List<AppNotification>> inboxStream(String userId) {
    return FirebaseConfig.notificationInbox(userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AppNotification.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // ============================================================
  // UNREAD COUNT STREAM
  // Powers the notification badge count on the app bar
  // ============================================================
  static Stream<int> unreadCountStream(String userId) {
    return FirebaseConfig.notificationInbox(userId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================================
  // MARK AS READ
  // PATCH /notifications/:notification_id/read
  // Also updates Firestore directly for instant UI response
  // ============================================================
  static Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      // Optimistic update in Firestore directly
      await FirebaseConfig.notificationInbox(userId).doc(notificationId).update(
        {'is_read': true, 'read_at': FieldValue.serverTimestamp()},
      );

      // Also tell the backend (updates MongoDB alert if linked)
      await _dio.patch(ApiConfig.markNotificationRead(notificationId));
    } catch (e) {
      debugPrint('[NotificationService] Mark as read failed: $e');
    }
  }

  // ============================================================
  // MARK ALL READ
  // Batch update all unread notifications in Firestore
  // ============================================================
  static Future<void> markAllRead(String userId) async {
    try {
      final unread = await FirebaseConfig.notificationInbox(
        userId,
      ).where('is_read', isEqualTo: false).get();

      // Firestore batch write — max 500 per batch
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {
          'is_read': true,
          'read_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Tell backend
      await _dio.post(ApiConfig.markAllNotificationsRead);

      debugPrint('[NotificationService] Marked ${unread.docs.length} as read.');
    } catch (e) {
      debugPrint('[NotificationService] Mark all read failed: $e');
    }
  }

  // ============================================================
  // NOTIFICATION PREFERENCES
  // Read and update patient's notification settings
  // Stored in Firestore notification_preferences/{user_id}
  // ============================================================
  static Future<Map<String, dynamic>?> getPreferences(String userId) async {
    try {
      final doc = await FirebaseConfig.notificationPreferences(userId).get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('[NotificationService] Get preferences failed: $e');
      return null;
    }
  }

  static Future<void> updatePreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      // Update Firestore directly (source of truth for prefs)
      await FirebaseConfig.notificationPreferences(userId).set({
        ...preferences,
        'user_id': userId,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Sync to backend so the reminder scheduler picks it up
      await _dio.patch(
        ApiConfig.updateNotificationPreferences,
        data: preferences,
      );

      debugPrint('[NotificationService] Preferences updated for $userId');
    } catch (e) {
      debugPrint('[NotificationService] Update preferences failed: $e');
    }
  }

  // ============================================================
  // DEREGISTER DEVICE TOKEN
  // Called on logout — removes the FCM token from Firestore
  // so no more notifications are sent to this device
  // ============================================================
  static Future<void> deregisterToken() async {
    try {
      final token = await FirebaseConfig.getDeviceToken();
      if (token == null || token.isEmpty) return;

      await _dio.delete(ApiConfig.removeFcmToken, data: {'fcm_token': token});

      debugPrint('[NotificationService] FCM token deregistered.');
    } catch (e) {
      debugPrint('[NotificationService] Token deregister failed: $e');
    }
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================
  static bool _isEscalationMessage(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    return type.startsWith('escalation_level');
  }
}
