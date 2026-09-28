import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/suppliers/views/add_supplier_page.dart';
import 'package:mandi/modules/suppliers/views/supplier_detail_page.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final canAdd = shopCtx.hasPermission('manage_suppliers');

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSupplierPage()),
              ),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add Supplier'),
            )
          : null,
      body: Consumer<SupplierProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final suppliers = provider.search(_searchCtrl.text);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(MSpacing.md),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone or product...',
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
                child: suppliers.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'No suppliers added yet.'
                              : 'No suppliers match your search.',
                          style: MText.bodyMd
                              .copyWith(color: MColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(MSpacing.md),
                        itemCount: suppliers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: MSpacing.sm),
                        itemBuilder: (context, i) {
                          final s = suppliers[i];
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
                                child: Text(
                                  s.name.isNotEmpty
                                      ? s.name[0].toUpperCase()
                                      : 'S',
                                  style: MText.titleLg
                                      .copyWith(color: MColors.primary),
                                ),
                              ),
                              title: Text(s.name, style: MText.titleLg),
                              subtitle: Text(
                                s.productsSupplied.isNotEmpty
                                    ? '${s.phone} • ${s.productsSupplied}'
                                    : s.phone,
                                style: MText.bodySm
                                    .copyWith(color: MColors.textSecondary),
                              ),
                              trailing: Text(
                                'Rs. ${s.runningBalance.toStringAsFixed(0)}',
                                style: MText.labelMd.copyWith(
                                  color: s.runningBalance > 0
                                      ? MColors.danger
                                      : (s.runningBalance < 0
                                          ? Colors.green
                                          : MColors.textPrimary),
                                ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SupplierDetailPage(supplier: s),
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
