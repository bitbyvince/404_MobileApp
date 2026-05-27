class SymptomLogModel {
  final String logId;
  final String patientId;
  final String tbCaseNumber;
  final String barangayId;
  final DateTime loggedAt;
  final List<SymptomEntry> symptoms;
  final String freeTextNotes;
  final bool isReviewed;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const SymptomLogModel({
    required this.logId,
    required this.patientId,
    required this.tbCaseNumber,
    required this.barangayId,
    required this.loggedAt,
    required this.symptoms,
    required this.freeTextNotes,
    required this.isReviewed,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  // ── DERIVED ──────────────────────────────────────────────

  // Whether this log has any symptoms
  bool get hasSymptoms => symptoms.isNotEmpty;

  // Whether this log has free text notes
  bool get hasNotes => freeTextNotes.isNotEmpty;

  // Whether this log has not yet been reviewed by staff
  bool get isUnreviewed => !isReviewed;

  // Total number of symptoms in this log
  int get symptomCount => symptoms.length;

  // Highest severity in this log (1=Mild, 2=Moderate, 3=Severe)
  int get highestSeverity {
    if (symptoms.isEmpty) return 0;
    return symptoms.map((s) => s.severity).reduce((a, b) => a > b ? a : b);
  }

  // Whether any symptom in this log is severe
  bool get hasSevereSymptom => symptoms.any((s) => s.severity == 3);

  // Whether any symptom in this log is moderate or severe
  bool get hasModerateOrSevereSymptom => symptoms.any((s) => s.severity >= 2);

  // Count of severe symptoms
  int get severeSymptomCount => symptoms.where((s) => s.severity == 3).length;

  // Severity label for the overall log
  // Based on highest severity present
  String get overallSeverityLabel {
    switch (highestSeverity) {
      case 3:
        return 'Severe';
      case 2:
        return 'Moderate';
      case 1:
        return 'Mild';
      default:
        return 'None';
    }
  }

  // Severity color key for symptom_history_tile.dart
  // 'severe' | 'moderate' | 'mild' | 'none'
  String get severityColorKey {
    switch (highestSeverity) {
      case 3:
        return 'severe';
      case 2:
        return 'moderate';
      case 1:
        return 'mild';
      default:
        return 'none';
    }
  }

  // Short summary string for symptom_history_tile.dart
  // e.g. "Nausea, Joint Pain +1 more"
  String get summarySentence {
    if (symptoms.isEmpty) return 'No symptoms logged';
    if (symptoms.length == 1) return symptoms.first.symptom;
    if (symptoms.length == 2) {
      return '${symptoms[0].symptom}, ${symptoms[1].symptom}';
    }
    return '${symptoms[0].symptom}, ${symptoms[1].symptom} '
        '+${symptoms.length - 2} more';
  }

  // Whether this log was made today
  bool get isToday {
    final now = DateTime.now();
    return loggedAt.year == now.year &&
        loggedAt.month == now.month &&
        loggedAt.day == now.day;
  }

  // Formatted log date for display
  // e.g. "January 1, 2025"
  String get formattedDate {
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
    return '${months[loggedAt.month - 1]} ${loggedAt.day}, ${loggedAt.year}';
  }

  // Formatted log time for display
  // e.g. "08:30 AM"
  String get formattedTime {
    final hour = loggedAt.hour;
    final minute = loggedAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }

  // List of just the symptom names for chip display
  List<String> get symptomNames => symptoms.map((s) => s.symptom).toList();

  // ── FACTORY: FROM JSON ───────────────────────────────────
  factory SymptomLogModel.fromJson(Map<String, dynamic> json) {
    return SymptomLogModel(
      logId: json['log_id'] as String,
      patientId: json['patient_id'] as String,
      tbCaseNumber: json['tb_case_number'] as String,
      barangayId: json['barangay_id'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      symptoms: (json['symptoms'] as List? ?? [])
          .map((s) => SymptomEntry.fromJson(s as Map<String, dynamic>))
          .toList(),
      freeTextNotes: json['free_text_notes'] as String? ?? '',
      isReviewed: json['reviewed_by'] != null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ── TO JSON ──────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'log_id': logId,
    'patient_id': patientId,
    'tb_case_number': tbCaseNumber,
    'barangay_id': barangayId,
    'logged_at': loggedAt.toIso8601String(),
    'symptoms': symptoms.map((s) => s.toJson()).toList(),
    'free_text_notes': freeTextNotes,
    'reviewed_by': reviewedBy,
    'reviewed_at': reviewedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  // ── COPY WITH ────────────────────────────────────────────
  SymptomLogModel copyWith({
    String? logId,
    String? patientId,
    String? tbCaseNumber,
    String? barangayId,
    DateTime? loggedAt,
    List<SymptomEntry>? symptoms,
    String? freeTextNotes,
    bool? isReviewed,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return SymptomLogModel(
      logId: logId ?? this.logId,
      patientId: patientId ?? this.patientId,
      tbCaseNumber: tbCaseNumber ?? this.tbCaseNumber,
      barangayId: barangayId ?? this.barangayId,
      loggedAt: loggedAt ?? this.loggedAt,
      symptoms: symptoms ?? this.symptoms,
      freeTextNotes: freeTextNotes ?? this.freeTextNotes,
      isReviewed: isReviewed ?? this.isReviewed,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomLogModel &&
          runtimeType == other.runtimeType &&
          logId == other.logId;

  @override
  int get hashCode => logId.hashCode;

  @override
  String toString() =>
      'SymptomLogModel(logId: $logId, loggedAt: $loggedAt, '
      'symptoms: $symptomCount, severity: $overallSeverityLabel)';
}

// ── Individual symptom entry within a log ───────────────
class SymptomEntry {
  final String symptom;
  final int severity;

  const SymptomEntry({required this.symptom, required this.severity});

  // Severity label
  String get severityLabel {
    switch (severity) {
      case 1:
        return 'Mild';
      case 2:
        return 'Moderate';
      case 3:
        return 'Severe';
      default:
        return 'Unknown';
    }
  }

  // Whether this is a severe symptom
  bool get isSevere => severity == 3;

  // Whether this is a moderate symptom
  bool get isModerate => severity == 2;

  // Whether this is a mild symptom
  bool get isMild => severity == 1;

  // Severity color key for severity_slider.dart and chips
  String get severityColorKey {
    switch (severity) {
      case 1:
        return 'mild';
      case 2:
        return 'moderate';
      case 3:
        return 'severe';
      default:
        return 'mild';
    }
  }

  // Display string for symptom_history_tile.dart
  // e.g. "Nausea (Moderate)"
  String get displayLabel => '$symptom ($severityLabel)';

  factory SymptomEntry.fromJson(Map<String, dynamic> json) => SymptomEntry(
    symptom: json['symptom'] as String,
    severity: json['severity'] as int,
  );

  Map<String, dynamic> toJson() => {'symptom': symptom, 'severity': severity};

  SymptomEntry copyWith({String? symptom, int? severity}) => SymptomEntry(
    symptom: symptom ?? this.symptom,
    severity: severity ?? this.severity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomEntry &&
          runtimeType == other.runtimeType &&
          symptom == other.symptom;

  @override
  int get hashCode => symptom.hashCode;

  @override
  String toString() =>
      'SymptomEntry(symptom: $symptom, severity: $severityLabel)';
}

// ── Symptom history result wrapper ──────────────────────
// Returned by symptom_repository.getHistory()
class SymptomHistoryResult {
  final List<SymptomLogModel> logs;
  final bool hasMore;
  final int total;

  const SymptomHistoryResult({
    required this.logs,
    required this.hasMore,
    required this.total,
  });

  factory SymptomHistoryResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return SymptomHistoryResult(
      logs: (data['logs'] as List? ?? [])
          .map((l) => SymptomLogModel.fromJson(l as Map<String, dynamic>))
          .toList(),
      hasMore:
          ((data['page'] as int? ?? 1) * (data['limit'] as int? ?? 20)) <
          (data['total'] as int? ?? 0),
      total: data['total'] as int? ?? 0,
    );
  }
}
