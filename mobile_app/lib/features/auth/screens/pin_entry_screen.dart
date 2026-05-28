import 'package:flutter/material.dart';
import '../../../core/router/route_names.dart';
import '../../../services/secure_storage_service.dart';
import '../widgets/pin_pad.dart';

class PinEntryScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final String loginMethod;

  const PinEntryScreen({
    super.key,
    required this.userId,
    required this.displayName,
    this.loginMethod = 'pin',
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pin = '';
  bool _loading = false;
  String? _error;
  bool _shake = false;

  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);
  static const _maxPin = 4;

  void _onDigit(String digit) {
    if (_pin.length >= _maxPin) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == _maxPin) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final saved = await SecureStorageService.getPin();
      if (saved != null && saved == _pin) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, RouteNames.dashboard);
      } else {
        throw Exception('Invalid PIN');
      }
    } catch (_) {
      setState(() {
        _error = 'Incorrect PIN. Please try again.';
        _shake = true;
        _pin = '';
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _shake = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── AVATAR ────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _blue.withOpacity(0.1),
                ),
                child: const Icon(Icons.person_rounded, size: 38, color: _blue),
              ),
              const SizedBox(height: 14),
              Text(
                'Welcome back,',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                widget.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your 4-digit PIN to continue',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 36),

              // ── PIN DOTS + ERROR ──────────────────────
              AnimatedSlide(
                offset: _shake ? const Offset(0.05, 0) : Offset.zero,
                duration: const Duration(milliseconds: 100),
                child: PinPad(
                  pinLength: _maxPin,
                  currentLength: _pin.length,
                  onDigitTap: _onDigit,
                  onBackspace: _onBackspace,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),

              // ── DIFFERENT ACCOUNT LINK ────────────────
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, RouteNames.login),
                child: const Text(
                  'Sign in with a different account',
                  style: TextStyle(
                    fontSize: 13,
                    color: _blue,
                    fontWeight: FontWeight.w500,
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
