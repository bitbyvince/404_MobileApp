import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Nurse Clara',
        'message': 'Remember to take your medicine with a meal today.',
        'time': '10:30 AM',
        'icon': Icons.mail,
        'iconColor': const Color(0xFF0066FF),
      },
      {
        'title': 'Health Center',
        'message': 'Your next check-up is scheduled for next Monday at 9:00 AM.',
        'time': 'Yesterday',
        'icon': Icons.mail,
        'iconColor': const Color(0xFF0066FF),
      },
      {
        'title': 'System',
        'message': 'Great job! You have reached 80% compliance this week.',
        'time': '2 days ago',
        'icon': Icons.info,
        'iconColor': Colors.grey[400],
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Header
              const Text(
                'Notification',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              // Notifications List
              ...notifications.asMap().entries.map((entry) {
                int index = entry.key;
                Map notification = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index != notifications.length - 1 ? 16 : 40,
                  ),
                  child: _buildNotificationCard(
                    title: notification['title'] as String,
                    message: notification['message'] as String,
                    time: notification['time'] as String,
                    icon: notification['icon'] as IconData,
                    iconColor: notification['iconColor'] as Color,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Time Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              // Time
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Message
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

