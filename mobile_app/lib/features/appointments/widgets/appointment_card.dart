import 'package:flutter/material.dart';
import 'appointment_status_badge.dart';

class AppointmentCard extends StatelessWidget {
  final String purpose;
  final String scheduledDate;
  final String scheduledTime;
  final String healthCenterName;
  final String status;
  final bool isToday;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const AppointmentCard({
    super.key,
    required this.purpose,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.healthCenterName,
    required this.status,
    this.isToday = false,
    this.onTap,
    this.onCancel,
  });

  Color get _statusColor {
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

  IconData get _purposeIcon {
    switch (purpose) {
      case 'Sputum Test':
        return Icons.science_outlined;
      case 'Emergency':
        return Icons.emergency_outlined;
      case 'Routine':
        return Icons.calendar_today_outlined;
      default:
        return Icons.medical_services_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isToday
              ? Border.all(
                  color: const Color(0xFF1A73E8).withOpacity(0.4),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_purposeIcon, color: _statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          purpose,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      AppointmentStatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$scheduledDate at $scheduledTime',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          healthCenterName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (status == 'Pending' || status == 'Confirmed')
              IconButton(
                icon: Icon(
                  Icons.cancel_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: onCancel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
