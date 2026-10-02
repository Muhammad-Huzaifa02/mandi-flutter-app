import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/products/views/add_edit_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _testWeightCtrl = TextEditingController(text: '120');

  @override
  void dispose() {
    _testWeightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final shopCtx = context.watch<ShopContextProvider>();
    final canEdit = shopCtx.hasPermission('manage_products');

    final testWeight = double.tryParse(_testWeightCtrl.text) ?? 0;
    final testManns = MandiCalculator.kgToMann(testWeight);
    final testTotalPrice = MandiCalculator.calculateTotalAmount(
      weightKg: testWeight,
      pricePer40kg: product.sellingPrice,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditProductPage(product: product),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Low Stock Warning Banner
            if (product.isLowStock)
              Container(
                margin: const EdgeInsets.only(bottom: MSpacing.lg),
                padding: const EdgeInsets.all(MSpacing.md),
                decoration: BoxDecoration(
                  color: MColors.danger.withValues(alpha: 0.1),
                  borderRadius: MRadius.md,
                  border: Border.all(color: MColors.danger),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: MColors.danger),
                    const SizedBox(width: MSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Low Stock Alert', style: MText.titleLg),
                          Text(
                            'Current stock (${MandiCalculator.formatWeightDisplay(product.currentStock)}) is below the minimum threshold (${MandiCalculator.formatWeightDisplay(product.minStockLevel)}).',
                            style: MText.bodySm
                                .copyWith(color: MColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Header Overview Card
            Container(
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: MRadius.lg,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product.name, style: MText.titleLg),
                      Chip(
                        label: Text(product.category, style: MText.bodySm),
                        backgroundColor: MColors.primary.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  const Divider(height: MSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rate per 40 KG (Maund)',
                              style: MText.bodySm),
                          const SizedBox(height: MSpacing.xs),
                          Text(
                            'Rs. ${product.sellingPrice.toStringAsFixed(0)}',
                            style: MText.titleLg
                                .copyWith(color: MColors.primary),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Current Stock', style: MText.bodySm),
                          const SizedBox(height: MSpacing.xs),
                          Text(
                            MandiCalculator.formatWeightDisplay(
                                product.currentStock),
                            style: MText.titleLg.copyWith(
                              color: product.isLowStock
                                  ? MColors.danger
                                  : MColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Mandi Weight & Price Calculator Card
            Container(
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: MRadius.lg,
                border: Border.all(color: MColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_outlined, color: MColors.primary),
                      SizedBox(width: MSpacing.xs),
                      Text('Mandi Price Calculator', style: MText.titleLg),
                    ],
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    '1 Mann = 40 KG. Enter weight in KG to calculate Manns and total price.',
                    style: MText.bodySm.copyWith(color: MColors.textSecondary),
                  ),
                  const SizedBox(height: MSpacing.md),
                  TextField(
                    controller: _testWeightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Enter Weight (KG)',
                      suffixText: 'KG',
                    ),
                  ),
                  const SizedBox(height: MSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(MSpacing.md),
                    decoration: BoxDecoration(
                      color: MColors.background,
                      borderRadius: MRadius.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Converted Weight:',
                                style: MText.bodyMd),
                            Text(
                              '${testManns.toStringAsFixed(2)} Mann',
                              style: MText.titleLg
                                  .copyWith(color: MColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: MSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rate / 40 KG:', style: MText.bodyMd),
                            Text('Rs. ${product.sellingPrice.toStringAsFixed(0)}',
                                style: MText.bodyMd),
                          ],
                        ),
                        const Divider(height: MSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:', style: MText.titleLg),
                            Text(
                              'Rs. ${testTotalPrice.toStringAsFixed(0)}',
                              style: MText.titleLg
                                  .copyWith(color: MColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
