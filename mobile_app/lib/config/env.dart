// ============================================================
// lib/config/env.dart
//
// Environment configuration loaded via --dart-define at build time.
// Never hardcode real values here — all sensitive values come
// from the build command or your CI/CD pipeline.
//
// Development build:
//   flutter run \
//     --dart-define=API_BASE_URL=http://192.168.1.10:5000/api \
//     --dart-define=ENVIRONMENT=development
//
// Production build:
//   flutter build apk \
//     --dart-define=API_BASE_URL=https://api.respiratrack.com/api \
//     --dart-define=ENVIRONMENT=production
//
// Or use a .env file loader like envied package if you prefer
// compile-time code generation over --dart-define flags.
// ============================================================

class Env {
  Env._(); // prevent instantiation — all fields are static

  // ── Environment ─────────────────────────────────────────
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // ── Backend API ──────────────────────────────────────────
  // Local dev: your machine's LAN IP so the Android emulator
  // or physical device can reach your Express server.
  // DO NOT use 'localhost' on a physical device — it won't work.
  // Find your LAN IP: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  // API request timeout durations (milliseconds)
  static const int connectTimeoutMs = int.fromEnvironment(
    'CONNECT_TIMEOUT_MS',
    defaultValue: 10000, // 10 seconds
  );

  static const int receiveTimeoutMs = int.fromEnvironment(
    'RECEIVE_TIMEOUT_MS',
    defaultValue: 15000, // 15 seconds
  );

  // ── JWT ──────────────────────────────────────────────────
  // These are NOT secrets — they are just key names used
  // by flutter_secure_storage to store/retrieve tokens.
  // The actual JWT value comes from the backend response.
  static const String jwtStorageKey = 'respiratrack_jwt';
  static const String refreshTokenKey = 'respiratrack_refresh_token';
  static const String userIdStorageKey = 'respiratrack_user_id';
  static const String patientIdStorageKey = 'respiratrack_patient_id';
  static const String tbCaseNumberKey = 'respiratrack_tb_case_number';
  static const String savedIdentifierKey = 'respiratrack_saved_identifier';
  // savedIdentifierKey stores the last-used login identifier
  // (tb_case_number / phone / email) so the patient only
  // types it once and the app pre-fills it on return visits

  // ── PIN ──────────────────────────────────────────────────
  // PIN is stored hashed in flutter_secure_storage
  // for offline PIN validation (biometric fallback, etc.)
  static const String pinStorageKey = 'respiratrack_pin_hash';

  // ── OTP ──────────────────────────────────────────────────
  static const int otpExpiryMinutes = int.fromEnvironment(
    'OTP_EXPIRY_MINUTES',
    defaultValue: 5,
  );

  static const int otpMaxAttempts = int.fromEnvironment(
    'OTP_MAX_ATTEMPTS',
    defaultValue: 3,
  );

  // ── Notifications ────────────────────────────────────────
  // Android notification channel config (must match
  // what your backend sends in FCM payloads)
  static const String notificationChannelId = 'respiratrack_channel';
  static const String notificationChannelName = 'RespiraTrack Alerts';
  static const String notificationChannelDesc =
      'Medication reminders, missed dose alerts, and appointment notifications';

  // ── Compliance thresholds ────────────────────────────────
  // These drive color coding in the compliance calendar
  // and risk badge on the dashboard
  static const double complianceGreenThreshold = 90.0; // >= 90% → green
  static const double complianceYellowThreshold = 75.0; // 75–89% → yellow
  // below 75% → red

  // ── Splash screen ────────────────────────────────────────
  static const int splashMinDurationMs = int.fromEnvironment(
    'SPLASH_MIN_DURATION_MS',
    defaultValue: 2000, // 2 seconds minimum display
  );

  // ── Debug ────────────────────────────────────────────────
  // Enables verbose API logging in the Dio interceptor
  // Automatically false in production regardless of flag
  static bool get enableApiLogging =>
      isDevelopment &&
      bool.fromEnvironment('ENABLE_API_LOGGING', defaultValue: true);

  // ── Validation ───────────────────────────────────────────
  // Call this in main.dart before runApp() to catch missing
  // required config early instead of crashing mid-session
  static void validate() {
    final errors = <String>[];

    if (apiBaseUrl.isEmpty) {
      errors.add('API_BASE_URL is required.');
    }

    if (!apiBaseUrl.startsWith('http://') &&
        !apiBaseUrl.startsWith('https://')) {
      errors.add('API_BASE_URL must start with http:// or https://');
    }

    if (isProduction && apiBaseUrl.startsWith('http://')) {
      errors.add('API_BASE_URL must use https:// in production.');
    }

    if (errors.isNotEmpty) {
      throw StateError(
        '\n\n[Env] Configuration errors:\n${errors.map((e) => '  • $e').join('\n')}\n'
        'Pass values via --dart-define=KEY=VALUE when running or building.\n',
      );
    }
  }
}
