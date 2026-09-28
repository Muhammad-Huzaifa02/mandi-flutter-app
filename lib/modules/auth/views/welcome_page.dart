import 'package:flutter/material.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/modules/auth/views/login_page.dart';
import 'package:mandi/modules/auth/views/register_owner_page.dart';

/// One login for every account type (owner, staff, customer, supplier) —
/// so "Login / Continue" is the single primary action here. "Create New
/// Shop" stays available but as a secondary path, for the one case where
/// a shop doesn't exist yet: everyone with an existing account, whatever
/// their role, goes through the same door.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MColors.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset('assets/images/logo.png', width: 130),
              const SizedBox(height: MSpacing.lg),
              Text('Welcome to Mandi',
                  textAlign: TextAlign.center,
                  style: MText.displayMd.copyWith(color: Colors.white)),
              const SizedBox(height: MSpacing.sm),
              Text(
                'One platform for shop owners, staff, customers and '
                'suppliers — sign in below to continue.',
                textAlign: TextAlign.center,
                style: MText.bodyMd.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: MSpacing.lg),
              const Wrap(
                spacing: MSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  _RoleChip('Shop Owners'),
                  _RoleChip('Staff'),
                  _RoleChip('Customers'),
                  _RoleChip('Suppliers'),
                ],
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.gold,
                    foregroundColor: const Color(0xFF2B2205),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('Login / Continue'),
                ),
              ),
              const SizedBox(height: MSpacing.md),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterOwnerPage()),
                ),
                child: Text('Create New Shop',
                    style: MText.bodyMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline)),
              ),
              const SizedBox(height: MSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  const _RoleChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: MRadius.full,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: MText.labelSm.copyWith(color: Colors.white)),
    );
  }
}
