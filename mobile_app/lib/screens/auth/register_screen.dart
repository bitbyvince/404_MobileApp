// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Format phone to E.164 for Firebase and backend
      final rawPhone = _phoneCtrl.text.trim();
      final e164Phone = rawPhone.startsWith('0')
          ? '+63${rawPhone.substring(1)}'
          : rawPhone.startsWith('+')
          ? rawPhone
          : '+63$rawPhone';

      // Step 1: POST /auth/register → creates unverified user in MongoDB
      // Returns { user_id, session_id }
      final result = await ref
          .read(authProvider.notifier)
          .register(
            contactNumber: e164Phone,
            password: _passCtrl.text,
            fullName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim().isEmpty
                ? null
                : _emailCtrl.text.trim(),
          );

      // Step 2: Send Firebase OTP via verifyPhoneNumber
      if (!mounted) return;
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: e164Phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (_) {}, // auto-complete handled in otp_screen
        verificationFailed: (e) {
          throw Exception(e.message);
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;
          // Navigate to OTP screen with all required extras
          context.push(
            '/otp',
            extra: {
              'phone': e164Phone,
              'userId': result['user_id'],
              'sessionId': result['session_id'],
              'verificationId': verificationId,
            },
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.toString())),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('409') || raw.contains('already registered')) {
      return 'This phone number is already registered. Try logging in instead.';
    }
    if (raw.contains('SocketException') || raw.contains('connection')) {
      return 'Cannot reach server. Check your internet connection.';
    }
    if (raw.contains('invalid-phone-number')) {
      return 'Invalid phone number format. Use 09XXXXXXXXX.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: const AppLogo(size: 70)),
                const SizedBox(height: 14),
                Center(child: Text('Create Account', style: AppTextStyles.h2)),
                Center(
                  child: Text(
                    'Sign up to get TB risk alerts in your area',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                _label('Full Name'),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Enter your full name',
                  keyboardType: TextInputType.name,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                _label('Email (optional)'),
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                _label('Mobile Number'),
                AppTextField(
                  controller: _phoneCtrl,
                  label: '09XX XXX XXXX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '🇵🇭 +63',
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                      return 'Enter a valid PH mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'You will receive an OTP SMS for verification.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 14),

                _label('Password'),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Create a password',
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 12),

                // Data privacy notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.lightBlue.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your information is confidential and protected under '
                          'the Data Privacy Act. It will only be used to send '
                          'TB risk alerts relevant to your area.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                PrimaryButton(
                  label: 'SEND OTP & REGISTER',
                  loading: _loading,
                  onPressed: _loading ? null : _register,
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: AppTextStyles.caption,
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.go('/login'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: AppTextStyles.bodyBold),
  );
}
