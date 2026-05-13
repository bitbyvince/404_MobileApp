// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      // Calls POST /auth/login on your backend
      // Backend verifies credentials against MongoDB public_users
      // Returns JWT → stored in FlutterSecureStorage by authProvider
      await ref
          .read(authProvider.notifier)
          .login(idOrEmail: _idCtrl.text.trim(), password: _passCtrl.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.toString())),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('401') || raw.contains('Invalid credentials')) {
      return 'Incorrect ID/email or password.';
    }
    if (raw.contains('403') || raw.contains('not verified')) {
      return 'Phone number not verified. Please register and complete OTP.';
    }
    if (raw.contains('SocketException') || raw.contains('connection')) {
      return 'Cannot reach server. Check your internet connection.';
    }
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    // Watch loading state from authProvider
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const AppLogo(size: 100),
                const SizedBox(height: 16),
                Text('RespiraTrack', style: AppTextStyles.appTitle),
                const SizedBox(height: 4),
                Text(
                  'Your Partner in TB-DOTS Treatment',
                  style: AppTextStyles.appSubtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 52),

                // Patient ID or Email — matches backend id_or_email field
                AppTextField(
                  controller: _idCtrl,
                  label: 'Patient ID or Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  obscureText: _obscure,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'LOGIN',
                  loading: isLoading,
                  onPressed: isLoading ? null : _login,
                ),
                const SizedBox(height: 28),

                Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: AppTextStyles.caption,
                    children: [
                      TextSpan(
                        text: 'Register here',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.go('/register'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Text.rich(
                  TextSpan(
                    text: 'Having trouble logging in?\n',
                    style: AppTextStyles.caption,
                    children: [
                      TextSpan(
                        text: 'Contact your Health Center',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {},
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
