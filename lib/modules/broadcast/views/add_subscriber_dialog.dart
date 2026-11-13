import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/localization/app_strings.dart';
import '../../../data/models/broadcast_campaign_model.dart';
import '../providers/broadcast_provider.dart';

class AddSubscriberDialog extends StatefulWidget {
  const AddSubscriberDialog({super.key});

  @override
  State<AddSubscriberDialog> createState() => _AddSubscriberDialogState();
}

class _AddSubscriberDialogState extends State<AddSubscriberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  BroadcastChannel _platform = BroadcastChannel.whatsapp;
  String _subscriberType = 'farmer';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final broadcastProvider = context.read<BroadcastProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_add, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.val(context, en: 'Add Broadcast Subscriber', ur: 'نیا براڈکاسٹ ممبر شامل کریں'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(context, en: 'Full Name *', ur: 'مکمل نام *'),
                    hintText: AppStrings.val(context, en: 'e.g. Chaudhry Aslam', ur: 'مثلاً چوہدری اسلم'),
                    prefixIcon: const Icon(Icons.person, size: 18),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? AppStrings.val(context, en: 'Required', ur: 'لازمی') : null,
                ),
                const SizedBox(height: 12),

                // Phone or Telegram Chat ID
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(context, en: 'Phone / Telegram Chat ID *', ur: 'فون نمبر یا چیٹ آئی ڈی *'),
                    hintText: '0300-1234567',
                    prefixIcon: const Icon(Icons.phone, size: 18),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? AppStrings.val(context, en: 'Required', ur: 'لازمی') : null,
                ),
                const SizedBox(height: 12),

                // Platform & Type
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BroadcastChannel>(
                        initialValue: _platform,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Platform', ur: 'پلیٹ فارم'),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: BroadcastChannel.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _platform = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _subscriberType,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(context, en: 'Category', ur: 'قسم'),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: 'farmer', child: Text(AppStrings.val(context, en: 'Farmer', ur: 'زمیندار'), style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'buyer', child: Text(AppStrings.val(context, en: 'Buyer', ur: 'خریدار'), style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'agent', child: Text(AppStrings.val(context, en: 'Commission Agent', ur: 'آڑھتی'), style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'transporter', child: Text(AppStrings.val(context, en: 'Transporter', ur: 'ٹرانسپورٹر'), style: const TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _subscriberType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(context, en: 'Notes / Mandi Village', ur: 'علاقہ / تفصیل'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ')),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6B3C),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isSaving = true);
                              try {
                                await broadcastProvider.addSubscriber(
                                  name: _nameController.text.trim(),
                                  phoneOrChatId: _phoneController.text.trim(),
                                  platform: _platform,
                                  subscriberType: _subscriberType,
                                  notes: _notesController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(AppStrings.val(context, en: 'Subscriber added successfully!', ur: 'ممبر کامیابی سے شامل کر لیا گیا!'))),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isSaving = false);
                              }
                            },
                      child: Text(AppStrings.val(context, en: 'Save Subscriber', ur: 'ممبر محفوظ کریں')),
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
