import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/purchase_orders/providers/purchase_order_provider.dart';
import 'package:mandi/modules/purchase_orders/views/add_purchase_order_page.dart';

class PurchaseOrderListPage extends StatefulWidget {
  const PurchaseOrderListPage({super.key});

  @override
  State<PurchaseOrderListPage> createState() => _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends State<PurchaseOrderListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final canCreate = shopCtx.hasPermission('create_purchase');

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPurchaseOrderPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Purchase'),
            )
          : null,
      body: Consumer<PurchaseOrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = provider.search(_searchCtrl.text);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(MSpacing.md),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by supplier name or status...',
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
                child: orders.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'No purchase orders recorded yet.'
                              : 'No purchase orders match your search.',
                          style: MText.bodyMd
                              .copyWith(color: MColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(MSpacing.md),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: MSpacing.sm),
                        itemBuilder: (context, i) {
                          final po = orders[i];
                          final isReceived = po.status == 'received';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: MRadius.md,
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (isReceived
                                        ? Colors.green
                                        : MColors.warning)
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: isReceived
                                      ? Colors.green
                                      : MColors.warning,
                                ),
                              ),
                              title: Text(po.supplierName,
                                  style: MText.titleLg),
                              subtitle: Text(
                                'Status: ${po.status.toUpperCase()} ${po.createdAt != null ? '• ${po.createdAt!.day}/${po.createdAt!.month}/${po.createdAt!.year}' : ''}',
                                style: MText.bodySm
                                    .copyWith(color: MColors.textSecondary),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${po.total.toStringAsFixed(0)}',
                                    style: MText.titleLg
                                        .copyWith(color: MColors.primary),
                                  ),
                                  Text(
                                    po.pendingAmount > 0
                                        ? 'Pending: Rs. ${po.pendingAmount.toStringAsFixed(0)}'
                                        : 'PAID',
                                    style: MText.bodySm.copyWith(
                                      color: po.pendingAmount > 0
                                          ? MColors.danger
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
