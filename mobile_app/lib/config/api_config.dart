// ============================================================
// lib/config/api_config.dart
//
// Central API configuration.
// Base URL is pulled from Env so you never manually
// comment/uncomment lines to switch environments.
//
// All endpoint paths are defined as static methods or
// constants so dynamic segments (patient_id, etc.)
// are handled cleanly in one place.
//
// Headers and auth injection live in api_interceptor.dart,
// NOT here — this file is config only.
// ============================================================

import 'env.dart';

class ApiConfig {
  ApiConfig._(); // prevent instantiation

  // ── Base URL ─────────────────────────────────────────────
  // Pulled from Env which reads --dart-define at build time.
  // Never hardcode here — use the run commands below instead.
  //
  // Android emulator → host machine:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
  //
  // Physical device on same WiFi:
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.X:5000/api
  //
  // Production:
  //   flutter build apk --dart-define=API_BASE_URL=https://api.respiratrack.com/api
  static String get baseUrl => Env.apiBaseUrl;

  // ── Timeouts ─────────────────────────────────────────────
  static Duration get connectTimeout =>
      Duration(milliseconds: Env.connectTimeoutMs);

  static Duration get receiveTimeout =>
      Duration(milliseconds: Env.receiveTimeoutMs);

  // ============================================================
  // ENDPOINTS
  // Static methods for dynamic segments (patient_id, etc.)
  // Static constants for fixed paths.
  //
  // Rule:
  //   No dynamic segments → static const String
  //   Has dynamic segments → static String method(args)
  // ============================================================

  // ── Auth ─────────────────────────────────────────────────
  static const String login = '/auth/patient-login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String verifyToken = '/auth/verify';

  // ── OTP ──────────────────────────────────────────────────
  static const String otpRequest = '/auth/otp/request';
  static const String otpVerify = '/auth/otp/verify';
  static const String otpResetPin = '/auth/otp/reset-pin';

  // ── Patients ─────────────────────────────────────────────
  static const String myProfile = '/patients/me';
  static const String updateMyContact = '/patients/me/contact';
  static String patientById(String patientId) => '/patients/$patientId';

  // ── Medication Logs ───────────────────────────────────────
  static const String myMedicationLogs = '/medication-logs/my';
  static const String submitMedicationLog = '/medication-logs';
  static String todayMedicationLog(String patientId) =>
      '/medication-logs/patient/$patientId/today';
  static String medicationCalendar(String patientId) =>
      '/medication-logs/patient/$patientId/calendar';
  static String medicationStreak(String patientId) =>
      '/medication-logs/patient/$patientId/streak';
  static String patientMedicationLogs(String patientId) =>
      '/medication-logs/patient/$patientId';

  // ── Symptom Logs ─────────────────────────────────────────
  static const String mySymptomLogs = '/symptom-logs/my';
  static const String submitSymptomLog = '/symptom-logs';
  static String patientSymptomLogs(String patientId) =>
      '/symptom-logs/patient/$patientId';

  // ── Appointments ─────────────────────────────────────────
  static const String myAppointments = '/appointments/my';
  static const String requestAppointment = '/appointments';
  static const String availableSlots = '/appointments/available-slots';
  static String appointmentById(String appointmentId) =>
      '/appointments/$appointmentId';
  static String cancelAppointment(String appointmentId) =>
      '/appointments/$appointmentId/cancel';

  // ── Sputum Tests ─────────────────────────────────────────
  static const String mySputumTests = '/sputum-tests/my';
  static String patientSputumSummary(String patientId) =>
      '/sputum-tests/patient/$patientId/summary';
  static const String nextSputumTest = '/sputum-tests/upcoming';

  // ── Notifications ─────────────────────────────────────────
  static const String notificationPreferences = '/notifications/preferences';
  static const String updateNotificationPreferences =
      '/notifications/preferences';
  static const String saveFcmToken = '/notifications/fcm-token';
  static const String removeFcmToken = '/notifications/fcm-token';
  static const String markAllNotificationsRead = '/notifications/mark-all-read';
  static String markNotificationRead(String notificationId) =>
      '/notifications/$notificationId/read';

  // ── Compliance ────────────────────────────────────────────
  static String patientCompliance(String patientId) =>
      '/compliance/patient/$patientId';

  // ── Health Records ────────────────────────────────────────
  static String healthRecords(String patientId) =>
      '/patients/$patientId/health-records';

  // ── Dashboard ─────────────────────────────────────────────
  static String dashboard(String patientId) => '/patients/$patientId/dashboard';
}
