class AppointmentModel {
  final String appointmentId;
  final String patientId;
  final String tbCaseNumber;
  final String barangayId;
  final String healthCenterId;
  final String healthCenterName;
  final DateTime requestedAt;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String purpose;
  final String status;
  final String? confirmedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentModel({
    required this.appointmentId,
    required this.patientId,
    required this.tbCaseNumber,
    required this.barangayId,
    required this.healthCenterId,
    required this.healthCenterName,
    required this.requestedAt,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.purpose,
    required this.status,
    this.confirmedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── DERIVED ──────────────────────────────────────────────

  // Whether the appointment is still upcoming
  bool get isUpcoming => status == 'Pending' || status == 'Confirmed';

  // Whether the appointment has been confirmed by staff
  bool get isConfirmed => status == 'Confirmed';

  // Whether the appointment is pending confirmation
  bool get isPending => status == 'Pending';

  // Whether the appointment has been completed
  bool get isCompleted => status == 'Completed';

  // Whether the appointment was cancelled
  bool get isCancelled => status == 'Cancelled';

  // Whether the appointment can still be cancelled by the patient
  // Only Pending or Confirmed appointments can be cancelled
  bool get isCancellable => status == 'Pending' || status == 'Confirmed';

  // Whether the appointment is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  // Whether the scheduled date is in the past
  bool get isPast =>
      scheduledDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  // Status color key for appointment_status_badge.dart
  // 'pending' | 'confirmed' | 'completed' | 'cancelled'
  String get statusColorKey => status.toLowerCase();

  // Purpose icon key for appointment_card.dart
  String get purposeIconKey {
    switch (purpose) {
      case 'Follow-up':
        return 'follow_up';
      case 'Sputum Test':
        return 'sputum';
      case 'Emergency':
        return 'emergency';
      case 'Routine':
        return 'routine';
      default:
        return 'follow_up';
    }
  }

  // Formatted scheduled date + time for display
  // e.g. "January 10, 2025 at 09:00 AM"
  String get formattedSchedule {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = months[scheduledDate.month - 1];
    final day = scheduledDate.day;
    final year = scheduledDate.year;
    return '$month $day, $year at $scheduledTime';
  }

  // Days until appointment (negative if past)
  int get daysUntil => scheduledDate.difference(DateTime.now()).inDays;

  // ── FACTORY: FROM JSON ───────────────────────────────────
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointment_id'] as String,
      patientId: json['patient_id'] as String,
      tbCaseNumber: json['tb_case_number'] as String,
      barangayId: json['barangay_id'] as String,
      healthCenterId: json['health_center_id'] as String,
      healthCenterName: json['health_center_name'] as String,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] as String,
      purpose: json['purpose'] as String,
      status: json['status'] as String,
      confirmedBy: json['confirmed_by'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ── TO JSON ──────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'appointment_id': appointmentId,
    'patient_id': patientId,
    'tb_case_number': tbCaseNumber,
    'barangay_id': barangayId,
    'health_center_id': healthCenterId,
    'health_center_name': healthCenterName,
    'requested_at': requestedAt.toIso8601String(),
    'scheduled_date': scheduledDate.toIso8601String(),
    'scheduled_time': scheduledTime,
    'purpose': purpose,
    'status': status,
    'confirmed_by': confirmedBy,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // ── COPY WITH ────────────────────────────────────────────
  AppointmentModel copyWith({
    String? appointmentId,
    String? patientId,
    String? tbCaseNumber,
    String? barangayId,
    String? healthCenterId,
    String? healthCenterName,
    DateTime? requestedAt,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? purpose,
    String? status,
    String? confirmedBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      tbCaseNumber: tbCaseNumber ?? this.tbCaseNumber,
      barangayId: barangayId ?? this.barangayId,
      healthCenterId: healthCenterId ?? this.healthCenterId,
      healthCenterName: healthCenterName ?? this.healthCenterName,
      requestedAt: requestedAt ?? this.requestedAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModel &&
          runtimeType == other.runtimeType &&
          appointmentId == other.appointmentId;

  @override
  int get hashCode => appointmentId.hashCode;

  @override
  String toString() =>
      'AppointmentModel(appointmentId: $appointmentId, purpose: $purpose, '
      'scheduledDate: $scheduledDate, status: $status)';
}

// ── Appointment list result wrapper ─────────────────────
// Returned by appointment_repository.getPast()
class AppointmentListResult {
  final List<AppointmentModel> appointments;
  final bool hasMore;
  final int total;

  const AppointmentListResult({
    required this.appointments,
    required this.hasMore,
    required this.total,
  });

  factory AppointmentListResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AppointmentListResult(
      appointments: (data['appointments'] as List? ?? [])
          .map((a) => AppointmentModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      hasMore:
          ((data['page'] as int? ?? 1) * (data['limit'] as int? ?? 10)) <
          (data['total'] as int? ?? 0),
      total: data['total'] as int? ?? 0,
    );
  }
}
