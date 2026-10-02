import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/auth_provider.dart';

/// Dedicated mobile account activation page for staff, customers, and suppliers
/// accepting an email invitation.
class AccountActivationPage extends StatefulWidget {
  const AccountActivationPage({super.key});

  @override
  State<AccountActivationPage> createState() => _AccountActivationPageState();
}

class _AccountActivationPageState extends State<AccountActivationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final meta = auth.user?.userMetadata ?? {};

    _name = TextEditingController(text: meta['full_name'] as String? ?? '');
    _phone = TextEditingController(text: meta['phone'] as String? ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      // Update password in Supabase Auth
      await auth.updatePassword(_password.text);

      auth.clearNeedsPasswordSetup();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account activated successfully! Welcome to Mandi.'),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final meta = auth.user?.userMetadata ?? {};
    final shopName = meta['invited_to_shop'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Account Activation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Banner Card
                Container(
                  padding: const EdgeInsets.all(MSpacing.lg),
                  decoration: BoxDecoration(
                    color: MColors.primary.withValues(alpha: 0.08),
                    borderRadius: MRadius.lg,
                    border: Border.all(color: MColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined,
                              color: MColors.primary, size: 28),
                          const SizedBox(width: MSpacing.sm),
                          Expanded(
                            child: Text(
                              'Welcome to Mandi!',
                              style: MText.titleLg.copyWith(color: MColors.primary),
                            ),
                          ),
                        ],
                      ),
                      if (shopName.isNotEmpty) ...[
                        const SizedBox(height: MSpacing.xs),
                        Text(
                          'You have been invited to join $shopName',
                          style: MText.bodyMd.copyWith(
                              color: MColors.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: MSpacing.xs),
                      Text(
                        'Email: ${auth.user?.email ?? ''}',
                        style: MText.bodySm.copyWith(color: MColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: MSpacing.lg),

                const Text('Complete Your Profile & Password', style: MText.titleLg),
                const SizedBox(height: MSpacing.sm),

                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Muhammad Ali',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),

                const SizedBox(height: MSpacing.md),

                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    hintText: '0300 1234567',
                  ),
                ),

                const SizedBox(height: MSpacing.md),

                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Create Password *',
                    hintText: 'Minimum 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: MSpacing.md),

                TextFormField(
                  controller: _confirmPassword,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password *',
                    hintText: 'Re-enter your password',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _password.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: MSpacing.md),
                  Text(_error!, style: const TextStyle(color: MColors.danger)),
                ],

                const SizedBox(height: MSpacing.xl),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Activate Account & Open Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
