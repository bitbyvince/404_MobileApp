// ============================================================
// lib/services/api/api_interceptor.dart
//
// Dio interceptor that handles:
//   1. JWT injection — adds Authorization header to every request
//   2. Token refresh — on 401, silently refresh and retry once
//   3. Request queuing — queues concurrent requests during refresh
//      so only ONE refresh call goes out even if 5 requests 401
//   4. Logout on hard auth failure — clears storage and redirects
//      if refresh also fails (session truly expired)
//   5. Structured error mapping — converts Dio/HTTP errors into
//      AppException types your repositories can handle cleanly
// ============================================================

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../config/env.dart';
import '../secure_storage_service.dart';

class ApiInterceptor extends Interceptor {
  ApiInterceptor(this._dio);

  final Dio _dio;

  // ── Token refresh state ───────────────────────────────────
  // Prevents multiple simultaneous refresh calls when several
  // requests 401 at the same time (e.g. dashboard loads 4 endpoints)
  bool _isRefreshing = false;

  // Queue of (resolve, reject) pairs waiting for refresh to finish
  final List<
    ({
      void Function(String newToken) resolve,
      void Function(DioException error) reject,
    })
  >
  _pendingRequests = [];

  // ── REQUEST ───────────────────────────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Inject JWT into Authorization header
    // Skip for auth endpoints that don't need a token
    final isAuthRoute = _isAuthRoute(options.path);

    if (!isAuthRoute) {
      final token = await SecureStorageService.getJwt();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (Env.enableApiLogging) {
      debugPrint('[ApiInterceptor] → ${options.method} ${options.path}');
    }

    handler.next(options);
  }

