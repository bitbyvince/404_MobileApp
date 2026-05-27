import 'package:flutter/material.dart';

class StreakCard extends StatelessWidget {
  final int streakDays;
  final bool takenToday;

  const StreakCard({
    super.key,
    required this.streakDays,
    required this.takenToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              color: takenToday
                  ? const Color(0xFF34A853).withOpacity(0.12)
                  : Colors.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: takenToday ? const Color(0xFF34A853) : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays-Day Streak',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  takenToday
                      ? 'Great job! Medication taken today.'
                      : 'Don\'t break your streak — take today\'s dose.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (takenToday)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF34A853),
              size: 22,
            ),
        ],
      ),
    );
  }
}
