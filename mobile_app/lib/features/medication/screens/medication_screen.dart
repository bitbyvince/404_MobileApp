import 'package:flutter/material.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/models/medication_log_model.dart';
import '../widgets/medicine_card.dart';
import '../widgets/mark_taken_button.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);
  static const _green = Color(0xFF34A853);

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  MedicationLogModel? _todayLog;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final log = await MedicationRepository.instance.getLogByDate(
        date: DateTime.now(),
      );
      setState(() => _todayLog = log);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllTaken() async {
    setState(() => _submitting = true);
    try {
      final updated = await MedicationRepository.instance.markAllTaken(
        takenAt: DateTime.now(),
      );
      setState(() => _todayLog = updated);
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

  Future<void> _markDrugTaken(MedicineLogEntry entry) async {
    try {
      final updated = await MedicationRepository.instance.markDrugTaken(
        drugName: entry.drugName,
        strength: entry.strength,
        takenAt: DateTime.now(),
      );
      setState(() => _todayLog = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  bool get _allTaken =>
      _todayLog != null &&
      _todayLog!.medicines.every((m) => m.status == 'Taken');

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
            onPressed: _loadToday,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _loadToday)
          : RefreshIndicator(
              onRefresh: _loadToday,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── DATE HEADER ───────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Medication",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formattedToday(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          if (_todayLog != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_todayLog!.takenCount} of ${_todayLog!.totalDrugCount} doses taken',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── DRUG LIST ─────────────────────
                    if (_todayLog != null) ...[
                      const Text(
                        'Drug Regimen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._todayLog!.medicines.map(
                        (m) => MedicineCard(
                          drugName: m.drugName,
                          strength: m.strength,
                          unit: m.unit,
                          numberToBeTaken: m.numberToBeTaken,
                          status: m.status,
                          onMarkTaken: m.isTaken
                              ? null
                              : () => _markDrugTaken(m),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── MARK ALL TAKEN ────────────────
                      MarkTakenButton(
                        isTaken: _allTaken,
                        isLoading: _submitting,
                        onPressed: _markAllTaken,
                        label: 'Mark as Taken',
                      ),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.medication_outlined,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No medication scheduled for today.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── INSTRUCTION BOX ───────────────
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
                              'Take your medicine with water after a meal. Contact your health center if you experience severe side effects.',
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

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
