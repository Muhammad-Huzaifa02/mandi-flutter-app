// Dialog to Record Weighbridge Tare & Net Weight
// (*کنڈا خالی وزن اور خالص وزن ریکارڈنگ*).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/gate_pass_model.dart';
import 'package:mandi/modules/gate_pass/providers/gate_pass_provider.dart';

class RecordWeighmentDialog extends StatefulWidget {
  final GatePassModel gatePass;

  const RecordWeighmentDialog({super.key, required this.gatePass});

  @override
  State<RecordWeighmentDialog> createState() => _RecordWeighmentDialogState();
}

class _RecordWeighmentDialogState extends State<RecordWeighmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  late final TextEditingController _grossCtrl;
  final _tareCtrl = TextEditingController(text: '1200');
  double _calculatedNetKg = 0.0;
  double _calculatedNetMaunds = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _grossCtrl = TextEditingController(
      text: widget.gatePass.grossWeightKg != null
          ? widget.gatePass.grossWeightKg!.toStringAsFixed(0)
          : '4800',
    );
    _computeNet();
  }

  @override
  void dispose() {
    _grossCtrl.dispose();
    _tareCtrl.dispose();
    super.dispose();
  }

  void _computeNet() {
    final gross = double.tryParse(_grossCtrl.text.trim()) ?? 0.0;
    final tare = double.tryParse(_tareCtrl.text.trim()) ?? 0.0;
    final net = (gross - tare).clamp(0.0, double.infinity);
    setState(() {
      _calculatedNetKg = net;
      _calculatedNetMaunds = net / 40.0;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final tare = double.tryParse(_tareCtrl.text.trim()) ?? 0.0;
    final gross = double.tryParse(_grossCtrl.text.trim());

    final provider = context.read<GatePassProvider>();
    final success = await provider.recordWeighment(
      passId: widget.gatePass.id,
      tareWeightKg: tare,
      grossWeightOverride: gross,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.val(context, en: 'Weighment Recorded Successfully!', ur: 'وزن کامیابی سے درج ہو گیا!')),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error saving weighment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      maxWidth: 500,
      title: Row(
        children: [
          const Icon(Icons.scale, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${AppStrings.tr(context, 'tare_weighment_title')} (${widget.gatePass.tokenNumber})',
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
              Text(
                'Vehicle: ${widget.gatePass.vehicleNumber} | Farmer: ${widget.gatePass.farmerName}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _grossCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${AppStrings.tr(context, 'gross_weight')} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.fitness_center),
                ),
                onChanged: (_) => _computeNet(),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.tr(context, 'required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tareCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${AppStrings.tr(context, 'empty_tare_weight')} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.line_weight),
                ),
                onChanged: (_) => _computeNet(),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.tr(context, 'required') : null,
              ),
              const SizedBox(height: 16),
              // Net Calculation Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  children: [
                    Text(AppStrings.tr(context, 'net_crop_weight'),
                        style: const TextStyle(fontSize: 12, color: Colors.teal)),
                    const SizedBox(height: 4),
                    Text(
                      '${_numberFmt.format(_calculatedNetKg)} KG',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '= ${_numberFmt.format(_calculatedNetMaunds)} ${AppStrings.tr(context, 'maunds')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(AppStrings.tr(context, 'cancel')),
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
              : Text(AppStrings.tr(context, 'save_weighment'), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
