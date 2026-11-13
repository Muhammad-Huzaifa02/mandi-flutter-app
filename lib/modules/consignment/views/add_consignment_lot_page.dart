import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';
import 'package:mandi/modules/consignment/providers/consignment_provider.dart';

/// Form page to register a new incoming crop arrival lot (Aawak & Dheri / آمد و ڈھیری).
class AddConsignmentLotPage extends StatefulWidget {
  final String? initialVehicleNumber;
  final int? initialBags;
  final double? initialWeightKg;

  const AddConsignmentLotPage({
    super.key,
    this.initialVehicleNumber,
    this.initialBags,
    this.initialWeightKg,
  });

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
    if (widget.initialVehicleNumber != null &&
        widget.initialVehicleNumber!.isNotEmpty) {
      _vehicleCtrl.text = widget.initialVehicleNumber!;
    }
    if (widget.initialBags != null && widget.initialBags! > 0) {
      _bagsCtrl.text = widget.initialBags.toString();
    }
    if (widget.initialWeightKg != null && widget.initialWeightKg! > 0) {
      _weightCtrl.text = widget.initialWeightKg!.toStringAsFixed(1);
    }
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
        title: Text(
          AppStrings.val(context, en: 'Register Arrival Lot', ur: 'نئی آمد و ڈھیری کا اندراج'),
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
                      AppStrings.val(context, en: 'Consignment Details', ur: 'مال کی تفصیلات'),
                      style: MText.titleMd.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: MSpacing.md),

                    // Lot Number
                    TextFormField(
                      controller: _lotNumCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(context, en: 'Lot / Dheri # *', ur: 'ڈھیری نمبر *'),
                        prefixIcon: const Icon(Icons.tag),
                      ),
                      validator: (val) => val?.trim().isEmpty == true
                          ? AppStrings.val(context, en: 'Enter lot #', ur: 'ڈھیری نمبر درج کریں')
                          : null,
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Supplier / Farmer Dropdown
                    DropdownButtonFormField<Supplier>(
                      initialValue: _selectedSupplier,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(context, en: 'Farmer *', ur: 'زمیندار *'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items: suppliers
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('${s.name} (${s.phone})'),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSupplier = val),
                      validator: (val) => val == null
                          ? AppStrings.val(context, en: 'Please select farmer', ur: 'زمیندار منتخب کریں')
                          : null,
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Commodity / Product Dropdown
                    DropdownButtonFormField<Product>(
                      initialValue: _selectedProduct,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(context, en: 'Commodity / Product *', ur: 'جنس / فصل *'),
                        prefixIcon: const Icon(Icons.grass_outlined),
                      ),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedProduct = val),
                      validator: (val) => val == null
                          ? AppStrings.val(context, en: 'Please select product', ur: 'جنس منتخب کریں')
                          : null,
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Vehicle / Trolley Number
                    TextFormField(
                      controller: _vehicleCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(context, en: 'Vehicle / Trolley #', ur: 'گاڑی / ٹرالی نمبر'),
                        prefixIcon: const Icon(Icons.local_shipping_outlined),
                        hintText: AppStrings.val(
                          context,
                          en: 'e.g. Trolley # 14 or MN-9901',
                          ur: 'مثلاً ٹرالی نمبر 14 یا MN-9901',
                        ),
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
                      AppStrings.val(context, en: 'Weight & Bag Count', ur: 'وزن اور بوریاں'),
                      style: MText.titleMd.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: MSpacing.md),

                    // Bag Count
                    TextFormField(
                      controller: _bagsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(context, en: 'Number of Bags *', ur: 'تعداد بوریاں *'),
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (val) {
                        final n = int.tryParse(val?.trim() ?? '');
                        if (n == null || n <= 0) {
                          return AppStrings.val(context, en: 'Enter valid bag count', ur: 'بوریوں کی درست تعداد درج کریں');
                        }
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
                        labelText: AppStrings.val(context, en: 'Gross Weight in KG *', ur: 'بھرا وزن (کلوگرام) *'),
                        prefixIcon: const Icon(Icons.scale_outlined),
                        suffixText: '${_maunds.toStringAsFixed(2)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        final n = double.tryParse(val?.trim() ?? '');
                        if (n == null || n <= 0) {
                          return AppStrings.val(context, en: 'Enter valid weight in KG', ur: 'درست وزن درج کریں');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: MSpacing.sm),

                    // Base/Expected Rate per Maund
                    TextFormField(
                      controller: _rateCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppStrings.val(
                          context,
                          en: 'Base / Asking Rate per Maund',
                          ur: 'ابتدائی ریٹ فی من',
                        ),
                        prefixIcon: const Icon(Icons.price_change_outlined),
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
                              AppStrings.val(context, en: 'Weight in Maunds (40 KG):', ur: 'وزن فی من (40 کلو):'),
                              style: MText.caption.copyWith(color: Colors.white),
                            ),
                            Text(
                              '${_maunds.toStringAsFixed(2)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
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
                      decoration: InputDecoration(
                        labelText: AppStrings.val(context, en: 'Remarks / Notes', ur: 'نوٹ / تبصرہ'),
                        prefixIcon: const Icon(Icons.notes_outlined),
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
                      ? AppStrings.val(context, en: 'Saving Arrival Lot...', ur: 'ڈھیری محفوظ ہو رہی ہے...')
                      : AppStrings.val(context, en: 'Register Arrival Lot', ur: 'ڈھیری درج کریں')),
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
              AppStrings.val(
                context,
                en: 'Arrival lot ${_lotNumCtrl.text.trim()} registered successfully!',
                ur: 'ڈھیری نمبر ${_lotNumCtrl.text.trim()} کا کامیابی سے اندراج ہو گیا!',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.val(
                context,
                en: 'Failed to save arrival lot: $e',
                ur: 'ڈھیری محفوظ کرنے میں ناکامی: $e',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
