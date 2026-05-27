import 'package:flutter/material.dart';

class SputumCountdownCard extends StatelessWidget {
  final int daysUntilTest;
  final int testMonth;
  final DateTime? dueDate;
  final bool noTestScheduled;

  const SputumCountdownCard({
    super.key,
    required this.daysUntilTest,
    required this.testMonth,
    this.dueDate,
    this.noTestScheduled = false,
  });

  Color get _urgencyColor {
    if (noTestScheduled) return Colors.grey;
    if (daysUntilTest <= 3) return const Color(0xFFE53935);
    if (daysUntilTest <= 7) return const Color(0xFFFFA000);
    return const Color(0xFF1A73E8);
  }

  String get _urgencyLabel {
    if (noTestScheduled) return 'All tests completed';
    if (daysUntilTest == 0) return 'Due today';
    if (daysUntilTest < 0) return 'Overdue';
    if (daysUntilTest == 1) return 'Due tomorrow';
    return 'Days until Month $testMonth Sputum Test';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _urgencyColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.science_outlined, color: _urgencyColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _urgencyLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                noTestScheduled
                    ? const Text(
                        'No upcoming sputum tests',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            daysUntilTest < 0
                                ? '${daysUntilTest.abs()}'
                                : '$daysUntilTest',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _urgencyColor,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3, left: 4),
                            child: Text(
                              daysUntilTest < 0 ? 'days overdue' : 'days',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          if (!noTestScheduled && dueDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(dueDate!),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _urgencyColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Month $testMonth',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _urgencyColor,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
