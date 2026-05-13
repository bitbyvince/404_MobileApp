// lib/config/api_config.dart

class ApiConfig {
  // ─── BASE URL ───────────────────────────────────────────────────────────────
  // Switch between these depending on where you are testing:

  // Android emulator connecting to your PC's localhost
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Real Android device on the same WiFi as your PC
  // Find your PC's local IP: open CMD → type ipconfig → look for IPv4 Address
  // static const String baseUrl = 'http://192.168.1.X:3000';

  // Production (after deploying to Render)
  // static const String baseUrl = 'https://respiratrack.onrender.com';

  // ─── ENDPOINTS ──────────────────────────────────────────────────────────────

  // Auth
  static const String register = '$baseUrl/api/auth/public/register';
  static const String verifyOtp = '$baseUrl/api/auth/public/verify-otp';
  static const String login = '$baseUrl/api/auth/public/login';
  static const String staffLogin = '$baseUrl/api/auth/staff/login';
  static const String saveFcmToken = '$baseUrl/api/auth/fcm-token';
  static const String verifyToken = '$baseUrl/api/auth/verify';

  // Users
  static const String myProfile = '$baseUrl/api/users/me';
  static const String updateLocation = '$baseUrl/api/users/me/location';

  // Heatmap
  static const String heatmapZones = '$baseUrl/api/heatmap';
  static const String heatmapNearby = '$baseUrl/api/heatmap/nearby';

  // Education
  static const String education = '$baseUrl/api/education';

  // Notifications
  static const String notifications = '$baseUrl/api/notifications';

  // ─── HEADERS ────────────────────────────────────────────────────────────────

  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
