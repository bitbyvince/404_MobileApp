class SputumTestModel {
  final String testId;
  final String patientId;
  final String tbCaseNumber;
  final String barangayId;
  final int month;
  final DateTime dueDate;
  final DateTime? dateCollected;
  final String? result;
  final String? resultEnteredBy;
  final DateTime? resultEnteredAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SputumTestModel({
    required this.testId,
    required this.patientId,
    required this.tbCaseNumber,
    required this.barangayId,
    required this.month,
    required this.dueDate,
    this.dateCollected,
    this.result,
    this.resultEnteredBy,
    this.resultEnteredAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── DERIVED ──────────────────────────────────────────────

  // Whether a result has been entered
  bool get hasResult =>
      result != null && result != 'Pending' && result!.isNotEmpty;

  // Whether result is negative (good outcome)
  bool get isNegative => result == 'Negative';

  // Whether result is positive (treatment concern)
  bool get isPositive => result == 'Positive';

  // Whether test is still pending
  bool get isPending => result == null || result == 'Pending';

  // Whether test was not done
  bool get isNotDone => result == 'Not Done';

  // Whether this test is overdue (due date passed, still pending)
  bool get isOverdue => isPending && dueDate.isBefore(DateTime.now());

  // Days until due (negative if overdue)
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  // Whether collection date matches due date (on-time)
  bool get wasOnTime {
    if (dateCollected == null) return false;
    return !dateCollected!.isAfter(dueDate.add(const Duration(days: 3)));
  }

  // Month label for sputum_timeline.dart
  String get monthLabel => 'Month $month';

  // Result label with fallback
  String get resultLabel => result ?? 'Pending';

  // Result color key for result_badge.dart
  // 'negative' | 'positive' | 'pending' | 'not_done' | 'overdue'
  String get resultColorKey {
    if (isOverdue) return 'overdue';
    if (isNegative) return 'negative';
    if (isPositive) return 'positive';
    if (isNotDone) return 'not_done';
    return 'pending';
  }

  // Color key for sputum_test_card.dart border/background
  String get cardColorKey {
    if (isNegative) return 'success';
    if (isPositive) return 'critical';
    if (isOverdue) return 'overdue';
    if (isNotDone) return 'warning';
    return 'pending';
  }

  // Icon key for sputum_test_card.dart
  String get iconKey {
    if (isNegative) return 'check_circle';
    if (isPositive) return 'warning_circle';
    if (isOverdue) return 'overdue_clock';
    return 'pending_clock';
  }

  // Formatted due date for display
  // e.g. "December 10, 2024"
  String get formattedDueDate {
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
    return '${months[dueDate.month - 1]} ${dueDate.day}, ${dueDate.year}';
  }

  // Formatted collection date for display
  String? get formattedCollectionDate {
    if (dateCollected == null) return null;
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
    return '${months[dateCollected!.month - 1]} '
        '${dateCollected!.day}, ${dateCollected!.year}';
  }

  // ── PLACEHOLDER FACTORY ──────────────────────────────────
  // Used by SputumProvider.timelineItems to fill in months
  // that haven't been created in the database yet
  factory SputumTestModel.placeholder({required int month}) {
    return SputumTestModel(
      testId: 'placeholder_month_$month',
      patientId: '',
      tbCaseNumber: '',
      barangayId: '',
      month: month,
      dueDate: DateTime.now(),
      result: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isPlaceholder => testId.startsWith('placeholder_');

  // ── FACTORY: FROM JSON ───────────────────────────────────
  factory SputumTestModel.fromJson(Map<String, dynamic> json) {
    return SputumTestModel(
      testId: json['test_id'] as String,
      patientId: json['patient_id'] as String,
      tbCaseNumber: json['tb_case_number'] as String,
      barangayId: json['barangay_id'] as String,
      month: json['month'] as int,
      dueDate: DateTime.parse(json['due_date'] as String),
      dateCollected: json['date_collected'] != null
          ? DateTime.parse(json['date_collected'] as String)
          : null,
      result: json['result'] as String?,
      resultEnteredBy: json['result_entered_by'] as String?,
      resultEnteredAt: json['result_entered_at'] != null
          ? DateTime.parse(json['result_entered_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ── TO JSON ──────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'test_id': testId,
    'patient_id': patientId,
    'tb_case_number': tbCaseNumber,
    'barangay_id': barangayId,
    'month': month,
    'due_date': dueDate.toIso8601String(),
    'date_collected': dateCollected?.toIso8601String(),
    'result': result,
    'result_entered_by': resultEnteredBy,
    'result_entered_at': resultEnteredAt?.toIso8601String(),
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // ── COPY WITH ────────────────────────────────────────────
  SputumTestModel copyWith({
    String? testId,
    String? patientId,
    String? tbCaseNumber,
    String? barangayId,
    int? month,
    DateTime? dueDate,
    DateTime? dateCollected,
    String? result,
    String? resultEnteredBy,
    DateTime? resultEnteredAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SputumTestModel(
      testId: testId ?? this.testId,
      patientId: patientId ?? this.patientId,
      tbCaseNumber: tbCaseNumber ?? this.tbCaseNumber,
      barangayId: barangayId ?? this.barangayId,
      month: month ?? this.month,
      dueDate: dueDate ?? this.dueDate,
      dateCollected: dateCollected ?? this.dateCollected,
      result: result ?? this.result,
      resultEnteredBy: resultEnteredBy ?? this.resultEnteredBy,
      resultEnteredAt: resultEnteredAt ?? this.resultEnteredAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SputumTestModel &&
          runtimeType == other.runtimeType &&
          testId == other.testId;

  @override
  int get hashCode => testId.hashCode;

  @override
  String toString() =>
      'SputumTestModel(testId: $testId, month: $month, '
      'result: $resultLabel, isOverdue: $isOverdue)';
}
