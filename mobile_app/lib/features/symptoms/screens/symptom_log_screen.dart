import 'package:flutter/material.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../data/models/symptom_log_model.dart';

class SymptomLogScreen extends StatefulWidget {
  const SymptomLogScreen({super.key});

  @override
  State<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends State<SymptomLogScreen> {
  final _symptoms = <SymptomEntry>[];
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await SymptomRepository.instance.submitLog(
        symptoms: _symptoms,
        freeTextNotes: '',
      );
      // ignore: avoid_print
      print('Submitted: $result');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Symptoms submitted')));
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
      appBar: AppBar(title: const Text('Log Symptoms')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text('Select symptoms and severity (simple demo)'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
