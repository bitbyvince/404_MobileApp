import 'package:flutter/material.dart';
import '../../../data/repositories/sputum_repository.dart';
import '../../../data/models/sputum_test_model.dart';
import '../widgets/sputum_timeline.dart';
import '../widgets/sputum_test_card.dart';
import '../widgets/result_badge.dart';

class SputumScreen extends StatefulWidget {
  const SputumScreen({super.key});

  @override
  State<SputumScreen> createState() => _SputumScreenState();
}

class _SputumScreenState extends State<SputumScreen> {
  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);
  static const _green = Color(0xFF34A853);

  bool _loading = true;
  String? _error;
  List<SputumTestModel> _tests = [];
  SputumTestModel? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SputumRepository.instance.getMyTests();
      list.sort((a, b) => a.month.compareTo(b.month));
      setState(() => _tests = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<SputumTimelineItem> get _timelineItems {
    return [2, 5, 6].map((month) {
      final test = _tests.firstWhere(
        (t) => t.month == month,
        orElse: () => SputumTestModel.placeholder(month: month),
      );
      final isCompleted = test.result != null && test.result != 'Pending';
      final isOverdue = test.isOverdue;
      return SputumTimelineItem(
        month: month,
        result: test.result ?? 'Pending',
        status: isCompleted
            ? (test.result == 'Negative'
                  ? 'completed_negative'
                  : 'completed_positive')
            : isOverdue
            ? 'overdue'
            : 'pending',
        formattedDueDate: test.formattedDueDate,
        isCompleted: isCompleted,
        isOverdue: isOverdue,
      );
    }).toList();
  }

  SputumTestModel? get _nextTest {
    final today = DateTime.now();
    final pending = _tests
        .where(
          (t) =>
              (t.result == null || t.result == 'Pending') &&
              t.dueDate.isAfter(today),
        )
        .toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.first;
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
          'Sputum Tests',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HEADER ──────────────────────
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
                            'Sputum Test Tracker',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'WHO standard checkpoints: Month 2, 5, and 6',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          if (_nextTest != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Next test in ${_nextTest!.daysUntilDue} days — ${_nextTest!.formattedDueDate}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── PROGRESS SUMMARY ────────────
                    Row(
                      children: [
                        _ProgressChip(
                          label: 'Completed',
                          count: _tests
                              .where(
                                (t) =>
                                    t.result != null && t.result != 'Pending',
                              )
                              .length,
                          color: _green,
                        ),
                        const SizedBox(width: 8),
                        _ProgressChip(
                          label: 'Pending',
                          count: _tests
                              .where(
                                (t) =>
                                    t.result == null || t.result == 'Pending',
                              )
                              .length,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        _ProgressChip(
                          label: 'Overdue',
                          count: _tests.where((t) => t.isOverdue).length,
                          color: const Color(0xFFE53935),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── TIMELINE ────────────────────
                    const Text(
                      'Test Timeline',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SputumTimeline(
                      items: _timelineItems,
                      onItemTap: (month) {
                        final test = _tests.firstWhere(
                          (t) => t.month == month,
                          orElse: () =>
                              SputumTestModel.placeholder(month: month),
                        );
                        setState(() => _selected = test);
                      },
                    ),

                    // ── SELECTED DETAIL ─────────────
                    if (_selected != null && !_selected!.isPlaceholder) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Test Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SputumTestCard(
                        month: _selected!.month,
                        result: _selected!.result ?? 'Pending',
                        status: _selected!.result ?? 'Pending',
                        formattedDueDate: _selected!.formattedDueDate,
                        isOverdue: _selected!.isOverdue,
                        formattedCollectionDate:
                            _selected!.formattedCollectionDate,
                      ),
                      if (_selected!.notes != null &&
                          _selected!.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selected!.notes!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ProgressChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
