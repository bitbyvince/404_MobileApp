import 'package:flutter/material.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/models/notification_model.dart';
import '../widgets/notification_tile.dart';
import '../widgets/notification_preferences_sheet.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);

  bool _loading = true;
  String? _error;
  List<NotificationModel> _items = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await NotificationRepository.instance.getNotifications(
        page: 1,
        limit: 30,
      );
      final count = await NotificationRepository.instance.getUnreadCount();
      setState(() {
        _items = res.notifications;
        _unreadCount = count;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(NotificationModel n) async {
    if (n.isRead) return;
    try {
      await NotificationRepository.instance.markAsRead(n.notificationId);
      setState(() {
        final idx = _items.indexWhere(
          (i) => i.notificationId == n.notificationId,
        );
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationRepository.instance.markAllAsRead();
      setState(() {
        _items = _items
            .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
            .toList();
        _unreadCount = 0;
      });
    } catch (_) {}
  }

  void _showPreferences() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotificationPreferencesSheet(
        medicationReminder: true,
        appointmentReminder: true,
        sputumReminder: true,
        alertsEnabled: true,
        reminderHour: 8,
        reminderMinute: 0,
        onSave:
            ({
              medicationReminder,
              appointmentReminder,
              sputumReminder,
              alerts,
              reminderHour,
              reminderMinute,
            }) async {
              try {
                await NotificationRepository.instance.savePreferences(
                  medicationReminder: medicationReminder ?? true,
                  appointmentReminder: appointmentReminder ?? true,
                  sputumReminder: sputumReminder ?? true,
                  alerts: alerts ?? true,
                  reminderHour: reminderHour ?? 8,
                  reminderMinute: reminderMinute ?? 0,
                );
              } catch (_) {}
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            Text(
              'Stay updated with your treatment reminders',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showPreferences,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return NotificationTile(
                    senderName: item.title,
                    message: item.body,
                    relativeTime: item.relativeTime,
                    type: item.type,
                    isRead: item.isRead,
                    onTap: () => _markAsRead(item),
                  );
                },
              ),
            ),
    );
  }
}
