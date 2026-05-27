import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final String senderName;
  final String message;
  final String relativeTime;
  final String type;
  final bool isRead;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.senderName,
    required this.message,
    required this.relativeTime,
    required this.type,
    required this.isRead,
    this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case 'Medication Reminder':
        return Icons.medication_outlined;
      case 'Appointment':
        return Icons.event_outlined;
      case 'Sputum Test':
        return Icons.science_outlined;
      case 'Alert':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (type) {
      case 'Alert':
        return const Color(0xFFE53935);
      case 'Medication Reminder':
        return const Color(0xFF34A853);
      case 'Appointment':
        return const Color(0xFF1A73E8);
      case 'Sputum Test':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? Colors.grey.shade200
                : const Color(0xFF1A73E8).withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ICON ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            // ── CONTENT ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relativeTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── UNREAD DOT ───────────────────────────────
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A73E8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
