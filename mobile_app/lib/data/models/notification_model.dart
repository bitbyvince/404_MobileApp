class NotificationModel {
  final String notificationId;
  final String recipientId;
  final String firebaseUid;
  final String type;
  final String title;
  final String body;
  final String? relatedId;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.firebaseUid,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    required this.isRead,
    required this.sentAt,
    this.readAt,
    required this.createdAt,
  });

  // ── DERIVED ──────────────────────────────────────────────

  // Whether this notification is unread
  bool get isUnread => !isRead;

  // Whether this notification is a medication reminder
  bool get isMedicationReminder => type == 'Medication Reminder';

  // Whether this notification is an appointment reminder
  bool get isAppointmentReminder => type == 'Appointment';

  // Whether this notification is a sputum test reminder
  bool get isSputumReminder => type == 'Sputum Test';

  // Whether this notification is an alert
  bool get isAlert => type == 'Alert';

  // Whether this notification is an OTP notification
  bool get isOtp => type == 'OTP';

  // How long ago this notification was sent
  // Returns a human-readable relative time string
  // e.g. 'Just now' | '5 minutes ago' | '2 hours ago' | 'Yesterday' | 'Jan 3'
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(sentAt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    // Fall back to formatted date for older notifications
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[sentAt.month - 1]} ${sentAt.day}';
  }

  // Whether this notification was sent today
  bool get isToday {
    final now = DateTime.now();
    return sentAt.year == now.year &&
        sentAt.month == now.month &&
        sentAt.day == now.day;
  }

  // Whether this notification was sent yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return sentAt.year == yesterday.year &&
        sentAt.month == yesterday.month &&
        sentAt.day == yesterday.day;
  }

  // Icon key for notification_tile.dart
  String get iconKey {
    switch (type) {
      case 'Medication Reminder':
        return 'medication';
      case 'Appointment':
        return 'appointment';
      case 'Sputum Test':
        return 'sputum';
      case 'Alert':
        return 'alert';
      case 'OTP':
        return 'otp';
      default:
        return 'info';
    }
  }

  // Color key for notification_tile.dart
  // Unread notifications are visually highlighted
  String get colorKey {
    if (isUnread) {
      switch (type) {
        case 'Alert':
          return 'unread_alert';
        case 'Medication Reminder':
          return 'unread_medication';
        default:
          return 'unread_default';
      }
    }
    return 'read';
  }

  // Route this notification should navigate to on tap
  // Used by notification_provider.resolveNotificationRoute()
  String get targetRoute {
    switch (type) {
      case 'Medication Reminder':
        return '/medication';
      case 'Appointment':
        return '/appointments';
      case 'Sputum Test':
        return '/sputum';
      case 'Alert':
        return '/notifications';
      default:
        return '/notifications';
    }
  }

  // ── FACTORY: FROM JSON ───────────────────────────────────
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId:
          json['_id'] as String? ?? json['notification_id'] as String,
      recipientId: json['recipient_id'] as String,
      firebaseUid: json['firebase_uid'] as String? ?? '',
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      relatedId: json['related_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      sentAt: DateTime.parse(json['sent_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ── FACTORY: FROM FCM PAYLOAD ────────────────────────────
  // Builds a NotificationModel from a Firebase Cloud Messaging
  // message payload received in the foreground
  factory NotificationModel.fromFcmPayload(Map<String, dynamic> payload) {
    final notification = payload['notification'] as Map<String, dynamic>? ?? {};
    final data = payload['data'] as Map<String, dynamic>? ?? {};

    return NotificationModel(
      notificationId:
          data['notification_id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      recipientId: data['recipient_id'] as String? ?? '',
      firebaseUid: data['firebase_uid'] as String? ?? '',
      type: data['type'] as String? ?? 'Info',
      title: notification['title'] as String? ?? data['title'] as String? ?? '',
      body: notification['body'] as String? ?? data['body'] as String? ?? '',
      relatedId: data['related_id'] as String?,
      isRead: false,
      sentAt: DateTime.now(),
      readAt: null,
      createdAt: DateTime.now(),
    );
  }

  // ── TO JSON ──────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'notification_id': notificationId,
    'recipient_id': recipientId,
    'firebase_uid': firebaseUid,
    'type': type,
    'title': title,
    'body': body,
    'related_id': relatedId,
    'is_read': isRead,
    'sent_at': sentAt.toIso8601String(),
    'read_at': readAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  // ── COPY WITH ────────────────────────────────────────────
  NotificationModel copyWith({
    String? notificationId,
    String? recipientId,
    String? firebaseUid,
    String? type,
    String? title,
    String? body,
    String? relatedId,
    bool? isRead,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      recipientId: recipientId ?? this.recipientId,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          notificationId == other.notificationId;

  @override
  int get hashCode => notificationId.hashCode;

  @override
  String toString() =>
      'NotificationModel(id: $notificationId, type: $type, '
      'title: $title, isRead: $isRead)';
}

// ── Notification list result wrapper ────────────────────
// Returned by notification_repository.getNotifications()
class NotificationListResult {
  final List<NotificationModel> notifications;
  final bool hasMore;
  final int total;
  final int unreadCount;

  const NotificationListResult({
    required this.notifications,
    required this.hasMore,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return NotificationListResult(
      notifications: (data['notifications'] as List? ?? [])
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList(),
      hasMore:
          ((data['page'] as int? ?? 1) * (data['limit'] as int? ?? 20)) <
          (data['total'] as int? ?? 0),
      total: data['total'] as int? ?? 0,
      unreadCount: data['unread_count'] as int? ?? 0,
    );
  }
}
