import 'package:flutter/material.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/customer_model.dart';

class CustomerDetailPage extends StatelessWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: MRadius.lg,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: MColors.primary.withOpacity(0.1),
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : 'C',
                      style: MText.titleLg.copyWith(color: MColors.primary),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name, style: MText.titleLg),
                        if (customer.city.isNotEmpty)
                          Text(customer.city,
                              style: MText.bodyMd
                                  .copyWith(color: MColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpacing.lg),

            // Balance Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: MRadius.lg,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ledger Balance', style: MText.labelMd),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${customer.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: customer.runningBalance > 0
                          ? MColors.danger
                          : (customer.runningBalance < 0
                              ? Colors.green
                              : MColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    customer.runningBalance > 0
                        ? 'Customer owes you'
                        : (customer.runningBalance < 0
                            ? 'Advance payment received'
                            : 'Settled'),
                    style:
                        MText.bodySm.copyWith(color: MColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpacing.lg),

            // Contact Information
            const Text('Contact Information', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            _DetailTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: customer.phone.isNotEmpty ? customer.phone : 'Not provided',
            ),
            _DetailTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: customer.email.isNotEmpty ? customer.email : 'Not provided',
            ),
            _DetailTile(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value:
                  customer.address.isNotEmpty ? customer.address : 'Not provided',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MColors.textSecondary),
          const SizedBox(width: MSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: MText.bodySm.copyWith(color: MColors.textSecondary)),
              Text(value, style: MText.bodyMd),
            ],
          ),
        ],
      ),
    );
  }
}
