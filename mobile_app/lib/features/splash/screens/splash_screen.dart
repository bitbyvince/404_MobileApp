import 'package:flutter/material.dart';
import '../../../core/router/route_names.dart';
import '../../../services/secure_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));

    // Check if user has a valid token
    final token = await SecureStorageService.getJwt();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // User is already logged in
      Navigator.pushReplacementNamed(context, RouteNames.dashboard);
    } else {
      // User needs to log in
      Navigator.pushReplacementNamed(context, RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 80, color: Colors.blue.shade50),
            const SizedBox(height: 24),
            Text(
              'RespiraTrack',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Partner in TB-DOTS Treatment',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
