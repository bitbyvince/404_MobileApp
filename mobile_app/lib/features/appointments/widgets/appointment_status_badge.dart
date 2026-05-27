import 'package:flutter/material.dart';

class AppointmentStatusBadge extends StatelessWidget {
  final String status;

  const AppointmentStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFF34A853);
      case 'Pending':
        return const Color(0xFFFFA000);
      case 'Completed':
        return const Color(0xFF1A73E8);
      case 'Cancelled':
        return Colors.grey;
      default:
        return const Color(0xFFFFA000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
