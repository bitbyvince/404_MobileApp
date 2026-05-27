/// Utility class for computing patient medication compliance metrics.
///
/// Mirrors the backend complianceCalculator.js logic so the mobile app
/// can display consistent figures without an extra API round-trip.
class ComplianceCalculator {
  ComplianceCalculator._();

  // ── Core percentage ──────────────────────────────────────

  /// Calculates compliance percentage.
  ///   compliance% = (dosesTaken / dosesRequired) * 100
  ///
  /// Partial doses count as 0.5 toward the numerator.
  /// Returns 0.0 if [dosesRequired] is 0.
  static double percentage({
    required int dosesTaken,
    required int dosesPartial,
    required int dosesRequired,
  }) {
    if (dosesRequired <= 0) return 0.0;
    final effective = dosesTaken + (dosesPartial * 0.5);
    return (effective / dosesRequired * 100).clamp(0.0, 100.0);
  }

  /// Convenience overload that accepts a raw taken/required ratio.
  static double simplePercentage({
    required int dosesTaken,
    required int dosesRequired,
  }) => percentage(
    dosesTaken: dosesTaken,
    dosesPartial: 0,
    dosesRequired: dosesRequired,
  );

  // ── Risk level ───────────────────────────────────────────

  /// Maps a compliance percentage to a risk level label.
  ///
  ///   ≥ 90%  → Compliant
  ///   50–89% → At Risk
  ///   < 50%  → Defaulter (used only after escalation threshold reached)
  static ComplianceRiskLevel riskLevel(double compliancePercentage) {
    if (compliancePercentage >= 90) return ComplianceRiskLevel.compliant;
    if (compliancePercentage >= 50) return ComplianceRiskLevel.atRisk;
    return ComplianceRiskLevel.defaulter;
  }

  // ── Streak ───────────────────────────────────────────────

  /// Counts the current consecutive "Taken" streak from the most recent log.
  /// [statuses] should be ordered newest-first.
  ///
  /// A "Taken" or "Partial" entry continues the streak.
  /// A "Missed" entry breaks it.
  static int currentStreak(List<String> statuses) {
    int streak = 0;
    for (final status in statuses) {
      if (status == 'Taken' || status == 'Partial') {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Counts the longest consecutive "Taken" streak in the entire history.
  /// [statuses] can be in any order.
  static int longestStreak(List<String> statuses) {
    int longest = 0;
    int current = 0;
    for (final status in statuses) {
      if (status == 'Taken' || status == 'Partial') {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  // ── Days remaining ───────────────────────────────────────

  /// Returns the number of treatment days remaining.
  /// Returns 0 if [endDate] is in the past.
  static int daysRemaining(DateTime endDate) {
    final today = DateTime.now();
    final diff = endDate.difference(
      DateTime(today.year, today.month, today.day),
    );
    return diff.inDays.clamp(0, double.maxFinite.toInt());
  }

  /// Returns the treatment progress as a value between 0.0 and 1.0.
  static double treatmentProgress({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final total = endDate.difference(startDate).inDays;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  // ── Adherence label ──────────────────────────────────────

  /// Returns a human-readable adherence label.
  ///
  ///   ≥ 95% → Excellent
  ///   90–94% → Good
  ///   75–89% → Fair
  ///   < 75%  → Poor
  static String adherenceLabel(double compliancePercentage) {
    if (compliancePercentage >= 95) return 'Excellent';
    if (compliancePercentage >= 90) return 'Good';
    if (compliancePercentage >= 75) return 'Fair';
    return 'Poor';
  }

  // ── Summary ──────────────────────────────────────────────

  /// Produces a full compliance summary from a list of daily log statuses.
  /// [statuses] should be ordered oldest-first for streak accuracy.
  static ComplianceSummary summarise({
    required List<String> statuses,
    required int dosesRequired,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final taken = statuses.where((s) => s == 'Taken').length;
    final partial = statuses.where((s) => s == 'Partial').length;
    final missed = statuses.where((s) => s == 'Missed').length;

    final pct = percentage(
      dosesTaken: taken,
      dosesPartial: partial,
      dosesRequired: dosesRequired,
    );
    final risk = riskLevel(pct);
    final label = adherenceLabel(pct);

    return ComplianceSummary(
      dosesTaken: taken,
      dosesPartial: partial,
      dosesMissed: missed,
      dosesRequired: dosesRequired,
      compliancePercentage: pct,
      riskLevel: risk,
      adherenceLabel: label,
      currentStreak: currentStreak(statuses.reversed.toList()),
      longestStreak: longestStreak(statuses),
      daysRemaining: daysRemaining(endDate),
      treatmentProgress: treatmentProgress(
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }
}

// ── Enums & value objects ────────────────────────────────────────────────────

enum ComplianceRiskLevel {
  compliant,
  atRisk,
  defaulter;

  String get label {
    switch (this) {
      case ComplianceRiskLevel.compliant:
        return 'Compliant';
      case ComplianceRiskLevel.atRisk:
        return 'At Risk';
      case ComplianceRiskLevel.defaulter:
        return 'Defaulter';
    }
  }
}

class ComplianceSummary {
  const ComplianceSummary({
    required this.dosesTaken,
    required this.dosesPartial,
    required this.dosesMissed,
    required this.dosesRequired,
    required this.compliancePercentage,
    required this.riskLevel,
    required this.adherenceLabel,
    required this.currentStreak,
    required this.longestStreak,
    required this.daysRemaining,
    required this.treatmentProgress,
  });

  final int dosesTaken;
  final int dosesPartial;
  final int dosesMissed;
  final int dosesRequired;
  final double compliancePercentage;
  final ComplianceRiskLevel riskLevel;
  final String adherenceLabel;
  final int currentStreak;
  final int longestStreak;
  final int daysRemaining;
  final double treatmentProgress; // 0.0 – 1.0
}
