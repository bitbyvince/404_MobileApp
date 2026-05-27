import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(
    0xFF1A73E8,
  ); // Blue from login btn & header
  static const Color primaryDark = Color(0xFF1558B0);
  static const Color primaryLight = Color(0xFF4A9EFF);
  static const Color primarySurface = Color(0xFFE8F1FD); // Light blue tint bg

  // ── Accent / Status ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34A853); // Green — taken / compliance
  static const Color successLight = Color(0xFFE6F4EA);
  static const Color error = Color(0xFFEA4335); // Red — missed dose
  static const Color errorLight = Color(0xFFFCE8E6);
  static const Color warning = Color(0xFFFBBC04); // Yellow — partial / at risk
  static const Color warningLight = Color(0xFFFEF7E0);
  static const Color pending = Color(0xFFBDBDBD); // Grey — pending dose

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA); // App scaffold bg
  static const Color surface = Color(0xFFFFFFFF); // Card bg
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFDDE3EE);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E); // Near-black headings
  static const Color textSecondary = Color(0xFF5F6368); // Subtext / labels
  static const Color textHint = Color(0xFFADB5BD); // Placeholder
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Text on blue bg

  // ── Calendar specific ──────────────────────────────────────────────────────
  static const Color calendarTaken = Color(0xFF34A853);
  static const Color calendarMissed = Color(0xFFEA4335);
  static const Color calendarToday = Color(0xFF1A73E8);

  // ── Progress / Compliance ──────────────────────────────────────────────────
  static const Color progressTrack = Color(0xFFE0E0E0);
  static const Color progressFill = Color(0xFF1A73E8);

  // ── Notification categories ────────────────────────────────────────────────
  static const Color notifNurse = Color(0xFF1A73E8);
  static const Color notifCenter = Color(0xFF34A853);
  static const Color notifSystem = Color(0xFF9E9E9E);

  // ── Shadow ─────────────────────────────────────────────────────────────────
  static const Color shadowColor = Color(0x14000000); // 8% black
}
