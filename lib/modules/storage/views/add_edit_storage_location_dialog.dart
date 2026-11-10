import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/storage_location_model.dart';
import 'package:mandi/modules/storage/providers/storage_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Modal dialog for adding or editing a Godown, Cold Store, or Shop Platform.
class AddEditStorageLocationDialog extends StatefulWidget {
  final StorageLocation? existingLocation;

  const AddEditStorageLocationDialog({super.key, this.existingLocation});

  @override
  State<AddEditStorageLocationDialog> createState() =>
      _AddEditStorageLocationDialogState();
}

class _AddEditStorageLocationDialogState
    extends State<AddEditStorageLocationDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late StorageLocationType _type;
  late TextEditingController _addressCtrl;
  late TextEditingController _contactPersonCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _rentCtrl;
  late TextEditingController _notesCtrl;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final loc = widget.existingLocation;
    if (loc != null) {
      _nameCtrl = TextEditingController(text: loc.name);
      _type = loc.type;
      _addressCtrl = TextEditingController(text: loc.address);
      _contactPersonCtrl = TextEditingController(text: loc.contactPerson);
      _phoneCtrl = TextEditingController(text: loc.phone);
      _capacityCtrl =
          TextEditingController(text: loc.capacityBags.toString());
      _rentCtrl = TextEditingController(
          text: loc.monthlyRentPerBag.toStringAsFixed(0));
      _notesCtrl = TextEditingController(text: loc.notes);
      _isActive = loc.isActive;
    } else {
      _nameCtrl = TextEditingController();
      _type = StorageLocationType.godown;
      _addressCtrl = TextEditingController();
      _contactPersonCtrl = TextEditingController();
      _phoneCtrl = TextEditingController();
      _capacityCtrl = TextEditingController(text: '1000');
      _rentCtrl = TextEditingController(text: '0');
      _notesCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _capacityCtrl.dispose();
    _rentCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final shopId = context.read<ShopContextProvider>().currentShopId;
      if (shopId == null) {
        throw Exception('No active shop context selected.');
      }

      final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 0;
      final rent = double.tryParse(_rentCtrl.text.trim()) ?? 0.0;

      final loc = StorageLocation(
        id: widget.existingLocation?.id ?? '',
        shopId: shopId,
        name: _nameCtrl.text.trim(),
        type: _type,
        address: _addressCtrl.text.trim(),
        contactPerson: _contactPersonCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        capacityBags: capacity,
        currentBags: widget.existingLocation?.currentBags ?? 0,
        monthlyRentPerBag: rent,
        isActive: _isActive,
        notes: _notesCtrl.text.trim(),
      );

      final storageProv = context.read<StorageProvider>();
      if (widget.existingLocation == null) {
        await storageProv.addLocation(loc);
      } else {
        await storageProv.updateLocation(loc);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingLocation == null
                  ? 'Storage facility added successfully.'
                  : 'Storage facility updated.',
            ),
            backgroundColor: MColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving storage facility: $e'),
            backgroundColor: MColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingLocation != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warehouse_outlined,
                          color: MColors.primaryLight,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEdit
                              ? 'Edit Storage Facility'
                              : 'Add Storage Facility (گودام / کولڈ سٹوریج)',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Location Type Choice
                Text(
                  'Facility Type (قسم):',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Godown (منڈی گودام)'),
                      selected: _type == StorageLocationType.godown,
                      selectedColor: MColors.primary.withValues(alpha: 0.15),
                      onSelected: (v) {
                        if (v) {
                          setState(() => _type = StorageLocationType.godown);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Cold Store (کولڈ سٹوریج)'),
                      selected: _type == StorageLocationType.coldStorage,
                      selectedColor: Colors.blueAccent.withValues(alpha: 0.15),
                      onSelected: (v) {
                        if (v) {
                          setState(
                              () => _type = StorageLocationType.coldStorage);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Shop Pharr (پھڑ)'),
                      selected: _type == StorageLocationType.shopPharr,
                      selectedColor: MColors.gold.withValues(alpha: 0.15),
                      onSelected: (v) {
                        if (v) {
                          setState(
                              () => _type = StorageLocationType.shopPharr);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Facility Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Facility Name (گودام یا سٹور کا نام) *',
                    hintText: 'e.g. Al-Rehman Cold Store / Mandi Godown #3',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter facility name'
                      : null,
                ),
                const SizedBox(height: 14),

                // Capacity & Monthly Rent
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _capacityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Capacity (کل گنجائش بوریاں) *',
                          hintText: 'e.g. 5000',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Rent / Bag (کرایہ)',
                          hintText: 'e.g. 80 (0 if own shop)',
                          prefixIcon: Icon(Icons.monetization_on_outlined),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Contact Person & Phone
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contactPersonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Manager / Munshi Name',
                          hintText: 'e.g. Haji Bashir',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phone (فون نمبر)',
                          hintText: '03001234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Address
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location / Address (پتہ)',
                    hintText: 'e.g. Depalpur Road near Grain Market',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Remarks (تفصیل)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        isEdit ? 'Update Facility' : 'Save Facility',
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
