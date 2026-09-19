import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/pk_phone.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/modules/auth/views/forgot_password_otp_page.dart';

class ForgotPasswordPhonePage extends StatefulWidget {
  const ForgotPasswordPhonePage({super.key});

  @override
  State<ForgotPasswordPhonePage> createState() =>
      _ForgotPasswordPhonePageState();
}

class _ForgotPasswordPhonePageState extends State<ForgotPasswordPhonePage> {
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  void _onChanged(String v) {
    final formatted = PkPhone.formatAsTyped(v);
    if (formatted != v) {
      _phone.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _sendOtp() async {
    if (!PkPhone.isValid(_phone.text)) {
      setState(() => _error = PkPhone.errorMessage);
      return;
    }
    final e164 = PkPhone.toE164(_phone.text)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().sendPhoneOtp(e164);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ForgotPasswordOtpPage(phoneE164: e164)),
      );
    } catch (e) {
      setState(() =>
          _error = 'Could not send the code. Please check the number and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: MSpacing.md),
              Text(
                'Enter your registered phone number — we\'ll send a one-time '
                'code to verify it\'s you.',
                style: MText.bodyMd.copyWith(color: MColors.textSecondary),
              ),
              const SizedBox(height: MSpacing.lg),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '3XX XXXXXXX',
                  prefixText: '🇵🇰 +92  ',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: MSpacing.xs),
                Text(_error!, style: const TextStyle(color: MColors.danger)),
              ],
              const SizedBox(height: MSpacing.lg),
              ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
