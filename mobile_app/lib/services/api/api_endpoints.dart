// ============================================================
// lib/services/api/api_endpoints.dart
//
// Re-exports ApiConfig as ApiEndpoints so any file that
// imported ApiEndpoints still works without changes.
//
// All actual endpoint definitions live in:
//   lib/config/api_config.dart
//
// Usage:
//   import '../../services/api/api_endpoints.dart';
//   final url = ApiEndpoints.login;
//   final url = ApiEndpoints.patientById('PT-0001');
// ============================================================

import '../../config/api_config.dart';
export '../../config/api_config.dart' show ApiConfig;

// Alias so existing code using ApiEndpoints.login etc. still works
typedef ApiEndpoints = ApiConfig;
