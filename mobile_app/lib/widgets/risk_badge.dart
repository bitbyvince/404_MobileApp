import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RiskBadge extends StatelessWidget {
  final String level; // "Compliant" | "At Risk" | "Defaulter"
  const RiskBadge({super.key, required this.level});

  Color get _color {
    switch (level) {
      case 'Compliant':
        return AppColors.success;
      case 'At Risk':
        return AppColors.riskModerate;
      case 'Defaulter':
        return AppColors.critical;
      default:
        return AppColors.riskNone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
