// Dialog to Record Partner Drawing or Capital Injection.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/data/models/partner_capital_model.dart';
import 'package:mandi/modules/partner_capital/providers/partner_capital_provider.dart';

class RecordPartnerDrawingDialog extends StatefulWidget {
  final ShopPartnerModel? initialPartner;
  final bool isCapitalInjection;

  const RecordPartnerDrawingDialog({
    super.key,
    this.initialPartner,
    this.isCapitalInjection = false,
  });

  @override
  State<RecordPartnerDrawingDialog> createState() => _RecordPartnerDrawingDialogState();
}

class _RecordPartnerDrawingDialogState extends State<RecordPartnerDrawingDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPartnerId;
  final _amountCtrl = TextEditingController(text: '50000');
  String _paymentMethod = 'cash';
  final _referenceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPartnerId = widget.initialPartner?.id;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_descCtrl.text.isEmpty) {
      _descCtrl.text = widget.isCapitalInjection
          ? AppStrings.val(context, en: 'Capital Injection', ur: 'سرمایہ اضافہ')
          : AppStrings.val(context, en: 'Monthly Drawing', ur: 'ماہانہ ذاتی خرچ');
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPartnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Please select a partner.',
              ur: 'براہ کرم شراکت دار منتخب کریں۔',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final provider = context.read<PartnerCapitalProvider>();

    bool success;
    if (widget.isCapitalInjection) {
      success = await provider.recordCapitalInjection(
        partnerId: _selectedPartnerId!,
        amount: amount,
        paymentMethod: _paymentMethod,
        reference: _referenceCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        transactionDate: DateTime.now(),
      );
    } else {
      success = await provider.recordDrawing(
        partnerId: _selectedPartnerId!,
        amount: amount,
        paymentMethod: _paymentMethod,
        reference: _referenceCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        transactionDate: DateTime.now(),
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isCapitalInjection
                  ? AppStrings.val(
                      context,
                      en: 'Capital added successfully!',
                      ur: 'سرمایہ کامیابی سے جمع ہو گیا!',
                    )
                  : AppStrings.val(
                      context,
                      en: 'Drawing recorded successfully!',
                      ur: 'ذاتی خرچ کامیابی سے درج ہو گیا!',
                    ),
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error saving transaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartnerCapitalProvider>();
    final partners = provider.partners.where((p) => p.isActive).toList();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isCapitalInjection ? Icons.add_circle : Icons.money_off,
            color: widget.isCapitalInjection ? Colors.green : Colors.amber.shade900,
          ),
          const SizedBox(width: 8),
          Text(
            widget.isCapitalInjection
                ? AppStrings.val(context, en: 'Capital Injection', ur: 'سرمایہ اضافہ')
                : AppStrings.val(context, en: 'Partner Drawing', ur: 'ذاتی خرچ یا نکلوانا'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedPartnerId ?? (partners.isNotEmpty ? partners.first.id : null),
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Select Partner *',
                    ur: 'شراکت دار منتخب کریں *',
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                items: partners.map((p) {
                  return DropdownMenuItem<String>(
                    value: p.id,
                    child: Text('${p.name} (${p.profitRatioFormatted})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedPartnerId = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.val(context, en: 'Amount *', ur: 'رقم *'),
                  prefixText: 'Rs. ',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.payments),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.val(context, en: 'Required', ur: 'لازمی')
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Payment Method',
                    ur: 'طریقہ ادائیگی',
                  ),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'cash',
                    child: Text(AppStrings.val(context, en: 'Cash', ur: 'نقد')),
                  ),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text(AppStrings.val(context, en: 'Bank Transfer', ur: 'بینک ٹرانسفر')),
                  ),
                  DropdownMenuItem(
                    value: 'cheque',
                    child: Text(AppStrings.val(context, en: 'Cheque', ur: 'چیک')),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referenceCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Cheque / Ref No.',
                    ur: 'چیک یا حوالہ نمبر',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.val(context, en: 'Description', ur: 'تفصیل'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں')),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isCapitalInjection ? Colors.green[800] : Colors.amber[900],
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  widget.isCapitalInjection
                      ? AppStrings.val(context, en: 'Inject Capital', ur: 'سرمایہ جمع کریں')
                      : AppStrings.val(context, en: 'Save Drawing', ur: 'ذاتی خرچ درج کریں'),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
