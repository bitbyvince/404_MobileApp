import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../medication/screens/compliance_calendar_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/router/route_names.dart';
import '../../../providers/patient_provider.dart';
import '../../../data/models/patient_model.dart';
import '../widgets/streak_card.dart';
import '../widgets/days_remaining_card.dart';
import '../widgets/sputum_countdown_card.dart';
import '../widgets/today_checklist_card.dart';
import '../widgets/quick_access_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  static const _navy = Color(0xFF1A3A5C);
  static const _blue = Color(0xFF1A73E8);

  final _pages = const [
    _HomePage(),
    ComplianceCalendarScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: _navy,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              backgroundColor: _blue,
              onPressed: () => context.push(RouteNames.bookAppointment),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _HomePage extends ConsumerStatefulWidget {
  const _HomePage();

  @override
  ConsumerState<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<_HomePage> {
  static const _blue = Color(0xFF1A73E8);

  bool _markingTaken = false;

  Future<void> _markTaken() async {
    setState(() => _markingTaken = true);
    try {
      // Wire to MedicationRepository.instance.markAllTaken in production
      await Future.delayed(const Duration(milliseconds: 800));
      ref.invalidate(patientProvider);
    } finally {
      if (mounted) setState(() => _markingTaken = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientProvider);
    return patientAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (patient) => _buildHome(patient),
    );
  }

  Widget _buildHome(PatientModel? patient) {
    final name = patient?.firstName ?? 'Patient';
    final compliance = patient?.compliance.compliancePercentage ?? 0.0;
    final daysLeft = patient != null
        ? patient.endDate.difference(DateTime.now()).inDays.clamp(0, 9999)
        : 0;
    final currentDay = patient?.currentTreatmentDay ?? 0;
    final totalDays = patient?.totalTreatmentDays ?? 180;
    final streakDays = patient?.compliance.consecutiveMissedDoses == 0
        ? patient?.compliance.dosesTaken ?? 0
        : 0;
    final takenToday = patient?.compliance.lastDoseTaken != null &&
        _isToday(patient!.compliance.lastDoseTaken!);

    // Sputum countdown
    final nextSputum = patient?.sputumTestSchedule
        .where((s) => s.status == 'Pending' && s.dueDate.isAfter(DateTime.now()))
        .toList()
      ?..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final hasSputum = nextSputum != null && nextSputum.isNotEmpty;
    final daysUntilSputum = hasSputum
        ? nextSputum.first.dueDate.difference(DateTime.now()).inDays
        : 0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(patientProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER BANNER ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: const BoxDecoration(color: _blue),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $name!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Day $currentDay of $totalDays Treatment',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── STREAK ────────────────────────────
                    StreakCard(
                      streakDays: streakDays,
                      takenToday: takenToday,
                    ),
                    const SizedBox(height: 12),

                    // ── COMPLIANCE + DAYS LEFT + PROGRESS ─
                    DaysRemainingCard(
                      daysRemaining: daysLeft,
                      totalDays: totalDays,
                      compliancePercentage: compliance,
                    ),
                    const SizedBox(height: 12),

                    // ── SPUTUM COUNTDOWN ──────────────────
                    SputumCountdownCard(
                      daysUntilTest: hasSputum ? daysUntilSputum : 0,
                      testMonth: hasSputum ? nextSputum.first.month : 0,
                      dueDate: hasSputum ? nextSputum.first.dueDate : null,
                      noTestScheduled: !hasSputum,
                    ),
                    const SizedBox(height: 12),

                    // ── TODAY'S CHECKLIST ─────────────────
                    TodayChecklistCard(
                      medicationName: 'Anti-TB Meds (Daily Dose)',
                      instruction: 'Take with water after meal',
                      isTaken: takenToday,
                      isLoading: _markingTaken,
                      date: DateTime.now(),
                      stockDoses: 45,
                      // ── Navigate to full medication screen on tap ──────────
                      onMarkTaken: () => context.push(RouteNames.medication),
                    ),
                    const SizedBox(height: 20),

                    // ── QUICK ACCESS ──────────────────────
                    const Text(
                      'QUICK ACCESS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9E9E9E),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    QuickAccessGrid(
                      items: [
                        const QuickAccessItem(
                          label: 'Medication',
                          icon: Icons.medication_rounded,
                          color: Color(0xFF1A73E8),
                          route: RouteNames.medication, // '/medication'
                        ),
                        const QuickAccessItem(
                          label: 'Symptoms',
                          icon: Icons.sick_outlined,
                          color: Color(0xFFE53935),
                          route: RouteNames.symptoms,
                        ),
                        const QuickAccessItem(
                          label: 'Sputum',
                          icon: Icons.biotech_outlined,
                          color: Color(0xFF9C27B0),
                          route: RouteNames.sputum,
                        ),
                        const QuickAccessItem(
                          label: 'Appointments',
                          icon: Icons.calendar_today_outlined,
                          color: Color(0xFF34A853),
                          route: RouteNames.appointments,
                        ),
                      ],
                      // ── KEY FIX: use context.push not Navigator.pushNamed ──
                      onTap: (route) => context.push(route),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}