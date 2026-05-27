import 'package:flutter/foundation.dart';
import '../data/repositories/appointment_repository.dart';
import '../data/models/appointment_model.dart';

enum AppointmentStatus { initial, loading, loaded, submitting, success, error }

class AppointmentProvider extends ChangeNotifier {
  final AppointmentRepository _appointmentRepository;

  AppointmentProvider({required AppointmentRepository appointmentRepository})
    : _appointmentRepository = appointmentRepository;

  // ── STATE ────────────────────────────────────────────────
  AppointmentStatus _status = AppointmentStatus.initial;
  String? _errorMessage;

  // Upcoming confirmed/pending appointments
  List<AppointmentModel> _upcoming = [];

  // Past/completed/cancelled appointments
  List<AppointmentModel> _past = [];

  // Currently viewed appointment detail
  AppointmentModel? _selectedAppointment;

  // Available slots for booking (list of DateTime)
  List<DateTime> _availableSlots = [];
  bool _isSlotsLoading = false;

  // Pagination for past appointments
  bool _hasMorePast = true;
  int _pastPage = 1;
  bool _isLoadingMore = false;

  // ── GETTERS ──────────────────────────────────────────────
  AppointmentStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<AppointmentModel> get upcoming => _upcoming;
  List<AppointmentModel> get past => _past;
  AppointmentModel? get selectedAppointment => _selectedAppointment;
  List<DateTime> get availableSlots => _availableSlots;
  bool get isSlotsLoading => _isSlotsLoading;
  bool get isLoading => _status == AppointmentStatus.loading;
  bool get isSubmitting => _status == AppointmentStatus.submitting;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePast => _hasMorePast;

  // ── Derived: Next upcoming appointment ──────────────────
  AppointmentModel? get nextAppointment =>
      _upcoming.isNotEmpty ? _upcoming.first : null;

  // ── LOAD UPCOMING APPOINTMENTS ───────────────────────────
  Future<void> loadUpcoming() async {
    _setStatus(AppointmentStatus.loading);
    _clearError();
    try {
      final results = await _appointmentRepository.getUpcoming();
      _upcoming = results;
      _setStatus(AppointmentStatus.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── LOAD PAST APPOINTMENTS (paginated) ───────────────────
  Future<void> loadPast({bool refresh = false}) async {
    if (refresh) {
      _past = [];
      _pastPage = 1;
      _hasMorePast = true;
    }

    if (!_hasMorePast) return;
    if (_isLoadingMore) return;

    if (_past.isEmpty) {
      _setStatus(AppointmentStatus.loading);
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    _clearError();
    try {
      final result = await _appointmentRepository.getPast(
        page: _pastPage,
        limit: 10,
      );
      _past.addAll(result.appointments);
      _hasMorePast = result.hasMore;
      _pastPage++;
      _setStatus(AppointmentStatus.loaded);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── LOAD AVAILABLE SLOTS ─────────────────────────────────
  // Called when the patient opens the book appointment screen
  // and picks a date on the slot_picker widget
  Future<void> loadAvailableSlots({
    required String healthCenterId,
    required DateTime date,
  }) async {
    _isSlotsLoading = true;
    _availableSlots = [];
    notifyListeners();
    try {
      final slots = await _appointmentRepository.getAvailableSlots(
        healthCenterId: healthCenterId,
        date: date,
      );
      _availableSlots = slots;
    } catch (_) {
      _availableSlots = [];
    } finally {
      _isSlotsLoading = false;
      notifyListeners();
    }
  }

  // ── BOOK APPOINTMENT ─────────────────────────────────────
  Future<bool> bookAppointment({
    required DateTime scheduledDate,
    required String scheduledTime,
    required String purpose,
    String? notes,
  }) async {
    _setStatus(AppointmentStatus.submitting);
    _clearError();
    try {
      final newAppointment = await _appointmentRepository.book(
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        purpose: purpose,
        notes: notes,
      );
      // Prepend to upcoming list — status will be "Pending"
      _upcoming.insert(0, newAppointment);
      // Sort upcoming by scheduled date ascending
      _upcoming.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      _setStatus(AppointmentStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── CANCEL APPOINTMENT ───────────────────────────────────
  Future<bool> cancelAppointment(String appointmentId) async {
    _setStatus(AppointmentStatus.submitting);
    _clearError();
    try {
      await _appointmentRepository.cancel(appointmentId);

      // Move from upcoming to past with cancelled status
      final index = _upcoming.indexWhere(
        (a) => a.appointmentId == appointmentId,
      );
      if (index != -1) {
        final cancelled = _upcoming[index].copyWith(status: 'Cancelled');
        _upcoming.removeAt(index);
        _past.insert(0, cancelled);
      }

      // Clear selected if it was the cancelled one
      if (_selectedAppointment?.appointmentId == appointmentId) {
        _selectedAppointment = null;
      }

      _setStatus(AppointmentStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── SELECT APPOINTMENT (detail view) ────────────────────
  void selectAppointment(AppointmentModel appointment) {
    _selectedAppointment = appointment;
    notifyListeners();
  }

  void clearSelectedAppointment() {
    _selectedAppointment = null;
    notifyListeners();
  }

  // ── REFRESH ALL ──────────────────────────────────────────
  Future<void> refreshAll() async {
    await Future.wait([loadUpcoming(), loadPast(refresh: true)]);
  }

  // ── RESET (on logout) ────────────────────────────────────
  void reset() {
    _status = AppointmentStatus.initial;
    _errorMessage = null;
    _upcoming = [];
    _past = [];
    _selectedAppointment = null;
    _availableSlots = [];
    _isSlotsLoading = false;
    _hasMorePast = true;
    _pastPage = 1;
    _isLoadingMore = false;
    notifyListeners();
  }

  // ── PRIVATE HELPERS ──────────────────────────────────────
  void _setStatus(AppointmentStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AppointmentStatus.error;
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
