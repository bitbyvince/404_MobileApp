import 'package:flutter/material.dart';
import 'sputum_test_card.dart';

class SputumTimelineItem {
  final int month;
  final String result;
  final String status;
  final String formattedDueDate;
  final bool isOverdue;
  final bool isCompleted;

  const SputumTimelineItem({
    required this.month,
    required this.result,
    required this.status,
    required this.formattedDueDate,
    required this.isOverdue,
    required this.isCompleted,
  });
}

class SputumTimeline extends StatelessWidget {
  final List<SputumTimelineItem> items;
  final void Function(int month) onItemTap;

  const SputumTimeline({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;
        return _TimelineRow(
          item: item,
          isLast: isLast,
          onTap: () => onItemTap(item.month),
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final SputumTimelineItem item;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineRow({
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  Color get _nodeColor {
    if (item.isCompleted) {
      return item.result == 'Negative'
          ? const Color(0xFF34A853)
          : const Color(0xFFE53935);
    }
    if (item.isOverdue) return const Color(0xFFE53935);
    return const Color(0xFFBDBDBD);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TIMELINE SPINE ───────────────────────────
            Column(
              children: [
                // Node circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _nodeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _nodeColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: item.isCompleted
                        ? Icon(
                            item.result == 'Negative'
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '${item.month}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade200),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // ── CONTENT ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
                child: SputumTestCard(
                  month: item.month,
                  result: item.result,
                  status: item.status,
                  formattedDueDate: item.formattedDueDate,
                  isOverdue: item.isOverdue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
