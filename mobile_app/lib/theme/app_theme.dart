// lib/theme/app_theme.dart
// ─────────────────────────────────────────────────────────────
// RespiraTrack Color Palette & Theme
// Derived from the app screenshots:
//   Primary Blue  : #1A7FDB  (buttons, header bars, logo text)
//   Light Blue    : #4FA8F5  (subtitles, secondary accents)
//   White         : #FFFFFF  (backgrounds, card surfaces)
//   Light Grey    : #F4F6FA  (screen backgrounds)
//   Text Dark     : #1A1A2E  (headings)
//   Text Medium   : #4A5568  (body text)
//   Text Light    : #9AA5B4  (hints, captions)
//   Risk – High   : #E53E3E  (31+ cases)
//   Risk – Moderate: #ECC94B (11–30 cases)
//   Risk – Low    : #48BB78  (1–10 cases)
//   Risk – None   : #CBD5E0  (no reported cases)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primaryBlue = Color(0xFF1A7FDB);
  static const lightBlue = Color(0xFF4FA8F5);
  static const skyBlue = Color(0xFFE8F4FD);
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F6FA);
  static const cardSurface = Color(0xFFFFFFFF);
  static const cardShadow = Color(0x141A7FDB);
  static const textDark = Color(0xFF1A1A2E);
  static const textMedium = Color(0xFF4A5568);
  static const textLight = Color(0xFF9AA5B4);
  static const border = Color(0xFFDDE3EE);
  static const inputFill = Color(0xFFFFFFFF);

  // Risk levels (heatmap legend)
  static const riskHigh = Color(0xFFE53E3E);
  static const riskModerate = Color(0xFFECC94B);
  static const riskLow = Color(0xFF48BB78);
  static const riskNone = Color(0xFFCBD5E0);

  // Severity
  static const critical = Color(0xFFE53E3E);
  static const warning = Color(0xFFF6AD55);
  static const info = Color(0xFF4FA8F5);
  static const success = Color(0xFF48BB78);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins', // add to pubspec if using Google Fonts
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      secondary: AppColors.lightBlue,
      surface: AppColors.cardSurface,
      background: AppColors.background,
      onPrimary: AppColors.white,
      onSurface: AppColors.textDark,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamily: 'Poppins',
        ),
        elevation: 2,
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textMedium, fontSize: 14),
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.cardSurface,
      elevation: 2,
      shadowColor: AppColors.cardShadow, // ← CHANGE THIS LINE
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Bottom Nav Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textLight,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
  );
}

// ─── Text Styles ──────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );
  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );
  static const bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );
  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.white,
  );
  static const appTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryBlue,
    letterSpacing: -0.5,
  );
  static const appSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
  );
}
