// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/secure_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _pinController = TextEditingController();

  bool _loading = false;
  bool _obscurePin = true;
  String? _error;

  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);

  // ── Detect what the user typed ─────────────────────────
  // Shown as a hint tag below the identifier field
  String get _identifierHint {
    final text = _identifierController.text.trim();
    if (text.isEmpty) return '';
    if (RegExp(r'^PHNT-', caseSensitive: false).hasMatch(text)) {
      return 'TB Case Number';
    }
    if (RegExp(r'^(\+63|0)9').hasMatch(text)) {
      return 'Phone Number';
    }
    if (text.contains('@')) {
      return 'Email Address';
    }
    return '';
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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

      final user = await AuthRepository.instance.getMe();
      await SecureStorageService.saveUserIdentity(
        userId: user.userId,
        patientId: user.patientId ?? '',
        tbCaseNumber: user.tbCaseNumber ?? '',
      );

      // Save identifier for pre-fill on next launch
      await SecureStorageService.saveIdentifier(
        _identifierController.text.trim(),
      );

      if (!mounted) return;
      context.go(RouteNames.dashboard); // GoRouter — not Navigator
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Invalid credentials. Please check your '
            'details and try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Identifier validator ───────────────────────────────
  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your TB case number, phone number, or email.';
    }

    final v = value.trim();

    // TB case number: PHNT-1304-071-S26-0001
    if (RegExp(
      r'^PHNT-\d{4}-\d{3}-(S|DR)\d{2}-\d{4}$',
      caseSensitive: false,
    ).hasMatch(v))
      return null;

    // Philippine phone: 09XXXXXXXXX or +639XXXXXXXXX
    if (RegExp(r'^(\+63|0)9\d{9}$').hasMatch(v)) return null;

    // Email
    if (RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(v))
      return null;

    return 'Enter a valid TB case number '
        '(PHNT-1304-071-S26-0001), '
        'phone (09XXXXXXXXX), or email.';
  }

  // ── PIN validator ──────────────────────────────────────
  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your 4-digit PIN.';
    }
    if (value.length != 4) {
      return 'PIN must be exactly 4 digits.';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'PIN must contain numbers only.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // ── Logo ────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _blue.withValues(alpha: 0.08),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/images/logo404.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── App name ─────────────────────────────
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Respira',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _blue,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Track',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Partner in TB-DOTS Treatment',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 40),

                // ── Section label ────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Use your TB case number, phone, or email',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Identifier field ──────────────────────
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _identifierController,
                  builder: (context, value, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: 'TB Case No. / Phone / Email',
                            hintText: 'PHNT-1304-071-S26-0001',
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                            // Shows detected type tag (e.g. "TB Case Number")
                            suffixIcon: _identifierHint.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Chip(
                                      label: Text(
                                        _identifierHint,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _blue,
                                        ),
                                      ),
                                      backgroundColor: _blue.withValues(
                                        alpha: 0.08,
                                      ),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      side: BorderSide.none,
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _blue,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade400,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade400,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: _validateIdentifier,
                        ),

                        // Accepted formats hint
                        const SizedBox(height: 6),
                        Text(
                          'Accepted: PHNT-1304-071-S26-0001 '
                          '• 09XXXXXXXXX • email@example.com',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── PIN field ─────────────────────────────
                TextFormField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  maxLength: 4,
                  // Only allow digits
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '4-Digit PIN',
                    hintText: '••••',
                    counterText: '', // hides the "0/4" character counter
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePin = !_obscurePin),
                      icon: Icon(
                        _obscurePin
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _blue, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red.shade400,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: _validatePin,
                ),
                const SizedBox(height: 8),

                // ── Forgot PIN link ───────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.push(RouteNames.accountRecovery),
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        fontSize: 13,
                        color: _blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Error message ─────────────────────────
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Login button ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _blue.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Contact health center link ─────────────
                Text(
                  "Don't have an account?",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.push(RouteNames.accountRecovery),
                  child: Text(
                    'Contact your Health Center',
                    style: TextStyle(
                      fontSize: 13,
                      color: _blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
