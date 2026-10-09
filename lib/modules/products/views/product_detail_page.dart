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

    final isAvailable = product.isActive && product.currentStock > 0;

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
              tooltip: 'Edit Product',
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
            // Product Name, Price & Availability Status Card
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: MText.titleLg.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Chip(
                        avatar: Icon(
                          isAvailable
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: isAvailable ? Colors.greenAccent : MColors.danger,
                          size: 18,
                        ),
                        label: Text(
                          isAvailable
                              ? 'Currently Available'
                              : 'Currently Unavailable',
                          style: TextStyle(
                            color: isAvailable ? Colors.greenAccent : MColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: (isAvailable
                                ? Colors.green
                                : MColors.danger)
                            .withValues(alpha: 0.2),
                      ),
                    ],
                  ),

                  const Divider(height: MSpacing.lg, color: Colors.white24),

                  const Text('Rate / 40 KG (Maund)',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${product.sellingPrice.toStringAsFixed(0)}',
                    style: MText.titleLg.copyWith(
                      color: MColors.gold,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Mandi Price Calculator
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
                    '1 Mann = 40 KG. Enter weight in KG to calculate total price.',
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
                        const Divider(height: MSpacing.md, color: Colors.white24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              'Rs. ${testTotalPrice.toStringAsFixed(0)}',
                              style: MText.titleLg
                                  .copyWith(color: Colors.greenAccent),
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
