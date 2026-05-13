// lib/utils/risk_color_helper.dart

import 'package:flutter/material.dart';

class RiskColorHelper {
  // ─── PATIENT RISK LEVELS ─────────────────────────────────────────────────
  // Used for: Patient.risk_level and ComplianceRecord.risk_level
  // Values: 'Compliant' | 'At Risk' | 'Defaulter'

  static Color patientRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Compliant':
        return const Color(0xFF16A34A); // green
      case 'At Risk':
        return const Color(0xFFF59E0B); // amber
      case 'Defaulter':
        return const Color(0xFFDC2626); // red
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  static Color patientRiskBackground(String riskLevel) {
    switch (riskLevel) {
      case 'Compliant':
        return const Color(0xFFDCFCE7); // green-100
      case 'At Risk':
        return const Color(0xFFFEF3C7); // amber-100
      case 'Defaulter':
        return const Color(0xFFFEE2E2); // red-100
      default:
        return const Color(0xFFF3F4F6); // gray-100
    }
  }

  // ─── HEATMAP ZONE RISK LEVELS ────────────────────────────────────────────
  // Used for: HeatmapZone.risk_level and EducationContent.risk_level_target
  // Values: 'Low' | 'Moderate' | 'High' | 'Critical'

  static Color zoneRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return const Color(0xFF16A34A); // green
      case 'Moderate':
        return const Color(0xFFF59E0B); // amber
      case 'High':
        return const Color(0xFFEA580C); // orange
      case 'Critical':
        return const Color(0xFFDC2626); // red
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  static Color zoneRiskBackground(String riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return const Color(0xFFDCFCE7); // green-100
      case 'Moderate':
        return const Color(0xFFFEF3C7); // amber-100
      case 'High':
        return const Color(0xFFFFEDD5); // orange-100
      case 'Critical':
        return const Color(0xFFFEE2E2); // red-100
      default:
        return const Color(0xFFF3F4F6); // gray-100
    }
  }

  // Circle color for OpenStreetMap heatmap zones — semi-transparent
  static Color zoneCircleColor(String riskLevel) {
    return zoneRiskColor(riskLevel).withOpacity(0.35);
  }

  static Color zoneBorderColor(String riskLevel) {
    return zoneRiskColor(riskLevel).withOpacity(0.85);
  }

  // ─── ALERT SEVERITY ──────────────────────────────────────────────────────
  // Values: 'Critical' | 'Warning' | 'Info'

  static Color alertSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return const Color(0xFFDC2626); // red
      case 'Warning':
        return const Color(0xFFF59E0B); // amber
      case 'Info':
        return const Color(0xFF2563EB); // blue
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  static Color alertSeverityBackground(String severity) {
    switch (severity) {
      case 'Critical':
        return const Color(0xFFFEE2E2); // red-100
      case 'Warning':
        return const Color(0xFFFEF3C7); // amber-100
      case 'Info':
        return const Color(0xFFDBEAFE); // blue-100
      default:
        return const Color(0xFFF3F4F6); // gray-100
    }
  }

  // ─── STOCK STATUS ────────────────────────────────────────────────────────
  // Values: 'Adequate' | 'Low' | 'Critical' | 'Out of Stock'

  static Color stockStatusColor(String status) {
    switch (status) {
      case 'Adequate':
        return const Color(0xFF16A34A); // green
      case 'Low':
        return const Color(0xFFF59E0B); // amber
      case 'Critical':
        return const Color(0xFFEA580C); // orange
      case 'Out of Stock':
        return const Color(0xFFDC2626); // red
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  // ─── COMPLIANCE PERCENTAGE ───────────────────────────────────────────────

  // Returns a color based on a 0–100 compliance percentage
  static Color fromPercentage(double percentage) {
    if (percentage >= 80) return const Color(0xFF16A34A); // green
    if (percentage >= 50) return const Color(0xFFF59E0B); // amber
    return const Color(0xFFDC2626); // red
  }

  // ─── ICONS ───────────────────────────────────────────────────────────────

  static IconData patientRiskIcon(String riskLevel) {
    switch (riskLevel) {
      case 'Compliant':
        return Icons.check_circle_rounded;
      case 'At Risk':
        return Icons.warning_amber_rounded;
      case 'Defaulter':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static IconData alertSeverityIcon(String severity) {
    switch (severity) {
      case 'Critical':
        return Icons.error_rounded;
      case 'Warning':
        return Icons.warning_amber_rounded;
      case 'Info':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
