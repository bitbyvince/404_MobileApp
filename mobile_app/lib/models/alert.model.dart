// ─── alert.model.dart ─────────────────────────────────────────────────────────

class Alert {
  final String id;
  final String patientId;
  final String nurseId;
  final AlertType alertType;
  final AlertSeverity severity;
  final String message;
  final bool isRead;
  final String? actionLink;
  final DateTime createdAt;

  Alert({
    required this.id,
    required this.patientId,
    required this.nurseId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.isRead,
    this.actionLink,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['_id'] as String,
      patientId: json['patient_id'] as String,
      nurseId: json['nurse_id'] as String,
      alertType: AlertType.fromString(json['alert_type'] as String),
      severity: AlertSeverity.fromString(json['severity'] as String),
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      actionLink: json['action_link'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'patient_id': patientId,
    'nurse_id': nurseId,
    'alert_type': alertType.value,
    'severity': severity.value,
    'message': message,
    'is_read': isRead,
    'action_link': actionLink,
    'created_at': createdAt.toIso8601String(),
  };

  Alert copyWith({bool? isRead}) => Alert(
    id: id,
    patientId: patientId,
    nurseId: nurseId,
    alertType: alertType,
    severity: severity,
    message: message,
    isRead: isRead ?? this.isRead,
    actionLink: actionLink,
    createdAt: createdAt,
  );
}

enum AlertType {
  missedDose('Missed Dose'),
  defaulterRisk('Defaulter Risk'),
  lowStock('Low Stock'),
  nonCompliance('Non-Compliance'),
  other('Other');

  const AlertType(this.value);
  final String value;

  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AlertType.other,
    );
  }
}

enum AlertSeverity {
  critical('Critical'),
  warning('Warning'),
  info('Info');

  const AlertSeverity(this.value);
  final String value;

  static AlertSeverity fromString(String value) {
    return AlertSeverity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AlertSeverity.info,
    );
  }
}
