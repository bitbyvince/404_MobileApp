import 'package:flutter/material.dart';

class MedicineCard extends StatelessWidget {
  final String drugName;
  final String strength;
  final String unit;
  final int numberToBeTaken;
  final String status;
  final bool isLoading;
  final VoidCallback? onMarkTaken;

  const MedicineCard({
    super.key,
    required this.drugName,
    required this.strength,
    required this.unit,
    required this.numberToBeTaken,
    required this.status,
    this.isLoading = false,
    this.onMarkTaken,
  });

  bool get _isTaken => status == 'Taken';
  bool get _isMissed => status == 'Missed';

  Color get _statusColor {
    if (_isTaken) return const Color(0xFF34A853);
    if (_isMissed) return const Color(0xFFE53935);
    return const Color(0xFF1A73E8);
  }

  Color get _bgColor {
    if (_isTaken) return const Color(0xFF34A853).withOpacity(0.07);
    if (_isMissed) return const Color(0xFFE53935).withOpacity(0.07);
    return const Color(0xFF1A73E8).withOpacity(0.07);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // ── DRUG ICON ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Rx',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── DRUG INFO ─────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$drugName $strength',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$numberToBeTaken $unit daily',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // ── STATUS / ACTION ───────────────────────────
          if (_isTaken)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF34A853),
              size: 26,
            )
          else if (_isMissed)
            const Icon(Icons.cancel_rounded, color: Color(0xFFE53935), size: 26)
          else
            GestureDetector(
              onTap: isLoading ? null : onMarkTaken,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Take',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
