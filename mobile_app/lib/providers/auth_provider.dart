import 'package:flutter/foundation.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../services/secure_storage_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;

  AuthProvider({
    required AuthRepository authRepository,
    required SecureStorageService secureStorage,
  }) : _authRepository = authRepository,
       _secureStorage = secureStorage;

  // ── STATE ────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  // ── GETTERS ──────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ── INIT: Check stored token on app launch ───────────────
  Future<void> init() async {
    _setLoading(true);
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        _setStatus(AuthStatus.unauthenticated);
        return;
      }
      // Token exists — validate with backend and load user
      final user = await _authRepository.getMe();
      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
    } catch (_) {
      await _secureStorage.clearAll();
      _setStatus(AuthStatus.unauthenticated);
    } finally {
      _setLoading(false);
    }
  }

  // ── PATIENT LOGIN ────────────────────────────────────────
  // identifier = patient_id (PT-XXXX) | phone_number | email
  Future<bool> patientLogin({
    required String identifier,
    required String pin,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      // Repository auto-detects identifier type internally —
      // no need to pass identifierType from the provider
      final result = await _authRepository.patientLogin(
        identifier: identifier,
        pin: pin,
      );

      await _secureStorage.saveTokens(
        accessToken: result['accessToken'] ?? '',
        refreshToken: result['refreshToken'] ?? '',
      );

      final user = await _authRepository.getMe();
      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── OTP LOGIN ────────────────────────────────────────────
  Future<bool> otpLogin({
    required String phoneNumber,
    required String firebaseIdToken,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authRepository.verifyOtp(
        phoneNumber: phoneNumber,
        firebaseIdToken: firebaseIdToken,
      );

      await _secureStorage.saveTokens(
        accessToken: result['accessToken'] ?? '',
        refreshToken: result['refreshToken'] ?? '',
      );

      final user = await _authRepository.getMe();
      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── LOGOUT ───────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authRepository.logout();
    } catch (_) {
      // Always clear locally regardless of network result
    } finally {
      await _secureStorage.clearAll();
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);
      _setLoading(false);
    }
  }

  // ── CHANGE PIN ───────────────────────────────────────────
  Future<bool> changePin({
    required String currentPin,
    required String newPin,
    required String confirmNewPin,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.changePin(
        currentPin: currentPin,
        newPin: newPin,
        confirmNewPin: confirmNewPin,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── REFRESH CURRENT USER ─────────────────────────────────
  Future<void> refreshCurrentUser() async {
    try {
      final user = await _authRepository.getMe();
      _currentUser = user;
      notifyListeners();
    } catch (_) {
      // Silently fail — stale data is acceptable here
    }
  }

  // ── TOKEN REFRESH ────────────────────────────────────────
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        await logout();
        return false;
      }
      final result = await _authRepository.refreshToken(refreshToken);
      await _secureStorage.saveTokens(
        accessToken: result['accessToken'] ?? '',
        refreshToken: result['refreshToken'] ?? '',
      );
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  // ── PRIVATE HELPERS ──────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
