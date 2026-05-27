import 'package:flutter/material.dart';

class HealthRecordsScreen extends StatelessWidget {
  const HealthRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Records')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Treatment Start Date'),
              subtitle: const Text('January 15, 2026'),
            ),
            ListTile(
              title: const Text('Regimen'),
              subtitle: const Text(
                '2 months intensive + 4 months continuation',
              ),
            ),
            ListTile(
              title: const Text('Assigned Physician'),
              subtitle: const Text('Dr. Maria Santos'),
            ),
            ListTile(
              title: const Text('TB Case Number'),
              subtitle: const Text('TB-2026-001234'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Medication History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Anti-TB Medications'),
                subtitle: const Text('90+ doses taken\n2 doses missed'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sputum Tests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Month 2 Test'),
                subtitle: const Text('Negative - Excellent progress'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
