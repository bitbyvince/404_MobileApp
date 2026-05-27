import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSpacing {
  AppSpacing._();

  // ── Base scale ─────────────────────────────────────────────────────────────
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 12.w;
  static double get lg => 16.w;
  static double get xl => 20.w;
  static double get xxl => 24.w;
  static double get xxxl => 32.w;

  // ── Vertical gaps (SizedBox helpers) ──────────────────────────────────────
  static SizedBox get gapXS => SizedBox(height: 4.h);
  static SizedBox get gapSM => SizedBox(height: 8.h);
  static SizedBox get gapMD => SizedBox(height: 12.h);
  static SizedBox get gapLG => SizedBox(height: 16.h);
  static SizedBox get gapXL => SizedBox(height: 20.h);
  static SizedBox get gapXXL => SizedBox(height: 24.h);
  static SizedBox get gapXXXL => SizedBox(height: 32.h);

  // ── Horizontal gaps ────────────────────────────────────────────────────────
  static SizedBox get hGapXS => SizedBox(width: 4.w);
  static SizedBox get hGapSM => SizedBox(width: 8.w);
  static SizedBox get hGapMD => SizedBox(width: 12.w);
  static SizedBox get hGapLG => SizedBox(width: 16.w);
  static SizedBox get hGapXL => SizedBox(width: 20.w);

  // ── Padding presets ────────────────────────────────────────────────────────
  static EdgeInsets get screenPadding =>
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h);

  static EdgeInsets get cardPadding =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h);

  static EdgeInsets get cardPaddingLG =>
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h);

  static EdgeInsets get listTilePadding =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h);

  static EdgeInsets get buttonPadding =>
      EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h);

  static EdgeInsets get chipPadding =>
      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h);

  static EdgeInsets get inputPadding =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h);

  static EdgeInsets get headerPadding =>
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h);

  // ── Border radius ─────────────────────────────────────────────────────────
  static BorderRadius get radiusSM => BorderRadius.circular(8.r);
  static BorderRadius get radiusMD => BorderRadius.circular(12.r);
  static BorderRadius get radiusLG => BorderRadius.circular(16.r);
  static BorderRadius get radiusXL => BorderRadius.circular(20.r);
  static BorderRadius get radiusXXL => BorderRadius.circular(24.r);
  static BorderRadius get radiusFull => BorderRadius.circular(100.r);

  // ── Icon sizes ────────────────────────────────────────────────────────────
  static double get iconXS => 14.w;
  static double get iconSM => 18.w;
  static double get iconMD => 22.w;
  static double get iconLG => 26.w;
  static double get iconXL => 32.w;

  // ── Card elevation shadow ─────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0x0F000000),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadowMD => [
    BoxShadow(
      color: const Color(0x18000000),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
