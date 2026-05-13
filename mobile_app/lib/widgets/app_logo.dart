// lib/widgets/app_logo.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        // ─────────────────────────────────────────────────────
        // INSERT YOUR LOGO HERE
        // 1. Add your logo image to: assets/images/logo.png
        // 2. It's already declared in pubspec.yaml under assets
        // 3. Recommended size: 512x512px PNG with transparent bg
        // ─────────────────────────────────────────────────────
        'assets/logo404.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholderLogo(),
      ),
    );
  }

  // Placeholder shown until you add the real logo asset
  Widget _placeholderLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.skyBlue,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryBlue, width: 3),
      ),
      child: Icon(
        Icons.air_outlined,
        size: size * 0.55,
        color: AppColors.primaryBlue,
      ),
    );
  }
}
