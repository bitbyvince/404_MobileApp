import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/route_names.dart';
import '../../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set up fade animation — this is lightweight, fine on main thread
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // Kick off heavy initialization AFTER the first frame renders
    // addPostFrameCallback ensures the splash UI is painted first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  // Inside _SplashScreenState

  Future<void> _initialize() async {
    try {
      final results = await Future.wait([
        _checkSession(),
        Future.delayed(const Duration(milliseconds: 2000)),
      ]);

      final isLoggedIn = results[0] as bool;

      if (!mounted) return;

      // ── KEY FIX ───────────────────────────────────────────
      // Small delay ensures GoRouter is fully mounted in the
      // widget tree before we call context.go()
      await Future.microtask(() {});

      if (!mounted) return;

      if (isLoggedIn) {
        context.go(RouteNames.dashboard);
      } else {
        context.go(RouteNames.login);
      }
    } catch (e) {
      debugPrint('[SplashScreen] Initialization error: $e');
      // Wait for router to be ready before navigating on error
      await Future.microtask(() {});
      if (mounted) context.go(RouteNames.login);
    }
  }

  // ── Session check ────────────────────────────────────────
  // Wrapped in a separate method so it runs as a Future
  // without blocking the animation or UI rendering
  Future<bool> _checkSession() async {
    try {
      // flutter_secure_storage first-time crypto verification
      // happens here — it's slow but now it's off the main render loop
      return await AuthService.checkExistingSession();
    } catch (e) {
      debugPrint('[SplashScreen] Session check failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use your brand navy blue color
      backgroundColor: const Color(0xFF1A3A5C),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/images/logo404.png', width: 120, height: 120),
              const SizedBox(height: 24),

              // App name
              const Text(
                'RespiraTrack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'TB Monitoring System',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator — shows the app is working
              // not frozen
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
