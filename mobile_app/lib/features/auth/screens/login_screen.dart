import 'package:flutter/material.dart';
import '../../../core/router/route_names.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/secure_storage_service.dart';
import '../widgets/login_input_field.dart';
import '../widgets/login_method_toggle.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _pinController = TextEditingController();

  LoginMethod _method = LoginMethod.identifier;
  bool _loading = false;
  String? _error;

  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);

  @override
  void dispose() {
    _identifierController.dispose();
    _pinController.dispose();
    super.dispose();
  }

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
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.dashboard);
    } catch (e) {
      setState(() => _error = 'Invalid credentials. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                const SizedBox(height: 20),

                // ── LOGO ──────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _blue.withOpacity(0.08),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    size: 52,
                    color: _blue,
                  ),
                ),
                const SizedBox(height: 16),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 36),

                // ── LOGIN METHOD TOGGLE ───────────────────
                LoginMethodToggle(
                  selected: _method,
                  onChanged: (m) => setState(() {
                    _method = m;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 24),

                // ── IDENTIFIER FIELD ─────────────────────
                LoginInputField(
                  label: 'Patient ID or Email',
                  hint: _method == LoginMethod.identifier
                      ? 'PHNT-137-071-S26-0001 or email'
                      : _method == LoginMethod.pin
                      ? 'TB case number or phone'
                      : 'Registered phone number',
                  controller: _identifierController,
                  keyboardType: _method == LoginMethod.otp
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  prefixIcon: Icon(
                    _method == LoginMethod.otp
                        ? Icons.phone_outlined
                        : Icons.badge_outlined,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'This field is required.' : null,
                ),
                const SizedBox(height: 16),

                // ── PIN / PASSWORD FIELD ──────────────────
                if (_method != LoginMethod.otp) ...[
                  LoginInputField(
                    label: _method == LoginMethod.pin ? 'PIN' : 'Password',
                    hint: _method == LoginMethod.pin
                        ? 'Enter your 4-digit PIN'
                        : 'Enter your password',
                    controller: _pinController,
                    obscureText: true,
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'PIN is required.';
                      if (_method == LoginMethod.pin && v.length != 4) {
                        return 'PIN must be 4 digits.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'An OTP will be sent to your registered phone number.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── ERROR MESSAGE ─────────────────────────
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
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

                // ── LOGIN BUTTON ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
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
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── RECOVERY LINK ─────────────────────────
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, RouteNames.accountRecovery),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      children: const [
                        TextSpan(text: 'Having trouble logging in?\n'),
                        TextSpan(
                          text: 'Contact your Health Center',
                          style: TextStyle(
                            color: _blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
