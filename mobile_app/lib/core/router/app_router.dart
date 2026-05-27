import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/pin_entry_screen.dart';
import '../../features/auth/screens/account_recovery_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/medication/screens/medication_screen.dart';
import '../../features/medication/screens/compliance_calendar_screen.dart';
import '../../features/symptoms/screens/symptom_log_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';
import '../../features/appointments/screens/book_appointment_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/sputum/screens/sputum_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/health_records_screen.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Splash ───────────────────────────────────────────
      case '/':
      case RouteNames.splash:
        return _fade(const SplashScreen(), settings);

      // ── Auth ─────────────────────────────────────────────
      case RouteNames.login:
      case '/login':
        return _slide(const LoginScreen(), settings);

      case RouteNames.pinEntry:
      case '/login/pin':
        final args = settings.arguments as Map<String, dynamic>? ?? {};

        return _slide(
          PinEntryScreen(
            userId: args['user_id'] as String? ?? '',
            displayName: args['display_name'] as String? ?? '',
            loginMethod: args['login_method'] as String? ?? 'pin',
          ),
          settings,
        );

      case RouteNames.accountRecovery:
      case '/login/recovery':
        return _slide(const AccountRecoveryScreen(), settings);

      // ── Main ─────────────────────────────────────────────
      case RouteNames.dashboard:
      case '/dashboard':
        return _fade(const DashboardScreen(), settings);

      // ── Medication ───────────────────────────────────────
      case RouteNames.medication:
      case '/medication':
        return _slide(const MedicationScreen(), settings);

      case RouteNames.complianceCalendar:
      case '/medication/calendar':
        return _slide(const ComplianceCalendarScreen(), settings);

      // ── Symptoms ─────────────────────────────────────────
      case RouteNames.symptomLog:
      case '/symptoms/log':
        return _slide(const SymptomLogScreen(), settings);

      // ── Appointments ─────────────────────────────────────
      case RouteNames.appointments:
      case '/appointments':
        return _slide(const AppointmentsScreen(), settings);

      case RouteNames.bookAppointment:
      case '/appointments/book':
        return _modal(const BookAppointmentScreen(), settings);

      // ── Notifications ────────────────────────────────────
      case RouteNames.notifications:
      case '/notifications':
        return _slide(const NotificationsScreen(), settings);

      // ── Sputum ───────────────────────────────────────────
      case RouteNames.sputum:
      case '/sputum':
        return _slide(const SputumScreen(), settings);

      // ── Profile ──────────────────────────────────────────
      case RouteNames.profile:
      case '/profile':
        return _slide(const ProfileScreen(), settings);

      case RouteNames.healthRecords:
      case '/profile/health-records':
        return _slide(const HealthRecordsScreen(), settings);

      // ── 404 ──────────────────────────────────────────────
      default:
        return _error(settings.name ?? 'unknown');
    }
  }

  // ── Transition builders ──────────────────────────────────

  /// Standard right-to-left slide transition
  static PageRouteBuilder _slide(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        final tween = Tween<Offset>(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  /// Fade transition
  static PageRouteBuilder _fade(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Bottom slide-up modal transition
  static PageRouteBuilder _modal(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      opaque: false,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween<Offset>(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }

  /// Unknown route fallback
  static MaterialPageRoute _error(String routeName) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text(
            'No route defined for "$routeName"',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
