import 'package:flutter/material.dart';

enum LoginMethod { identifier, pin, otp }

class LoginMethodToggle extends StatelessWidget {
  final LoginMethod selected;
  final void Function(LoginMethod method) onChanged;

  const LoginMethodToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ToggleTab(
            label: 'ID / Email',
            isSelected: selected == LoginMethod.identifier,
            onTap: () => onChanged(LoginMethod.identifier),
          ),
          _ToggleTab(
            label: 'PIN',
            isSelected: selected == LoginMethod.pin,
            onTap: () => onChanged(LoginMethod.pin),
          ),
          _ToggleTab(
            label: 'OTP',
            isSelected: selected == LoginMethod.otp,
            onTap: () => onChanged(LoginMethod.otp),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1A73E8).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
