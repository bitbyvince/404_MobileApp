class PatientModel {
  final String patientId;
  final String tbCaseNumber;
  final String? userId;
  final String registeredBy;

  // Personal info
  final String lastName;
  final String firstName;
  final String middleName;
  final String fullName;
  final DateTime birthDate;
  final int age;
  final String sex;
  final String? philhealthNumber;
  final String phoneNumber;
  final String? email;

  // Location
  final String barangayId;
  final String barangayName;
  final String healthCenterId;
  final String healthCenterName;
  final String? assignedNurseId;

  // Diagnosis
  final String diagnosis;
  final DateTime dateOfDiagnosis;
  final String classification;
  final String bacteriologicalStatus;
  final PatientType patientType;

  // Treatment
  final String treatmentPhase;
  final String locationOfTreatment;
  final DateTime dateStarted;
  final DateTime endDate;
  final int treatmentDurationMonths;
  final DateTime scheduleOfTreatment;
  final String datSupport;
  final String regimenType;
  final List<DrugRegimenItem> drugRegimen;
  final TreatmentSupporter treatmentSupporter;

  // Outcome
  final TreatmentOutcome treatmentOutcome;

  // Contact tracing
  final ContactTracing contactTracing;

  final String additionalNotes;

  // Sputum schedule
  final List<SputumScheduleItem> sputumTestSchedule;

  // Compliance
  final ComplianceData compliance;

  // Risk score
  final RiskScoreData riskScore;

  // Escalation
  final EscalationData escalation;

  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientModel({
    required this.patientId,
    required this.tbCaseNumber,
    this.userId,
    required this.registeredBy,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.fullName,
    required this.birthDate,
    required this.age,
    required this.sex,
    this.philhealthNumber,
    required this.phoneNumber,
    this.email,
    required this.barangayId,
    required this.barangayName,
    required this.healthCenterId,
    required this.healthCenterName,
    this.assignedNurseId,
    required this.diagnosis,
    required this.dateOfDiagnosis,
    required this.classification,
    required this.bacteriologicalStatus,
    required this.patientType,
    required this.treatmentPhase,
    required this.locationOfTreatment,
    required this.dateStarted,
    required this.endDate,
    required this.treatmentDurationMonths,
    required this.scheduleOfTreatment,
    required this.datSupport,
    required this.regimenType,
    required this.drugRegimen,
    required this.treatmentSupporter,
    required this.treatmentOutcome,
    required this.contactTracing,
    required this.additionalNotes,
    required this.sputumTestSchedule,
    required this.compliance,
    required this.riskScore,
    required this.escalation,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── DERIVED ──────────────────────────────────────────────

  // Days remaining in treatment
  int get daysRemaining {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  // Current day number in treatment timeline
  int get currentTreatmentDay {
    final diff = DateTime.now().difference(dateStarted).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  // Total treatment days
  int get totalTreatmentDays => endDate.difference(dateStarted).inDays;

  // Treatment progress (0.0 – 1.0)
  double get treatmentProgress {
    if (totalTreatmentDays == 0) return 0.0;
    return (currentTreatmentDay / totalTreatmentDays).clamp(0.0, 1.0);
  }

  // Whether treatment has reached a terminal outcome
  bool get isTreatmentComplete {
    const terminalStatuses = [
      'Cured',
      'Treatment Completed',
      'Treatment Failed',
      'Died',
      'Lost to Follow-Up',
      'Not Evaluated',
    ];
    return terminalStatuses.contains(treatmentOutcome.status);
  }

  // Next pending sputum test
  SputumScheduleItem? get nextSputumTest {
    final today = DateTime.now();
    final pending = sputumTestSchedule
        .where((s) => s.status == 'Pending' && s.dueDate.isAfter(today))
        .toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.first;
  }

  // Days until next sputum test
  int get daysUntilNextSputumTest {
    final next = nextSputumTest;
    if (next == null) return 0;
    final diff = next.dueDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  // Risk level color key for UI
  // 'compliant' | 'at_risk' | 'defaulter'
  String get riskColorKey {
    switch (compliance.riskLevel) {
      case 'Compliant':
        return 'compliant';
      case 'At Risk':
        return 'at_risk';
      case 'Defaulter':
        return 'defaulter';
      default:
        return 'compliant';
    }
  }

  // Treatment phase color key for UI
  String get phaseColorKey =>
      treatmentPhase == 'Intensive' ? 'intensive' : 'continuation';

  // Whether patient has a linked mobile account
  bool get hasMobileAccount => userId != null;

  // ── FACTORY: FROM JSON ───────────────────────────────────
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      patientId: json['patient_id'] as String,
      tbCaseNumber: json['tb_case_number'] as String,
      userId: json['user_id'] as String?,
      registeredBy: json['registered_by'] as String,
      lastName: json['last_name'] as String,
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String? ?? '',
      fullName: json['full_name'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      age: json['age'] as int,
      sex: json['sex'] as String,
      philhealthNumber: json['philhealth_number'] as String?,
      phoneNumber: json['phone_number'] as String,
      email: json['email'] as String?,
      barangayId: json['barangay_id'] as String,
      barangayName: json['barangay_name'] as String,
      healthCenterId: json['health_center_id'] as String,
      healthCenterName: json['health_center_name'] as String,
      assignedNurseId: json['assigned_nurse_id'] as String?,
      diagnosis: json['diagnosis'] as String,
      dateOfDiagnosis: DateTime.parse(json['date_of_diagnosis'] as String),
      classification: json['classification'] as String,
      bacteriologicalStatus: json['bacteriological_status'] as String,
      patientType: PatientType.fromJson(
        json['patient_type'] as Map<String, dynamic>,
      ),
      treatmentPhase: json['treatment_phase'] as String,
      locationOfTreatment: json['location_of_treatment'] as String,
      dateStarted: DateTime.parse(json['date_started'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      treatmentDurationMonths: json['treatment_duration_months'] as int,
      scheduleOfTreatment: DateTime.parse(
        json['schedule_of_treatment'] as String,
      ),
      datSupport: json['dat_support'] as String,
      regimenType: json['regimen_type'] as String,
      drugRegimen: (json['drug_regimen'] as List? ?? [])
          .map((d) => DrugRegimenItem.fromJson(d as Map<String, dynamic>))
          .toList(),
      treatmentSupporter: TreatmentSupporter.fromJson(
        json['treatment_supporter'] as Map<String, dynamic>? ?? {},
      ),
      treatmentOutcome: TreatmentOutcome.fromJson(
        json['treatment_outcome'] as Map<String, dynamic>,
      ),
      contactTracing: ContactTracing.fromJson(
        json['contact_tracing'] as Map<String, dynamic>? ?? {},
      ),
      additionalNotes: json['additional_notes'] as String? ?? '',
      sputumTestSchedule: (json['sputum_test_schedule'] as List? ?? [])
          .map((s) => SputumScheduleItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      compliance: ComplianceData.fromJson(
        json['compliance'] as Map<String, dynamic>,
      ),
      riskScore: RiskScoreData.fromJson(
        json['risk_score'] as Map<String, dynamic>,
      ),
      escalation: EscalationData.fromJson(
        json['escalation'] as Map<String, dynamic>,
      ),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ── TO JSON ──────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'tb_case_number': tbCaseNumber,
    'user_id': userId,
    'registered_by': registeredBy,
    'last_name': lastName,
    'first_name': firstName,
    'middle_name': middleName,
    'full_name': fullName,
    'birth_date': birthDate.toIso8601String(),
    'age': age,
    'sex': sex,
    'philhealth_number': philhealthNumber,
    'phone_number': phoneNumber,
    'email': email,
    'barangay_id': barangayId,
    'barangay_name': barangayName,
    'health_center_id': healthCenterId,
    'health_center_name': healthCenterName,
    'assigned_nurse_id': assignedNurseId,
    'diagnosis': diagnosis,
    'date_of_diagnosis': dateOfDiagnosis.toIso8601String(),
    'classification': classification,
    'bacteriological_status': bacteriologicalStatus,
    'patient_type': patientType.toJson(),
    'treatment_phase': treatmentPhase,
    'location_of_treatment': locationOfTreatment,
    'date_started': dateStarted.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'treatment_duration_months': treatmentDurationMonths,
    'schedule_of_treatment': scheduleOfTreatment.toIso8601String(),
    'dat_support': datSupport,
    'regimen_type': regimenType,
    'drug_regimen': drugRegimen.map((d) => d.toJson()).toList(),
    'treatment_supporter': treatmentSupporter.toJson(),
    'treatment_outcome': treatmentOutcome.toJson(),
    'contact_tracing': contactTracing.toJson(),
    'additional_notes': additionalNotes,
    'sputum_test_schedule': sputumTestSchedule.map((s) => s.toJson()).toList(),
    'compliance': compliance.toJson(),
    'risk_score': riskScore.toJson(),
    'escalation': escalation.toJson(),
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // ── COPY WITH ────────────────────────────────────────────
  PatientModel copyWith({
    String? patientId,
    String? tbCaseNumber,
    String? userId,
    String? registeredBy,
    String? lastName,
    String? firstName,
    String? middleName,
    String? fullName,
    DateTime? birthDate,
    int? age,
    String? sex,
    String? philhealthNumber,
    String? phoneNumber,
    String? email,
    String? barangayId,
    String? barangayName,
    String? healthCenterId,
    String? healthCenterName,
    String? assignedNurseId,
    String? diagnosis,
    DateTime? dateOfDiagnosis,
    String? classification,
    String? bacteriologicalStatus,
    PatientType? patientType,
    String? treatmentPhase,
    String? locationOfTreatment,
    DateTime? dateStarted,
    DateTime? endDate,
    int? treatmentDurationMonths,
    DateTime? scheduleOfTreatment,
    String? datSupport,
    String? regimenType,
    List<DrugRegimenItem>? drugRegimen,
    TreatmentSupporter? treatmentSupporter,
    TreatmentOutcome? treatmentOutcome,
    ContactTracing? contactTracing,
    String? additionalNotes,
    List<SputumScheduleItem>? sputumTestSchedule,
    ComplianceData? compliance,
    RiskScoreData? riskScore,
    EscalationData? escalation,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientModel(
      patientId: patientId ?? this.patientId,
      tbCaseNumber: tbCaseNumber ?? this.tbCaseNumber,
      userId: userId ?? this.userId,
      registeredBy: registeredBy ?? this.registeredBy,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      philhealthNumber: philhealthNumber ?? this.philhealthNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      barangayId: barangayId ?? this.barangayId,
      barangayName: barangayName ?? this.barangayName,
      healthCenterId: healthCenterId ?? this.healthCenterId,
      healthCenterName: healthCenterName ?? this.healthCenterName,
      assignedNurseId: assignedNurseId ?? this.assignedNurseId,
      diagnosis: diagnosis ?? this.diagnosis,
      dateOfDiagnosis: dateOfDiagnosis ?? this.dateOfDiagnosis,
      classification: classification ?? this.classification,
      bacteriologicalStatus:
          bacteriologicalStatus ?? this.bacteriologicalStatus,
      patientType: patientType ?? this.patientType,
      treatmentPhase: treatmentPhase ?? this.treatmentPhase,
      locationOfTreatment: locationOfTreatment ?? this.locationOfTreatment,
      dateStarted: dateStarted ?? this.dateStarted,
      endDate: endDate ?? this.endDate,
      treatmentDurationMonths:
          treatmentDurationMonths ?? this.treatmentDurationMonths,
      scheduleOfTreatment: scheduleOfTreatment ?? this.scheduleOfTreatment,
      datSupport: datSupport ?? this.datSupport,
      regimenType: regimenType ?? this.regimenType,
      drugRegimen: drugRegimen ?? this.drugRegimen,
      treatmentSupporter: treatmentSupporter ?? this.treatmentSupporter,
      treatmentOutcome: treatmentOutcome ?? this.treatmentOutcome,
      contactTracing: contactTracing ?? this.contactTracing,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      sputumTestSchedule: sputumTestSchedule ?? this.sputumTestSchedule,
      compliance: compliance ?? this.compliance,
      riskScore: riskScore ?? this.riskScore,
      escalation: escalation ?? this.escalation,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientModel &&
          runtimeType == other.runtimeType &&
          patientId == other.patientId;

  @override
  int get hashCode => patientId.hashCode;

  @override
  String toString() =>
      'PatientModel(patientId: $patientId, tbCaseNumber: $tbCaseNumber, '
      'name: $fullName, phase: $treatmentPhase, risk: ${compliance.riskLevel})';
}

// ── NESTED VALUE CLASSES ─────────────────────────────────

class PatientType {
  final bool isNew;
  final bool isRetreatment;
  final bool isDrugSusceptible;
  final bool isDrugResistant;

  const PatientType({
    required this.isNew,
    required this.isRetreatment,
    required this.isDrugSusceptible,
    required this.isDrugResistant,
  });

  String get label {
    if (isDrugResistant) return 'Drug-Resistant';
    if (isRetreatment) return 'Retreatment';
    return 'New Case';
  }

  factory PatientType.fromJson(Map<String, dynamic> json) => PatientType(
    isNew: json['is_new'] as bool? ?? true,
    isRetreatment: json['is_retreatment'] as bool? ?? false,
    isDrugSusceptible: json['is_drug_susceptible'] as bool? ?? true,
    isDrugResistant: json['is_drug_resistant'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'is_new': isNew,
    'is_retreatment': isRetreatment,
    'is_drug_susceptible': isDrugSusceptible,
    'is_drug_resistant': isDrugResistant,
  };

  PatientType copyWith({
    bool? isNew,
    bool? isRetreatment,
    bool? isDrugSusceptible,
    bool? isDrugResistant,
  }) => PatientType(
    isNew: isNew ?? this.isNew,
    isRetreatment: isRetreatment ?? this.isRetreatment,
    isDrugSusceptible: isDrugSusceptible ?? this.isDrugSusceptible,
    isDrugResistant: isDrugResistant ?? this.isDrugResistant,
  );
}

class DrugRegimenItem {
  final String drugName;
  final String strength;
  final String unit;
  final int numberToBeTaken;

  const DrugRegimenItem({
    required this.drugName,
    required this.strength,
    required this.unit,
    required this.numberToBeTaken,
  });

  // Display label for medicine_card.dart
  // e.g. "Isoniazid 300mg × 1 tablet"
  String get displayLabel => '$drugName $strength × $numberToBeTaken $unit';

  // Short label for chip display
  String get shortLabel => '$drugName $strength';

  factory DrugRegimenItem.fromJson(Map<String, dynamic> json) =>
      DrugRegimenItem(
        drugName: json['drug_name'] as String,
        strength: json['strength'] as String,
        unit: json['unit'] as String,
        numberToBeTaken: json['number_to_be_taken'] as int,
      );

  Map<String, dynamic> toJson() => {
    'drug_name': drugName,
    'strength': strength,
    'unit': unit,
    'number_to_be_taken': numberToBeTaken,
  };

  DrugRegimenItem copyWith({
    String? drugName,
    String? strength,
    String? unit,
    int? numberToBeTaken,
  }) => DrugRegimenItem(
    drugName: drugName ?? this.drugName,
    strength: strength ?? this.strength,
    unit: unit ?? this.unit,
    numberToBeTaken: numberToBeTaken ?? this.numberToBeTaken,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrugRegimenItem &&
          runtimeType == other.runtimeType &&
          drugName == other.drugName &&
          strength == other.strength;

  @override
  int get hashCode => drugName.hashCode ^ strength.hashCode;
}

class TreatmentSupporter {
  final String? name;
  final String? contact;

  const TreatmentSupporter({this.name, this.contact});

  bool get hasSupporter => name != null && name!.isNotEmpty;

  factory TreatmentSupporter.fromJson(Map<String, dynamic> json) =>
      TreatmentSupporter(
        name: json['name'] as String?,
        contact: json['contact'] as String?,
      );

  Map<String, dynamic> toJson() => {'name': name, 'contact': contact};

  TreatmentSupporter copyWith({String? name, String? contact}) =>
      TreatmentSupporter(
        name: name ?? this.name,
        contact: contact ?? this.contact,
      );
}

class TreatmentOutcome {
  final String status;
  final DateTime? dateOfOutcome;
  final String? recordedBy;

  const TreatmentOutcome({
    required this.status,
    this.dateOfOutcome,
    this.recordedBy,
  });

  bool get isOnTreatment => status == 'On Treatment';

  bool get isTerminal {
    const terminalStatuses = [
      'Cured',
      'Treatment Completed',
      'Treatment Failed',
      'Died',
      'Lost to Follow-Up',
      'Not Evaluated',
    ];
    return terminalStatuses.contains(status);
  }

  // Outcome color key for UI
  String get colorKey {
    switch (status) {
      case 'On Treatment':
        return 'on_treatment';
      case 'Cured':
      case 'Treatment Completed':
        return 'success';
      case 'Treatment Failed':
      case 'Lost to Follow-Up':
      case 'Not Evaluated':
        return 'warning';
      case 'Died':
        return 'critical';
      default:
        return 'on_treatment';
    }
  }

  factory TreatmentOutcome.fromJson(Map<String, dynamic> json) =>
      TreatmentOutcome(
        status: json['status'] as String? ?? 'On Treatment',
        dateOfOutcome: json['date_of_outcome'] != null
            ? DateTime.parse(json['date_of_outcome'] as String)
            : null,
        recordedBy: json['recorded_by'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'status': status,
    'date_of_outcome': dateOfOutcome?.toIso8601String(),
    'recorded_by': recordedBy,
  };

  TreatmentOutcome copyWith({
    String? status,
    DateTime? dateOfOutcome,
    String? recordedBy,
  }) => TreatmentOutcome(
    status: status ?? this.status,
    dateOfOutcome: dateOfOutcome ?? this.dateOfOutcome,
    recordedBy: recordedBy ?? this.recordedBy,
  );
}

class ContactTracing {
  final int numberOfContacts;
  final DateTime? schedule;

  const ContactTracing({required this.numberOfContacts, this.schedule});

  bool get hasSchedule => schedule != null;

  factory ContactTracing.fromJson(Map<String, dynamic> json) => ContactTracing(
    numberOfContacts: json['number_of_contacts'] as int? ?? 0,
    schedule: json['schedule'] != null
        ? DateTime.parse(json['schedule'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'number_of_contacts': numberOfContacts,
    'schedule': schedule?.toIso8601String(),
  };

  ContactTracing copyWith({int? numberOfContacts, DateTime? schedule}) =>
      ContactTracing(
        numberOfContacts: numberOfContacts ?? this.numberOfContacts,
        schedule: schedule ?? this.schedule,
      );
}

class SputumScheduleItem {
  final int month;
  final DateTime dueDate;
  final String status;

  const SputumScheduleItem({
    required this.month,
    required this.dueDate,
    required this.status,
  });

  bool get isPending => status == 'Pending';
  bool get isCompleted => status == 'Completed';
  bool get isMissed => status == 'Missed';

  bool get isOverdue => isPending && dueDate.isBefore(DateTime.now());

  // Days until due (negative if overdue)
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  // Month label for sputum_timeline.dart
  String get monthLabel => 'Month $month';

  // Status color key for UI
  String get statusColorKey {
    if (isCompleted) return 'completed';
    if (isOverdue) return 'overdue';
    if (isMissed) return 'missed';
    return 'pending';
  }

  factory SputumScheduleItem.fromJson(Map<String, dynamic> json) =>
      SputumScheduleItem(
        month: json['month'] as int,
        dueDate: DateTime.parse(json['due_date'] as String),
        status: json['status'] as String? ?? 'Pending',
      );

  Map<String, dynamic> toJson() => {
    'month': month,
    'due_date': dueDate.toIso8601String(),
    'status': status,
  };

  SputumScheduleItem copyWith({
    int? month,
    DateTime? dueDate,
    String? status,
  }) => SputumScheduleItem(
    month: month ?? this.month,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
  );
}

class ComplianceData {
  final int totalDosesRequired;
  final int dosesTaken;
  final int dosesMissed;
  final int dosesRemaining;
  final double compliancePercentage;
  final String adherence;
  final int consecutiveMissedDoses;
  final DateTime? lastDoseTaken;
  final String riskLevel;

  const ComplianceData({
    required this.totalDosesRequired,
    required this.dosesTaken,
    required this.dosesMissed,
    required this.dosesRemaining,
    required this.compliancePercentage,
    required this.adherence,
    required this.consecutiveMissedDoses,
    this.lastDoseTaken,
    required this.riskLevel,
  });

  // Whether compliance is above the 80% target
  bool get isAboveTarget => compliancePercentage >= 80.0;

  // Compliance percentage as a 0.0–1.0 value for progress indicators
  double get complianceRatio => (compliancePercentage / 100).clamp(0.0, 1.0);

  // Risk level color key
  String get riskColorKey {
    switch (riskLevel) {
      case 'Compliant':
        return 'compliant';
      case 'At Risk':
        return 'at_risk';
      case 'Defaulter':
        return 'defaulter';
      default:
        return 'compliant';
    }
  }

  factory ComplianceData.fromJson(Map<String, dynamic> json) => ComplianceData(
    totalDosesRequired: json['total_doses_required'] as int? ?? 168,
    dosesTaken: json['doses_taken'] as int? ?? 0,
    dosesMissed: json['doses_missed'] as int? ?? 0,
    dosesRemaining: json['doses_remaining'] as int? ?? 168,
    compliancePercentage: (json['compliance_percentage'] as num? ?? 0)
        .toDouble(),
    adherence: json['adherence'] as String? ?? 'Pending',
    consecutiveMissedDoses: json['consecutive_missed_doses'] as int? ?? 0,
    lastDoseTaken: json['last_dose_taken'] != null
        ? DateTime.parse(json['last_dose_taken'] as String)
        : null,
    riskLevel: json['risk_level'] as String? ?? 'Compliant',
  );

  Map<String, dynamic> toJson() => {
    'total_doses_required': totalDosesRequired,
    'doses_taken': dosesTaken,
    'doses_missed': dosesMissed,
    'doses_remaining': dosesRemaining,
    'compliance_percentage': compliancePercentage,
    'adherence': adherence,
    'consecutive_missed_doses': consecutiveMissedDoses,
    'last_dose_taken': lastDoseTaken?.toIso8601String(),
    'risk_level': riskLevel,
  };

  ComplianceData copyWith({
    int? totalDosesRequired,
    int? dosesTaken,
    int? dosesMissed,
    int? dosesRemaining,
    double? compliancePercentage,
    String? adherence,
    int? consecutiveMissedDoses,
    DateTime? lastDoseTaken,
    String? riskLevel,
  }) => ComplianceData(
    totalDosesRequired: totalDosesRequired ?? this.totalDosesRequired,
    dosesTaken: dosesTaken ?? this.dosesTaken,
    dosesMissed: dosesMissed ?? this.dosesMissed,
    dosesRemaining: dosesRemaining ?? this.dosesRemaining,
    compliancePercentage: compliancePercentage ?? this.compliancePercentage,
    adherence: adherence ?? this.adherence,
    consecutiveMissedDoses:
        consecutiveMissedDoses ?? this.consecutiveMissedDoses,
    lastDoseTaken: lastDoseTaken ?? this.lastDoseTaken,
    riskLevel: riskLevel ?? this.riskLevel,
  );
}

class RiskScoreData {
  final int score;
  final RiskScoreFactors factors;
  final DateTime lastComputed;

  const RiskScoreData({
    required this.score,
    required this.factors,
    required this.lastComputed,
  });

  // Risk band label based on score
  // 0–30: Low | 31–60: Moderate | 61–100: High
  String get band {
    if (score <= 30) return 'Low';
    if (score <= 60) return 'Moderate';
    return 'High';
  }

  // Risk band color key for UI
  String get bandColorKey {
    if (score <= 30) return 'low';
    if (score <= 60) return 'moderate';
    return 'high';
  }

  // Normalised 0.0–1.0 value for progress indicators
  double get normalised => (score / 100).clamp(0.0, 1.0);

  factory RiskScoreData.fromJson(Map<String, dynamic> json) => RiskScoreData(
    score: json['score'] as int? ?? 0,
    factors: RiskScoreFactors.fromJson(
      json['factors'] as Map<String, dynamic>? ?? {},
    ),
    lastComputed: json['last_computed'] != null
        ? DateTime.parse(json['last_computed'] as String)
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'score': score,
    'factors': factors.toJson(),
    'last_computed': lastComputed.toIso8601String(),
  };

  RiskScoreData copyWith({
    int? score,
    RiskScoreFactors? factors,
    DateTime? lastComputed,
  }) => RiskScoreData(
    score: score ?? this.score,
    factors: factors ?? this.factors,
    lastComputed: lastComputed ?? this.lastComputed,
  );
}

class RiskScoreFactors {
  final int consecutiveMissed;
  final int symptomFrequency;
  final int daysIntoTreatment;
  final double phaseWeight;

  const RiskScoreFactors({
    required this.consecutiveMissed,
    required this.symptomFrequency,
    required this.daysIntoTreatment,
    required this.phaseWeight,
  });

  factory RiskScoreFactors.fromJson(Map<String, dynamic> json) =>
      RiskScoreFactors(
        consecutiveMissed: json['consecutive_missed'] as int? ?? 0,
        symptomFrequency: json['symptom_frequency'] as int? ?? 0,
        daysIntoTreatment: json['days_into_treatment'] as int? ?? 0,
        phaseWeight: (json['phase_weight'] as num? ?? 1.0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'consecutive_missed': consecutiveMissed,
    'symptom_frequency': symptomFrequency,
    'days_into_treatment': daysIntoTreatment,
    'phase_weight': phaseWeight,
  };

  RiskScoreFactors copyWith({
    int? consecutiveMissed,
    int? symptomFrequency,
    int? daysIntoTreatment,
    double? phaseWeight,
  }) => RiskScoreFactors(
    consecutiveMissed: consecutiveMissed ?? this.consecutiveMissed,
    symptomFrequency: symptomFrequency ?? this.symptomFrequency,
    daysIntoTreatment: daysIntoTreatment ?? this.daysIntoTreatment,
    phaseWeight: phaseWeight ?? this.phaseWeight,
  );
}

class EscalationData {
  final int level;
  final DateTime? escalatedAt;
  final String escalatedBy;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String notes;

  const EscalationData({
    required this.level,
    this.escalatedAt,
    required this.escalatedBy,
    this.acknowledgedBy,
    this.acknowledgedAt,
    required this.notes,
  });

  bool get isEscalated => level > 0;
  bool get isAcknowledged => acknowledgedBy != null;

  // Escalation level label
  String get levelLabel {
    switch (level) {
      case 0:
        return 'None';
      case 1:
        return 'Level 1 — Nurse Notified';
      case 2:
        return 'Level 2 — Admin Flagged';
      case 3:
        return 'Level 3 — Defaulter';
      default:
        return 'Unknown';
    }
  }

  factory EscalationData.fromJson(Map<String, dynamic> json) => EscalationData(
    level: json['level'] as int? ?? 0,
    escalatedAt: json['escalated_at'] != null
        ? DateTime.parse(json['escalated_at'] as String)
        : null,
    escalatedBy: json['escalated_by'] as String? ?? 'system',
    acknowledgedBy: json['acknowledged_by'] as String?,
    acknowledgedAt: json['acknowledged_at'] != null
        ? DateTime.parse(json['acknowledged_at'] as String)
        : null,
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'level': level,
    'escalated_at': escalatedAt?.toIso8601String(),
    'escalated_by': escalatedBy,
    'acknowledged_by': acknowledgedBy,
    'acknowledged_at': acknowledgedAt?.toIso8601String(),
    'notes': notes,
  };

  EscalationData copyWith({
    int? level,
    DateTime? escalatedAt,
    String? escalatedBy,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    String? notes,
  }) => EscalationData(
    level: level ?? this.level,
    escalatedAt: escalatedAt ?? this.escalatedAt,
    escalatedBy: escalatedBy ?? this.escalatedBy,
    acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    notes: notes ?? this.notes,
  );
}
