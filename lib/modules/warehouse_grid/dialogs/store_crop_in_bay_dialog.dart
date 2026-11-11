// Dialog to Store Crop in a Warehouse Bay
// (*گودام کے خانے میں مال ذخیرہ کریں*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/data/models/warehouse_grid_model.dart';
import 'package:mandi/modules/warehouse_grid/providers/warehouse_grid_provider.dart';

class StoreCropInBayDialog extends StatefulWidget {
  final WarehouseGridBayModel bay;

  const StoreCropInBayDialog({super.key, required this.bay});

  @override
  State<StoreCropInBayDialog> createState() => _StoreCropInBayDialogState();
}

class _StoreCropInBayDialogState extends State<StoreCropInBayDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _cropCtrl;
  late final TextEditingController _farmerCtrl;
  late final TextEditingController _lotCtrl;
  late final TextEditingController _bagsCtrl;
  late final TextEditingController _capacityCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cropCtrl = TextEditingController(text: widget.bay.cropName ?? 'Basmati Rice (دھان)');
    _farmerCtrl = TextEditingController(text: widget.bay.farmerName ?? 'Malik Farm');
    _lotCtrl = TextEditingController(text: widget.bay.lotCode ?? 'LOT-${widget.bay.chamberCode}-${widget.bay.bayCode}');
    _bagsCtrl = TextEditingController(
      text: widget.bay.currentBags > 0 ? widget.bay.currentBags.toString() : '150',
    );
    _capacityCtrl = TextEditingController(text: widget.bay.maxCapacityBags.toString());
  }

  @override
  void dispose() {
    _cropCtrl.dispose();
    _farmerCtrl.dispose();
    _lotCtrl.dispose();
    _bagsCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final bags = int.tryParse(_bagsCtrl.text.trim()) ?? 0;
    final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 200;

    final provider = context.read<WarehouseGridProvider>();
    final success = await provider.storeCropInBay(
      bayId: widget.bay.id,
      cropName: _cropCtrl.text.trim(),
      farmerName: _farmerCtrl.text.trim(),
      lotCode: _lotCtrl.text.trim(),
      bags: bags,
      maxCapacityBags: capacity,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock Stored in Bay ${widget.bay.bayCode} Successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error updating bay'),
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
          const Icon(Icons.inventory, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Store Stock in Bay ${widget.bay.bayCode}\n(${widget.bay.chamberCode} خانے میں مال کا اندراج)',
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
                controller: _cropCtrl,
                decoration: const InputDecoration(
                  labelText: 'Crop Commodity / جنس *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grain),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _farmerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Farmer / زمیندار *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lotCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lot Code / لاٹ نمبر *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bagsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stored Bags (بوریاں) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bay Capacity *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('منسوخ (Cancel)'),
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
              : const Text('محفوظ کریں (Store Stock)', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
