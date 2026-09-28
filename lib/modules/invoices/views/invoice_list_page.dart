import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/invoices/views/create_invoice_page.dart';
import 'package:mandi/modules/invoices/views/invoice_detail_page.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final canCreate = shopCtx.hasPermission('create_invoice');

    return Scaffold(
      appBar: AppBar(title: const Text('Sales Invoices')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateInvoicePage()),
              ),
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('New Invoice'),
            )
          : null,
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final invoices = provider.search(_searchCtrl.text);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(MSpacing.md),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by invoice # or customer name...',
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
                child: invoices.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'No invoices created yet.'
                              : 'No invoices match your search.',
                          style: MText.bodyMd
                              .copyWith(color: MColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(MSpacing.md),
                        itemCount: invoices.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: MSpacing.sm),
                        itemBuilder: (context, i) {
                          final inv = invoices[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: MRadius.md,
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    MColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.receipt_long,
                                    color: MColors.primary),
                              ),
                              title: Text(inv.invoiceNumber,
                                  style: MText.titleLg),
                              subtitle: Text(
                                inv.customerName.isNotEmpty
                                    ? inv.customerName
                                    : 'Walk-in Customer',
                                style: MText.bodySm
                                    .copyWith(color: MColors.textSecondary),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${inv.total.toStringAsFixed(0)}',
                                    style: MText.titleLg
                                        .copyWith(color: MColors.primary),
                                  ),
                                  Text(
                                    inv.pendingAmount > 0
                                        ? 'Pending: Rs. ${inv.pendingAmount.toStringAsFixed(0)}'
                                        : 'PAID',
                                    style: MText.bodySm.copyWith(
                                      color: inv.pendingAmount > 0
                                          ? MColors.danger
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      InvoiceDetailPage(invoice: inv),
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
