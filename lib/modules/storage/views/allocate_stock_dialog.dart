import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/storage_allocation_model.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';
import 'package:mandi/modules/storage/providers/storage_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Modal dialog to record allocation / transfer of crop bags into a Godown or Cold Store.
class AllocateStockDialog extends StatefulWidget {
  final String? preselectedLocationId;

  const AllocateStockDialog({super.key, this.preselectedLocationId});

  @override
  State<AllocateStockDialog> createState() => _AllocateStockDialogState();
}

class _AllocateStockDialogState extends State<AllocateStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateFmt = DateFormat('dd/MM/yyyy');

  String? _selectedLocationId;
  String? _selectedProductId;
  late TextEditingController _productNameCtrl;
  late TextEditingController _lotNoCtrl;
  late TextEditingController _partyNameCtrl;
  late TextEditingController _bagCountCtrl;
  late TextEditingController _weightKgCtrl;
  late TextEditingController _rentRateCtrl;
  late TextEditingController _notesCtrl;
  DateTime _inwardDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = widget.preselectedLocationId;
    _productNameCtrl = TextEditingController();
    _lotNoCtrl = TextEditingController();
    _partyNameCtrl = TextEditingController();
    _bagCountCtrl = TextEditingController(text: '100');
    _weightKgCtrl = TextEditingController(text: '4000'); // 100 maunds
    _rentRateCtrl = TextEditingController(text: '0');
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _lotNoCtrl.dispose();
    _partyNameCtrl.dispose();
    _bagCountCtrl.dispose();
    _weightKgCtrl.dispose();
    _rentRateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _maunds {
    final kg = double.tryParse(_weightKgCtrl.text.trim()) ?? 0.0;
    return kg > 0 ? kg / 40.0 : 0.0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a storage facility.'),
          backgroundColor: MColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final shopId = context.read<ShopContextProvider>().currentShopId;
      if (shopId == null) throw Exception('No active shop context.');

      final bags = int.tryParse(_bagCountCtrl.text.trim()) ?? 0;
      final kg = double.tryParse(_weightKgCtrl.text.trim()) ?? 0.0;
      final rent = double.tryParse(_rentRateCtrl.text.trim()) ?? 0.0;

      final allocation = StorageAllocation(
        id: '',
        shopId: shopId,
        storageLocationId: _selectedLocationId!,
        productId: _selectedProductId,
        productName: _productNameCtrl.text.trim(),
        lotNumber: _lotNoCtrl.text.trim(),
        partyName: _partyNameCtrl.text.trim(),
        bagCount: bags,
        weightKg: kg,
        inwardDate: _inwardDate,
        status: AllocationStatus.inStore,
        rentRatePerBag: rent,
        notes: _notesCtrl.text.trim(),
      );

      await context.read<StorageProvider>().allocateStock(allocation);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock successfully allocated into storage.'),
            backgroundColor: MColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error allocating stock: $e'),
            backgroundColor: MColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<StorageProvider>().locations;
    final products = context.watch<ProductProvider>().products;

    if (_selectedLocationId == null && locations.isNotEmpty) {
      _selectedLocationId = locations.first.id;
      _rentRateCtrl.text =
          locations.first.monthlyRentPerBag.toStringAsFixed(0);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.move_to_inbox_outlined,
                          color: MColors.primaryLight,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.val(context, en: 'Store Crop Stock', ur: 'مال گودام میں رکھیں'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Target Storage Facility
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocationId,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(context, en: 'Select Godown / Cold Store *', ur: 'گودام یا سٹور منتخب کریں *'),
                    prefixIcon: const Icon(Icons.warehouse_outlined),
                  ),
                  items: locations.map((loc) {
                    final typeStr = AppStrings.isUrdu(context) ? loc.typeLabelUrdu : loc.typeLabelEnglish;
                    final freeStr = AppStrings.val(context, en: 'Free', ur: 'خالی گنجائش');
                    final bagsStr = AppStrings.val(context, en: 'bags', ur: 'بوریاں');
                    return DropdownMenuItem(
                      value: loc.id,
                      child: Text(
                        '${loc.name} ($typeStr - $freeStr: ${loc.availableCapacityBags} $bagsStr)',
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      setState(() {
                        _selectedLocationId = id;
                        final found =
                            locations.where((l) => l.id == id).firstOrNull;
                        if (found != null) {
                          _rentRateCtrl.text =
                              found.monthlyRentPerBag.toStringAsFixed(0);
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Product Selection
                if (products.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProductId,
                    decoration: InputDecoration(
                      labelText: AppStrings.val(context, en: 'Select Commodity / Product *', ur: 'فصل یا جنس منتخب کریں *'),
                      prefixIcon: const Icon(Icons.grass_outlined),
                    ),
                    items: products.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (${p.category})'),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final found =
                            products.where((p) => p.id == id).firstOrNull;
                        setState(() {
                          _selectedProductId = id;
                          if (found != null) {
                            _productNameCtrl.text = found.name;
                          }
                        });
                      }
                    },
                  )
                else
                  TextFormField(
                    controller: _productNameCtrl,
                    decoration: InputDecoration(
                      labelText: AppStrings.val(context, en: 'Commodity Name *', ur: 'فصل کا نام *'),
                      hintText: AppStrings.val(context, en: 'e.g. Potato / Wheat', ur: 'مثلاً آلو یا گندم'),
                      prefixIcon: const Icon(Icons.grass_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? AppStrings.val(context, en: 'Please enter crop name', ur: 'براہ کرم فصل کا نام درج کریں')
                        : null,
                  ),
                const SizedBox(height: 14),

                // Lot Number & Party Name
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _lotNoCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Lot / Dheri #', ur: 'ڈھیری نمبر'),
                          hintText: 'LOT-42',
                          prefixIcon: const Icon(Icons.tag),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _partyNameCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Farmer / Owner Name', ur: 'زمیندار یا مالک کا نام'),
                          hintText: AppStrings.val(context, en: 'e.g. Malik Arshad', ur: 'مثلاً ملک ارشد'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bags Count & Weight KG
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bagCountCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Bag Count *', ur: 'تعداد بوریاں *'),
                          hintText: '100',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return AppStrings.val(context, en: 'Required', ur: 'لازمی');
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) return AppStrings.val(context, en: 'Must be > 0', ur: 'صفر سے بڑا ہو');
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightKgCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Weight (KG)', ur: 'وزن (کلوگرام)'),
                          hintText: '4000',
                          prefixIcon: const Icon(Icons.scale_outlined),
                          suffixText: '${_maunds.toStringAsFixed(1)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
                          suffixStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: MColors.primaryLight,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Inward Date & Rent Rate
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _inwardDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _inwardDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: AppStrings.val(context, en: 'Inward Date', ur: 'تاریخ آمد'),
                            prefixIcon: const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(_dateFmt.format(_inwardDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rentRateCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Monthly Rent / Bag (PKR)', ur: 'ماہانہ کرایہ فی بوری (روپیہ)'),
                          hintText: '80',
                          prefixIcon:
                              const Icon(Icons.account_balance_wallet_outlined),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(context, en: 'Notes / Storage Instructions', ur: 'تفصیل یا سٹوریج ہدایات'),
                    hintText: AppStrings.val(context, en: 'e.g. Stacked in Chamber B, Rack 4', ur: 'مثلاً چیمبر بی، ریک ۴'),
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(AppStrings.val(context, en: 'Store Batch', ur: 'مال محفوظ کریں')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
