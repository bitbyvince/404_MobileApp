// lib/providers/patient_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/patient_repository.dart';
import '../data/models/patient_model.dart';

// ── Repository provider ───────────────────────────────────
// PatientRepository is a singleton — access via .instance
// No Dio injection needed here because PatientRepository
// handles that internally via ApiClient.instance
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository.instance; // ← this is the fix
});

// ── Patient notifier ──────────────────────────────────────
class PatientNotifier extends AsyncNotifier<PatientModel?> {
  @override
  Future<PatientModel?> build() async {
    return _fetchProfile();
  }

  Future<PatientModel?> _fetchProfile() async {
    final repo = ref.read(patientRepositoryProvider);
    return repo.getMyProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProfile);
  }

  Future<void> refreshProfile() async {
    final previous = state.valueOrNull;
    state = AsyncData(previous);
    try {
      final fresh = await _fetchProfile();
      state = AsyncData(fresh);
    } catch (_) {
      // Keep stale data on silent refresh failure
    }
  }

  Future<bool> updateContactInfo({String? phoneNumber, String? email}) async {
    try {
      final repo = ref.read(patientRepositoryProvider);
      final updated = await repo.updateContactInfo(
        phoneNumber: phoneNumber,
        email: email,
      );
      state = AsyncData(updated);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  void updateComplianceLocally({
    required int dosesTaken,
    required int dosesMissed,
    required int dosesRemaining,
    required double compliancePercentage,
    required int consecutiveMissedDoses,
    required String riskLevel,
    DateTime? lastDoseTaken,
  }) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        compliance: current.compliance.copyWith(
          dosesTaken: dosesTaken,
          dosesMissed: dosesMissed,
          dosesRemaining: dosesRemaining,
          compliancePercentage: compliancePercentage,
          consecutiveMissedDoses: consecutiveMissedDoses,
          riskLevel: riskLevel,
          lastDoseTaken: lastDoseTaken,
        ),
      ),
    );
  }

  void updateSputumScheduleLocally(List<SputumScheduleItem> updatedSchedule) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(sputumTestSchedule: updatedSchedule));
  }

  void reset() {
    state = const AsyncData(null);
  }

  // ── Derived getters ──────────────────────────────────────
  int get daysRemaining {
    final patient = state.valueOrNull;
    if (patient == null) return 0;
    final diff = patient.endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get currentTreatmentDay {
    final patient = state.valueOrNull;
    if (patient == null) return 0;
    final diff = DateTime.now().difference(patient.dateStarted).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  double get compliancePercentage {
    return state.valueOrNull?.compliance.compliancePercentage ?? 0.0;
  }

  int get daysUntilNextSputumTest {
    final patient = state.valueOrNull;
    if (patient == null) return 0;
    final today = DateTime.now();
    final pending =
        patient.sputumTestSchedule
            .where((s) => s.status == 'Pending' && s.dueDate.isAfter(today))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (pending.isEmpty) return 0;
    return pending.first.dueDate.difference(today).inDays;
  }
}

// ── The provider ──────────────────────────────────────────
final patientProvider = AsyncNotifierProvider<PatientNotifier, PatientModel?>(
  PatientNotifier.new,
);

// ── Convenience providers ─────────────────────────────────
final patientNameProvider = Provider<String>((ref) {
  return ref.watch(patientProvider).valueOrNull?.firstName ?? 'Patient';
});

final compliancePercentageProvider = Provider<double>((ref) {
  return ref
          .watch(patientProvider)
          .valueOrNull
          ?.compliance
          .compliancePercentage ??
      0.0;
});

final daysRemainingProvider = Provider<int>((ref) {
  final patient = ref.watch(patientProvider).valueOrNull;
  if (patient == null) return 0;
  final diff = patient.endDate.difference(DateTime.now()).inDays;
  return diff < 0 ? 0 : diff;
});
