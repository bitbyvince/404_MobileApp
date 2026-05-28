import 'package:flutter/foundation.dart';
import '../data/repositories/sputum_repository.dart';
import '../data/models/sputum_test_model.dart';

enum SputumStatus { initial, loading, loaded, error }

class SputumProvider extends ChangeNotifier {
  final SputumRepository _sputumRepository;

  SputumProvider({required SputumRepository sputumRepository})
    : _sputumRepository = sputumRepository;

  // ── STATE ────────────────────────────────────────────────
  SputumStatus _status = SputumStatus.initial;
  String? _errorMessage;

  // Full list of all sputum tests for this patient
  List<SputumTestModel> _tests = [];

  // Currently selected test for detail view
  SputumTestModel? _selectedTest;

  // ── GETTERS ──────────────────────────────────────────────
  SputumStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<SputumTestModel> get tests => _tests;
  SputumTestModel? get selectedTest => _selectedTest;
  bool get isLoading => _status == SputumStatus.loading;

  // ── Derived: Completed tests ──────────────────────────────
  List<SputumTestModel> get completedTests =>
      _tests.where((t) => t.result != 'Pending' && t.result != null).toList();

  // ── Derived: Pending tests ────────────────────────────────
  List<SputumTestModel> get pendingTests =>
      _tests.where((t) => t.result == 'Pending' || t.result == null).toList();

  // ── Derived: Next pending test ────────────────────────────
  SputumTestModel? get nextPendingTest {
    final today = DateTime.now();
    final upcoming = pendingTests
        // ignore: unnecessary_null_comparison
        .where((t) => t.dueDate == null || t.dueDate.isAfter(today))
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return upcoming.first;
  }

  // ── Derived: Most recent completed test ──────────────────
  SputumTestModel? get mostRecentTest {
    if (completedTests.isEmpty) return null;
    final sorted = [...completedTests]
      ..sort((a, b) {
        // ignore: unnecessary_null_comparison
        final aDate = a.dateCollected ?? a.dueDate;
        // ignore: unnecessary_null_comparison
        final bDate = b.dateCollected ?? b.dueDate;
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }

  // ── Derived: Days until next test ────────────────────────
  int get daysUntilNextTest {
    final next = nextPendingTest;
    // ignore: unnecessary_null_comparison
    if (next == null || next.dueDate == null) return 0;
    final diff = next.dueDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  // ── Derived: Overall test timeline progress ───────────────
  // Returns how many of the 3 WHO checkpoints are done
  int get completedCount => completedTests.length;
  int get totalCount => _tests.length;

  // ── Derived: Latest test result label ────────────────────
  // Returns 'Negative' | 'Positive' | 'Pending' | 'Not Done' | null
  String? get latestResultLabel => mostRecentTest?.result;

  // ── Derived: Is treatment progressing well ───────────────
  // True if all completed tests are Negative
  bool get isProgressingWell {
    if (completedTests.isEmpty) return true;
    return completedTests.every((t) => t.result == 'Negative');
  }

  // ── LOAD ALL SPUTUM TESTS ────────────────────────────────
  Future<void> loadTests() async {
    _setStatus(SputumStatus.loading);
    _clearError();
    try {
      final tests = await _sputumRepository.getMyTests();
      // Sort by month ascending for timeline display
      tests.sort((a, b) => a.month.compareTo(b.month));
      _tests = tests;
      _setStatus(SputumStatus.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── REFRESH TESTS ────────────────────────────────────────
  // Silent refresh — does not trigger loading state
  // Called after appointment booking (sputum-type) or
  // when returning to sputum screen from background
  Future<void> refreshTests() async {
    _clearError();
    try {
      final tests = await _sputumRepository.getMyTests();
      tests.sort((a, b) => a.month.compareTo(b.month));
      _tests = tests;
      notifyListeners();
    } catch (_) {
      // Keep stale data silently
    }
  }

  // ── SELECT TEST (detail / expanded view) ─────────────────
  void selectTest(SputumTestModel test) {
    _selectedTest = test;
    notifyListeners();
  }

  void clearSelectedTest() {
    _selectedTest = null;
    notifyListeners();
  }

  // ── SYNC RESULT FROM BACKEND ─────────────────────────────
  // When the patient opens the app and a health staff has
  // entered a result since last session, this updates the
  // specific test locally without reloading the full list
  Future<void> syncTestResult(String testId) async {
    _clearError();
    try {
      final updated = await _sputumRepository.getTestById(testId);
      final index = _tests.indexWhere((t) => t.testId == testId);
      if (index != -1) {
        _tests[index] = updated;
        // If the selected test is the one that was updated, refresh it
        if (_selectedTest?.testId == testId) {
          _selectedTest = updated;
        }
        notifyListeners();
      }
    } catch (_) {
      // Silently fail — result will sync on next loadTests()
    }
  }

  // ── GET TIMELINE ITEMS ───────────────────────────────────
  // Returns all 3 WHO months in order, filling in gaps with
  // placeholder models if the schedule hasn't been created yet
  List<SputumTimelineItem> get timelineItems {
    const requiredMonths = [2, 5, 6];
    return requiredMonths.map((month) {
      final test = _tests.firstWhere(
        (t) => t.month == month,
        orElse: () => SputumTestModel.placeholder(month: month),
      );
      return SputumTimelineItem(
        month: month,
        test: test,
        isCompleted: test.result != null && test.result != 'Pending',
        isPending: test.result == 'Pending' || test.result == null,
        isOverdue: _isOverdue(test),
      );
    }).toList();
  }

  bool _isOverdue(SputumTestModel test) {
    if (test.result == null || test.result == 'Pending') return false;
    return test.dueDate.isBefore(DateTime.now());
  }

  // ── RESET (on logout) ────────────────────────────────────
  void reset() {
    _status = SputumStatus.initial;
    _errorMessage = null;
    _tests = [];
    _selectedTest = null;
    notifyListeners();
  }

  // ── PRIVATE HELPERS ──────────────────────────────────────
  void _setStatus(SputumStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = SputumStatus.error;
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

// ── Timeline item wrapper ────────────────────────────────
// Used by sputum_timeline.dart widget to render each checkpoint
class SputumTimelineItem {
  final int month;
  final SputumTestModel test;
  final bool isCompleted;
  final bool isPending;
  final bool isOverdue;

  const SputumTimelineItem({
    required this.month,
    required this.test,
    required this.isCompleted,
    required this.isPending,
    required this.isOverdue,
  });

  // Label shown on the timeline node
  String get monthLabel => 'Month $month';

  // Color key for the timeline widget
  // 'completed_negative' | 'completed_positive' | 'pending' | 'overdue'
  String get colorKey {
    if (isOverdue) return 'overdue';
    if (isPending) return 'pending';
    if (test.result == 'Negative') return 'completed_negative';
    if (test.result == 'Positive') return 'completed_positive';
    return 'pending';
  }
}
