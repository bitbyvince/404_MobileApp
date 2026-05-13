// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Mark all as read
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
      body: _NotificationsList(),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  Future<String?> _getUserId() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'mongo_user_id');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserId(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final userId = snap.data!;

        // ── Real-time stream from Firestore notification_logs ──
        // Filters to this user's notifications, ordered newest first
        final stream = FirebaseFirestore.instance
            .collection('notification_logs')
            .where('mongo_user_id', isEqualTo: userId)
            .orderBy('sent_at', descending: true)
            .limit(50)
            .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _EmptyNotifications();
            }

            final docs = snapshot.data!.docs;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _NotificationCard(data: data);
              },
            );
          },
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NotificationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['notification_type'] as String? ?? '';
    final title = data['title'] as String? ?? 'Alert';
    final body = data['body'] as String? ?? '';
    final status = data['status'] as String? ?? 'sent';
    final sentAt = data['sent_at'] as Timestamp?;

    final isGeofence = type == 'geofence_alert';
    final color = isGeofence ? AppColors.critical : AppColors.warning;
    final icon = isGeofence
        ? Icons.location_on_rounded
        : Icons.medical_information_outlined;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),

          // ── Content ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: color,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Severity pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isGeofence ? 'Critical' : 'Warning',
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      sentAt != null
                          ? _formatDate(sentAt.toDate())
                          : 'Just now',
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    // "Click to message" action for geofence alerts
                    if (isGeofence)
                      GestureDetector(
                        onTap: () {
                          // TODO: Open health center contact
                        },
                        child: Text(
                          'Click to message →',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('No notifications yet', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            "You'll be alerted when TB activity is detected near you.",
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
