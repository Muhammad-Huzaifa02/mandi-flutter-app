import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/modules/onboarding/views/shop_setup_wizard.dart';

/// Shown when a user is signed in but isn't an active member of any shop
/// yet — e.g. they registered but never finished the setup wizard, or
/// their only membership was deactivated. This is the state the old app
/// had no way to represent at all.
class NoShopPage extends StatelessWidget {
  const NoShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 64, color: MColors.primary),
              const SizedBox(height: MSpacing.lg),
              const Text('No shop yet', style: MText.titleLg),
              const SizedBox(height: MSpacing.sm),
              Text(
                'You\'re signed in, but you don\'t belong to any shop. '
                'Create your own shop, or ask an owner to add you as staff.',
                textAlign: TextAlign.center,
                style: MText.bodyMd.copyWith(color: MColors.textSecondary),
              ),
              const SizedBox(height: MSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShopSetupWizard(
                        ownerName: (auth.user?.userMetadata?['full_name'] as String?) ??
                            auth.user?.email?.split('@').first ??
                            '',
                        ownerPhone: auth.user?.phone ?? '',
                        ownerEmail: auth.user?.email ?? '',
                      ),
                    ),
                  ),
                  child: const Text('Create New Shop'),
                ),
              ),
              const SizedBox(height: MSpacing.sm),
              TextButton(
                onPressed: () => auth.signOut(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
