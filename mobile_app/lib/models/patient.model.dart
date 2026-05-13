// ─── patient.model.dart ───────────────────────────────────────────────────────

class Patient {
  final String id;
  final String barangayId;
  final String? addedByNurse;
  final String? addedByAdmin;
  final String fullName;
  final int age;
  final PatientSex sex;
  final String zone;
  final String? street;
  final TbStatus tbStatus;
  final DateTime diagnosisDate;
  final TreatmentPhase phase;
  final Adherence adherence;
  final RiskLevel? riskLevel;
  final int remainingDoses;
  final int totalDoses;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.barangayId,
    this.addedByNurse,
    this.addedByAdmin,
    required this.fullName,
    required this.age,
    required this.sex,
    required this.zone,
    this.street,
    required this.tbStatus,
    required this.diagnosisDate,
    required this.phase,
    required this.adherence,
    this.riskLevel,
    required this.remainingDoses,
    required this.totalDoses,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] as String,
      barangayId: json['barangay_id'] is Map
          ? json['barangay_id']['_id'] as String
          : json['barangay_id'] as String,
      addedByNurse: json['added_by_nurse'] as String?,
      addedByAdmin: json['added_by_admin'] as String?,
      fullName: json['full_name'] as String,
      age: (json['age'] as num).toInt(),
      sex: PatientSex.fromString(json['sex'] as String),
      zone: json['zone'] as String,
      street: json['street'] as String?,
      tbStatus: TbStatus.fromString(json['tb_status'] as String),
      diagnosisDate: DateTime.parse(json['diagnosis_date'] as String),
      phase: TreatmentPhase.fromString(json['phase'] as String),
      adherence: Adherence.fromString(json['adherence'] as String),
      riskLevel: json['risk_level'] != null
          ? RiskLevel.fromString(json['risk_level'] as String)
          : null,
      remainingDoses: (json['remaining_doses'] as num?)?.toInt() ?? 0,
      totalDoses: (json['total_doses'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'barangay_id': barangayId,
    'added_by_nurse': addedByNurse,
    'added_by_admin': addedByAdmin,
    'full_name': fullName,
    'age': age,
    'sex': sex.value,
    'zone': zone,
    'street': street,
    'tb_status': tbStatus.value,
    'diagnosis_date': diagnosisDate.toIso8601String(),
    'phase': phase.value,
    'adherence': adherence.value,
    'risk_level': riskLevel?.value,
    'remaining_doses': remainingDoses,
    'total_doses': totalDoses,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // Convenience getters for UI
  double get compliancePercentage {
    if (totalDoses == 0) return 0;
    final taken = totalDoses - remainingDoses;
    return (taken / totalDoses) * 100;
  }

  bool get isDefaulter => riskLevel == RiskLevel.defaulter;
  bool get isAtRisk => riskLevel == RiskLevel.atRisk;
  bool get isCompliant => riskLevel == RiskLevel.compliant;
  bool get isIntensive => phase == TreatmentPhase.intensive;
}

enum PatientSex {
  male('Male'),
  female('Female'),
  other('Other');

  const PatientSex(this.value);
  final String value;

  static PatientSex fromString(String value) {
    return PatientSex.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PatientSex.other,
    );
  }
}

enum TbStatus {
  newCase('New'),
  relapse('Relapse'),
  treatmentAfterFailure('Treatment After Failure'),
  treatmentAfterLoss('Treatment After Loss to Follow-up'),
  other('Other');

  const TbStatus(this.value);
  final String value;

  static TbStatus fromString(String value) {
    return TbStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TbStatus.other,
    );
  }
}

enum TreatmentPhase {
  intensive('Intensive'),
  continuation('Continuation');

  const TreatmentPhase(this.value);
  final String value;

  static TreatmentPhase fromString(String value) {
    return TreatmentPhase.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TreatmentPhase.intensive,
    );
  }
}

enum Adherence {
  regular('Regular'),
  irregular('Irregular');

  const Adherence(this.value);
  final String value;

  static Adherence fromString(String value) {
    return Adherence.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Adherence.regular,
    );
  }
}

enum RiskLevel {
  compliant('Compliant'),
  atRisk('At Risk'),
  defaulter('Defaulter');

  const RiskLevel(this.value);
  final String value;

  static RiskLevel fromString(String value) {
    return RiskLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RiskLevel.compliant,
    );
  }
}
