import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
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
                              ? AppStrings.val(context, en: 'Edit Storage Facility', ur: 'گودام معلومات تبدیل کریں')
                              : AppStrings.val(context, en: 'Add Storage Facility', ur: 'نیا گودام یا سٹوریج درج کریں'),
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
                  AppStrings.val(context, en: 'Facility Type:', ur: 'سہولت کی قسم:'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(AppStrings.val(context, en: 'Godown', ur: 'منڈی گودام')),
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
                      label: Text(AppStrings.val(context, en: 'Cold Store', ur: 'کولڈ سٹوریج')),
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
                      label: Text(AppStrings.val(context, en: 'Shop Pharr', ur: 'پھڑ')),
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
                  decoration: InputDecoration(
                    labelText: AppStrings.val(context, en: 'Facility Name *', ur: 'گودام یا سٹور کا نام *'),
                    hintText: AppStrings.val(context, en: 'e.g. Al-Rehman Cold Store / Mandi Godown #3', ur: 'مثلاً الرحمٰن کولڈ سٹور / گودام نمبر ۳'),
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? AppStrings.val(context, en: 'Please enter facility name', ur: 'براہ کرم گودام کا نام درج کریں')
                      : null,
                ),
                const SizedBox(height: 14),

                // Capacity & Monthly Rent
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _capacityCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Capacity (Total Bags) *', ur: 'کل گنجائش (بوریاں) *'),
                          hintText: '5000',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return AppStrings.val(context, en: 'Required', ur: 'لازمی');
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) return AppStrings.val(context, en: 'Must be > 0', ur: 'صفر سے بڑا ہو');
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rentCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Monthly Rent / Bag (PKR)', ur: 'ماہانہ کرایہ فی بوری (روپیہ)'),
                          hintText: AppStrings.val(context, en: 'e.g. 80 (0 if own shop)', ur: 'مثلاً ۸۰ (اپنی دکان ہو تو صفر)'),
                          prefixIcon: const Icon(Icons.monetization_on_outlined),
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
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Manager / Munshi Name', ur: 'منیجر یا منشی کا نام'),
                          hintText: AppStrings.val(context, en: 'e.g. Haji Bashir', ur: 'مثلاً حاجی بشیر'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Phone Number', ur: 'فون نمبر'),
                          hintText: '03001234567',
                          prefixIcon: const Icon(Icons.phone_outlined),
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
                  decoration: InputDecoration(
                    labelText: AppStrings.val(context, en: 'Location / Address', ur: 'پتہ یا مقام'),
                    hintText: AppStrings.val(context, en: 'e.g. Depalpur Road near Grain Market', ur: 'مثلاً دیپالپور روڈ غلہ منڈی'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(context, en: 'Notes / Remarks', ur: 'تفصیل یا ہدایات'),
                    prefixIcon: const Icon(Icons.note_alt_outlined),
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
                      child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ')),
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
                        isEdit
                            ? AppStrings.val(context, en: 'Update Facility', ur: 'معلومات محفوظ کریں')
                            : AppStrings.val(context, en: 'Save Facility', ur: 'گودام محفوظ کریں'),
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
