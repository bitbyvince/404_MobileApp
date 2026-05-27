import 'package:flutter/foundation.dart';
import '../data/repositories/patient_repository.dart';
import '../data/models/patient_model.dart';

enum PatientStatus { initial, loading, loaded, updating, success, error }

class PatientProvider extends ChangeNotifier {
  final PatientRepository _patientRepository;

  PatientProvider({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  // ── STATE ────────────────────────────────────────────────
  PatientStatus _status = PatientStatus.initial;
  String? _errorMessage;

  // The logged-in patient's own record
  PatientModel? _patient;

  // ── GETTERS ──────────────────────────────────────────────
  PatientStatus get status => _status;
  String? get errorMessage => _errorMessage;
  PatientModel? get patient => _patient;
  bool get isLoading => _status == PatientStatus.loading;
  bool get isUpdating => _status == PatientStatus.updating;
  bool get hasPatient => _patient != null;

  // ── Derived: Days remaining in treatment ─────────────────
  int get daysRemaining {
    if (_patient == null) return 0;
    final today = DateTime.now();
    final end = _patient!.endDate;
    final diff = end.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  // ── Derived: Current treatment day number ────────────────
  int get currentTreatmentDay {
    if (_patient == null) return 0;
    final today = DateTime.now();
    final start = _patient!.dateStarted;
    final diff = today.difference(start).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  // ── Derived: Total treatment days ────────────────────────
  int get totalTreatmentDays {
    if (_patient == null) return 0;
    return _patient!.endDate.difference(_patient!.dateStarted).inDays;
  }

  // ── Derived: Treatment progress percentage (0.0 – 1.0) ──
  double get treatmentProgress {
    if (totalTreatmentDays == 0) return 0.0;
    final progress = currentTreatmentDay / totalTreatmentDays;
    return progress.clamp(0.0, 1.0);
  }

  // ── Derived: Days until next sputum test ─────────────────
  int get daysUntilNextSputumTest {
    if (_patient == null) return 0;
    final today = DateTime.now();
    final pending = _patient!.sputumTestSchedule
        .where((s) => s.status == 'Pending' && s.dueDate.isAfter(today))
        .toList();
    if (pending.isEmpty) return 0;
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.first.dueDate.difference(today).inDays;
  }

  // ── Derived: Next sputum test due date ───────────────────
  DateTime? get nextSputumTestDate {
    if (_patient == null) return null;
    final today = DateTime.now();
    final pending = _patient!.sputumTestSchedule
        .where((s) => s.status == 'Pending' && s.dueDate.isAfter(today))
        .toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.first.dueDate;
  }

  // ── Derived: Compliance percentage ───────────────────────
  double get compliancePercentage {
    if (_patient == null) return 0.0;
    return _patient!.compliance.compliancePercentage;
  }

  // ── Derived: Risk level label ─────────────────────────────
  String get riskLevel {
    if (_patient == null) return 'Unknown';
    return _patient!.compliance.riskLevel;
  }

  // ── Derived: Risk score ───────────────────────────────────
  int get riskScore {
    if (_patient == null) return 0;
    return _patient!.riskScore.score;
  }

  // ── Derived: Consecutive missed doses ────────────────────
  int get consecutiveMissedDoses {
    if (_patient == null) return 0;
    return _patient!.compliance.consecutiveMissedDoses;
  }

  // ── Derived: Current drug regimen ────────────────────────
  List<DrugRegimenItem> get drugRegimen {
    if (_patient == null) return [];
    return _patient!.drugRegimen;
  }

  // ── Derived: Treatment phase label ───────────────────────
  String get treatmentPhase {
    if (_patient == null) return '';
    return _patient!.treatmentPhase;
  }

  // ── Derived: Is treatment completed ──────────────────────
  bool get isTreatmentComplete {
    if (_patient == null) return false;
    const terminalStatuses = [
      'Cured',
      'Treatment Completed',
      'Treatment Failed',
      'Died',
      'Lost to Follow-Up',
      'Not Evaluated',
    ];
    return terminalStatuses.contains(_patient!.treatmentOutcome.status);
  }

  // ── LOAD PATIENT PROFILE ─────────────────────────────────
  // Called on dashboard init and after login
  Future<void> loadProfile() async {
    _setStatus(PatientStatus.loading);
    _clearError();
    try {
      final patient = await _patientRepository.getMyProfile();
      _patient = patient;
      _setStatus(PatientStatus.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── REFRESH PROFILE ──────────────────────────────────────
  // Silent refresh — does not trigger loading state
  // Used after medication log, symptom log, or appointment actions
  Future<void> refreshProfile() async {
    _clearError();
    try {
      final patient = await _patientRepository.getMyProfile();
      _patient = patient;
      notifyListeners();
    } catch (_) {
      // Silent — keep stale data if refresh fails
    }
  }

  // ── UPDATE CONTACT INFO ──────────────────────────────────
  // Patient can update their own phone/email from profile screen
  Future<bool> updateContactInfo({String? phoneNumber, String? email}) async {
    _setStatus(PatientStatus.updating);
    _clearError();
    try {
      final updated = await _patientRepository.updateContactInfo(
        phoneNumber: phoneNumber,
        email: email,
      );
      _patient = updated;
      _setStatus(PatientStatus.success);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── UPDATE COMPLIANCE LOCALLY ────────────────────────────
  // Called by MedicationProvider after a dose log so the
  // dashboard reflects the new compliance without a full reload
  void updateComplianceLocally({
    required int dosesTaken,
    required int dosesMissed,
    required int dosesRemaining,
    required double compliancePercentage,
    required int consecutiveMissedDoses,
    required String riskLevel,
    required DateTime? lastDoseTaken,
  }) {
    if (_patient == null) return;
    _patient = _patient!.copyWith(
      compliance: _patient!.compliance.copyWith(
        dosesTaken: dosesTaken,
        dosesMissed: dosesMissed,
        dosesRemaining: dosesRemaining,
        compliancePercentage: compliancePercentage,
        consecutiveMissedDoses: consecutiveMissedDoses,
        riskLevel: riskLevel,
        lastDoseTaken: lastDoseTaken,
      ),
    );
    notifyListeners();
  }

  // ── UPDATE SPUTUM SCHEDULE LOCALLY ───────────────────────
  // Called by SputumProvider after a test result is entered
  void updateSputumScheduleLocally(List<SputumScheduleItem> updatedSchedule) {
    if (_patient == null) return;
    _patient = _patient!.copyWith(sputumTestSchedule: updatedSchedule);
    notifyListeners();
  }

  // ── RESET (on logout) ────────────────────────────────────
  void reset() {
    _status = PatientStatus.initial;
    _errorMessage = null;
    _patient = null;
    notifyListeners();
  }

  // ── PRIVATE HELPERS ──────────────────────────────────────
  void _setStatus(PatientStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = PatientStatus.error;
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
