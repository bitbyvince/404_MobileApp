import 'package:flutter/material.dart';

class MarkTakenButton extends StatelessWidget {
  final bool isTaken;
  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  const MarkTakenButton({
    super.key,
    required this.isTaken,
    required this.isLoading,
    required this.onPressed,
    this.label = 'Mark as Taken',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: isTaken
            ? _TakenState(key: const ValueKey('taken'))
            : _NotTakenState(
                key: const ValueKey('not_taken'),
                label: label,
                isLoading: isLoading,
                onPressed: onPressed,
              ),
      ),
    );
  }
}

class _TakenState extends StatelessWidget {
  const _TakenState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF34A853).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF34A853).withOpacity(0.35)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF34A853), size: 20),
          SizedBox(width: 8),
          Text(
            'Medication Taken',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34A853),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotTakenState extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _NotTakenState({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF34A853),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF34A853).withOpacity(0.6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }
}
