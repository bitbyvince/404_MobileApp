import 'package:flutter/material.dart';

class AccountRecoveryScreen extends StatelessWidget {
  const AccountRecoveryScreen({super.key});

  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Account Recovery',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ICON ──────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 48,
                  color: _blue,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Need help accessing your account?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow the steps below to regain access to your RespiraTrack account.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // ── STEPS ────────────────────────────────────
            _RecoveryStep(
              number: '1',
              title: 'Locate your TB Case Number',
              description:
                  'Your TB case number (e.g. PHNT-137-071-S26-0001) was given to you by your health center when you were registered.',
            ),
            const SizedBox(height: 16),
            _RecoveryStep(
              number: '2',
              title: 'Contact your Health Center',
              description:
                  'Visit or call your assigned barangay health center and provide your full name and TB case number. Staff will verify your identity and reset your PIN.',
            ),
            const SizedBox(height: 16),
            _RecoveryStep(
              number: '3',
              title: 'Use your phone number',
              description:
                  'If you registered a phone number, you can also request an OTP to log in without your PIN.',
            ),
            const SizedBox(height: 32),

            // ── HEALTH CENTERS ────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pasig City Health Centers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HealthCenterTile(
                    name: 'Caniogan Health Center - IDOTS',
                    phone: '02-8123-4567',
                    icon: Icons.local_hospital_outlined,
                  ),
                  const Divider(),
                  _HealthCenterTile(
                    name: 'Bambang Health Center - IDOTS',
                    phone: '02-8234-5678',
                    icon: Icons.local_hospital_outlined,
                  ),
                  const Divider(),
                  _HealthCenterTile(
                    name: 'Nagpayong Super Health Center - IDOTS',
                    phone: '02-8345-6789',
                    icon: Icons.local_hospital_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── BACK TO LOGIN ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  side: const BorderSide(color: _blue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text(
                  'Back to Login',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _RecoveryStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF1A73E8),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthCenterTile extends StatelessWidget {
  final String name;
  final String phone;
  final IconData icon;

  const _HealthCenterTile({
    required this.name,
    required this.phone,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
