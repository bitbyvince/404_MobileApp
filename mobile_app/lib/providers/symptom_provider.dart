import 'package:flutter/foundation.dart';
import '../data/repositories/symptom_repository.dart';
import '../data/models/symptom_log_model.dart';

enum SymptomStatus { initial, loading, loaded, submitting, success, error }

class SymptomProvider extends ChangeNotifier {
  final SymptomRepository _symptomRepository;

  SymptomProvider({required SymptomRepository symptomRepository})
    : _symptomRepository = symptomRepository;

  // ── STATE ────────────────────────────────────────────────
  SymptomStatus _status = SymptomStatus.initial;
  String? _errorMessage;

  // Full symptom log history
  List<SymptomLogModel> _history = [];

  // Today's log — null means no symptoms logged today yet
  SymptomLogModel? _todayLog;

  // Active selections on the symptom log form
  // Maps symptom name → severity (1=Mild, 2=Moderate, 3=Severe)
  Map<String, int> _selectedSymptoms = {};

  // Free text notes field value
  String _freeTextNotes = '';

  // Pagination
  bool _hasMore = true;
  int _page = 1;
  bool _isLoadingMore = false;

  // ── MASTER SYMPTOM LIST ──────────────────────────────────
  // Pre-defined options for symptom_chip_selector.dart
  static const List<String> availableSymptoms = [
    'Nausea',
    'Vomiting',
    'Rash',
    'Joint Pain',
    'Dizziness',
    'Blurred Vision',
    'Abdominal Pain',
    'Fever',
    'Fatigue',
    'Tingling in Hands/Feet',
    'Dark Urine',
    'Yellowing of Skin',
    'Hearing Loss',
    'Other',
  ];

  // ── SEVERITY LABELS ──────────────────────────────────────
  static const Map<int, String> severityLabels = {
    1: 'Mild',
    2: 'Moderate',
    3: 'Severe',
  };

  // ── GETTERS ──────────────────────────────────────────────
  SymptomStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<SymptomLogModel> get history => _history;
  SymptomLogModel? get todayLog => _todayLog;
  Map<String, int> get selectedSymptoms => Map.unmodifiable(_selectedSymptoms);
  String get freeTextNotes => _freeTextNotes;
  bool get isLoading => _status == SymptomStatus.loading;
  bool get isSubmitting => _status == SymptomStatus.submitting;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  // ── Derived: Has selections on form ──────────────────────
  bool get hasSelections => _selectedSymptoms.isNotEmpty;

  // ── Derived: Has logged symptoms today ───────────────────
  bool get hasLoggedToday => _todayLog != null;

  // ── Derived: Count of severe symptoms today ──────────────
  int get severeSymptomsToday {
    if (_todayLog == null) return 0;
    return _todayLog!.symptoms.where((s) => s.severity == 3).length;
  }

  // ── Derived: Symptom frequency for risk score input ──────
  // Returns number of symptom logs in the past 7 days
  int get recentSymptomFrequency {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _history.where((log) => log.loggedAt.isAfter(sevenDaysAgo)).length;
  }

