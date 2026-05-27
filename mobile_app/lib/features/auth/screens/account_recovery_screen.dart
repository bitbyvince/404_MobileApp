import 'package:flutter/material.dart';

class AccountRecoveryScreen extends StatelessWidget {
  const AccountRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Recovery')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'If you cannot access your account, please contact your assigned health center.\n\nProvide your TB case number or registered phone number when contacting support.',
            ),
            SizedBox(height: 20),
            Text('You can also request a PIN reset from your health center.'),
          ],
        ),
      ),
    );
  }
}
