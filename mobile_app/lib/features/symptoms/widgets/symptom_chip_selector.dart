import 'package:flutter/material.dart';

class SymptomChipSelector extends StatelessWidget {
  final List<String> availableSymptoms;
  final Map<String, int> selectedSymptoms;
  final void Function(String symptom) onToggle;

  const SymptomChipSelector({
    super.key,
    required this.availableSymptoms,
    required this.selectedSymptoms,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableSymptoms.map((symptom) {
        final isSelected = selectedSymptoms.containsKey(symptom);
        final severity = selectedSymptoms[symptom] ?? 1;
        return _SymptomChip(
          label: symptom,
          isSelected: isSelected,
          severity: severity,
          onTap: () => onToggle(symptom),
        );
      }).toList(),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int severity;
  final VoidCallback onTap;

  const _SymptomChip({
    required this.label,
    required this.isSelected,
    required this.severity,
    required this.onTap,
  });

  Color get _selectedColor {
    switch (severity) {
      case 3:
        return const Color(0xFFE53935);
      case 2:
        return const Color(0xFFFFA000);
      default:
        return const Color(0xFF1A73E8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _selectedColor.withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _selectedColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.circle, size: 8, color: _selectedColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _selectedColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
