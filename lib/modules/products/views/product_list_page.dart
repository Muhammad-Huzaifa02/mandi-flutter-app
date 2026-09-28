import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';
import 'package:mandi/modules/products/views/add_edit_product_page.dart';
import 'package:mandi/modules/products/views/product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _searchCtrl = TextEditingController();
  bool _showLowStockOnly = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final canEdit = shopCtx.hasPermission('manage_products');

    return Scaffold(
      appBar: AppBar(title: const Text('Products & Inventory')),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditProductPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          var products = provider.search(_searchCtrl.text);
          if (_showLowStockOnly) {
            products = products.where((p) => p.isLowStock).toList();
          }

          final lowStockCount = provider.lowStockProducts.length;

          return Column(
            children: [
              // Low stock alert banner
              if (lowStockCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: MSpacing.md, vertical: MSpacing.xs),
                  child: InkWell(
                    onTap: () => setState(
                        () => _showLowStockOnly = !_showLowStockOnly),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: MSpacing.md, vertical: MSpacing.sm),
                      decoration: BoxDecoration(
                        color: _showLowStockOnly
                            ? MColors.danger
                            : MColors.danger.withOpacity(0.1),
                        borderRadius: MRadius.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                            color: _showLowStockOnly
                                ? Colors.white
                                : MColors.danger,
                          ),
                          const SizedBox(width: MSpacing.sm),
                          Expanded(
                            child: Text(
                              '$lowStockCount product(s) below minimum stock level!',
                              style: MText.bodySm.copyWith(
                                color: _showLowStockOnly
                                    ? Colors.white
                                    : MColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _showLowStockOnly ? 'Show All' : 'Filter Low Stock',
                            style: MText.bodySm.copyWith(
                              color: _showLowStockOnly
                                  ? Colors.white
                                  : MColors.danger,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(MSpacing.md),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search product or category...',
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
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? (_showLowStockOnly
                                  ? 'No low stock products.'
                                  : 'No products added yet.')
                              : 'No products match your search.',
                          style: MText.bodyMd
                              .copyWith(color: MColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(MSpacing.md),
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: MSpacing.sm),
                        itemBuilder: (context, i) {
                          final p = products[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: MRadius.md,
                              side: BorderSide(
                                color: p.isLowStock
                                    ? MColors.danger
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: p.isLowStock
                                    ? MColors.danger.withOpacity(0.1)
                                    : MColors.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.grass,
                                  color: p.isLowStock
                                      ? MColors.danger
                                      : MColors.primary,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(p.name, style: MText.titleLg),
                                  ),
                                  if (p.isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: MColors.danger,
                                        borderRadius: MRadius.full,
                                      ),
                                      child: const Text(
                                        'LOW STOCK',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'Rate: Rs. ${p.sellingPrice.toStringAsFixed(0)} / 40kg • Stock: ${MandiCalculator.formatWeightDisplay(p.currentStock)}',
                                style: MText.bodySm
                                    .copyWith(color: MColors.textSecondary),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPage(product: p),
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
