import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/pk_cnic.dart';
import 'package:mandi/core/utils/pk_phone.dart';
import 'package:mandi/modules/onboarding/views/shop_setup_wizard.dart';
import 'package:mandi/providers/auth_provider.dart';

/// Step 1 of 3 — creates the Supabase Auth account only. The shop itself
/// is created later, by the Shop Setup Wizard's Finish button, and only
/// once a real session exists.
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
  final _confirm = TextEditingController();

  bool _loading = false;
  String? _error; // friendly message shown to every user
  String? _debugDetail; // raw error, shown ONLY in debug builds

  @override
  void dispose() {
    _fullName.dispose();
    _mobile.dispose();
    _cnic.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _reformat(
      TextEditingController c, String Function(String) format, String v) {
    final formatted = format(v);
    if (formatted != v) {
      c.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // Read everything needed from context BEFORE the first await.
    final auth = context.read<AuthProvider>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = _fullName.text.trim();
    final email = _email.text.trim();
    final phone = PkPhone.toE164(_mobile.text)!; // validated above
    final cnic =
        _cnic.text.trim().isEmpty ? null : PkCnic.formatAsTyped(_cnic.text);

    setState(() {
      _loading = true;
      _error = null;
      _debugDetail = null;
    });

    try {
      final response = await auth.registerWithEmail(
        email,
        _password.text,
        fullName: name,
      );
      if (!mounted) return;

      // With "Confirm email" ON, Supabase answers a repeat sign-up for an
      // already-registered address with a fake success (no error) whose
      // user has an EMPTY identities list — that is the duplicate-email
      // signal, not a new account.
      final identities = response.user?.identities;
      if (identities != null && identities.isEmpty) {
        setState(() => _error =
            'This email is already registered. Please sign in or use another email.');
        return;
      }

      // No session yet = the project requires email confirmation first.
      // Don't enter the wizard: its Finish step needs a real session.
      if (response.session == null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirm your email'),
            content: Text(
              'We sent a confirmation link to $email. Tap it, then come back '
              'and log in to finish setting up your shop.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) nav.pop();
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Account created. Now set up your shop.')),
      );
      nav.pushReplacement(MaterialPageRoute(
        builder: (_) => ShopSetupWizard(
          ownerName: name,
          ownerPhone: phone,
          ownerEmail: email,
          ownerCnic: cnic,
        ),
      ));
    } catch (e, st) {
      // Always log the real cause for developers.
      debugPrint('SIGNUP_ERROR: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _debugDetail = kDebugMode ? e.toString() : null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Maps Supabase Auth / Postgres / network failures to plain language.
  /// Matches on the exception text AND Supabase's error-code names
  /// (e.g. email_exists, over_email_send_rate_limit). Never returns raw
  /// exception text, paths, keys or stack traces.
  String _friendlyError(Object error) {
    final raw = error.toString().toLowerCase();
    bool has(String s) => raw.contains(s);

    if (has('user_already_exists') ||
        has('email_exists') ||
        has('already registered') ||
        has('already exists')) {
      return 'This email is already registered. Please sign in or use another email.';
    }
    if (has('weak_password') ||
        has('password should be at least') ||
        has('password should contain') ||
        has('at least 6 characters')) {
      return 'Please choose a stronger password (at least 6 characters).';
    }
    if (has('signup_disabled') ||
        has('signups not allowed') ||
        has('signups are disabled') ||
        has('signup is disabled')) {
      return 'New sign-ups are turned off right now. Please contact support.';
    }
    if (has('over_email_send_rate_limit') ||
        has('over_request_rate_limit') ||
        has('rate limit') ||
        has('for security purposes') ||
        has('too many requests')) {
      return 'Too many sign-up attempts right now. Please wait a while '
          '(it can take up to an hour) and try again.';
    }
    if (has('email_address_invalid') || (has('email') && has('invalid'))) {
      return 'Please enter a valid email address.';
    }
    if (has('database error saving new user') || has('unexpected_failure')) {
      return 'The server could not save your new account. Please try again '
          'shortly, and contact support if it keeps happening.';
    }
    if (has('permission') ||
        has('denied') ||
        has('row-level security') ||
        has('42501')) {
      return 'Your account could not be created because access to the '
          'database was denied.';
    }
    if (has('socketexception') ||
        has('failed host lookup') ||
        has('clientexception') ||
        has('timeout') ||
        has('network') ||
        has('connection')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    if (has('invalid api key') || has('apikey')) {
      return 'This app could not reach its server. Please update the app or contact support.';
    }
    return 'Could not create your account. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MSpacing.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Step 1 of 3',
                    style: MText.labelMd.copyWith(color: MColors.primary)),
                const SizedBox(height: MSpacing.xs),
                const Text('Owner Information', style: MText.titleLg),
                const SizedBox(height: MSpacing.lg),
                TextFormField(
                  controller: _fullName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Please enter your full name.'
                      : null,
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) => _reformat(_mobile, PkPhone.formatAsTyped, v),
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: '300 0000000',
                    prefixText: '🇵🇰 +92  ',
                  ),
                  validator: (v) => (v == null || !PkPhone.isValid(v))
                      ? PkPhone.errorMessage
                      : null,
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _cnic,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) => _reformat(_cnic, PkCnic.formatAsTyped, v),
                  decoration: const InputDecoration(
                    labelText: 'CNIC (optional)',
                    hintText: 'XXXXX-XXXXXXX-X',
                  ),
                  validator: (v) =>
                      (v != null && v.isNotEmpty && !PkCnic.isValid(v))
                          ? PkCnic.errorMessage
                          : null,
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch((v ?? '').trim())
                      ? null
                      : 'Please enter a valid email address.',
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters.'
                      : null,
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                  validator: (v) =>
                      v != _password.text ? 'Passwords do not match.' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: MSpacing.md),
                  Text(_error!, style: const TextStyle(color: MColors.danger)),
                ],
                if (_debugDetail != null) ...[
                  const SizedBox(height: MSpacing.xs),
                  // Debug builds only (kDebugMode) — never shown in release.
                  SelectableText(
                    'Debug: $_debugDetail',
                    style: MText.labelSm.copyWith(color: MColors.textSecondary),
                  ),
                ],
                const SizedBox(height: MSpacing.lg),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
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
