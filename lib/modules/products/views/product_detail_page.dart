import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
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
                  color: MColors.danger.withValues(alpha: 0.2),
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
                          Text('Low Stock Alert',
                              style: MText.titleLg.copyWith(color: MColors.danger)),
                          Text(
                            'Current stock (${MandiCalculator.formatWeightDisplay(product.currentStock)}) is below the minimum threshold (${MandiCalculator.formatWeightDisplay(product.minStockLevel)}).',
                            style: MText.bodySm.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Header Overview GlassCard
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product.name,
                          style: MText.titleLg.copyWith(color: Colors.white)),
                      Chip(
                        label: Text(product.category,
                            style: MText.bodySm.copyWith(color: Colors.white)),
                        backgroundColor: MColors.gold.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const Divider(height: MSpacing.lg, color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rate per 40 KG (Maund)',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: MSpacing.xs),
                          Text(
                            'Rs. ${product.sellingPrice.toStringAsFixed(0)}',
                            style: MText.titleLg.copyWith(color: MColors.gold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Current Stock',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: MSpacing.xs),
                          Text(
                            MandiCalculator.formatWeightDisplay(
                                product.currentStock),
                            style: MText.titleLg.copyWith(
                              color: product.isLowStock
                                  ? MColors.danger
                                  : Colors.white,
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

            // Mandi Weight & Price Calculator GlassCard
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calculate_outlined, color: MColors.gold),
                      const SizedBox(width: MSpacing.xs),
                      Text('Mandi Price Calculator',
                          style: MText.titleLg.copyWith(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    '1 Mann = 40 KG. Enter weight in KG to calculate Manns and total price.',
                    style: MText.bodySm.copyWith(color: Colors.white70),
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
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: MRadius.md,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Converted Weight:',
                                style: TextStyle(color: Colors.white, fontSize: 14)),
                            Text(
                              '${testManns.toStringAsFixed(2)} Mann',
                              style: MText.titleLg.copyWith(color: MColors.gold),
                            ),
                          ],
                        ),
                        const SizedBox(height: MSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rate / 40 KG:',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('Rs. ${product.sellingPrice.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        const Divider(height: MSpacing.md, color: Colors.white24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              'Rs. ${testTotalPrice.toStringAsFixed(0)}',
                              style: MText.titleLg.copyWith(color: Colors.greenAccent),
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
