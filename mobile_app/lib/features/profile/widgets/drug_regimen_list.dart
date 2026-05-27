import 'package:flutter/material.dart';

class DrugRegimenItem {
  final String drugName;
  final String strength;
  final String unit;
  final int numberToBeTaken;

  const DrugRegimenItem({
    required this.drugName,
    required this.strength,
    required this.unit,
    required this.numberToBeTaken,
  });
}

class DrugRegimenList extends StatelessWidget {
  final List<DrugRegimenItem> drugs;

  const DrugRegimenList({super.key, required this.drugs});

  static const List<Color> _drugColors = [
    Color(0xFF1A73E8),
    Color(0xFF34A853),
    Color(0xFFE53935),
    Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Drug Regimen',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          ...drugs.asMap().entries.map((entry) {
            final index = entry.key;
            final drug = entry.value;
            final color = _drugColors[index % _drugColors.length];
            return _DrugItem(drug: drug, color: color);
          }),
        ],
      ),
    );
  }
}

class _DrugItem extends StatelessWidget {
  final DrugRegimenItem drug;
  final Color color;

  const _DrugItem({required this.drug, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Rx',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${drug.drugName} ${drug.strength}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  '${drug.numberToBeTaken} ${drug.unit} daily',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 12, color: color),
          ),
        ],
      ),
    );
  }
}
