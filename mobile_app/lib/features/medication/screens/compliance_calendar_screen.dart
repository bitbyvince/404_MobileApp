import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ComplianceCalendarScreen extends StatelessWidget {
  const ComplianceCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Calendar')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: DateTime.now(),
            ),
            const SizedBox(height: 12),
            const Text('Green = Taken, Red = Missed, Yellow = Partial'),
          ],
        ),
      ),
    );
  }
}
