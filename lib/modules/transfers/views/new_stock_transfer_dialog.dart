import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/shop_model.dart';
import 'package:mandi/modules/transfers/providers/multi_shop_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Modal dialog to record a new Inter-Shop consignment stock transfer.
class NewStockTransferDialog extends StatefulWidget {
  const NewStockTransferDialog({super.key});

  @override
  State<NewStockTransferDialog> createState() => _NewStockTransferDialogState();
}

class _NewStockTransferDialogState extends State<NewStockTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  Shop? _selectedDestinationShop;
  late final TextEditingController _commodityCtrl;
  late final TextEditingController _packageTypeCtrl;
  final _packageCountCtrl = TextEditingController(text: '300');
  final _weightKgCtrl = TextEditingController(text: '6000'); // 150 Maunds
  final _ratePerMaundCtrl = TextEditingController(text: '3200'); // Rs/Maund
  final _transitFreightCtrl = TextEditingController(text: '25000'); // Rs freight
  final _vehicleNumberCtrl = TextEditingController(text: 'FD-7840');
  final _driverNameCtrl = TextEditingController(text: 'Ghulam Rasool');
  final _driverPhoneCtrl = TextEditingController(text: '03001234567');
  final _notesCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _commodityCtrl = TextEditingController(text: 'Kinnu');
    _packageTypeCtrl = TextEditingController(text: 'Crate');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopCtx = context.read<ShopContextProvider>();
      final otherShops = shopCtx.availableShops
          .where((s) => s.id != shopCtx.currentShopId)
          .toList();
      if (otherShops.isNotEmpty) {
        setState(() {
          _selectedDestinationShop = otherShops.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _commodityCtrl.dispose();
    _packageTypeCtrl.dispose();
    _packageCountCtrl.dispose();
    _weightKgCtrl.dispose();
    _ratePerMaundCtrl.dispose();
    _transitFreightCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _weightKg => double.tryParse(_weightKgCtrl.text.trim()) ?? 0.0;
  double get _weightMaunds => _weightKg / 40.0;
  double get _ratePerMaund =>
      double.tryParse(_ratePerMaundCtrl.text.trim()) ?? 0.0;
  double get _stockValue => _weightMaunds * _ratePerMaund;
  double get _transitFreight =>
      double.tryParse(_transitFreightCtrl.text.trim()) ?? 0.0;
  double get _totalDeliveredCost => _stockValue + _transitFreight;
  double get _effectiveCostPerMaund =>
      _weightMaunds > 0 ? (_totalDeliveredCost / _weightMaunds) : 0.0;

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final shopCtx = context.read<ShopContextProvider>();
    final destShop = _selectedDestinationShop;

    if (destShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Please select destination branch',
              ur: 'برائے مہربانی منزل والی برانچ منتخب کریں',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (destShop.id == shopCtx.currentShopId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Destination cannot be the same shop',
              ur: 'منزل کی دکان موجودہ برانچ سے مختلف ہونی چاہیے',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final multiShopProv = context.read<MultiShopProvider>();
    final success = await multiShopProv.createTransfer(
      destinationShopId: destShop.id,
      commodityName: _commodityCtrl.text.trim(),
      quantityKg: _weightKg,
      quantityMaunds: _weightMaunds,
      packageType: _packageTypeCtrl.text.trim(),
      packageCount: int.tryParse(_packageCountCtrl.text.trim()) ?? 0,
      unitCostPkr: _ratePerMaund,
      totalValuePkr: _stockValue,
      transitFreightPkr: _transitFreight,
      vehicleNumber: _vehicleNumberCtrl.text.trim(),
      driverName: _driverNameCtrl.text.trim(),
      driverPhone: _driverPhoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Stock transfer recorded successfully (${destShop.name})',
              ur: 'اسٹاک کی منتقلی کامیابی سے درج ہو گئی ہے (${destShop.name})',
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Failed to record stock transfer',
              ur: 'منتقلی کے اندراج میں خرابی پیش آگئی',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppStrings.isUrdu(context);
    final shopCtx = context.watch<ShopContextProvider>();
    final availableBranches = shopCtx.availableShops
        .where((s) => s.id != shopCtx.currentShopId)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_shipping_outlined,
                          color: MColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Inter-Shop Stock Transfer',
                              ur: 'اسٹاک منتقلی چالان',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${AppStrings.val(context, en: "From", ur: "از")}: ${shopCtx.currentShop?.name ?? (isUrdu ? "موجودہ برانچ" : "Current Branch")} (${shopCtx.currentShop?.city ?? ""})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Form Content
                Expanded(
                  child: ListView(
                    children: [
                      // Destination Shop Selection
                      Text(
                        AppStrings.val(
                          context,
                          en: 'Destination Branch',
                          ur: 'منزل برانچ',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (availableBranches.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.amber.shade800),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Only one shop is attached to your account. Add another shop to enable transfers.',
                                    ur: 'آپ کے اکاؤنٹ کے ساتھ صرف ایک دکان منسلک ہے۔ نئی دکان شامل کرنے کے بعد منتقلی ممکن ہوگی۔',
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<Shop>(
                          initialValue: _selectedDestinationShop,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.storefront_outlined),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          items: availableBranches.map((s) {
                            return DropdownMenuItem<Shop>(
                              value: s,
                              child: Text(
                                '${s.name} — ${s.city} (${s.address.isNotEmpty ? s.address : (isUrdu ? "منڈی برانچ" : "Mandi Branch")})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedDestinationShop = val);
                          },
                          validator: (val) => val == null
                              ? AppStrings.val(
                                  context,
                                  en: 'Please select destination branch',
                                  ur: 'براہ کرم برانچ منتخب کریں',
                                )
                              : null,
                        ),
                      const SizedBox(height: 16),

                      // Commodity & Package Info
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _commodityCtrl,
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Commodity Name',
                                  ur: 'جنس کا نام',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.eco_outlined),
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                      ? AppStrings.val(
                                          context,
                                          en: 'Field is required',
                                          ur: 'لازمی درج کریں',
                                        )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _packageTypeCtrl,
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Packing Type',
                                  ur: 'پیکنگ کی قسم',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _packageCountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Package Count',
                                  ur: 'تعداد بوریاں / پیکنگ',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Weight & Rates
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightKgCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Total Weight (KG)',
                                  ur: 'کل وزن (کلوگرام)',
                                ),
                                helperText:
                                    '= ${_numberFmt.format(_weightMaunds)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.scale_outlined),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                final v = double.tryParse(val ?? '');
                                if (v == null || v <= 0) {
                                  return AppStrings.val(
                                    context,
                                    en: 'Enter valid weight',
                                    ur: 'درست وزن درج کریں',
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _ratePerMaundCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Rate / Maund (PKR)',
                                  ur: 'ریٹ فی من (روپے)',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixText: 'Rs. ',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                final v = double.tryParse(val ?? '');
                                if (v == null || v <= 0) {
                                  return AppStrings.val(
                                    context,
                                    en: 'Enter valid rate',
                                    ur: 'درست ریٹ درج کریں',
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _transitFreightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Transit Freight (PKR)',
                                  ur: 'کرایہ گاڑی (روپے)',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixText: 'Rs. ',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Carrier / Driver Info
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _vehicleNumberCtrl,
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Vehicle Number',
                                  ur: 'گاڑی نمبر',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon:
                                    const Icon(Icons.directions_car_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _driverNameCtrl,
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Driver Name',
                                  ur: 'ڈرائیور کا نام',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _driverPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Driver Phone',
                                  ur: 'ڈرائیور فون نمبر',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(
                            context,
                            en: 'Notes / Remarks',
                            ur: 'اضافی ہدایات یا تفصیل',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Real-time Economics Summary Card
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calculate_outlined,
                                    color: MColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Consignment Economics',
                                    ur: 'منتقلی لاگت و مالی حساب',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Stock Value:',
                                    ur: 'مال کی کل مالیت:',
                                  ),
                                  style: TextStyle(
                                      color: Colors.grey.shade700),
                                ),
                                Text('Rs. ${_currencyFmt.format(_stockValue)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Transit Freight:',
                                    ur: 'کرایہ گاڑی:',
                                  ),
                                  style: TextStyle(
                                      color: Colors.grey.shade700),
                                ),
                                Text(
                                    'Rs. ${_currencyFmt.format(_transitFreight)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Total Delivered Cost:',
                                    ur: 'کل ترسیلی لاگت:',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: MColors.primary,
                                  ),
                                ),
                                Text(
                                  'Rs. ${_currencyFmt.format(_totalDeliveredCost)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: MColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Landed / Maund:',
                                    ur: 'مؤثر لاگت فی من:',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Rs. ${_numberFmt.format(_effectiveCostPerMaund)} / ${AppStrings.val(context, en: 'Maund', ur: 'من')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        AppStrings.val(
                          context,
                          en: 'Cancel',
                          ur: 'منسوخ کریں',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        _isSaving
                            ? AppStrings.val(
                                context,
                                en: 'Dispatching...',
                                ur: 'روانہ ہو رہا ہے...',
                              )
                            : AppStrings.val(
                                context,
                                en: 'Dispatch Consignment',
                                ur: 'چالان جاری اور روانہ کریں',
                              ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
