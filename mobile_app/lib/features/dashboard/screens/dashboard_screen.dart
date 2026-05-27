import 'package:flutter/material.dart';
import '../../medication/screens/medication_screen.dart';
import '../../medication/screens/compliance_calendar_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../appointments/screens/appointments_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notification',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => Navigator.pushNamed(context, '/appointments'),
            )
          : null,
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello, Patient!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Medicine Inventory'),
                    SizedBox(height: 8),
                    Text('Anti-TB Medication Stock — 45 Doses Available'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text("Today's Medication"),
                subtitle: const Text('Anti-TB Meds (Daily Dose)'),
                trailing: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/medication'),
                  child: const Text('Mark as Taken'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: const [
                          Text('Compliance'),
                          SizedBox(height: 8),
                          Text('87%'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: const [
                          Text('Days Left'),
                          SizedBox(height: 8),
                          Text('135'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/medication'),
                  icon: const Icon(Icons.medical_services),
                  label: const Text('Medication'),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/symptoms/log'),
                  icon: const Icon(Icons.note_add),
                  label: const Text('Log Symptoms'),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/appointments'),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Appointments'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/sputum'),
                  icon: const Icon(Icons.science),
                  label: const Text('Sputum Tests'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
