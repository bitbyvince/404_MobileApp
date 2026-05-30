import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/models/appointment_model.dart';
import '../../../core/router/route_names.dart';
import '../widgets/appointment_card.dart';
import '../widgets/appointment_status_badge.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);

  late TabController _tabController;
  bool _loadingUpcoming = true;
  bool _loadingPast = true;
  List<AppointmentModel> _upcoming = [];
  List<AppointmentModel> _past = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadUpcoming();
    _loadPast();
  }

  Future<void> _loadUpcoming() async {
    setState(() => _loadingUpcoming = true);
    try {
      final list = await AppointmentRepository.instance.getUpcoming();
      setState(() => _upcoming = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingUpcoming = false);
    }
  }

  Future<void> _loadPast() async {
    setState(() => _loadingPast = true);
    try {
      final result = await AppointmentRepository.instance.getPast(
        page: 1,
        limit: 20,
      );
      setState(() => _past = result.appointments);
    } catch (_) {
    } finally {
      setState(() => _loadingPast = false);
    }
  }

  Future<void> _cancel(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AppointmentRepository.instance.cancel(appointmentId);
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment cancelled.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Appointments',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              await context.push(RouteNames.bookAppointment);
              _loadAll();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Upcoming (${_upcoming.length})'),
            const Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUpcomingTab(), _buildPastTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push(RouteNames.bookAppointment);
          _loadAll();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Book Appointment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_loadingUpcoming) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_upcoming.isEmpty) {
      return _EmptyState(
        icon: Icons.calendar_today_outlined,
        message: 'No upcoming appointments.',
        subtitle: 'Tap the button below to book one.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUpcoming,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcoming.length,
        itemBuilder: (context, i) {
          final appt = _upcoming[i];
          return AppointmentCard(
            purpose: appt.purpose,
            scheduledDate: appt.formattedSchedule,
            scheduledTime: appt.scheduledTime,
            healthCenterName: appt.healthCenterName,
            status: appt.status,
            isToday: appt.isToday,
            onCancel: appt.isCancellable
                ? () => _cancel(appt.appointmentId)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildPastTab() {
    if (_loadingPast) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_past.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        message: 'No past appointments.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPast,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _past.length,
        itemBuilder: (context, i) {
          final appt = _past[i];
          return AppointmentCard(
            purpose: appt.purpose,
            scheduledDate: appt.formattedSchedule,
            scheduledTime: appt.scheduledTime,
            healthCenterName: appt.healthCenterName,
            status: appt.status,
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const _EmptyState({required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }
}
