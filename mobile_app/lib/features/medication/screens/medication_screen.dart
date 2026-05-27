import 'package:flutter/material.dart';
import '../../../data/repositories/medication_repository.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = await MedicationRepository.instance.getLogByDate(
        date: DateTime.now(),
      );
      // ignore: avoid_print
      print('Loaded medication log: $today');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
            ? Text('Error: $_error')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Today\'s medication:'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await MedicationRepository.instance.markAllTaken(
                        takenAt: DateTime.now(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked all as taken')),
                      );
                    },
                    child: const Text('Mark as Taken'),
                  ),
                ],
              ),
      ),
    );
  }
}
