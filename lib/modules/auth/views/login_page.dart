import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/pk_phone.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/modules/auth/views/forgot_password_phone_page.dart';

/// One login screen for every account type — owner, staff, customer,
/// supplier. Nobody picks a role or a shop here; ShopContextProvider
/// resolves both after AuthProvider confirms who signed in (see
/// AppRoot). The identifier field accepts either a Pakistani phone
/// number or an email address — whichever the person has on file.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  bool get _looksLikeEmail => _identifier.text.contains('@');

  void _onIdentifierChanged(String v) {
    if (_looksLikeEmail) return; // don't reformat while typing an email
    final formatted = PkPhone.formatLocalFull(v);
    if (formatted != v) {
      _identifier.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      if (_looksLikeEmail) {
        await auth.signInWithEmail(_identifier.text.trim(), _password.text);
      } else {
        final e164 = PkPhone.toE164(_identifier.text)!;
        await auth.signInWithPhone(e164, _password.text);
      }
      // AppRoot listens to AuthProvider and will route to the right place
      // (shop creation, or the right dashboard) once shop context loads —
      // this screen never decides that itself.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
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
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect phone/email or password.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (lower.contains('for security purposes')) {
      return 'Too many attempts. Please try again in a moment.';
    }
    return 'Could not sign in. Please check your details and try again.';
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: MSpacing.md),
                const Text('Welcome back', style: MText.titleLg),
                const SizedBox(height: MSpacing.xs),
                Text(
                  'One login for every account — we\'ll take you straight '
                  'to your dashboard.',
                  style: MText.bodyMd.copyWith(color: MColors.textSecondary),
                ),
                const SizedBox(height: MSpacing.lg),
                TextFormField(
                  controller: _identifier,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _onIdentifierChanged,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number or Email',
                    hintText: '0300 1234567 or you@example.com',
                    prefixText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.contains('@')) {
                      return v.contains('.') ? null : 'Enter a valid email';
                    }
                    return PkPhone.isValid(v) ? null : PkPhone.errorMessage;
                  },
                ),
                const SizedBox(height: MSpacing.md),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPhonePage()),
                    ),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: MSpacing.xs),
                  Text(_error!, style: const TextStyle(color: MColors.danger)),
                ],
                const SizedBox(height: MSpacing.md),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
