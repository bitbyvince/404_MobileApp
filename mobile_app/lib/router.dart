// lib/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/main_shell.dart';
import 'screens/home/home_screen.dart';
import 'screens/heatmap/heatmap_screen.dart';
import 'screens/education/education_screen.dart';
import 'screens/education/education_detail_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    // ── Redirect guard ─────────────────────────────────────────
    // Redirects unauthenticated users to /login from protected routes.
    // Redirects authenticated users away from /login and /register.
    redirect: (context, state) {
      final authState = ref.watch(authProvider);
      final isAuthed = authState.isAuthenticated;
      final isLoading = authState.isLoading;

      final onAuthRoute =
          state.uri.path == '/login' ||
          state.uri.path == '/register' ||
          state.uri.path == '/otp' ||
          state.uri.path == '/splash';

      if (isLoading) return '/splash';
      if (!isAuthed && !onAuthRoute) return '/login';
      if (isAuthed && state.uri.path == '/login') return '/home';
      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // OTP screen receives { phone, confirmation } map from RegisterScreen
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(extras: extras);
        },
      ),

      // Main shell wraps all authenticated routes with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/map', builder: (_, __) => const HeatmapScreen()),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/education',
            builder: (_, __) => const EducationScreen(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                builder: (context, state) => EducationDetailScreen(
                  contentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
