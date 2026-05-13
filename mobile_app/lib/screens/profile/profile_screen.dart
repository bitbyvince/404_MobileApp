// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

// Provider: GET /user/profile — returns MongoDB public_users document
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.getMyProfile();
  return res['user'] as Map<String, dynamic>;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.critical,
              ),
              const SizedBox(height: 12),
              Text('Could not load profile', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (user) {
          // All fields come from MongoDB public_users document
          final fullName = user['full_name'] as String? ?? 'User';
          final contactNumber = user['contact_number'] as String? ?? '';
          final email = user['email'] as String? ?? '';
          final otpVerified = user['otp_verified'] as bool? ?? false;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Avatar & Info ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.skyBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBlue,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(fullName, style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Text(contactNumber, style: AppTextStyles.caption),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(email, style: AppTextStyles.caption),
                    ],
                    const SizedBox(height: 10),
                    // OTP verification badge — from otp_verified field
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: otpVerified
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: otpVerified
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        otpVerified
                            ? '✓ Phone Verified'
                            : '⚠ Phone Not Verified',
                        style: TextStyle(
                          color: otpVerified
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Settings ────────────────────────────────────
              Text('Settings', style: AppTextStyles.h3),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notification Preferences',
                      onTap: () {},
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      label: 'Location Sharing',
                      onTap: () {},
                      trailing: Switch(
                        value: true,
                        onChanged: (_) {},
                        activeColor: AppColors.primaryBlue,
                      ),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      onTap: () {},
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Data Privacy Notice ─────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.skyBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.security_outlined,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Your health information is strictly confidential and '
                        'protected under the Data Privacy Act of 2012.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Logout — calls authProvider.logout() ────────
              // Clears JWT from secure storage + signs out of Firebase
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.critical,
                ),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.critical),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.critical),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue, size: 22),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(color: AppColors.textDark),
      ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    color: AppColors.border,
    indent: 56,
    endIndent: 16,
  );
}
