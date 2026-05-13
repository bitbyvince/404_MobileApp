// ─── user.model.dart ──────────────────────────────────────────────────────────

class PublicUser {
  final String id;
  final String? fullName;
  final String contactNumber;
  final String? email;
  final UserLocation? lastLocation;
  final bool otpVerified;
  final DateTime createdAt;

  PublicUser({
    required this.id,
    this.fullName,
    required this.contactNumber,
    this.email,
    this.lastLocation,
    required this.otpVerified,
    required this.createdAt,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['_id'] as String,
      fullName: json['full_name'] as String?,
      contactNumber: json['contact_number'] as String,
      email: json['email'] as String?,
      lastLocation: json['last_location'] != null
          ? UserLocation.fromJson(json['last_location'] as Map<String, dynamic>)
          : null,
      otpVerified: json['otp_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'full_name': fullName,
    'contact_number': contactNumber,
    'email': email,
    'last_location': lastLocation?.toJson(),
    'otp_verified': otpVerified,
    'created_at': createdAt.toIso8601String(),
  };

  String get displayName => fullName ?? contactNumber;
  bool get hasLocation => lastLocation != null;
}

class UserLocation {
  final double latitude;
  final double longitude;

  UserLocation({required this.latitude, required this.longitude});

  // GeoJSON stores as [longitude, latitude]
  factory UserLocation.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List<dynamic>;
    return UserLocation(
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'Point',
    'coordinates': [longitude, latitude],
  };
}
