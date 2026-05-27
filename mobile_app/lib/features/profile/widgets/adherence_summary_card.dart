import 'package:flutter/material.dart';

class AdherenceSummaryCard extends StatelessWidget {
  final int dosesTaken;
  final int dosesMissed;
  final int dosesRemaining;
  final double compliancePercentage;
  final int consecutiveMissedDoses;
  final String riskLevel;
  final int riskScore;
  final String adherence;

  const AdherenceSummaryCard({
    super.key,
    required this.dosesTaken,
    required this.dosesMissed,
    required this.dosesRemaining,
    required this.compliancePercentage,
    required this.consecutiveMissedDoses,
    required this.riskLevel,
    required this.riskScore,
    required this.adherence,
  });

  Color get _complianceColor {
    if (compliancePercentage >= 80) return const Color(0xFF34A853);
    if (compliancePercentage >= 60) return const Color(0xFFFFA000);
    return const Color(0xFFE53935);
  }

  Color get _riskColor {
    switch (riskLevel) {
      case 'Defaulter':
        return const Color(0xFFE53935);
      case 'At Risk':
        return const Color(0xFFFFA000);
      default:
        return const Color(0xFF34A853);
    }
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
          const Text(
            'Adherence Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 14),

          // ── COMPLIANCE RING + STATS ──────────────────────
          Row(
            children: [
              // Circular compliance indicator
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (compliancePercentage / 100).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _complianceColor,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${compliancePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _complianceColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Dose counters
              Expanded(
                child: Column(
                  children: [
                    _DoseRow(
                      label: 'Taken',
                      count: dosesTaken,
                      color: const Color(0xFF34A853),
                    ),
                    const SizedBox(height: 6),
                    _DoseRow(
                      label: 'Missed',
                      count: dosesMissed,
                      color: const Color(0xFFE53935),
                    ),
                    const SizedBox(height: 6),
                    _DoseRow(
                      label: 'Remaining',
                      count: dosesRemaining,
                      color: const Color(0xFF1A73E8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),

          // ── RISK + ADHERENCE ROW ─────────────────────────
          Row(
            children: [
              Expanded(
                child: _SummaryBadge(
                  label: 'Risk Level',
                  value: riskLevel,
                  color: _riskColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryBadge(
                  label: 'Adherence',
                  value: adherence,
                  color: adherence == 'Regular'
                      ? const Color(0xFF34A853)
                      : const Color(0xFFFFA000),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryBadge(
                  label: 'Risk Score',
                  value: '$riskScore / 100',
                  color: riskScore <= 30
                      ? const Color(0xFF34A853)
                      : riskScore <= 60
                      ? const Color(0xFFFFA000)
                      : const Color(0xFFE53935),
                ),
              ),
            ],
          ),

          if (consecutiveMissedDoses > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE53935).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE53935),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$consecutiveMissedDoses consecutive missed '
                      '${consecutiveMissedDoses == 1 ? 'dose' : 'doses'}. '
                      'Please take your medication.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DoseRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _DoseRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
