import 'package:flutter/material.dart';

class DaysRemainingCard extends StatelessWidget {
  final int daysRemaining;
  final int totalDays;
  final double compliancePercentage;

  const DaysRemainingCard({
    super.key,
    required this.daysRemaining,
    required this.totalDays,
    required this.compliancePercentage,
  });

  double get _progress =>
      totalDays == 0 ? 0 : (1 - daysRemaining / totalDays).clamp(0.0, 1.0);

  Color get _complianceColor {
    if (compliancePercentage >= 80) return const Color(0xFF34A853);
    if (compliancePercentage >= 60) return const Color(0xFFFFA000);
    return const Color(0xFFE53935);
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
          // ── TOP ROW: Compliance + Days Left ─────────────
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'Compliance',
                  value: '${compliancePercentage.toStringAsFixed(0)}%',
                  valueColor: _complianceColor,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: _StatCell(
                  label: 'Days Left',
                  value: '$daysRemaining',
                  valueColor: const Color(0xFF1A73E8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── OVERALL PROGRESS ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OVERALL PROGRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A73E8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1A73E8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
