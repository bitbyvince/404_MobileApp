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
  // POST   /auth/login
  //        body: { identifier, identifier_type, pin }
  //        identifier_type: "tb_case_number" | "phone_number" | "email"
  static const String login = '/auth/patient-login';

  // POST   /auth/logout
  static const String logout = '/auth/logout';

  // POST   /auth/refresh
  //        body: { refresh_token }
  static const String refreshToken = '/auth/refresh';

  // POST   /auth/verify
  //        Verifies the current JWT is still valid
  //        Used by splash screen session check
  static const String verifyToken = '/auth/verify';

  // ── OTP ──────────────────────────────────────────────────
  // POST   /otp/request
  //        body: { identifier, identifier_type, otp_type }
  static const String otpRequest = '/otp/request';

  // POST   /otp/verify
  //        body: { identifier, otp_code, otp_type }
  static const String otpVerify = '/otp/verify';

  // POST   /otp/reset-pin
  //        body: { identifier, new_pin, session_token }
  static const String otpResetPin = '/otp/reset-pin';

  // ── Patients ─────────────────────────────────────────────
  // GET    /patients/me
  //        Returns the full patient profile for the logged-in patient
  //        Includes treatment details, drug regimen, compliance,
  //        escalation state, sputum schedule
  static const String myProfile = '/patients/me';

  // GET    /patients/:patient_id
  static String patientById(String patientId) => '/patients/$patientId';

  // PATCH  /patients/me/contact
  //        body: { phone_number, email }
  //        Patients can edit contact info (Module 8)
  static const String updateMyContact = '/patients/me/contact';

  // ── Medication Logs ───────────────────────────────────────
  // GET    /patients/:patient_id/medication-logs/today
  //        Returns today's medicine checklist (Module 3)
  static String todayMedicationLog(String patientId) =>
      '/patients/$patientId/medication-logs/today';

  // POST   /patients/:patient_id/medication-logs
  //        body: { log_date, medicines: [{ drug_name, status, taken_at }] }
  //        Patient taps "Mark as Taken" (Module 3)
  static String submitMedicationLog(String patientId) =>
      '/patients/$patientId/medication-logs';

  // GET    /patients/:patient_id/medication-logs/calendar
  //        Query params: ?month=YYYY-MM
  //        Returns compliance calendar data (Module 3)
  //        Response includes per-day status for color coding:
  //        green = Taken, yellow = Partial, red = Missed
  static String medicationCalendar(String patientId) =>
      '/patients/$patientId/medication-logs/calendar';

  // GET    /patients/:patient_id/medication-logs/streak
  //        Returns current streak, longest streak (Module 2 dashboard)
  static String medicationStreak(String patientId) =>
      '/patients/$patientId/medication-logs/streak';

  // ── Symptom Logs ─────────────────────────────────────────
  // POST   /patients/:patient_id/symptom-logs
  //        body: { symptoms: [{ symptom, severity }], free_text_notes }
  //        Module 4 — Symptom Logger
  static String submitSymptomLog(String patientId) =>
      '/patients/$patientId/symptom-logs';

  // GET    /patients/:patient_id/symptom-logs
  //        Query params: ?limit=20&page=1
  //        Returns symptom log history
  static String symptomLogs(String patientId) =>
      '/patients/$patientId/symptom-logs';

  // ── Appointments ─────────────────────────────────────────
  // GET    /patients/:patient_id/appointments
  //        Query params: ?status=Pending,Confirmed&upcoming=true
  //        Module 5 — Appointment Scheduler
  static String myAppointments(String patientId) =>
      '/patients/$patientId/appointments';

  // POST   /appointments
  //        body: { patient_id, purpose, scheduled_date,
  //                scheduled_time, physician, notes }
  //        Patient requests a booking
  static const String requestAppointment = '/appointments';

  // GET    /appointments/:appointment_id
  static String appointmentById(String appointmentId) =>
      '/appointments/$appointmentId';

  // PATCH  /appointments/:appointment_id/cancel
  //        body: { cancellation_reason }
  //        Patient cancels their own booking
  static String cancelAppointment(String appointmentId) =>
      '/appointments/$appointmentId/cancel';

  // GET    /appointments/available-slots
  //        Query params: ?barangay_id=BRG-001&date=YYYY-MM-DD
  //        Returns available time slots for a given date
  static const String availableSlots = '/appointments/available-slots';

  // ── Sputum Tests ─────────────────────────────────────────
  // GET    /patients/:patient_id/sputum-tests
  //        Returns full sputum test timeline (Module 7)
  //        Includes Month 2, 5, 6 schedule + results
  static String sputumTests(String patientId) =>
      '/patients/$patientId/sputum-tests';

  // GET    /patients/:patient_id/sputum-tests/next
  //        Returns the next upcoming sputum test
  //        Used by Module 2 dashboard countdown card
  static String nextSputumTest(String patientId) =>
      '/patients/$patientId/sputum-tests/next';

  // ── Notifications ─────────────────────────────────────────
  // Notification inbox is read directly from Firestore
  // via FirebaseConfig.notificationInbox(userId) — not REST.
  // These endpoints handle preferences only.

  // GET    /notifications/preferences
  //        Reads from Firestore notification_preferences/{user_id}
  //        Returned by backend as a proxy to keep Flutter code clean
  static const String notificationPreferences = '/notifications/preferences';

  // PATCH  /notifications/preferences
  //        body: { medication_reminder, missed_dose_alert,
  //                appointment_reminder, sputum_test_reminder, tone }
  //        Writes to Firestore notification_preferences/{user_id}
  static const String updateNotificationPreferences =
      '/notifications/preferences';

  // POST   /notifications/fcm-token
  //        body: { fcm_token, device_type, device_label, app_type }
  //        Saves device token to Firestore fcm_tokens/{user_id}/devices
  //        Call this on login and on FCM token refresh
  static const String saveFcmToken = '/notifications/fcm-token';

  // DELETE /notifications/fcm-token
  //        body: { fcm_token }
  //        Deactivates the device token on logout
  static const String removeFcmToken = '/notifications/fcm-token';

  // PATCH  /notifications/:notification_id/read
  //        Marks a notification as read
  //        (updates Firestore notification_inbox document)
  static String markNotificationRead(String notificationId) =>
      '/notifications/$notificationId/read';

  // POST   /notifications/mark-all-read
  //        Marks all inbox notifications as read for this user
  static const String markAllNotificationsRead = '/notifications/mark-all-read';

  // ── Compliance ────────────────────────────────────────────
  // GET    /patients/:patient_id/compliance
  //        Returns compliance percentage, status, risk level,
  //        doses taken/missed/remaining (Module 8 health records)
  static String patientCompliance(String patientId) =>
      '/patients/$patientId/compliance';

  // ── Health Records ────────────────────────────────────────
  // GET    /patients/:patient_id/health-records
  //        Returns full treatment history, all logs, adherence
  //        summary (Module 8 — Profile & Health Records)
  static String healthRecords(String patientId) =>
      '/patients/$patientId/health-records';

  // ── Dashboard ─────────────────────────────────────────────
  // GET    /patients/:patient_id/dashboard
  //        Single endpoint that returns all dashboard card data:
  //        streak, days remaining, next sputum, today's checklist
  //        Reduces the number of parallel requests on app open
  static String dashboard(String patientId) => '/patients/$patientId/dashboard';
}
