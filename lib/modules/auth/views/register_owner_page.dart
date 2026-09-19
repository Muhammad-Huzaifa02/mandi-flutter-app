import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/pk_phone.dart';
import 'package:mandi/core/utils/pk_cnic.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/modules/onboarding/views/shop_setup_wizard.dart';

/// Spec section 3 — Shop Owner Registration: owner info first, then hands
/// off to the Shop Setup Wizard (section 4) which collects shop info,
/// products, units, employees and finally calls createShopWithOwner.
class RegisterOwnerPage extends StatefulWidget {
  const RegisterOwnerPage({super.key});

  @override
  State<RegisterOwnerPage> createState() => _RegisterOwnerPageState();
}

class _RegisterOwnerPageState extends State<RegisterOwnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _mobile = TextEditingController();
  final _cnic = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context
          .read<AuthProvider>()
          .registerWithEmail(_email.text.trim(), _password.text);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ShopSetupWizard(
          ownerName: _fullName.text.trim(),
          ownerPhone: _mobile.text.trim(),
          ownerEmail: _email.text.trim(),
          ownerCnic: _cnic.text.trim().isEmpty ? null : _cnic.text.trim(),
        ),
      ));
    } on Exception catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Matches Supabase Auth (GoTrue) error message text, not Firebase's
  // error codes.
  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'An account already exists with this email.';
    }
    if (lower.contains('password should be at least')) {
      return 'Please choose a stronger password (6+ characters).';
    }
    return 'Could not create account. Please check your details.';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _mobile.dispose();
    _cnic.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Step 1 of 3', style: MText.labelSm.copyWith(color: MColors.primary)),
                const SizedBox(height: MSpacing.xs),
                const Text('Owner Information', style: MText.titleLg),
                const SizedBox(height: MSpacing.lg),
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) {
                    final formatted = PkPhone.formatAsTyped(v);
                    if (formatted != v) {
                      _mobile.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      hintText: '3XX XXXXXXX',
                      prefixText: '🇵🇰 +92  '),
                  validator: (v) => (v == null || !PkPhone.isValid(v))
                      ? PkPhone.errorMessage
                      : null,
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _cnic,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final formatted = PkCnic.formatAsTyped(v);
                    if (formatted != v) {
                      _cnic.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: const InputDecoration(
                      labelText: 'CNIC (optional)', hintText: 'XXXXX-XXXXXXX-X'),
                  validator: (v) => (v != null && v.isNotEmpty && !PkCnic.isValid(v))
                      ? PkCnic.errorMessage
                      : null,
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  validator: (v) => (v != _password.text) ? 'Passwords do not match' : null,
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
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
