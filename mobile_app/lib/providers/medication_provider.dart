import 'package:flutter/foundation.dart';
import '../data/repositories/medication_repository.dart';
import '../data/models/medication_log_model.dart';

enum MedicationStatus { initial, loading, loaded, submitting, success, error }

class MedicationProvider extends ChangeNotifier {
  final MedicationRepository _medicationRepository;

  MedicationProvider({required MedicationRepository medicationRepository})
    : _medicationRepository = medicationRepository;

  // ── STATE ────────────────────────────────────────────────
  MedicationStatus _status = MedicationStatus.initial;
  String? _errorMessage;

  // Today's log — null means not yet logged today
  MedicationLogModel? _todayLog;

  // Calendar view — maps date string (yyyy-MM-dd) to log
  Map<String, MedicationLogModel> _calendarLogs = {};

  // Full history list for the compliance calendar screen
  List<MedicationLogModel> _history = [];

  // Pagination
  bool _hasMoreHistory = true;
  int _historyPage = 1;
  bool _isLoadingMore = false;

  // ── GETTERS ──────────────────────────────────────────────
  MedicationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  MedicationLogModel? get todayLog => _todayLog;
  Map<String, MedicationLogModel> get calendarLogs => _calendarLogs;
  List<MedicationLogModel> get history => _history;
  bool get hasMoreHistory => _hasMoreHistory;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoading => _status == MedicationStatus.loading;
  bool get isSubmitting => _status == MedicationStatus.submitting;

  // ── Derived: Has the patient logged today? ───────────────
  bool get hasLoggedToday => _todayLog != null;

  // ── Derived: Are all drugs marked taken today? ───────────
  bool get allTakenToday {
    if (_todayLog == null) return false;
    return _todayLog!.medicines.every((m) => m.status == 'Taken');
  }

  // ── LOAD TODAY'S LOG ─────────────────────────────────────
  Future<void> loadTodayLog() async {
    _setStatus(MedicationStatus.loading);
    _clearError();
    try {
      final today = DateTime.now();
      final log = await _medicationRepository.getLogByDate(date: today);
      _todayLog = log;
      _setStatus(MedicationStatus.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── LOAD HISTORY (paginated) ─────────────────────────────
  Future<void> loadHistory({bool refresh = false}) async {
    if (refresh) {
      _history = [];
      _historyPage = 1;
      _hasMoreHistory = true;
    }

    if (!_hasMoreHistory) return;
    if (_isLoadingMore) return;

    if (_history.isEmpty) {
      _setStatus(MedicationStatus.loading);
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    _clearError();
    try {
      final result = await _medicationRepository.getHistory(
        page: _historyPage,
        limit: 30,
      );
      _history.addAll(result.logs);
      _hasMoreHistory = result.hasMore;
      _historyPage++;

      // Populate calendar map for quick date-keyed lookup
      for (final log in result.logs) {
        final key = _dateKey(log.logDate);
        _calendarLogs[key] = log;
      }

      _setStatus(MedicationStatus.loaded);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── MARK DRUG AS TAKEN ───────────────────────────────────
  // Called when patient taps "Mark as Taken" for a single drug
  Future<bool> markDrugTaken({
    required String drugName,
    required String strength,
  }) async {
    _setStatus(MedicationStatus.submitting);
    _clearError();
    try {
      final updatedLog = await _medicationRepository.markDrugTaken(
        drugName: drugName,
        strength: strength,
        takenAt: DateTime.now(),
      );
      _todayLog = updatedLog;
      // Update calendar map
      _calendarLogs[_dateKey(updatedLog.logDate)] = updatedLog;
      _setStatus(MedicationStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── MARK ALL DRUGS TAKEN ─────────────────────────────────
  // Called when patient taps the main "Mark All as Taken" button
  Future<bool> markAllTaken() async {
    _setStatus(MedicationStatus.submitting);
    _clearError();
    try {
      final updatedLog = await _medicationRepository.markAllTaken(
        takenAt: DateTime.now(),
      );
      _todayLog = updatedLog;
      _calendarLogs[_dateKey(updatedLog.logDate)] = updatedLog;

      // Update history if already loaded
      final historyIndex = _history.indexWhere(
        (l) => _dateKey(l.logDate) == _dateKey(updatedLog.logDate),
      );
      if (historyIndex != -1) {
        _history[historyIndex] = updatedLog;
      } else {
        _history.insert(0, updatedLog);
      }

      _setStatus(MedicationStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── GET LOG BY DATE (calendar tap) ──────────────────────
  Future<MedicationLogModel?> getLogByDate(DateTime date) async {
    final key = _dateKey(date);

    // Return from cache if available
    if (_calendarLogs.containsKey(key)) {
      return _calendarLogs[key];
    }

    try {
      final log = await _medicationRepository.getLogByDate(date: date);
      if (log != null) {
        _calendarLogs[key] = log;
        notifyListeners();
      }
      return log;
    } catch (_) {
      return null;
    }
  }

  // ── COMPLIANCE STATS ─────────────────────────────────────
  // Derives compliance color for calendar — used by compliance_calendar.dart
  // Returns 'taken' | 'partial' | 'missed' | 'none'
  String getDayStatus(DateTime date) {
    final key = _dateKey(date);
    final log = _calendarLogs[key];
    if (log == null) return 'none';
    return log.overallStatus.toLowerCase();
  }

  // ── RESET (on logout) ────────────────────────────────────
  void reset() {
    _status = MedicationStatus.initial;
    _errorMessage = null;
    _todayLog = null;
    _calendarLogs = {};
    _history = [];
    _hasMoreHistory = true;
    _historyPage = 1;
    _isLoadingMore = false;
    notifyListeners();
  }

  // ── PRIVATE HELPERS ──────────────────────────────────────
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _setStatus(MedicationStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = MedicationStatus.error;
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
