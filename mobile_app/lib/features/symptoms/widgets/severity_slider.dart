import 'package:flutter/material.dart';

class SeveritySlider extends StatelessWidget {
  final String symptom;
  final int severity;
  final void Function(String symptom, int severity) onChanged;

  const SeveritySlider({
    super.key,
    required this.symptom,
    required this.severity,
    required this.onChanged,
  });

  Color get _severityColor {
    switch (severity) {
      case 3:
        return const Color(0xFFE53935);
      case 2:
        return const Color(0xFFFFA000);
      default:
        return const Color(0xFF34A853);
    }
  }

  String get _severityLabel {
    switch (severity) {
      case 3:
        return 'Severe';
      case 2:
        return 'Moderate';
      default:
        return 'Mild';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _severityColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _severityColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                symptom,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _severityLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _severityColor,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: _severityColor,
              inactiveTrackColor: _severityColor.withOpacity(0.2),
              thumbColor: _severityColor,
              overlayColor: _severityColor.withOpacity(0.15),
            ),
            child: Slider(
              value: severity.toDouble(),
              min: 1,
              max: 3,
              divisions: 2,
              onChanged: (val) => onChanged(symptom, val.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mild', 'Moderate', 'Severe']
                .map(
                  (l) => Text(
                    l,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
