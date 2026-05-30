import 'package:flutter/material.dart';

class TodayChecklistCard extends StatelessWidget {
  final String medicationName;
  final String instruction;
  final bool isTaken;
  final bool isLoading;
  final DateTime date;
  final int stockDoses;
  final VoidCallback onMarkTaken;

  const TodayChecklistCard({
    super.key,
    required this.medicationName,
    required this.instruction,
    required this.isTaken,
    required this.isLoading,
    required this.date,
    required this.stockDoses,
    required this.onMarkTaken,
  });

  String get _formattedDate {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Medication',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                _formattedDate,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── MEDICINE ITEM ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isTaken
                  ? const Color(0xFF34A853).withOpacity(0.08)
                  : const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isTaken
                    ? const Color(0xFF34A853).withOpacity(0.3)
                    : const Color(0xFF1A73E8).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isTaken
                        ? const Color(0xFF34A853)
                        : const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Rx',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicationName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        instruction,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTaken)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34A853),
                    size: 22,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── MARK AS TAKEN BUTTON ─────────────────────────
          SizedBox(
            width: double.infinity,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isTaken
                  ? Container(
                      key: const ValueKey('taken'),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF34A853).withOpacity(0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Color(0xFF34A853),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Taken Today',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF34A853),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      key: const ValueKey('not_taken'),
                      onPressed: isLoading ? null : onMarkTaken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Mark as Taken',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


