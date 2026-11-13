// Dialog to Add a Shop Partner.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/modules/partner_capital/providers/partner_capital_provider.dart';

class AddPartnerDialog extends StatefulWidget {
  const AddPartnerDialog({super.key});

  @override
  State<AddPartnerDialog> createState() => _AddPartnerDialogState();
}

class _AddPartnerDialogState extends State<AddPartnerDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ratioCtrl = TextEditingController(text: '25.0');
  final _capitalCtrl = TextEditingController(text: '1000000');
  final _notesCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cnicCtrl.dispose();
    _phoneCtrl.dispose();
    _ratioCtrl.dispose();
    _capitalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final ratio = double.tryParse(_ratioCtrl.text.trim()) ?? 0.0;
    final capital = double.tryParse(_capitalCtrl.text.trim()) ?? 0.0;

    final provider = context.read<PartnerCapitalProvider>();
    final success = await provider.addPartner(
      name: _nameCtrl.text.trim(),
      cnic: _cnicCtrl.text.trim().isEmpty ? null : _cnicCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      profitSharingRatio: ratio,
      openingCapital: capital,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.val(
                context,
                en: 'Partner added successfully!',
                ur: 'حصہ دار کامیابی سے شامل ہو گیا!',
              ),
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error adding partner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.handshake, color: Colors.teal),
          const SizedBox(width: 8),
          Text(
            AppStrings.val(
              context,
              en: 'Add Shop Partner',
              ur: 'نیا شراکت دار شامل کریں',
            ),
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
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Partner Name *',
                    ur: 'شراکت دار کا نام *',
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.val(context, en: 'Required', ur: 'لازمی')
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(
                          context,
                          en: 'Phone',
                          ur: 'فون نمبر',
                        ),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cnicCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(
                          context,
                          en: 'CNIC',
                          ur: 'شناختی کارڈ نمبر',
                        ),
                        hintText: '35201-...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ratioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(
                          context,
                          en: 'Profit Share % *',
                          ur: 'منافع کا تناسب % *',
                        ),
                        hintText: 'e.g. 50.0',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.percent),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? AppStrings.val(context, en: 'Required', ur: 'لازمی')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _capitalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(
                          context,
                          en: 'Opening Capital *',
                          ur: 'ابتدائی سرمایہ *',
                        ),
                        hintText: 'Rs.',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.account_balance),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? AppStrings.val(context, en: 'Required', ur: 'لازمی')
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Notes / Remarks',
                    ur: 'تفصیل و شرائط',
                  ),
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
          child: Text(
            AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں'),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  AppStrings.val(
                    context,
                    en: 'Save Partner',
                    ur: 'شراکت دار محفوظ کریں',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
