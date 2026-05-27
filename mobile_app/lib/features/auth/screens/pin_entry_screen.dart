import 'package:flutter/material.dart';
import '../../../core/router/route_names.dart';
import '../../../services/secure_storage_service.dart';
import '../../../data/repositories/auth_repository.dart';

class PinEntryScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final String loginMethod;

  const PinEntryScreen({
    super.key,
    required this.userId,
    required this.displayName,
    this.loginMethod = 'pin',
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // For now, verify by checking saved PIN in secure storage (mock flow)
      final saved = await SecureStorageService.getPin();
      if (saved != null && saved == _pinController.text.trim()) {
        Navigator.pushReplacementNamed(context, RouteNames.dashboard);
      } else {
        throw Exception('Invalid PIN');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Welcome, ${widget.displayName}'),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: 'PIN'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