  // ── Derived: Most frequent symptom in history ────────────
  String? get mostFrequentSymptom {
    if (_history.isEmpty) return null;
    final frequency = <String, int>{};
    for (final log in _history) {
      for (final symptom in log.symptoms) {
        frequency[symptom.symptom] = (frequency[symptom.symptom] ?? 0) + 1;
      }
    }
    if (frequency.isEmpty) return null;
    return frequency.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ── LOAD TODAY'S LOG ─────────────────────────────────────
  Future<void> loadTodayLog() async {
    _setStatus(SymptomStatus.loading);
    _clearError();
    try {
      final log = await _symptomRepository.getTodayLog();
      _todayLog = log;
      _setStatus(SymptomStatus.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── LOAD HISTORY (paginated) ─────────────────────────────
  Future<void> loadHistory({bool refresh = false}) async {
    if (refresh) {
      _history = [];
      _page = 1;
      _hasMore = true;
    }

    if (!_hasMore) return;
    if (_isLoadingMore) return;

    if (_history.isEmpty) {
      _setStatus(SymptomStatus.loading);
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    _clearError();
    try {
      final result = await _symptomRepository.getHistory(
        page: _page,
        limit: 20,
      );
      _history.addAll(result.logs);
      _hasMore = result.hasMore;
      _page++;
      _setStatus(SymptomStatus.loaded);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── FORM: TOGGLE SYMPTOM SELECTION ───────────────────────
  // Called by symptom_chip_selector.dart when a chip is tapped
  void toggleSymptom(String symptom) {
    if (_selectedSymptoms.containsKey(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      // Default severity: 1 (Mild) on first selection
      _selectedSymptoms[symptom] = 1;
    }
    notifyListeners();
  }

  // ── FORM: UPDATE SEVERITY ────────────────────────────────
  // Called by severity_slider.dart when slider value changes
  void updateSeverity(String symptom, int severity) {
    if (!_selectedSymptoms.containsKey(symptom)) return;
    if (severity < 1 || severity > 3) return;
    _selectedSymptoms[symptom] = severity;
    notifyListeners();
  }

  // ── FORM: UPDATE FREE TEXT NOTES ─────────────────────────
  void updateFreeTextNotes(String notes) {
    _freeTextNotes = notes;
    // No notifyListeners() here — text field manages its own state
  }

  // ── FORM: CLEAR SELECTIONS ───────────────────────────────
  void clearSelections() {
    _selectedSymptoms = {};
    _freeTextNotes = '';
    notifyListeners();
  }

  // ── SUBMIT SYMPTOM LOG ───────────────────────────────────
  Future<bool> submitSymptomLog() async {
    if (_selectedSymptoms.isEmpty) {
      _setError('Please select at least one symptom before submitting.');
      return false;
    }

    _setStatus(SymptomStatus.submitting);
    _clearError();

    // Build the symptoms payload from current selections
    final symptoms = _selectedSymptoms.entries
        .map((entry) => SymptomEntry(symptom: entry.key, severity: entry.value))
        .toList();

    try {
      final newLog = await _symptomRepository.submitLog(
        symptoms: symptoms,
        freeTextNotes: _freeTextNotes.trim(),
      );

      // Update today's log
      _todayLog = newLog;

      // Prepend to history
      _history.insert(0, newLog);

      // Clear form state after successful submission
      clearSelections();

      _setStatus(SymptomStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── SEVERITY HELPER ──────────────────────────────────────
  // Returns the string label for a given severity int
  // Used by symptom_history_tile.dart and severity_slider.dart
  String getSeverityLabel(int severity) {
    return severityLabels[severity] ?? 'Unknown';
  }

  // ── SEVERITY COLOR KEY ───────────────────────────────────
  // Returns a color key string for the UI layer
  // 'mild' | 'moderate' | 'severe'
  String getSeverityColorKey(int severity) {
    switch (severity) {
      case 1:
        return 'mild';
      case 2:
        return 'moderate';
      case 3:
        return 'severe';
      default:
        return 'mild';
    }
  }

  // ── CHECK IF SYMPTOM IS SELECTED ─────────────────────────
  bool isSymptomSelected(String symptom) =>
      _selectedSymptoms.containsKey(symptom);

  // ── GET SEVERITY OF SELECTED SYMPTOM ─────────────────────
  int getSeverityOf(String symptom) => _selectedSymptoms[symptom] ?? 1;

  // ── RESET (on logout) ────────────────────────────────────
  void reset() {
    _status = SymptomStatus.initial;
    _errorMessage = null;
    _history = [];
    _todayLog = null;
    _selectedSymptoms = {};
    _freeTextNotes = '';
    _hasMore = true;
    _page = 1;
    _isLoadingMore = false;
    notifyListeners();
  }

  // ── PRIVATE HELPERS ──────────────────────────────────────
  void _setStatus(SymptomStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = SymptomStatus.error;
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
