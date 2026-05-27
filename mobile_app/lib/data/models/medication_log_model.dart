class MedicationLogModel {
  final String logId;
  final String patientId;
  final String tbCaseNumber;
  final String barangayId;
  final DateTime logDate;
  final DateTime loggedAt;
  final String loggedBy;
  final int treatmentDay;
  final List<MedicineLogEntry> medicines;
  final String overallStatus;
  final String? notes;
  final DateTime createdAt;

  const MedicationLogModel({
    required this.logId,
    required this.patientId,
    required this.tbCaseNumber,
    required this.barangayId,
    required this.logDate,
    required this.loggedAt,
    required this.loggedBy,
    required this.treatmentDay,
    required this.medicines,
    required this.overallStatus,
    this.notes,
    required this.createdAt,
  });

  // ── DERIVED ──────────────────────────────────────────────

  // Whether all drugs were taken
  bool get isFullyTaken => overallStatus == 'Taken';

  // Whether some drugs were taken
  bool get isPartial => overallStatus == 'Partial';

  // Whether no drugs were taken
  bool get isMissed => overallStatus == 'Missed';

  // Count of drugs taken
  int get takenCount => medicines.where((m) => m.status == 'Taken').length;

  // Count of drugs missed
  int get missedCount => medicines.where((m) => m.status == 'Missed').length;

  // Total number of drugs in the regimen
  int get totalDrugCount => medicines.length;

  // Whether a specific drug was taken today
  bool isDrugTaken(String drugName) =>
      medicines.any((m) => m.drugName == drugName && m.status == 'Taken');

  // Color key for compliance_calendar.dart
  // 'taken' | 'partial' | 'missed'
  String get calendarColorKey => overallStatus.toLowerCase();

  // Label for compliance calendar tooltip
  String get calendarLabel {
    switch (overallStatus) {
      case 'Taken':
        return 'All doses taken';
      case 'Partial':
        return '$takenCount of $totalDrugCount doses taken';
      case 'Missed':
        return 'No doses taken';
      default:
        return overallStatus;
    }
  }

  // ── FACTORY: FROM JSON ───────────────────────────────────
  factory MedicationLogModel.fromJson(Map<String, dynamic> json) {
    return MedicationLogModel(
      logId: json['log_id'] as String,
      patientId: json['patient_id'] as String,
      tbCaseNumber: json['tb_case_number'] as String,
      barangayId: json['barangay_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      loggedAt: DateTime.parse(json['logged_at'] as String),
      loggedBy: json['logged_by'] as String,
      treatmentDay: json['treatment_day'] as int,
      medicines: (json['medicines'] as List? ?? [])
          .map((m) => MedicineLogEntry.fromJson(m as Map<String, dynamic>))
          .toList(),
      overallStatus: json['overall_status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ── TO JSON ──────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'log_id': logId,
    'patient_id': patientId,
    'tb_case_number': tbCaseNumber,
    'barangay_id': barangayId,
    'log_date': logDate.toIso8601String(),
    'logged_at': loggedAt.toIso8601String(),
    'logged_by': loggedBy,
    'treatment_day': treatmentDay,
    'medicines': medicines.map((m) => m.toJson()).toList(),
    'overall_status': overallStatus,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  // ── COPY WITH ────────────────────────────────────────────
  MedicationLogModel copyWith({
    String? logId,
    String? patientId,
    String? tbCaseNumber,
    String? barangayId,
    DateTime? logDate,
    DateTime? loggedAt,
    String? loggedBy,
    int? treatmentDay,
    List<MedicineLogEntry>? medicines,
    String? overallStatus,
    String? notes,
    DateTime? createdAt,
  }) {
    return MedicationLogModel(
      logId: logId ?? this.logId,
      patientId: patientId ?? this.patientId,
      tbCaseNumber: tbCaseNumber ?? this.tbCaseNumber,
      barangayId: barangayId ?? this.barangayId,
      logDate: logDate ?? this.logDate,
      loggedAt: loggedAt ?? this.loggedAt,
      loggedBy: loggedBy ?? this.loggedBy,
      treatmentDay: treatmentDay ?? this.treatmentDay,
      medicines: medicines ?? this.medicines,
      overallStatus: overallStatus ?? this.overallStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationLogModel &&
          runtimeType == other.runtimeType &&
          logId == other.logId;

  @override
  int get hashCode => logId.hashCode;

  @override
  String toString() =>
      'MedicationLogModel(logId: $logId, logDate: $logDate, '
      'overallStatus: $overallStatus, takenCount: $takenCount/$totalDrugCount)';
}

// ── Individual drug entry within a log ──────────────────
class MedicineLogEntry {
  final String drugName;
  final String strength;
  final String unit;
  final int numberToBeTaken;
  final String status;
  final DateTime? takenAt;

  const MedicineLogEntry({
    required this.drugName,
    required this.strength,
    required this.unit,
    required this.numberToBeTaken,
    required this.status,
    this.takenAt,
  });

  // Whether this specific drug was taken
  bool get isTaken => status == 'Taken';

  // Whether this specific drug was missed
  bool get isMissed => status == 'Missed';

  // Display label combining drug name and strength
  // e.g. "Isoniazid 300mg"
  String get displayLabel => '$drugName $strength';

  // Status color key for medicine_card.dart
  // 'taken' | 'missed' | 'partial'
  String get statusColorKey => status.toLowerCase();

  factory MedicineLogEntry.fromJson(Map<String, dynamic> json) {
    return MedicineLogEntry(
      drugName: json['drug_name'] as String,
      strength: json['strength'] as String,
      unit: json['unit'] as String,
      numberToBeTaken: json['number_to_be_taken'] as int,
      status: json['status'] as String,
      takenAt: json['taken_at'] != null
          ? DateTime.parse(json['taken_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'drug_name': drugName,
    'strength': strength,
    'unit': unit,
    'number_to_be_taken': numberToBeTaken,
    'status': status,
    'taken_at': takenAt?.toIso8601String(),
  };

  MedicineLogEntry copyWith({
    String? drugName,
    String? strength,
    String? unit,
    int? numberToBeTaken,
    String? status,
    DateTime? takenAt,
  }) {
    return MedicineLogEntry(
      drugName: drugName ?? this.drugName,
      strength: strength ?? this.strength,
      unit: unit ?? this.unit,
      numberToBeTaken: numberToBeTaken ?? this.numberToBeTaken,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineLogEntry &&
          runtimeType == other.runtimeType &&
          drugName == other.drugName &&
          strength == other.strength;

  @override
  int get hashCode => drugName.hashCode ^ strength.hashCode;

  @override
  String toString() =>
      'MedicineLogEntry(drug: $drugName $strength, status: $status)';
}

// ── Medication history result wrapper ───────────────────
// Returned by medication_repository.getHistory()
class MedicationHistoryResult {
  final List<MedicationLogModel> logs;
  final bool hasMore;
  final int total;

  const MedicationHistoryResult({
    required this.logs,
    required this.hasMore,
    required this.total,
  });

  factory MedicationHistoryResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MedicationHistoryResult(
      logs: (data['logs'] as List? ?? [])
          .map((l) => MedicationLogModel.fromJson(l as Map<String, dynamic>))
          .toList(),
      hasMore:
          ((data['page'] as int? ?? 1) * (data['limit'] as int? ?? 30)) <
          (data['total'] as int? ?? 0),
      total: data['total'] as int? ?? 0,
    );
  }
}
