import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_navigation_wrapper.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const MainNavigationWrapper(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
