// Dialog to Issue Mandi Gate Pass & Inward Token
// (*گیٹ انٹری ٹوکن کا اجراء*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/locale_provider.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/modules/gate_pass/providers/gate_pass_provider.dart';

class IssueGatePassDialog extends StatefulWidget {
  const IssueGatePassDialog({super.key});

  @override
  State<IssueGatePassDialog> createState() => _IssueGatePassDialogState();
}

class _IssueGatePassDialogState extends State<IssueGatePassDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _vehicleCtrl;
  final _driverCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _farmerCtrl = TextEditingController();
  late final TextEditingController _commodityCtrl;
  final _bagsCtrl = TextEditingController(text: '80');
  final _grossWeightCtrl = TextEditingController();
  late final TextEditingController _platformCtrl;
  final _notesCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final isUrdu = context.read<LocaleProvider>().isUrdu;
    _vehicleCtrl = TextEditingController(text: isUrdu ? 'ٹریکٹر ٹرالی نمبر' : 'Tractor Trolley #');
    _commodityCtrl = TextEditingController(text: isUrdu ? 'گندم' : 'Wheat');
    _platformCtrl = TextEditingController(text: isUrdu ? 'پھڑ نمبر 1' : 'Platform 1');
  }

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _driverCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _farmerCtrl.dispose();
    _commodityCtrl.dispose();
    _bagsCtrl.dispose();
    _grossWeightCtrl.dispose();
    _platformCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<GatePassProvider>();
    final bags = int.tryParse(_bagsCtrl.text.trim()) ?? 0;
    final gross = double.tryParse(_grossWeightCtrl.text.trim());

    final passId = await provider.issueGatePass(
      vehicleNumber: _vehicleCtrl.text.trim(),
      driverName: _driverCtrl.text.trim(),
      driverPhone: _driverPhoneCtrl.text.trim().isEmpty ? null : _driverPhoneCtrl.text.trim(),
      farmerName: _farmerCtrl.text.trim(),
      commodityName: _commodityCtrl.text.trim(),
      estimatedBags: bags,
      assignedPlatform: _platformCtrl.text.trim(),
      grossWeightKg: gross,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (passId != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.val(context, en: 'Gate Token Issued Successfully!', ur: 'ٹوکن کامیابی سے جاری ہو گیا!')),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to issue token'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      maxWidth: 520,
      title: Row(
        children: [
          const Icon(Icons.confirmation_num, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.tr(context, 'issue_token_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
                controller: _vehicleCtrl,
                decoration: InputDecoration(
                  labelText: '${AppStrings.tr(context, 'vehicle_number')} *',
                  hintText: 'e.g. LHR-8821 / Tractor #5',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.agriculture),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.tr(context, 'required') : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _driverCtrl,
                      decoration: InputDecoration(
                        labelText: '${AppStrings.tr(context, 'driver_name')} *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.tr(context, 'required') : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _driverPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr(context, 'driver_phone'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _farmerCtrl,
                decoration: InputDecoration(
                  labelText: '${AppStrings.tr(context, 'farmer_name')} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.tr(context, 'required') : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _commodityCtrl,
                      decoration: InputDecoration(
                        labelText: '${AppStrings.tr(context, 'commodity')} *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.tr(context, 'required') : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _bagsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${AppStrings.tr(context, 'estimated_bags')} *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.tr(context, 'required') : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _grossWeightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Gross Wt (kg)',
                        hintText: 'e.g. 5200',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _platformCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr(context, 'platform_number'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(context, 'notes'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(AppStrings.tr(context, 'cancel')),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.print, color: Colors.white),
          label: Text(AppStrings.tr(context, 'issue_token_btn'), style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
        ),
      ],
    );
  }
}
