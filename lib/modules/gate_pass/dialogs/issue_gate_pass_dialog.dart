// Dialog to Issue Mandi Gate Pass & Inward Token
// (*گیٹ انٹری ٹوکن کا اجراء*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/modules/gate_pass/providers/gate_pass_provider.dart';

class IssueGatePassDialog extends StatefulWidget {
  const IssueGatePassDialog({super.key});

  @override
  State<IssueGatePassDialog> createState() => _IssueGatePassDialogState();
}

class _IssueGatePassDialogState extends State<IssueGatePassDialog> {
  final _formKey = GlobalKey<FormState>();

  final _vehicleCtrl = TextEditingController(text: 'Tractor Trolley #');
  final _driverCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _farmerCtrl = TextEditingController();
  final _commodityCtrl = TextEditingController(text: 'Wheat (گندم)');
  final _bagsCtrl = TextEditingController(text: '80');
  final _grossWeightCtrl = TextEditingController();
  final _platformCtrl = TextEditingController(text: 'پھڑ نمبر 1');
  final _notesCtrl = TextEditingController();

  bool _isSubmitting = false;

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
          const SnackBar(
            content: Text('Gate Token Issued Successfully! (ٹوکن جاری ہو گیا)'),
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.confirmation_num, color: Colors.teal),
          SizedBox(width: 8),
          Text(
            'Issue Gate Inward Token\n(گیٹ پاس و ٹوکن اجراء)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                decoration: const InputDecoration(
                  labelText: 'Vehicle / گاڑی نمبر *',
                  hintText: 'e.g. LHR-8821 / Tractor #5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _driverCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Driver / ڈرائیور *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _driverPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Driver Phone / فون',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _farmerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Farmer / زمیندار کا نام *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _commodityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Crop / جنس *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _bagsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Est. Bags (بوریاں) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                      decoration: const InputDecoration(
                        labelText: 'Platform / پھڑ نمبر',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes / ریمارکس',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('منسوخ (Cancel)'),
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
          label: const Text('ٹوکن جاری کریں (Issue Token)', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
        ),
      ],
    );
  }
}
