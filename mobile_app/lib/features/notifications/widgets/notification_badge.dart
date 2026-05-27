import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShow = count > 0 || showZero;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (shouldShow)
          Positioned(
            top: -4,
            right: -4,
            child: AnimatedScale(
              scale: shouldShow ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
