// ─── notification_log.model.dart ─────────────────────────────────────────────

class NotificationLog {
  final String id;
  final String mongoUserId;
  final RecipientType recipientType;
  final NotificationChannel channel;
  final NotificationType notificationType;
  final String title;
  final String body;
  final String? fcmToken;
  final String? geofenceAlertId;
  final String? mongoPatientId;
  final String? mongoAlertId;
  final NotificationStatus status;
  final String? errorMessage;
  final DateTime sentAt;

  NotificationLog({
    required this.id,
    required this.mongoUserId,
    required this.recipientType,
    required this.channel,
    required this.notificationType,
    required this.title,
    required this.body,
    this.fcmToken,
    this.geofenceAlertId,
    this.mongoPatientId,
    this.mongoAlertId,
    required this.status,
    this.errorMessage,
    required this.sentAt,
  });

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      id: json['id'] as String,
      mongoUserId: json['mongo_user_id'] as String,
      recipientType: RecipientType.fromString(json['recipient_type'] as String),
      channel: NotificationChannel.fromString(json['channel'] as String),
      notificationType: NotificationType.fromString(
        json['notification_type'] as String,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      fcmToken: json['fcm_token'] as String?,
      geofenceAlertId: json['geofence_alert_id'] as String?,
      mongoPatientId: json['mongo_patient_id'] as String?,
      mongoAlertId: json['mongo_alert_id'] as String?,
      status: NotificationStatus.fromString(json['status'] as String),
      errorMessage: json['error_message'] as String?,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mongo_user_id': mongoUserId,
    'recipient_type': recipientType.value,
    'channel': channel.value,
    'notification_type': notificationType.value,
    'title': title,
    'body': body,
    'fcm_token': fcmToken,
    'geofence_alert_id': geofenceAlertId,
    'mongo_patient_id': mongoPatientId,
    'mongo_alert_id': mongoAlertId,
    'status': status.value,
    'error_message': errorMessage,
    'sent_at': sentAt.toIso8601String(),
  };

  bool get isFailed => status == NotificationStatus.failed;
  bool get isSent => status == NotificationStatus.sent;
  bool get isPending => status == NotificationStatus.pending;
}

enum RecipientType {
  publicUser('public_user'),
  nurse('nurse');

  const RecipientType(this.value);
  final String value;

  static RecipientType fromString(String value) {
    return RecipientType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecipientType.publicUser,
    );
  }
}

enum NotificationChannel {
  fcmPush('fcm_push'),
  sms('sms');

  const NotificationChannel(this.value);
  final String value;

  static NotificationChannel fromString(String value) {
    return NotificationChannel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationChannel.fcmPush,
    );
  }
}

enum NotificationType {
  geofenceAlert('geofence_alert'),
  missedDose('missed_dose'),
  otp('otp'),
  system('system');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

enum NotificationStatus {
  sent('sent'),
  failed('failed'),
  pending('pending');

  const NotificationStatus(this.value);
  final String value;

  static NotificationStatus fromString(String value) {
    return NotificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationStatus.pending,
    );
  }
}
