import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/auth_provider.dart';

class ForgotPasswordNewPasswordPage extends StatefulWidget {
  const ForgotPasswordNewPasswordPage({super.key});

  @override
  State<ForgotPasswordNewPasswordPage> createState() =>
      _ForgotPasswordNewPasswordPageState();
}

class _ForgotPasswordNewPasswordPageState
    extends State<ForgotPasswordNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _error;
  bool _done = false;

  /// 0-3: rough strength — length, then a mix of letters+digits, then
  /// length+a symbol. Intentionally simple; this is feedback, not a gate.
  int get _strength {
    final v = _password.text;
    var s = 0;
    if (v.length >= 6) s++;
    if (RegExp(r'[A-Za-z]').hasMatch(v) && RegExp(r'[0-9]').hasMatch(v)) s++;
    if (v.length >= 10 && RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;
    return s;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().updatePassword(_password.text);
      if (!mounted) return;
      setState(() => _done = true);
    } catch (e) {
      setState(() => _error = 'Could not update your password. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: MColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: MColors.success, size: 34),
                ),
                const SizedBox(height: MSpacing.lg),
                const Text('Password Updated', style: MText.titleLg),
                const SizedBox(height: MSpacing.xs),
                Text(
                  'You\'re signed in — taking you to your dashboard now.',
                  textAlign: TextAlign.center,
                  style: MText.bodyMd.copyWith(color: MColors.textSecondary),
                ),
                const SizedBox(height: MSpacing.lg),
                ElevatedButton(
                  // Verifying the OTP already created a session, so the
                  // person is authenticated at this point — AppRoot will
                  // route them straight to their dashboard, not back to
                  // the login form.
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Password'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose a new password for your account.',
                  style: MText.bodyMd.copyWith(color: MColors.textSecondary),
                ),
                const SizedBox(height: MSpacing.lg),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure1,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: MSpacing.xs),
                Row(
                  children: List.generate(3, (i) {
                    final on = i < _strength;
                    final colors = [MColors.danger, MColors.warning, MColors.success];
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: on ? colors[_strength - 1] : Colors.grey.shade300,
                          borderRadius: MRadius.full,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) =>
                      (v != _password.text) ? 'Passwords do not match' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: MSpacing.sm),
                  Text(_error!, style: const TextStyle(color: MColors.danger)),
                ],
                const SizedBox(height: MSpacing.lg),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Update Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
