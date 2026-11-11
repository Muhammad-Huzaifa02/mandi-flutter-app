import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                    const Expanded(
                      child: Text(
                        'Add Broadcast Subscriber (نیا ممبر)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  decoration: const InputDecoration(
                    labelText: 'Full Name (نام) *',
                    hintText: 'e.g. Chaudhry Aslam / حاجی بشیر',
                    prefixIcon: Icon(Icons.person, size: 18),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Phone or Telegram Chat ID
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone / Telegram Chat ID *',
                    hintText: 'e.g. 0300-1234567 or @aslam_farmer',
                    prefixIcon: Icon(Icons.phone, size: 18),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Platform & Type
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BroadcastChannel>(
                        initialValue: _platform,
                        decoration: const InputDecoration(
                          labelText: 'Platform',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'farmer', child: Text('Farmer (زمیندار)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'buyer', child: Text('Buyer (خریدار)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'agent', child: Text('Agent (آڑھتی)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'transporter', child: Text('Transporter', style: TextStyle(fontSize: 12))),
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
                  decoration: const InputDecoration(
                    labelText: 'Notes / Mandi Village (علاقہ / تفصیل)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
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
                                    const SnackBar(content: Text('Subscriber added successfully!')),
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
                      child: const Text('Save Subscriber'),
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
