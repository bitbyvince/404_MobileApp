import 'package:flutter/material.dart';
import '../../../core/router/route_names.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/secure_storage_service.dart';
import '../../../data/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _pinController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AuthRepository.instance.patientLogin(
        identifier: _identifierController.text.trim(),
        pin: _pinController.text.trim(),
      );

      await SecureStorageService.saveJwt(result['accessToken'] ?? '');
      await SecureStorageService.saveRefreshToken(result['refreshToken'] ?? '');

      // Fetch user profile and save identity if available
      final user = await AuthRepository.instance.getMe();
      await SecureStorageService.saveUserIdentity(
        userId: user.userId,
        patientId: user.patientId ?? '',
        tbCaseNumber: user.tbCaseNumber ?? '',
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.dashboard);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Patient ID or Email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: 'PIN / Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('LOGIN'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, RouteNames.accountRecovery),
              child: const Text(
                'Having trouble logging in? Contact your Health Center',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
