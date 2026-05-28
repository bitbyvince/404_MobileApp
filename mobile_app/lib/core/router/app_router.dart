// lib/core/router/app_router.dart

import 'package:flutter/material.dart'; // ← MISSING — fixes Scaffold/Center/Text errors
import 'package:go_router/go_router.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: RouteNames.pinEntry,
        name: 'pin-entry',
        builder: (context, state) => const PinEntryScreen(userId: '', displayName: '',),
      ),

      GoRoute(
        path: RouteNames.accountRecovery,
        name: 'account-recovery',
        builder: (context, state) => const AccountRecoveryScreen(),
      ),

      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        // Pass query params if DashboardScreen needs displayName/userId
        // They come from the patient profile loaded by the provider,
        // so DashboardScreen should read them from the provider,
        // NOT as constructor params — remove required params from DashboardScreen
        builder: (context, state) => const DashboardScreen(),
      ),

      GoRoute(
        path: RouteNames.medication,
        name: 'medication',
        builder: (context, state) => const MedicationScreen(),
      ),

      GoRoute(
        path: RouteNames.complianceCalendar,
        name: 'compliance-calendar',
        builder: (context, state) => const ComplianceCalendarScreen(),
      ),

      GoRoute(
        path: RouteNames.symptoms,
        name: 'symptoms',
        builder: (context, state) => const SymptomLogScreen(),
      ),

      GoRoute(
        path: RouteNames.appointments,
        name: 'appointments',
        builder: (context, state) => const AppointmentsScreen(),
      ),

      GoRoute(
        path: RouteNames.bookAppointment,
        name: 'book-appointment',
        builder: (context, state) => const BookAppointmentScreen(),
      ),

      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      GoRoute(
        path: RouteNames.sputum,
        name: 'sputum',
        builder: (context, state) => const SputumScreen(),
      ),

      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: RouteNames.healthRecords,
        name: 'health-records',
        builder: (context, state) => const HealthRecordsScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri.path}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ),
  );
});
