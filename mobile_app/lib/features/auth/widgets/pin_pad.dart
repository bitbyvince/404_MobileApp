import 'package:flutter/material.dart';

class PinPad extends StatelessWidget {
  final int pinLength;
  final int currentLength;
  final void Function(String digit) onDigitTap;
  final void Function() onBackspace;
  final void Function()? onBiometric;
  final bool showBiometric;

  const PinPad({
    super.key,
    this.pinLength = 4,
    required this.currentLength,
    required this.onDigitTap,
    required this.onBackspace,
    this.onBiometric,
    this.showBiometric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── PIN DOTS ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinLength, (index) {
            final isFilled = index < currentLength;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? const Color(0xFF1A73E8) : Colors.transparent,
                border: Border.all(
                  color: isFilled
                      ? const Color(0xFF1A73E8)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        // ── DIGIT GRID ───────────────────────────────────
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            ...[
              '1',
              '2',
              '3',
              '4',
              '5',
              '6',
              '7',
              '8',
              '9',
            ].map((d) => _DigitButton(digit: d, onTap: () => onDigitTap(d))),
            // Bottom row: biometric | 0 | backspace
            if (showBiometric)
              _ActionButton(
                icon: Icons.fingerprint,
                onTap: onBiometric ?? () {},
              )
            else
              const SizedBox.shrink(),
            _DigitButton(digit: '0', onTap: () => onDigitTap('0')),
            _ActionButton(icon: Icons.backspace_outlined, onTap: onBackspace),
          ],
        ),
      ],
    );
  }
}

class _DigitButton extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _DigitButton({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Icon(icon, size: 24, color: const Color(0xFF2D3748)),
        ),
      ),
    );
  }
}