  // ── RESPONSE ──────────────────────────────────────────────
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (Env.enableApiLogging) {
      debugPrint(
        '[ApiInterceptor] ← ${response.statusCode} ${response.requestOptions.path}',
      );
    }
    handler.next(response);
  }

  // ── ERROR ─────────────────────────────────────────────────
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;
    final isAuthRoute = _isAuthRoute(requestPath);

    if (Env.enableApiLogging) {
      debugPrint(
        '[ApiInterceptor] ✗ $statusCode $requestPath — ${err.message}',
      );
    }

    // ── Handle 401 Unauthorized ────────────────────────────
    // Don't attempt refresh on auth routes — that would loop
    if (statusCode == 401 && !isAuthRoute) {
      return _handle401(err, handler);
    }

    // ── Handle 403 Forbidden ───────────────────────────────
    // Role/barangay scope violation — surface to the UI
    if (statusCode == 403) {
      return handler.reject(
        _wrapError(
          err,
          code: 'FORBIDDEN',
          message: 'You do not have permission to perform this action.',
        ),
      );
    }

    // ── Handle 404 Not Found ───────────────────────────────
    if (statusCode == 404) {
      return handler.reject(
        _wrapError(
          err,
          code: 'NOT_FOUND',
          message: 'The requested resource was not found.',
        ),
      );
    }

    // ── Handle 422 Validation Error ────────────────────────
    // Express returns validation errors from express-validator here
    if (statusCode == 422) {
      final errors = err.response?.data?['errors'];
      final message = errors != null
          ? _flattenValidationErrors(errors)
          : 'Validation failed. Please check your input.';
      return handler.reject(
        _wrapError(err, code: 'VALIDATION_ERROR', message: message),
      );
    }

    // ── Handle 429 Rate Limit ─────────────────────────────
    if (statusCode == 429) {
      return handler.reject(
        _wrapError(
          err,
          code: 'RATE_LIMITED',
          message: 'Too many requests. Please wait a moment and try again.',
        ),
      );
    }

    // ── Handle network/connection errors ───────────────────
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      return handler.reject(
        _wrapError(
          err,
          code: 'NO_CONNECTION',
          message:
              'Cannot connect to the server. '
              'Please check your internet connection.',
        ),
      );
    }

    // ── Handle timeout ─────────────────────────────────────
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return handler.reject(
        _wrapError(
          err,
          code: 'TIMEOUT',
          message: 'The request timed out. Please try again.',
        ),
      );
    }

    // ── Pass everything else through ───────────────────────
    handler.next(err);
  }

  // ── 401 Handler with request queuing ─────────────────────
  Future<void> _handle401(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If a refresh is already in progress, queue this request
    // and wait for the refresh to complete
    if (_isRefreshing) {
      final completer = Completer<String>();

      _pendingRequests.add((
        resolve: (token) => completer.complete(token),
        reject: (error) => completer.completeError(error),
      ));

      try {
        final newToken = await completer.future;
        // Retry the original request with the new token
        final response = await _retryRequest(err.requestOptions, newToken);
        return handler.resolve(response);
      } catch (e) {
        return handler.reject(err);
      }
    }

    // This is the FIRST 401 — initiate the refresh
    _isRefreshing = true;

    try {
      final newToken = await _refreshToken();

      if (newToken == null) {
        // Refresh failed — force logout
        await _forceLogout();
        _rejectPending(err);
        return handler.reject(
          _wrapError(
            err,
            code: 'SESSION_EXPIRED',
            message: 'Your session has expired. Please log in again.',
          ),
        );
      }

      // Resolve all queued requests with the new token
      _resolvePending(newToken);

      // Retry the original request
      final response = await _retryRequest(err.requestOptions, newToken);
      return handler.resolve(response);
    } catch (e) {
      await _forceLogout();
      _rejectPending(err);
      return handler.reject(
        _wrapError(
          err,
          code: 'SESSION_EXPIRED',
          message: 'Your session has expired. Please log in again.',
        ),
      );
    } finally {
      _isRefreshing = false;
      _pendingRequests.clear();
    }
  }

  // ── Token refresh call ────────────────────────────────────
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await SecureStorageService.readRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[ApiInterceptor] No refresh token found.');
        return null;
      }

      // Use a fresh Dio instance — NOT _dio — to avoid
      // the interceptor triggering on this refresh call itself
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // backend returns data.accessToken and data.refreshToken
        final responseData = data['data'] as Map<String, dynamic>?;
        final newJwt = responseData?['accessToken'] as String?;
        final newRefresh = responseData?['refreshToken'] as String?;

        if (newJwt == null) return null;

        await SecureStorageService.saveJwt(newJwt);
        if (newRefresh != null) {
          await SecureStorageService.saveRefreshToken(newRefresh);
        }

        debugPrint('[ApiInterceptor] Token refreshed successfully.');
        return newJwt;
      }

      return null;
    } catch (e) {
      debugPrint('[ApiInterceptor] Token refresh failed: $e');
      return null;
    }
  }

  // ── Retry original request with new token ─────────────────
  Future<Response> _retryRequest(
    RequestOptions options,
    String newToken,
  ) async {
    options.headers['Authorization'] = 'Bearer $newToken';
    return _dio.fetch(options);
  }

  // ── Queue management ──────────────────────────────────────
  void _resolvePending(String newToken) {
    for (final pending in _pendingRequests) {
      pending.resolve(newToken);
    }
  }

  void _rejectPending(DioException err) {
    for (final pending in _pendingRequests) {
      pending.reject(err);
    }
  }

  // ── Force logout ──────────────────────────────────────────
  // Clears all stored credentials when refresh fails.
  // The router watching authProvider will redirect to login.
  Future<void> _forceLogout() async {
    debugPrint('[ApiInterceptor] Forcing logout — clearing credentials.');
    await SecureStorageService.wipeAll();
    // Note: actual navigation to login screen is handled by
    // the authProvider Riverpod listener in app.dart
    // We don't navigate here because interceptors have no
    // access to BuildContext
  }

  // ── Helpers ───────────────────────────────────────────────
  // Routes that don't need an Authorization header
  bool _isAuthRoute(String path) {
    // These routes do NOT get an Authorization header injected
    // and do NOT trigger a refresh loop on 401.
    // /auth/verify is removed — it should receive the token.
    // Only login/refresh/otp routes truly need no token.
    const authPaths = [
      '/auth/patient-login',
      '/auth/login',
      '/auth/refresh',
      '/otp/request',
      '/otp/verify',
      '/otp/reset-pin',
    ];
    return authPaths.any((p) => path.contains(p));
  }

  // Wraps a DioException with a custom error code and message
  // stored in the response data so repositories can read them
  DioException _wrapError(
    DioException original, {
    required String code,
    required String message,
  }) {
    return DioException(
        requestOptions: original.requestOptions,
        response: original.response,
        type: original.type,
        error: original.error,
        message: message,
        stackTrace: original.stackTrace,
      )
      ..requestOptions.extra['error_code'] = code
      ..requestOptions.extra['error_message'] = message;
  }

  // Flattens express-validator error array into a single string
  // Express returns: { errors: [{ msg: '...', path: '...' }] }
  String _flattenValidationErrors(dynamic errors) {
    if (errors is List) {
      return errors
          .map((e) => e is Map ? e['msg'] ?? e.toString() : e.toString())
          .join(' ');
    }
    return errors.toString();
  }
}
