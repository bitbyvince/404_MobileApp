import 'package:flutter/material.dart';

class TreatmentInfoCard extends StatelessWidget {
  final String treatmentPhase;
  final String regimenType;
  final String datSupport;
  final String locationOfTreatment;
  final DateTime dateStarted;
  final DateTime endDate;
  final double progress;

  const TreatmentInfoCard({
    super.key,
    required this.treatmentPhase,
    required this.regimenType,
    required this.datSupport,
    required this.locationOfTreatment,
    required this.dateStarted,
    required this.endDate,
    required this.progress,
  });

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

  Color get _phaseColor => treatmentPhase == 'Intensive'
      ? const Color(0xFFE53935)
      : const Color(0xFF34A853);

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
                'Treatment Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _phaseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  treatmentPhase,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _phaseColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── DETAILS GRID ─────────────────────────────────
          _DetailRow(
            icon: Icons.medication_outlined,
            label: 'Regimen',
            value: regimenType,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.remove_red_eye_outlined,
            label: 'DAT Support',
            value: datSupport,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Treatment Location',
            value: locationOfTreatment,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.date_range_outlined,
            label: 'Duration',
            value: '${_formatDate(dateStarted)} – ${_formatDate(endDate)}',
          ),
          const SizedBox(height: 14),

          // ── PROGRESS ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A73E8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    );
  }
}
