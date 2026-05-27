import 'package:flutter/material.dart';

class ResultBadge extends StatelessWidget {
  final String? result;
  final bool isOverdue;

  const ResultBadge({super.key, this.result, this.isOverdue = false});

  String get _label {
    if (isOverdue && (result == null || result == 'Pending')) {
      return 'Overdue';
    }
    return result ?? 'Pending';
  }

  Color get _color {
    if (isOverdue && (result == null || result == 'Pending')) {
      return const Color(0xFFE53935);
    }
    switch (result) {
      case 'Negative':
        return const Color(0xFF34A853);
      case 'Positive':
        return const Color(0xFFE53935);
      case 'Not Done':
        return const Color(0xFFFFA000);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get _icon {
    if (isOverdue && (result == null || result == 'Pending')) {
      return Icons.warning_amber_rounded;
    }
    switch (result) {
      case 'Negative':
        return Icons.check_circle_rounded;
      case 'Positive':
        return Icons.cancel_rounded;
      case 'Not Done':
        return Icons.remove_circle_outlined;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
