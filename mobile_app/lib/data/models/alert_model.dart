class AlertModel {
  final String alertId;
  final String? patientId;
  final String? tbCaseNumber;
  final String barangayId;
  final String alertType;
  final int escalationLevel;
  final String message;
  final String severity;
  final String status;
  final List<String> targetRoles;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const AlertModel({
    required this.alertId,
    this.patientId,
    this.tbCaseNumber,
    required this.barangayId,
    required this.alertType,
    required this.escalationLevel,
    required this.message,
    required this.severity,
    required this.status,
    required this.targetRoles,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  // ── DERIVED ──────────────────────────────────────────────

  // Whether this alert is still active
  bool get isActive => status == 'Active';

  // Whether this is an escalation-type alert
  bool get isEscalation => escalationLevel > 0;

  // Whether this is a stock-related alert
  bool get isStockAlert => alertType == 'Low Stock' || alertType == 'Stockout';

  // Whether this is a missed dose alert
  bool get isMissedDose => alertType == 'Missed Dose';

  // Severity color key for the UI layer
  // 'info' | 'warning' | 'critical'
  String get severityColorKey {
    switch (severity) {
      case 'Critical':
        return 'critical';
      case 'Warning':
        return 'warning';
      default:
        return 'info';
    }
  }

  // Escalation level label for display
  String get escalationLabel {
    switch (escalationLevel) {
      case 1:
        return 'Level 1 — Nurse Notified';
      case 2:
        return 'Level 2 — Barangay Admin Flagged';
      case 3:
        return 'Level 3 — Defaulter';
      default:
        return '';
    }
  }

  // Icon key for the UI layer
  // Maps to an icon in the widget layer
  String get iconKey {
    switch (alertType) {
      case 'Missed Dose':
      case 'Escalation L1':
      case 'Escalation L2':
      case 'Escalation L3':
        return 'missed_dose';
      case 'Low Stock':
        return 'low_stock';
      case 'Stockout':
        return 'stockout';
      case 'Sputum Test Due':
        return 'sputum';
      case 'Appointment Reminder':
        return 'appointment';
      default:
        return 'info';
    }
  }

  // ── FACTORY: FROM JSON ───────────────────────────────────
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alert_id'] as String,
      patientId: json['patient_id'] as String?,
      tbCaseNumber: json['tb_case_number'] as String?,
      barangayId: json['barangay_id'] as String,
      alertType: json['alert_type'] as String,
      escalationLevel: json['escalation_level'] as int? ?? 0,
      message: json['message'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      targetRoles: List<String>.from(json['target_roles'] as List? ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
    );
  }

  // ── TO JSON ──────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'alert_id': alertId,
    'patient_id': patientId,
    'tb_case_number': tbCaseNumber,
    'barangay_id': barangayId,
    'alert_type': alertType,
    'escalation_level': escalationLevel,
    'message': message,
    'severity': severity,
    'status': status,
    'target_roles': targetRoles,
    'created_at': createdAt.toIso8601String(),
    'resolved_at': resolvedAt?.toIso8601String(),
    'resolved_by': resolvedBy,
  };

  // ── COPY WITH ────────────────────────────────────────────
  AlertModel copyWith({
    String? alertId,
    String? patientId,
    String? tbCaseNumber,
    String? barangayId,
    String? alertType,
    int? escalationLevel,
    String? message,
    String? severity,
    String? status,
    List<String>? targetRoles,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) {
    return AlertModel(
      alertId: alertId ?? this.alertId,
      patientId: patientId ?? this.patientId,
      tbCaseNumber: tbCaseNumber ?? this.tbCaseNumber,
      barangayId: barangayId ?? this.barangayId,
      alertType: alertType ?? this.alertType,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      targetRoles: targetRoles ?? this.targetRoles,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertModel &&
          runtimeType == other.runtimeType &&
          alertId == other.alertId;

  @override
  int get hashCode => alertId.hashCode;

  @override
  String toString() =>
      'AlertModel(alertId: $alertId, type: $alertType, severity: $severity, status: $status)';
}
