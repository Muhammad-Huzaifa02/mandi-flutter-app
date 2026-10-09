import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/data/models/purchase_order_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';
import 'package:mandi/modules/purchase_orders/providers/purchase_order_provider.dart';

class AddPurchaseOrderPage extends StatefulWidget {
  const AddPurchaseOrderPage({super.key});

  @override
  State<AddPurchaseOrderPage> createState() => _AddPurchaseOrderPageState();
}

class _AddPurchaseOrderPageState extends State<AddPurchaseOrderPage> {
  final _formKey = GlobalKey<FormState>();
  Supplier? _selectedSupplier;
  Product? _selectedProduct;

  final _weightCtrl = TextEditingController();
  final _ratePer40kgCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController(text: '0');
  String _status = 'received'; // 'pending' | 'received' | 'cancelled'
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _ratePer40kgCtrl.dispose();
    _totalCtrl.dispose();
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final r = double.tryParse(_ratePer40kgCtrl.text.trim()) ?? 0;
    if (w > 0 && r > 0) {
      final calcTotal = (w / 40.0) * r;
      _totalCtrl.text = calcTotal.toStringAsFixed(0);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    final provider = context.read<PurchaseOrderProvider>();
    setState(() => _saving = true);

    try {
      final total = double.parse(_totalCtrl.text.trim());
      final paid = double.tryParse(_paidAmountCtrl.text.trim()) ?? 0;
      final w = double.tryParse(_weightCtrl.text.trim()) ?? 0;
      final r = double.tryParse(_ratePer40kgCtrl.text.trim()) ?? 0;

      String? validSupplierId;
      if (_selectedSupplier != null) {
        validSupplierId = await SupabaseService.ensureSupplierRow(
          shopId: shopId,
          supplierId: _selectedSupplier!.id,
          userId: _selectedSupplier!.userId,
          name: _selectedSupplier!.name,
          phone: _selectedSupplier!.phone,
          email: _selectedSupplier!.email,
        );
      }

      final po = PurchaseOrder(
        id: '',
        shopId: shopId,
        supplierId: validSupplierId,
        supplierName: _selectedSupplier?.name ?? 'Direct Supplier',
        total: total,
        paidAmount: paid,
        status: _status,
      );

      await provider.addPurchaseOrder(po);

      // Auto-increase product stock in PostgreSQL when purchased from supplier
      if (_selectedProduct != null && w > 0) {
        final client = Supabase.instance.client;
        final currentStock = _selectedProduct!.currentStock;
        await client
            .from('products')
            .update({
              'current_stock': currentStock + w,
              'purchase_price': r > 0 ? r : _selectedProduct!.purchasePrice,
              'is_active': true,
            })
            .eq('id', _selectedProduct!.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Purchase order recorded & product stock updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: MColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final products = context.watch<ProductProvider>().products;
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final r = double.tryParse(_ratePer40kgCtrl.text.trim()) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Purchase Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Supplier>(
                initialValue: _selectedSupplier,
                decoration: const InputDecoration(labelText: 'Supplier'),
                hint: const Text('Select Supplier (Optional)'),
                items: suppliers
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.name} (${s.phone})'),
                        ))
                    .toList(),
                onChanged: (s) => setState(() => _selectedSupplier = s),
              ),
              const SizedBox(height: MSpacing.md),

              DropdownButtonFormField<Product>(
                initialValue: _selectedProduct,
                decoration:
                    const InputDecoration(labelText: 'Product Purchased'),
                hint: const Text('Select Product (Stock will increase)'),
                items: products
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                              '${p.name} (Current Stock: ${p.currentStock}kg)'),
                        ))
                    .toList(),
                onChanged: (p) {
                  if (p != null) {
                    setState(() {
                      _selectedProduct = p;
                      if (p.purchasePrice > 0) {
                        _ratePer40kgCtrl.text =
                            p.purchasePrice.toStringAsFixed(0);
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: MSpacing.md),

              // Option B: Rate per 40 KG Mandi Calculator
              const Text('Direct Purchase Calculation', style: MText.titleLg),
              const SizedBox(height: MSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        _calculateTotal();
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Weight (KG)',
                        hintText: 'e.g. 200',
                        suffixText: 'KG',
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _ratePer40kgCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        _calculateTotal();
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Rate / 40 KG (Maund)',
                        hintText: 'e.g. 4000',
                        suffixText: 'PKR',
                      ),
                    ),
                  ),
                ],
              ),
              if (w > 0 && r > 0) ...[
                const SizedBox(height: MSpacing.xs),
                Text(
                  '${(w / 40.0).toStringAsFixed(2)} Manns @ Rs. ${r.toStringAsFixed(0)} / 40kg',
                  style: MText.bodySm.copyWith(color: MColors.textSecondary),
                ),
              ],

              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _totalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Total Purchase Amount (PKR) *',
                  hintText: 'e.g. 50000',
                  suffixText: 'PKR',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _paidAmountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Paid Amount (PKR)',
                  hintText: 'e.g. 20000',
                  suffixText: 'PKR',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Order Status'),
                items: const [
                  DropdownMenuItem(value: 'received', child: Text('Received')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending Delivery')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (s) {
                  if (s != null) setState(() => _status = s);
                },
              ),
              const SizedBox(height: MSpacing.xl),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Purchase Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
