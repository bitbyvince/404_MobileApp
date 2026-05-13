// lib/screens/auth/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  // Receives { phone, confirmation } from RegisterScreen via GoRouter extra
  final Map<String, dynamic> extras;
  const OtpScreen({super.key, required this.extras});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otpCode = '';
  bool _loading = false;
  bool _resending = false;
  int _resendCountdown = 60;

  // verificationId is used when ConfirmationResult is not available (resend)
  String? _verificationId;
  ConfirmationResult? _confirmationResult;

  String get _phoneNumber => widget.extras['phone'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    // ConfirmationResult passed from RegisterScreen via GoRouter extras
    _verificationId = widget.extras['verificationId'] as String?;

    // If no confirmation result (e.g. deep link), trigger OTP ourselves
    if (_verificationId == null)
      _sendOtp();
    else
      _startCountdown();
  }

  // ── Resend OTP via Firebase verifyPhoneNumber ───────────────
  Future<void> _sendOtp() async {
    setState(() {
      _resending = true;
      _resendCountdown = 60;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneNumber,
      timeout: const Duration(seconds: 60),

      // Android auto-completes without user interaction
      verificationCompleted: (PhoneAuthCredential cred) async {
        await _signInWithCredential(cred);
      },

      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send OTP: ${e.message}'),
              backgroundColor: AppColors.critical,
            ),
          );
          setState(() => _resending = false);
        }
      },

      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _resending = false;
        });
        _startCountdown();
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  // ── Verify the entered OTP ──────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit OTP')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      UserCredential userCred;

      if (_confirmationResult != null) {
        // Use ConfirmationResult from initial registration flow
        userCred = await _confirmationResult!.confirm(_otpCode);
      } else if (_verificationId != null) {
        // Use verificationId from resend flow
        final cred = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: _otpCode,
        );
        userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      } else {
        throw Exception('No verification method available. Please resend OTP.');
      }

      await _signInWithCredential(userCred);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'invalid-verification-code'
            ? 'Incorrect OTP. Please try again.'
            : 'Verification failed: ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.critical),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── After Firebase confirms OTP, send idToken to backend ────
  // Backend route: POST /auth/verify-otp
  // Backend verifies with Firebase Admin SDK, finds/creates MongoDB user,
  // sets custom claims, returns your JWT.
  Future<void> _signInWithCredential(dynamic credOrUserCred) async {
    UserCredential userCred;

    if (credOrUserCred is UserCredential) {
      userCred = credOrUserCred;
    } else {
      userCred = await FirebaseAuth.instance.signInWithCredential(
        credOrUserCred as PhoneAuthCredential,
      );
    }

    final idToken = await userCred.user?.getIdToken();
    if (idToken == null) throw Exception('Firebase returned no ID token');

    // authProvider.confirmOtp() calls POST /auth/verify-otp with the idToken,
    // saves JWT + mongo_user_id to FlutterSecureStorage, registers FCM token
    await ref
        .read(authProvider.notifier)
        .verifyOtp(
          firebaseIdToken: idToken,
          userId: widget.extras['userId'] as String? ?? '',
          sessionId: widget.extras['sessionId'] as String? ?? '',
        );

    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = _loading || authState.status == AuthStatus.loading;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.skyBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 40,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 24),

              Text('Verify Your Number', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to\n$_phoneNumber',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              PinCodeTextField(
                appContext: context,
                length: 6,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 54,
                  fieldWidth: 46,
                  activeFillColor: AppColors.white,
                  inactiveFillColor: AppColors.background,
                  selectedFillColor: AppColors.skyBlue,
                  activeColor: AppColors.primaryBlue,
                  inactiveColor: AppColors.border,
                  selectedColor: AppColors.primaryBlue,
                ),
                enableActiveFill: true,
                onChanged: (v) => setState(() => _otpCode = v),
                onCompleted: (v) {
                  _otpCode = v;
                  _verifyOtp();
                },
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'VERIFY OTP',
                loading: isLoading,
                onPressed: isLoading ? null : _verifyOtp,
              ),
              const SizedBox(height: 20),

              _resendCountdown > 0
                  ? Text(
                      'Resend code in ${_resendCountdown}s',
                      style: AppTextStyles.caption,
                    )
                  : TextButton(
                      onPressed: _resending ? null : _sendOtp,
                      child: _resending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Resend OTP',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
