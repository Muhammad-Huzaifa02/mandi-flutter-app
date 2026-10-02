import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/payments/providers/payment_provider.dart';
import 'package:mandi/modules/payments/views/add_payment_page.dart';

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final canRecord = shopCtx.hasPermission('create_receipt');

    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Vouchers')),
      floatingActionButton: canRecord
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPaymentPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Record Payment'),
            )
          : null,
      body: Consumer<PaymentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = provider.search(_searchCtrl.text);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(MSpacing.md),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search payment reference or method...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: payments.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'No payment vouchers recorded yet.'
                              : 'No payments match your search.',
                          style: MText.bodyMd
                              .copyWith(color: MColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(MSpacing.md),
                        itemCount: payments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: MSpacing.sm),
                        itemBuilder: (context, i) {
                          final p = payments[i];
                          final isCustomer = p.partyType == 'customer';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: MRadius.md,
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (isCustomer
                                        ? Colors.green
                                        : MColors.primary)
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  isCustomer
                                      ? Icons.download_outlined
                                      : Icons.upload_outlined,
                                  color: isCustomer
                                      ? Colors.green
                                      : MColors.primary,
                                ),
                              ),
                              title: Text(
                                isCustomer
                                    ? 'Customer Receipt'
                                    : 'Supplier Settlement',
                                style: MText.titleLg,
                              ),
                              subtitle: Text(
                                '${p.method.toUpperCase()}${p.reference.isNotEmpty ? ' • Ref: ${p.reference}' : ''}',
                                style: MText.bodySm
                                    .copyWith(color: MColors.textSecondary),
                              ),
                              trailing: Text(
                                '${isCustomer ? '+' : '-'} Rs. ${p.amount.toStringAsFixed(0)}',
                                style: MText.titleLg.copyWith(
                                  color: isCustomer
                                      ? Colors.green
                                      : MColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
