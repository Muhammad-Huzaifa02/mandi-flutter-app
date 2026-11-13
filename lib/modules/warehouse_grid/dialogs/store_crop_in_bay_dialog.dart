// Dialog to Store Crop in a Warehouse Bay

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
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
    _cropCtrl = TextEditingController(text: widget.bay.cropName ?? 'Basmati Rice');
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
    final isUrdu = AppStrings.isUrdu(context);
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
            content: Text(
              isUrdu
                  ? 'خانہ ${widget.bay.bayCode} میں مال کا کامیابی سے اندراج ہو گیا!'
                  : 'Stock Stored in Bay ${widget.bay.bayCode} Successfully!',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? (isUrdu ? 'اندراج میں خرابی' : 'Error updating bay')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppStrings.isUrdu(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.inventory, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isUrdu
                  ? 'خانہ ${widget.bay.bayCode} میں مال کا اندراج'
                  : 'Store Stock in Bay ${widget.bay.bayCode}',
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
                decoration: InputDecoration(
                  labelText: isUrdu ? 'فصل و جنس *' : 'Crop Commodity *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.grain),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? (isUrdu ? 'لازمی ہے' : 'Required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _farmerCtrl,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'زمیندار *' : 'Farmer *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? (isUrdu ? 'لازمی ہے' : 'Required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lotCtrl,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'لاٹ نمبر *' : 'Lot Code *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? (isUrdu ? 'لازمی ہے' : 'Required') : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bagsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isUrdu ? 'تعداد بوریاں *' : 'Stored Bags *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? (isUrdu ? 'لازمی ہے' : 'Required') : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isUrdu ? 'کل گنجائش *' : 'Bay Capacity *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? (isUrdu ? 'لازمی ہے' : 'Required') : null,
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
          child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
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
                  isUrdu ? 'محفوظ کریں' : 'Store Stock',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
