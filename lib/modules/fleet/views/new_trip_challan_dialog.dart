import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/fleet_model.dart';
import 'package:mandi/modules/fleet/providers/fleet_provider.dart';

/// Modal dialog to record a new freight trip & print dispatch bilty
/// (*نیا ٹرپ بلٹی و کرایہ چالان اندراج*).
class NewTripChallanDialog extends StatefulWidget {
  final String? preselectedVehicleId;

  const NewTripChallanDialog({super.key, this.preselectedVehicleId});

  @override
  State<NewTripChallanDialog> createState() => _NewTripChallanDialogState();
}

class _NewTripChallanDialogState extends State<NewTripChallanDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedVehicleId;
  DateTime _tripDate = DateTime.now();

  final _originCtrl = TextEditingController(text: 'Arifwala Grain Mandi');
  final _destinationCtrl = TextEditingController();
  final _commodityCtrl = TextEditingController();
  final _weightKgCtrl = TextEditingController();
  final _weightMaundsCtrl = TextEditingController();
  final _bagCountCtrl = TextEditingController();
  final _partyNameCtrl = TextEditingController();

  final _agreedFreightCtrl = TextEditingController(text: '0');
  final _driverAdvanceCtrl = TextEditingController(text: '0');
  final _dieselExpenseCtrl = TextEditingController(text: '0');
  final _tollTaxCtrl = TextEditingController(text: '0');
  final _otherExpenseCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.preselectedVehicleId;

    _weightKgCtrl.addListener(_onWeightKgChanged);
    _agreedFreightCtrl.addListener(_updateFinances);
    _driverAdvanceCtrl.addListener(_updateFinances);
    _dieselExpenseCtrl.addListener(_updateFinances);
    _tollTaxCtrl.addListener(_updateFinances);
    _otherExpenseCtrl.addListener(_updateFinances);
  }

  void _onWeightKgChanged() {
    final kg = double.tryParse(_weightKgCtrl.text.trim()) ?? 0.0;
    if (kg > 0) {
      final maunds = kg / 40.0;
      _weightMaundsCtrl.text = maunds.toStringAsFixed(2);
    }
  }

  void _updateFinances() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    _commodityCtrl.dispose();
    _weightKgCtrl.dispose();
    _weightMaundsCtrl.dispose();
    _bagCountCtrl.dispose();
    _partyNameCtrl.dispose();
    _agreedFreightCtrl.dispose();
    _driverAdvanceCtrl.dispose();
    _dieselExpenseCtrl.dispose();
    _tollTaxCtrl.dispose();
    _otherExpenseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FleetProvider>();
    final vehicles = provider.vehicles.where((v) => v.isActive).toList();

    if (_selectedVehicleId == null && vehicles.isNotEmpty) {
      _selectedVehicleId = vehicles.first.id;
    }

    final freight = double.tryParse(_agreedFreightCtrl.text.trim()) ?? 0.0;
    final advance = double.tryParse(_driverAdvanceCtrl.text.trim()) ?? 0.0;
    final diesel = double.tryParse(_dieselExpenseCtrl.text.trim()) ?? 0.0;
    final toll = double.tryParse(_tollTaxCtrl.text.trim()) ?? 0.0;
    final other = double.tryParse(_otherExpenseCtrl.text.trim()) ?? 0.0;

    final fin = FleetTrip.computeTripFinances(
      agreedFreight: freight,
      driverAdvance: advance,
      diesel: diesel,
      toll: toll,
      other: other,
    );

    final currencyFmt = NumberFormat('#,##0', 'en_US');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: const Icon(Icons.assignment_outlined,
                          color: MColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Dispatch Trip Bilty', ur: 'نیا ٹرپ و بلٹی چالان'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textPrimary,
                            ),
                          ),
                          Text(
                            AppStrings.val(context, en: 'Cargo Weight, Freight Billing & Driver Advance', ur: 'وزن، کرایہ بلنگ اور ڈرائیور ایڈوانس'),
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
                const Divider(),
                const SizedBox(height: 12),

                // Vehicle & Trip Date
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Select Vehicle *', ur: 'گاڑی منتخب کریں *'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          if (vehicles.isEmpty)
                            Text(
                              AppStrings.val(context, en: 'No vehicles registered. Please register a vehicle first.', ur: 'کوئی گاڑی درج نہیں ہے۔ پہلے گاڑی رجسٹر کریں۔'),
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue: _selectedVehicleId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: vehicles.map((v) {
                                final driverText = v.driverName.isEmpty
                                    ? (AppStrings.isUrdu(context) ? 'بغیر ڈرائیور' : 'No Driver')
                                    : v.driverName;
                                return DropdownMenuItem(
                                  value: v.id,
                                  child: Text(
                                    '${v.registrationNumber} (${AppStrings.isUrdu(context) ? v.vehicleType.labelUrdu : v.vehicleType.labelEnglish}) - $driverText',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedVehicleId = val);
                                }
                              },
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Select vehicle'
                                  : null,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Trip Date', ur: 'ٹرپ کی تاریخ'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _tripDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => _tripDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                prefixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_tripDate),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Origin & Destination
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Origin *', ur: 'روانگی کا مقام *'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _originCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. Arifwala Grain Market',
                              prefixIcon: const Icon(Icons.trip_origin,
                                  size: 18, color: Colors.blue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Destination *', ur: 'منزل مقصود *'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _destinationCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. Karachi Port / Faisalabad Mills',
                              prefixIcon: const Icon(Icons.location_on_outlined,
                                  size: 18, color: Colors.redAccent),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Commodity, Bag Count, Party
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Commodity *', ur: 'جنس / فصل *'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _commodityCtrl,
                            decoration: InputDecoration(
                              hintText: AppStrings.val(context, en: 'e.g. Wheat, Corn, Paddy', ur: 'مثلاً گندم، مکی، دھان'),
                              prefixIcon: const Icon(Icons.grass, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Bags', ur: 'تعداد بوریاں'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _bagCountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Party / Buyer Name', ur: 'گاہک یا خریدار کا نام'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _partyNameCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. Al-Rehman Flour Mills',
                              prefixIcon: const Icon(Icons.business_outlined,
                                  size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Weight (KG & Maunds)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Weight in KG', ur: 'وزن کلوگرام'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _weightKgCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: 'KG',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Calculated Maunds (40 KG)', ur: 'حساب شدہ من (40 کلو)'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _weightMaundsCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: AppStrings.val(context, en: 'Mnds', ur: 'من'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Financial Section
                Text(
                  AppStrings.val(context, en: 'Trip Freight & Operating Expenses', ur: 'کرایہ اور سفری اخراجات'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: MColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Agreed Freight *', ur: 'طے شدہ کرایہ *'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _agreedFreightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            validator: (v) {
                              final d = double.tryParse(v ?? '') ?? -1;
                              return d < 0 ? 'Enter valid freight' : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Driver Advance', ur: 'ڈرائیور ایڈوانس'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _driverAdvanceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Diesel Expense', ur: 'ڈیزل کا خرچ'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _dieselExpenseCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Toll Tax & Chungi', ur: 'ٹول ٹیکس و چونگی پرچی'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tollTaxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Other Expenses', ur: 'دیگر اخراجات'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _otherExpenseCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Live Financial Summary Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(AppStrings.val(context, en: 'Total Expenses', ur: 'کل اخراجات'),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 3),
                          Text(
                            'Rs. ${currencyFmt.format(fin['totalExpenses'])}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.red),
                          ),
                        ],
                      ),
                      Container(
                          height: 30,
                          width: 1,
                          color: Colors.blueGrey.shade300),
                      Column(
                        children: [
                          Text(AppStrings.val(context, en: 'Balance Payable', ur: 'واجب الادا بقایا'),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 3),
                          Text(
                            'Rs. ${currencyFmt.format(fin['balanceFreight'])}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.orange),
                          ),
                        ],
                      ),
                      Container(
                          height: 30,
                          width: 1,
                          color: Colors.blueGrey.shade300),
                      Column(
                        children: [
                          Text(AppStrings.val(context, en: 'Est. Net Profit', ur: 'خالص بچت'),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 3),
                          Text(
                            'Rs. ${currencyFmt.format(fin['netProfit'])}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Remarks
                Text(
                  AppStrings.val(context, en: 'Trip Notes & Instructions', ur: 'ہدایات و تفصیل'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Delivery by tomorrow 8 AM, check moisture',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _saveTrip,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.local_shipping),
                      label: Text(AppStrings.val(context, en: 'Dispatch Trip', ur: 'ٹرپ روانہ کریں')),
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

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) return;

    setState(() => _isSaving = true);

    final kg = double.tryParse(_weightKgCtrl.text.trim()) ?? 0.0;
    final maunds = double.tryParse(_weightMaundsCtrl.text.trim());
    final bags = int.tryParse(_bagCountCtrl.text.trim()) ?? 0;
    final freight = double.tryParse(_agreedFreightCtrl.text.trim()) ?? 0.0;
    final advance = double.tryParse(_driverAdvanceCtrl.text.trim()) ?? 0.0;
    final diesel = double.tryParse(_dieselExpenseCtrl.text.trim()) ?? 0.0;
    final toll = double.tryParse(_tollTaxCtrl.text.trim()) ?? 0.0;
    final other = double.tryParse(_otherExpenseCtrl.text.trim()) ?? 0.0;

    final provider = context.read<FleetProvider>();
    final success = await provider.recordTrip(
      vehicleId: _selectedVehicleId!,
      tripDate: _tripDate,
      origin: _originCtrl.text.trim(),
      destination: _destinationCtrl.text.trim(),
      commodityName: _commodityCtrl.text.trim(),
      loadedWeightKg: kg,
      loadedWeightMaunds: maunds,
      bagCount: bags,
      partyName: _partyNameCtrl.text.trim(),
      agreedFreightPkr: freight,
      driverAdvancePkr: advance,
      dieselExpensePkr: diesel,
      tollAndTaxPkr: toll,
      otherExpensePkr: other,
      notes: _notesCtrl.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip dispatched & bilty generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record trip. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
