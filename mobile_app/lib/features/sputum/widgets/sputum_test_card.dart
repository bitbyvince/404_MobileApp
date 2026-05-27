import 'package:flutter/material.dart';
import 'result_badge.dart';

class SputumTestCard extends StatelessWidget {
  final int month;
  final String result;
  final String status;
  final String formattedDueDate;
  final bool isOverdue;
  final String? formattedCollectionDate;

  const SputumTestCard({
    super.key,
    required this.month,
    required this.result,
    required this.status,
    required this.formattedDueDate,
    required this.isOverdue,
    this.formattedCollectionDate,
  });

  Color get _cardColor {
    if (result == 'Negative') return const Color(0xFF34A853);
    if (result == 'Positive') return const Color(0xFFE53935);
    if (isOverdue) return const Color(0xFFE53935);
    return const Color(0xFF1A73E8);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Month $month Sputum Test',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              ResultBadge(result: result, isOverdue: isOverdue),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Due: $formattedDueDate',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          if (formattedCollectionDate != null) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  'Collected: $formattedCollectionDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
