import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/modules/auth/views/forgot_password_new_password_page.dart';

class ForgotPasswordOtpPage extends StatefulWidget {
  final String phoneE164;
  const ForgotPasswordOtpPage({super.key, required this.phoneE164});

  @override
  State<ForgotPasswordOtpPage> createState() => _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState extends State<ForgotPasswordOtpPage> {
  static const _codeLength = 6;
  final List<TextEditingController> _boxes =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(_codeLength, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  String get _code => _boxes.map((c) => c.text).join();

  void _onDigitChanged(int i, String v) {
    if (_error != null) setState(() => _error = null);
    if (v.isNotEmpty && i < _codeLength - 1) {
      _nodes[i + 1].requestFocus();
    }
    if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    if (_code.length == _codeLength) _verify();
  }

  Future<void> _verify() async {
    if (_code.length < _codeLength) {
      setState(() => _error = 'Enter the full 6-digit code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context
          .read<AuthProvider>()
          .verifyPhoneOtp(widget.phoneE164, _code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ForgotPasswordNewPasswordPage()),
      );
    } catch (e) {
      setState(() {
        _error = 'Incorrect code. Please try again.';
        for (final c in _boxes) {
          c.clear();
        }
      });
      _nodes.first.requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await context.read<AuthProvider>().sendPhoneOtp(widget.phoneE164);
      _startCountdown();
    } catch (_) {
      setState(() => _error = 'Could not resend the code. Please try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _boxes) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: MSpacing.md),
              Text('Enter the 6-digit code sent to',
                  style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
              const SizedBox(height: 4),
              Text(widget.phoneE164,
                  style: MText.titleLg.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Change number'),
              ),
              const SizedBox(height: MSpacing.md),
              AbsorbPointer(
                absorbing: _loading,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_codeLength, (i) {
                    return SizedBox(
                      width: 44,
                      child: TextField(
                        controller: _boxes[i],
                        focusNode: _nodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: MText.titleLg,
                        decoration: InputDecoration(
                          counterText: '',
                          errorBorder: _error != null
                              ? OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: MColors.danger),
                                  borderRadius: MRadius.md)
                              : null,
                        ),
                        onChanged: (v) => _onDigitChanged(i, v),
                      ),
                    );
                  }),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: MSpacing.sm),
                Text(_error!, style: const TextStyle(color: MColors.danger)),
              ],
              const SizedBox(height: MSpacing.md),
              _secondsLeft > 0
                  ? Text('Resend code in ${_secondsLeft}s',
                      style: MText.labelSm.copyWith(color: MColors.textSecondary))
                  : TextButton(
                      onPressed: _resending ? null : _resend,
                      child: _resending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Resend OTP'),
                    ),
              const SizedBox(height: MSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
