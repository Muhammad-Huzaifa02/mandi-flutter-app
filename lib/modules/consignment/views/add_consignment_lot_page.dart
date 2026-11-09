import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';
import 'package:mandi/modules/consignment/providers/consignment_provider.dart';

/// Form page to register a new incoming crop arrival lot (Aawak & Dheri / آمد و ڈھیری).
class AddConsignmentLotPage extends StatefulWidget {
  const AddConsignmentLotPage({super.key});

  @override
  State<AddConsignmentLotPage> createState() => _AddConsignmentLotPageState();
}

class _AddConsignmentLotPageState extends State<AddConsignmentLotPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _lotNumCtrl;
  final _vehicleCtrl = TextEditingController();
  final _bagsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Supplier? _selectedSupplier;
  Product? _selectedProduct;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 900) + 100;
    _lotNumCtrl = TextEditingController(text: 'DH-$randomSuffix');
  }

  @override
  void dispose() {
    _lotNumCtrl.dispose();
    _vehicleCtrl.dispose();
    _bagsCtrl.dispose();
    _weightCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _weightKg => double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
  double get _maunds => _weightKg > 0 ? (_weightKg / 40.0) : 0.0;
  double get _rate => double.tryParse(_rateCtrl.text.trim()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final products = context.watch<ProductProvider>().products;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Register Arrival Lot'),
            Text(
              'نئی آمد / ڈھیری کا اندراج',
              style: TextStyle(fontSize: 11, color: MColors.gold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(MSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consignment Details (تفصیلات مال)',
                      style: MText.titleMd.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: MSpacing.md),

                    // Lot Number
                    TextFormField(
                      controller: _lotNumCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lot / Dheri # (ڈھیری نمبر) *',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      validator: (val) =>
                          val?.trim().isEmpty == true ? 'Enter lot #' : null,
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Supplier / Farmer Dropdown
                    DropdownButtonFormField<Supplier>(
                      initialValue: _selectedSupplier,
                      decoration: const InputDecoration(
                        labelText: 'Farmer / Supplier (زمیندار / بیوپاری) *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: suppliers
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('${s.name} (${s.phone})'),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSupplier = val),
                      validator: (val) =>
                          val == null ? 'Please select farmer' : null,
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Commodity / Product Dropdown
                    DropdownButtonFormField<Product>(
                      initialValue: _selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Commodity / Product (جنس / فصل) *',
                        prefixIcon: Icon(Icons.grass_outlined),
                      ),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedProduct = val),
                      validator: (val) =>
                          val == null ? 'Please select product' : null,
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Vehicle / Trolley Number
                    TextFormField(
                      controller: _vehicleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle / Trolley # (گاڑی نمبر)',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                        hintText: 'e.g. Trolley # 14 or MN-9901',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MSpacing.md),

              GlassCard(
                padding: const EdgeInsets.all(MSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight & Bag Count (وزن و بوریاں)',
                      style: MText.titleMd.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: MSpacing.md),

                    // Bag Count
                    TextFormField(
                      controller: _bagsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number of Bags (تعداد بوریاں) *',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (val) {
                        final n = int.tryParse(val?.trim() ?? '');
                        if (n == null || n <= 0) return 'Enter valid bag count';
                        return null;
                      },
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Weight in KG
                    TextFormField(
                      controller: _weightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Gross Weight in KG (وزن کلوگرام) *',
                        prefixIcon: const Icon(Icons.scale_outlined),
                        suffixText: '${_maunds.toStringAsFixed(2)} Manns',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        final n = double.tryParse(val?.trim() ?? '');
                        if (n == null || n <= 0) return 'Enter valid weight in KG';
                        return null;
                      },
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Base/Expected Rate per Maund
                    TextFormField(
                      controller: _rateCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText:
                            'Base / Asking Rate per Maund (ابتدائی ریٹ فی من)',
                        prefixIcon: Icon(Icons.price_change_outlined),
                        prefixText: 'Rs. ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Real-Time Calculation Card
                    if (_maunds > 0)
                      Container(
                        padding: const EdgeInsets.all(MSpacing.sm),
                        decoration: BoxDecoration(
                          color: MColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: MColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Weight in Manns (40 KG):',
                              style: MText.caption.copyWith(color: Colors.white),
                            ),
                            Text(
                              '${_maunds.toStringAsFixed(2)} من (Manns)',
                              style: MText.bodySm.copyWith(
                                fontWeight: FontWeight.bold,
                                color: MColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: MSpacing.sm),

                    // Notes
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Remarks / Notes (نوٹ)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSaving
                      ? 'Saving Arrival Lot...'
                      : 'Register Arrival Lot (ڈھیری درج کریں)'),
                  onPressed: _isSaving ? null : _saveLot,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveLot() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null || _selectedProduct == null) return;

    setState(() => _isSaving = true);
    final prov = context.read<ConsignmentProvider>();

    try {
      await prov.addLot(
        lotNumber: _lotNumCtrl.text.trim(),
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        vehicleNumber: _vehicleCtrl.text.trim(),
        bagCount: int.parse(_bagsCtrl.text.trim()),
        weightKg: _weightKg,
        ratePerMaund: _rate,
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Arrival lot ${_lotNumCtrl.text.trim()} registered successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save arrival lot: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
