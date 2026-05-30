// lib/features/medication/screens/medication_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/models/medication_log_model.dart';
import '../../../data/models/patient_model.dart';
import '../widgets/medicine_card.dart';
import '../widgets/mark_taken_button.dart';

class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen> {
  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);
  static const _green = Color(0xFF34A853);

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  MedicationLogModel? _todayLog;
  PatientModel? _patient;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        MedicationRepository.instance.getLogByDate(date: DateTime.now()),
        PatientRepository.instance.getMyProfile(),
      ]);
      setState(() {
        _todayLog = results[0] as MedicationLogModel?;
        _patient = results[1] as PatientModel;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Unified drug checklist ─────────────────────────────────
  // If a log exists → use it as source of truth per drug status
  // If no log yet   → build from patient drug regimen (all Pending)
  List<_DrugEntry> get _drugChecklist {
    if (_todayLog != null) {
      return _todayLog!.medicines
          .map(
            (m) => _DrugEntry(
              drugName: m.drugName,
              strength: m.strength,
              unit: m.unit,
              numberToBeTaken: m.numberToBeTaken,
              status: m.status,
            ),
          )
          .toList();
    }
    if (_patient != null) {
      return _patient!.drugRegimen
          .map(
            (d) => _DrugEntry(
              drugName: d.drugName,
              strength: d.strength,
              unit: d.unit,
              numberToBeTaken: d.numberToBeTaken,
              status: 'Pending',
            ),
          )
          .toList();
    }
    return [];
  }

  int get _takenCount =>
      _drugChecklist.where((d) => d.status == 'Taken').length;
  int get _totalCount => _drugChecklist.length;
  bool get _allTaken =>
      _totalCount > 0 && _drugChecklist.every((d) => d.status == 'Taken');
  bool get _hasLog => _todayLog != null;

  // ── Mark individual drug ───────────────────────────────────
  Future<void> _markDrugTaken(_DrugEntry drug) async {
    if (drug.status == 'Taken' || _patient == null) return;

    // Optimistic UI
    setState(() {
      final idx = _drugChecklist.indexWhere(
        (d) => d.drugName == drug.drugName && d.strength == drug.strength,
      );
      if (idx != -1) _drugChecklist[idx].status = 'Taken';
    });

    try {
      if (_todayLog != null) {
        // Log already exists — PATCH it
        final updatedMedicines = _todayLog!.medicines.map((m) {
          if (m.drugName == drug.drugName && m.strength == drug.strength) {
            return {
              'drug_name': m.drugName,
              'strength': m.strength,
              'unit': m.unit,
              'number_to_be_taken': m.numberToBeTaken,
              'status': 'Taken',
              'taken_at': DateTime.now().toIso8601String(),
            };
          }
          return {
            'drug_name': m.drugName,
            'strength': m.strength,
            'unit': m.unit,
            'number_to_be_taken': m.numberToBeTaken,
            'status': m.status,
            'taken_at': m.takenAt?.toIso8601String(),
          };
        }).toList();

        final updated = await MedicationRepository.instance.updateLog(
          logId: _todayLog!.logId,
          medicines: updatedMedicines,
        );
        if (mounted) setState(() => _todayLog = updated);
      } else {
        // No log yet — POST new log
        final updated = await MedicationRepository.instance.markDrugTaken(
          drugName: drug.drugName,
          strength: drug.strength,
          takenAt: DateTime.now(),
          fullRegimen: _patient!.drugRegimen,
        );
        if (mounted) setState(() => _todayLog = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
        // Revert optimistic update
        await _loadAll();
      }
    }
  }

  // ── Mark all drugs taken ───────────────────────────────────
  Future<void> _markAllTaken() async {
    if (_allTaken || _submitting || _patient == null) return;
    setState(() => _submitting = true);

    try {
      if (_todayLog != null) {
        // Log exists — PATCH all medicines to Taken
        final now = DateTime.now().toIso8601String();
        final medicines = _todayLog!.medicines
            .map(
              (m) => {
                'drug_name': m.drugName,
                'strength': m.strength,
                'unit': m.unit,
                'number_to_be_taken': m.numberToBeTaken,
                'status': 'Taken',
                'taken_at': now,
              },
            )
            .toList();

        final updated = await MedicationRepository.instance.updateLog(
          logId: _todayLog!.logId,
          medicines: medicines,
        );
        if (mounted) setState(() => _todayLog = updated);
      } else {
        // No log yet — POST new log with all Taken
        final updated = await MedicationRepository.instance.markAllTaken(
          takenAt: DateTime.now(),
          fullRegimen: _patient!.drugRegimen,
        );
        if (mounted) setState(() => _todayLog = updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All doses marked as taken!'),
            backgroundColor: _green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Medication',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _loadAll)
          : _drugChecklist.isEmpty
          ? _EmptyState(onRetry: _loadAll)
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HEADER ──────────────────────────────
                    _HeaderCard(
                      date: _formattedToday(),
                      takenCount: _takenCount,
                      totalCount: _totalCount,
                      allTaken: _allTaken,
                      hasLog: _hasLog,
                    ),
                    const SizedBox(height: 20),

                    // ── DRUG COUNT LABEL ─────────────────────
                    Row(
                      children: [
                        const Text(
                          'Your Medicines Today',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_totalCount ${_totalCount == 1 ? 'drug' : 'drugs'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── DRUG LIST ────────────────────────────
                    ..._drugChecklist.map(
                      (drug) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MedicineCard(
                          drugName: drug.drugName,
                          strength: drug.strength,
                          unit: drug.unit,
                          numberToBeTaken: drug.numberToBeTaken,
                          status: drug.status,
                          onMarkTaken: drug.status == 'Taken'
                              ? null
                              : () => _markDrugTaken(drug),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ── PROGRESS SUMMARY ─────────────────────
                    if (_totalCount > 0) ...[
                      _ProgressSummary(
                        takenCount: _takenCount,
                        totalCount: _totalCount,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── MARK ALL / DONE BANNER ───────────────
                    if (!_allTaken) ...[
                      MarkTakenButton(
                        isTaken: false,
                        isLoading: _submitting,
                        onPressed: _markAllTaken,
                        label: 'Mark All as Taken',
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Or tap "Take" on each medicine individually',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: _green,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'All medicines taken for today!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── INSTRUCTION BOX ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.amber.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Take your medicine with water after a meal. '
                              'Contact your health center if you experience '
                              'severe side effects.',
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  String _formattedToday() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// ── Internal drug entry ────────────────────────────────────
class _DrugEntry {
  _DrugEntry({
    required this.drugName,
    required this.strength,
    required this.unit,
    required this.numberToBeTaken,
    required this.status,
  });

  final String drugName;
  final String strength;
  final String unit;
  final int numberToBeTaken;
  String status; // mutable for optimistic updates
}

// ── Header card ────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.date,
    required this.takenCount,
    required this.totalCount,
    required this.allTaken,
    required this.hasLog,
  });

  final String date;
  final int takenCount;
  final int totalCount;
  final bool allTaken;
  final bool hasLog;

  static const _blue = Color(0xFF1A73E8);
  static const _green = Color(0xFF34A853);

  @override
  Widget build(BuildContext context) {
    final color = allTaken ? _green : _blue;
    final progress = totalCount == 0 ? 0.0 : takenCount / totalCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allTaken ? 'All Done for Today!' : "Today's Medication",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    Center(
                      child: Text(
                        '$takenCount/$totalCount',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasLog
                ? '$takenCount of $totalCount doses logged'
                : 'Log your doses below',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress summary ────────────────────────────────────────
class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.takenCount, required this.totalCount});

  final int takenCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final remaining = totalCount - takenCount;
    return Row(
      children: [
        _SummaryChip(
          count: takenCount,
          label: 'Taken',
          color: const Color(0xFF34A853),
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 8),
        _SummaryChip(
          count: remaining,
          label: 'Remaining',
          color: remaining > 0
              ? const Color(0xFFFFA000)
              : const Color(0xFF9E9E9E),
          icon: Icons.radio_button_unchecked_rounded,
        ),
        const SizedBox(width: 8),
        _SummaryChip(
          count: totalCount,
          label: 'Total',
          color: const Color(0xFF1A73E8),
          icon: Icons.medication_rounded,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  final int count;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No drug regimen found.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your assigned nurse has not set up\n'
              'your medication schedule yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
