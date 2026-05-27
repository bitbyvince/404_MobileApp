// ============================================================
// lib/services/api/api_client.dart
//
// Singleton Dio instance for all HTTP calls in the app.
// Wired with ApiInterceptor for:
//   - JWT injection on every request
//   - Automatic token refresh on 401
//   - Standardized error handling
//   - Request/response logging in development
//
// Usage in repositories:
//   final _client = ApiClient.instance;
//   final response = await _client.get(ApiConfig.myProfile);
// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import 'api_interceptor.dart';

class ApiClient {
  ApiClient._(); // prevent instantiation

  static Dio? _instance;

  // ── Singleton accessor ───────────────────────────────────
  // Returns the same Dio instance across the entire app.
  // Lazy initialized on first access.
  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  // ── Factory ───────────────────────────────────────────────
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Do NOT throw on non-2xx by default —
        // ApiInterceptor.onError handles all status codes
        // so we can return structured error responses
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // ── Attach interceptors ─────────────────────────────────
    // Order matters — interceptors run in the order added
    // for requests, and in REVERSE order for responses/errors

    // 1. Auth interceptor — injects JWT, handles 401 refresh
    dio.interceptors.add(ApiInterceptor(dio));

    // 2. Logger — only active in development builds
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint('[Dio] $obj'),
        ),
      );
    }

    return dio;
  }

  // ── Reset ─────────────────────────────────────────────────
  // Call this on logout to clear any cached state in the
  // Dio instance (e.g. queued retry requests from interceptor)
  static void reset() {
    _instance?.interceptors.clear();
    _instance?.close();
    _instance = null;
    debugPrint('[ApiClient] Instance reset.');
  }
}
