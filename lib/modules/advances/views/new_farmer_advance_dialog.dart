import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/farmer_advance_model.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/modules/advances/providers/farmer_advance_provider.dart';
import 'package:mandi/modules/banking/providers/bank_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';

/// Modal dialog to disburse a new pre-harvest advance or input financing to a farmer.
class NewFarmerAdvanceDialog extends StatefulWidget {
  final Supplier? preselectedSupplier;

  const NewFarmerAdvanceDialog({super.key, this.preselectedSupplier});

  @override
  State<NewFarmerAdvanceDialog> createState() => _NewFarmerAdvanceDialogState();
}

class _NewFarmerAdvanceDialogState extends State<NewFarmerAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();

  Supplier? _selectedSupplier;
  final _customFarmerNameCtrl = TextEditingController();
  final _customPhoneCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _markupPercentCtrl = TextEditingController(text: '0');
  final _targetCropCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  FarmerAdvanceType _selectedType = FarmerAdvanceType.cash;
  DateTime _disbursementDate = DateTime.now();
  DateTime? _expectedHarvestDate;
  String _paymentMethod = 'cash';
  String? _selectedBankAccountId;

  bool _isSaving = false;
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _selectedSupplier = widget.preselectedSupplier;
    if (_selectedSupplier != null) {
      _customFarmerNameCtrl.text = _selectedSupplier!.name;
      _customPhoneCtrl.text = _selectedSupplier!.phone;
    }
  }

  @override
  void dispose() {
    _customFarmerNameCtrl.dispose();
    _customPhoneCtrl.dispose();
    _descriptionCtrl.dispose();
    _principalCtrl.dispose();
    _markupPercentCtrl.dispose();
    _targetCropCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDisbursementDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _disbursementDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _disbursementDate = picked);
    }
  }

  Future<void> _selectHarvestDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedHarvestDate ??
          DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _expectedHarvestDate = picked);
    }
  }

  Future<void> _saveAdvance() async {
    if (!_formKey.currentState!.validate()) return;

    final principal = double.tryParse(_principalCtrl.text.trim()) ?? 0.0;
    if (principal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Principal Amount > 0 Rs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final farmerName = _selectedSupplier?.name ?? _customFarmerNameCtrl.text.trim();
    if (farmerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a farmer name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final supplierId = _selectedSupplier?.id ?? 'custom-farmer';
    final markupPct = double.tryParse(_markupPercentCtrl.text.trim()) ?? 0.0;

    setState(() => _isSaving = true);
    try {
      final prov = context.read<FarmerAdvanceProvider>();
      await prov.createAdvance(
        supplierId: supplierId,
        farmerName: farmerName,
        farmerPhone: _selectedSupplier?.phone ?? _customPhoneCtrl.text.trim(),
        advanceType: _selectedType,
        description: _descriptionCtrl.text.trim(),
        principalAmount: principal,
        markupPercent: markupPct,
        disbursementDate: _disbursementDate,
        expectedHarvestDate: _expectedHarvestDate,
        targetCrop: _targetCropCtrl.text.trim(),
        paymentMethod: _paymentMethod,
        bankAccountId: _selectedBankAccountId,
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farmer advance recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record advance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final bankAccounts = context.watch<BankProvider>().bankAccounts;

    final principal = double.tryParse(_principalCtrl.text.trim()) ?? 0.0;
    final markupPct = double.tryParse(_markupPercentCtrl.text.trim()) ?? 0.0;
    final markupAmount = principal * (markupPct / 100.0);
    final totalPayable = principal + markupAmount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: MRadius.sm,
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.val(
                                context,
                                en: 'Disburse Farmer Advance',
                                ur: 'زمیندار پیشگی ایڈوانس',
                              ),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              AppStrings.val(
                                context,
                                en: 'Pre-harvest cash & agricultural inputs',
                                ur: 'پیشگی نقد رقم و زرعی سامان (کھاد، بیج)',
                              ),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),

                // ── Body Form ─────────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Farmer / Supplier Selection
                        DropdownButtonFormField<Supplier>(
                          initialValue: _selectedSupplier,
                          decoration: InputDecoration(
                            labelText: AppStrings.val(
                              context,
                              en: 'Select Registered Farmer',
                              ur: 'رجسٹرڈ زمیندار منتخب کریں',
                            ),
                            border: OutlineInputBorder(borderRadius: MRadius.sm),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          items: [
                            DropdownMenuItem<Supplier>(
                              value: null,
                              child: Text(
                                AppStrings.val(
                                  context,
                                  en: 'Custom / Walk-in Farmer',
                                  ur: 'غیر رجسٹرڈ / نیا زمیندار',
                                ),
                              ),
                            ),
                            ...suppliers.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text('${s.name} (${s.phone})'),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedSupplier = val;
                              if (val != null) {
                                _customFarmerNameCtrl.text = val.name;
                                _customPhoneCtrl.text = val.phone;
                              }
                            });
                          },
                        ),

                        if (_selectedSupplier == null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _customFarmerNameCtrl,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.val(
                                      context,
                                      en: 'Farmer Name *',
                                      ur: 'زمیندار کا نام *',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: MRadius.sm,
                                    ),
                                  ),
                                  validator: (v) => (_selectedSupplier == null &&
                                          (v == null || v.trim().isEmpty))
                                      ? AppStrings.val(context, en: 'Required', ur: 'لازمی')
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _customPhoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.val(
                                      context,
                                      en: 'Phone Number',
                                      ur: 'فون نمبر',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: MRadius.sm,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Advance Type & Description
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<FarmerAdvanceType>(
                                initialValue: _selectedType,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Advance Type',
                                    ur: 'ایڈوانس کی قسم',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                                items: FarmerAdvanceType.values.map((t) {
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                      AppStrings.val(context, en: t.labelEnglish, ur: t.labelUrdu),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedType = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _descriptionCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Details / Items',
                                    ur: 'تفصیل و سامان',
                                  ),
                                  hintText: AppStrings.val(
                                    context,
                                    en: 'e.g. 50 Bags DAP Fertilizer, 100L Diesel',
                                    ur: 'مثلاً 50 بوری کھاد، 100 لیٹر ڈیزل',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Principal Amount & Markup Percentage
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _principalCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Principal Amount (Rs.) *',
                                    ur: 'اصل رقم روپے *',
                                  ),
                                  prefixText: 'Rs. ',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon:
                                      const Icon(Icons.attach_money_rounded),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return AppStrings.val(context, en: 'Amount required', ur: 'رقم لازمی ہے');
                                  }
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num <= 0) {
                                    return 'Must be > 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _markupPercentCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Markup / Profit %',
                                  suffixText: '%',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Live Payable Calculation Summary Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.06),
                            borderRadius: MRadius.md,
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Principal: Rs. ${_currencyFmt.format(principal)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (markupAmount > 0)
                                    Text(
                                      'Markup ($markupPct%): +Rs. ${_currencyFmt.format(markupAmount)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppStrings.val(
                                      context,
                                      en: 'Total Loan Recoverable',
                                      ur: 'کل قابلِ واپسی قرضہ',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${_currencyFmt.format(totalPayable)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Target Crop & Expected Harvest Date
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _targetCropCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Committed Crop',
                                    ur: 'فصل کا وعدہ',
                                  ),
                                  hintText: AppStrings.val(
                                    context,
                                    en: 'e.g. Wheat, Rice, Cotton',
                                    ur: 'مثلاً گندم، دھان، کپاس',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon: const Icon(Icons.grass_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: _selectHarvestDate,
                                borderRadius: MRadius.sm,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: AppStrings.val(
                                      context,
                                      en: 'Expected Harvest Date',
                                      ur: 'متوقع تاریخ کٹائی',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: MRadius.sm,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                  ),
                                  child: Text(
                                    _expectedHarvestDate != null
                                        ? _dateFmt.format(_expectedHarvestDate!)
                                        : AppStrings.val(
                                            context,
                                            en: 'Select Harvest Date',
                                            ur: 'تاریخ منتخب کریں',
                                          ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _expectedHarvestDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Disbursement Date & Payment Method
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectDisbursementDate,
                                borderRadius: MRadius.sm,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: AppStrings.val(
                                      context,
                                      en: 'Disbursement Date',
                                      ur: 'تاریخ ادائیگی',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: MRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    _dateFmt.format(_disbursementDate),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _paymentMethod,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Disbursed Via',
                                    ur: 'طریقہ ادائیگی',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'cash',
                                    child: Text(
                                      AppStrings.val(context, en: 'Cash in Hand', ur: 'نقد رقم'),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'bank_transfer',
                                    child: Text(
                                      AppStrings.val(context, en: 'Bank Transfer', ur: 'بینک ٹرانسفر'),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cheque',
                                    child: Text(
                                      AppStrings.val(context, en: 'Cheque', ur: 'چیک'),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _paymentMethod = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        if (_paymentMethod != 'cash' &&
                            bankAccounts.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBankAccountId,
                            decoration: InputDecoration(
                              labelText: AppStrings.val(
                                context,
                                en: 'From Bank Account',
                                ur: 'بینک اکاؤنٹ سے',
                              ),
                              border: OutlineInputBorder(
                                borderRadius: MRadius.sm,
                              ),
                            ),
                            items: bankAccounts.map((b) {
                              return DropdownMenuItem(
                                value: b.id,
                                child: Text('${b.bankName} - ${b.accountTitle}'),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedBankAccountId = val),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Notes
                        TextFormField(
                          controller: _notesCtrl,
                          decoration: InputDecoration(
                            labelText: AppStrings.val(
                              context,
                              en: 'Special Conditions / Notes',
                              ur: 'شرائط و تفصیل',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: MRadius.sm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),

                // ── Actions ───────────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAdvance,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSaving
                            ? AppStrings.val(context, en: 'Disbursing...', ur: 'ادائیگی جاری ہے...')
                            : AppStrings.val(context, en: 'Disburse Advance', ur: 'ایڈوانس محفوظ کریں'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: MRadius.sm,
                        ),
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
