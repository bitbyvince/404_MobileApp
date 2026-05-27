class UserModel {
  final String userId;
  final String role;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final String? tbCaseNumber;
  final String? patientId;
  final String? barangayId;
  final String? healthCenterId;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.userId,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
    this.tbCaseNumber,
    this.patientId,
    this.barangayId,
    this.healthCenterId,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── DERIVED ──────────────────────────────────────────────

  // Full display name
  String get fullName => '$firstName $lastName'.trim();

  // Initial letters for avatar placeholder
  // e.g. "Juan Dela Cruz" → "JD"
  String get initials {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // Role checks
  bool get isSuperAdmin => role == 'super_admin';
  bool get isBarangayAdmin => role == 'barangay_admin';
  bool get isNurse => role == 'nurse';
  bool get isPatient => role == 'patient';

  // Whether this user belongs to a specific barangay
  bool get hasBarangay => barangayId != null;

  // Display label for the user's role
  String get roleLabel {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'barangay_admin':
        return 'Barangay Admin';
      case 'nurse':
        return 'Nurse';
      case 'patient':
        return 'Patient';
      default:
        return role;
    }
  }

  // Primary login identifier for display on profile screen
  // Shows TB case number for patients, email for staff
  String get primaryIdentifier {
    if (isPatient) return tbCaseNumber ?? phoneNumber ?? email ?? '';
    return email ?? '';
  }

  // ── FACTORY: FROM JSON ───────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      role: json['role'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      tbCaseNumber: json['tb_case_number'] as String?,
      patientId: json['patient_id'] as String?,
      barangayId: json['barangay_id'] as String?,
      healthCenterId: json['health_center_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ── TO JSON ──────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'role': role,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone_number': phoneNumber,
    'tb_case_number': tbCaseNumber,
    'patient_id': patientId,
    'barangay_id': barangayId,
    'health_center_id': healthCenterId,
    'is_active': isActive,
    'last_login': lastLogin?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // ── COPY WITH ────────────────────────────────────────────
  UserModel copyWith({
    String? userId,
    String? role,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? tbCaseNumber,
    String? patientId,
    String? barangayId,
    String? healthCenterId,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      tbCaseNumber: tbCaseNumber ?? this.tbCaseNumber,
      patientId: patientId ?? this.patientId,
      barangayId: barangayId ?? this.barangayId,
      healthCenterId: healthCenterId ?? this.healthCenterId,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'UserModel(userId: $userId, role: $role, name: $fullName)';
}
