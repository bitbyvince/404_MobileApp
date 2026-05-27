// ============================================================
// lib/config/firebase_config.dart
//
// Firebase initialization and service accessors.
// Call FirebaseConfig.initialize() once in main.dart
// before runApp().
//
// This file is safe to commit — it contains no secrets.
// Firebase identifies your app via google-services.json (Android)
// and GoogleService-Info.plist (iOS), NOT via code.
//
// Those two files go in:
//   android/app/google-services.json
//   ios/Runner/GoogleService-Info.plist
//
// Download them from:
//   Firebase Console → Project Settings → Your Apps
// ============================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ── Background message handler ───────────────────────────────
// MUST be a top-level function (not a method inside a class).
// Flutter calls this in a separate isolate when the app is
// in the background or terminated and an FCM message arrives.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Firebase must be re-initialized in the background isolate
  await Firebase.initializeApp();

  debugPrint('[FCM Background] type: ${message.data['type']}');
  debugPrint('[FCM Background] title: ${message.notification?.title}');

  // You can write to Firestore here if needed
  // e.g. mark a notification as received even while app is closed
  // But keep this lightweight — background isolates have limits
}

class FirebaseConfig {
  FirebaseConfig._(); // prevent instantiation

  // ── Service instances ────────────────────────────────────
  // Access these anywhere after initialize() has been called
  static FirebaseMessaging get messaging => FirebaseMessaging.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // ── Initialization ───────────────────────────────────────
  // Call once in main.dart before runApp()
  static Future<void> initialize() async {
    // 1. Initialize the Firebase app using config from
    //    google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();

    // 2. Register the background message handler
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // 3. Configure Firestore settings
    _configureFirestore();

    // 4. Request notification permissions from the OS
    await _requestNotificationPermissions();

    debugPrint('[FirebaseConfig] Initialized successfully.');
  }

  // ── Firestore settings ───────────────────────────────────
  static void _configureFirestore() {
    FirebaseFirestore.instance.settings = const Settings(
      // persistenceEnabled: true caches Firestore data locally.
      // Useful so the notification inbox loads even when offline.
      persistenceEnabled: true,

      // cacheSizeBytes: how much local cache to allow.
      // CACHE_SIZE_UNLIMITED keeps all synced data offline.
      // Use a fixed byte limit (e.g. 10485760 = 10MB) if storage
      // is a concern on low-end devices.
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ── Notification permissions ─────────────────────────────
  static Future<void> _requestNotificationPermissions() async {
    final settings = await messaging.requestPermission(
      alert: true, // show notification banners
      badge: true, // show badge count on app icon
      sound: true, // play notification sound
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus.name}');

    // On Android 13+, requestPermission() is required at runtime.
    // On older Android and iOS the OS handles this differently
    // but calling requestPermission() is safe regardless.
  }

  // ── FCM Token ────────────────────────────────────────────
  // Returns the current FCM device token.
  // Call this after initialize() and after the user logs in
  // so you can save it to Firestore under fcm_tokens/{user_id}.
  //
  // The token can change — FCM rotates it periodically.
  // onTokenRefresh() below handles rotation automatically.
  static Future<String?> getDeviceToken() async {
    try {
      final token = await messaging.getToken();
      debugPrint('[FCM] Device token: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] Failed to get device token: $e');
      return null;
    }
  }

  // ── Token refresh listener ───────────────────────────────
  // FCM rotates device tokens periodically.
  // This stream fires whenever the token changes.
  // Wire it up in notification_service.dart to update
  // Firestore with the new token automatically.
  //
  // Usage in notification_service.dart:
  //   FirebaseConfig.onTokenRefresh.listen((newToken) {
  //     _saveTokenToFirestore(newToken);
  //   });
  static Stream<String> get onTokenRefresh => messaging.onTokenRefresh;

  // ── Foreground message stream ────────────────────────────
  // Fires when the app is OPEN (foreground) and a message arrives.
  // FCM does NOT show a system notification automatically when
  // the app is in the foreground — you must show it yourself
  // using flutter_local_notifications (handled in notification_service.dart).
  //
  // Usage in notification_service.dart:
  //   FirebaseConfig.onForegroundMessage.listen((message) {
  //     _showLocalNotification(message);
  //     _addToInbox(message);
  //   });
  static Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  // ── Notification tap handler — app in background ─────────
  // Fires when the user TAPS a notification and the app was
  // running in the background (not terminated).
  // Use this to navigate to the correct screen on tap.
  //
  // Usage in notification_service.dart:
  //   FirebaseConfig.onNotificationTap.listen((message) {
  //     _handleDeepLink(message.data['deep_link']);
  //   });
  static Stream<RemoteMessage> get onNotificationTap =>
      FirebaseMessaging.onMessageOpenedApp;

  // ── Notification tap handler — app was terminated ────────
  // Returns the message that launched the app if the user
  // tapped a notification while the app was fully closed.
  // Call this once during initialization to handle cold starts.
  //
  // Usage in notification_service.dart:
  //   final initial = await FirebaseConfig.getInitialMessage();
  //   if (initial != null) _handleDeepLink(initial.data['deep_link']);
  static Future<RemoteMessage?> getInitialMessage() =>
      messaging.getInitialMessage();

  // ── Firestore collection references ─────────────────────
  // Typed collection references so you never mistype
  // a collection path anywhere in the app.
  //
  // Notification inbox for the logged-in patient:
  //   FirebaseConfig.notificationInbox('USR-0004')
  static CollectionReference<Map<String, dynamic>> notificationInbox(
    String userId,
  ) => firestore
      .collection('notification_inbox')
      .doc(userId)
      .collection('messages');

  // Notification preferences for the logged-in patient:
  //   FirebaseConfig.notificationPreferences('USR-0004')
  static DocumentReference<Map<String, dynamic>> notificationPreferences(
    String userId,
  ) => firestore.collection('notification_preferences').doc(userId);

  // Active session document:
  //   FirebaseConfig.activeSession('SESS-0001')
  static DocumentReference<Map<String, dynamic>> activeSession(
    String sessionId,
  ) => firestore.collection('active_sessions').doc(sessionId);

  // FCM token document for a user:
  //   FirebaseConfig.fcmTokenDoc('USR-0004')
  static DocumentReference<Map<String, dynamic>> fcmTokenDoc(String userId) =>
      firestore.collection('fcm_tokens').doc(userId);

  // FCM devices sub-collection for a user:
  //   FirebaseConfig.fcmDevices('USR-0004')
  static CollectionReference<Map<String, dynamic>> fcmDevices(String userId) =>
      firestore.collection('fcm_tokens').doc(userId).collection('devices');
}
