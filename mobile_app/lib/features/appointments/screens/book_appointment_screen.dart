import 'package:flutter/material.dart';
import '../../../data/repositories/appointment_repository.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  bool _loading = false;

  Future<void> _book() async {
    setState(() => _loading = true);
    try {
      final appt = await AppointmentRepository.instance.book(
        scheduledDate: DateTime.now().add(const Duration(days: 7)),
        scheduledTime: '09:00',
        purpose: 'Follow-up',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment requested')));
      Navigator.pop(context, appt);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Center(
        child: ElevatedButton(
          onPressed: _loading ? null : _book,
          child: _loading
              ? const CircularProgressIndicator()
              : const Text('Request'),
        ),
      ),
    );
  }
}
