// lib/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.body.copyWith(color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: label,
        suffixIcon: suffixIcon,
        prefix: prefixIcon,
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// lib/widgets/risk_badge.dart
// ─────────────────────────────────────────────────────────────
// (append
