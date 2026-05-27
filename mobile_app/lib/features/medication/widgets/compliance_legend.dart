import 'package:flutter/material.dart';

class ComplianceLegend extends StatelessWidget {
  const ComplianceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendItem(
          color: Color(0xFF34A853),
          icon: Icons.check_rounded,
          label: 'Taken',
        ),
        SizedBox(width: 16),
        _LegendItem(
          color: Color(0xFFE53935),
          icon: Icons.close_rounded,
          label: 'Missed',
        ),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFFBDBDBD), label: 'Pending'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String label;

  const _LegendItem({required this.color, this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 12)
              : null,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
