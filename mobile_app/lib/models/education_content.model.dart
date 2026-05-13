// ─── education_content.model.dart ────────────────────────────────────────────

class EducationContent {
  final String id;
  final String title;
  final String contentBody;
  final EducationCategory category;
  final RiskLevelTarget? riskLevelTarget;
  final bool isActive;
  final DateTime createdAt;

  EducationContent({
    required this.id,
    required this.title,
    required this.contentBody,
    required this.category,
    this.riskLevelTarget,
    required this.isActive,
    required this.createdAt,
  });

  factory EducationContent.fromJson(Map<String, dynamic> json) {
    return EducationContent(
      id: json['_id'] as String,
      title: json['title'] as String,
      contentBody: json['content_body'] as String,
      category: EducationCategory.fromString(json['category'] as String),
      riskLevelTarget: json['risk_level_target'] != null
          ? RiskLevelTarget.fromString(json['risk_level_target'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'content_body': contentBody,
    'category': category.value,
    'risk_level_target': riskLevelTarget?.value,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  // Short preview for list cards
  String get excerpt {
    if (contentBody.length <= 120) return contentBody;
    return '${contentBody.substring(0, 120)}...';
  }
}

enum EducationCategory {
  protectionProtocol('Protection Protocol'),
  tbAwareness('TB Awareness'),
  treatmentGuide('Treatment Guide'),
  emergencyResponse('Emergency Response');

  const EducationCategory(this.value);
  final String value;

  static EducationCategory fromString(String value) {
    return EducationCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EducationCategory.tbAwareness,
    );
  }
}

enum RiskLevelTarget {
  low('Low'),
  moderate('Moderate'),
  high('High'),
  critical('Critical');

  const RiskLevelTarget(this.value);
  final String value;

  static RiskLevelTarget fromString(String value) {
    return RiskLevelTarget.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RiskLevelTarget.low,
    );
  }
}
