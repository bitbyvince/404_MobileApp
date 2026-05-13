// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/auth_service.dart';
import '../utils/jwt_helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthStatus _status = AuthStatus.loading;
  String? _userId = null;
  String? _userRole = null;
  String? _error = null;

  // ─── GETTERS ─────────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get userRole => _userRole;
  String? get error => _error;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ─── RESTORE SESSION ON APP START ────────────────────────────────────────

  Future<void> checkExistingSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final hasToken = await JwtHelper.hasToken();

    if (hasToken) {
      final isValid = await _authService.isTokenValid();
      if (isValid) {
        _userId = await JwtHelper.getUserId();
        _userRole = await JwtHelper.getUserRole();
        _status = AuthStatus.authenticated;
      } else {
        // Token expired — clear and send to login
        await JwtHelper.clearSession();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // ─── STEP 1: REGISTER + SEND OTP ─────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String contactNumber,
    required String password,
    String? fullName,
    String? email,
  }) async {
    _error = null;

    try {
      // Creates user in MongoDB — returns user_id and session_id
      final result = await _authService.register(
        contactNumber: contactNumber,
        password: password,
        fullName: fullName,
        email: email,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ─── STEP 2: VERIFY OTP + SAVE SESSION ───────────────────────────────────

  Future<void> verifyOtp({
    required String firebaseIdToken,
    required String userId,
    required String sessionId,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOtp(
        firebaseIdToken: firebaseIdToken,
        userId: userId,
        sessionId: sessionId,
      );

      await JwtHelper.saveSession(
        token: result['token'],
        userId: result['user']['id'],
        role: result['user']['role'],
      );

      _userId = result['user']['id'];
      _userRole = result['user']['role'];
      _status = AuthStatus.authenticated;

      // Register FCM token after successful login
      await _registerFcmToken();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // ─── PUBLIC USER LOGIN ───────────────────────────────────────────────────

  Future<void> login({
    required String idOrEmail,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        contactNumber: idOrEmail,
        password: password,
      );

      await JwtHelper.saveSession(
        token: result['token'],
        userId: result['user']['id'],
        role: result['user']['role'],
      );

      _userId = result['user']['id'];
      _userRole = result['user']['role'];
      _status = AuthStatus.authenticated;

      await _registerFcmToken();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // ─── STAFF LOGIN (nurse / barangay_admin / super_admin) ──────────────────

  Future<void> staffLogin({
    required String email,
    required String password,
    required String role,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.staffLogin(
        email: email,
        password: password,
        role: role,
      );

      await JwtHelper.saveSession(
        token: result['token'],
        userId: result['user']['id'],
        role: result['user']['role'],
      );

      _userId = result['user']['id'];
      _userRole = result['user']['role'];
      _status = AuthStatus.authenticated;

      await _registerFcmToken();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _authService.logout(); // clears JwtHelper session
    await _firebaseAuth.signOut(); // clears Firebase Auth session

    _userId = null;
    _userRole = null;
    _error = null;
    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  // ─── REGISTER FCM TOKEN ──────────────────────────────────────────────────

  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _authService.saveFcmToken(fcmToken);
      }
    } catch (e) {
      // Non-fatal — FCM will retry on next login
      debugPrint('[AuthProvider] FCM token registration failed: $e');
    }
  }

  // ─── CLEAR ERROR ─────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// at the very bottom of auth_provider.dart

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});
