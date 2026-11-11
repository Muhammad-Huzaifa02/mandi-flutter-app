import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/broadcast_campaign_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import '../../rates/providers/mandi_rate_provider.dart';
import '../providers/broadcast_provider.dart';

class NewBroadcastDialog extends StatefulWidget {
  const NewBroadcastDialog({super.key});

  @override
  State<NewBroadcastDialog> createState() => _NewBroadcastDialogState();
}

class _NewBroadcastDialogState extends State<NewBroadcastDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Daily Mandi Bhav Bulletin');
  final _messageController = TextEditingController();

  BroadcastChannel _channel = BroadcastChannel.both;
  AudienceType _audience = AudienceType.allFarmers;
  final TemplateType _template = TemplateType.dailyRates;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillMandiRates();
    });
  }

  void _autoFillMandiRates() {
    final shopCtx = context.read<ShopContextProvider>();
    final rateProvider = context.read<MandiRateProvider>();
    final broadcastProvider = context.read<BroadcastProvider>();

    final shopName = shopCtx.currentShop?.name ?? 'Mandi Trade Commission';
    final munshiPhone = shopCtx.currentShop?.phone ?? '0300-1234567';

    final bulletin = broadcastProvider.synthesizeMandiRatesBulletin(
      marketName: 'فیصل آباد غلہ منڈی (Faisalabad Grain Market)',
      date: DateTime.now(),
      rates: rateProvider.rates,
      munshiPhone: munshiPhone,
      shopName: shopName,
      customNote: 'آج شام 5 بجے تک کاٹن کی نقد ادائیگی دستیاب ہے۔',
    );

    setState(() {
      _messageController.text = bulletin;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final broadcastProvider = context.watch<BroadcastProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.campaign, color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Mandi Broadcast Bulletin',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'نیا براڈکاسٹ پیغام (واٹس ایپ و ٹیلیگرام)',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campaign Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Campaign Title *',
                    hintText: 'e.g. Morning Mandi Bhav Rates',
                    prefixIcon: Icon(Icons.title, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Channel & Audience Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BroadcastChannel>(
                        initialValue: _channel,
                        decoration: const InputDecoration(
                          labelText: 'Channel (چینل)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: BroadcastChannel.values.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c.labelEn, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _channel = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<AudienceType>(
                        initialValue: _audience,
                        decoration: const InputDecoration(
                          labelText: 'Audience (مخاطب)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: AudienceType.values.map((a) {
                          return DropdownMenuItem(
                            value: a,
                            child: Text(a.labelEn, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _audience = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Auto-Synthesize Action
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.teal),
                      label: const Text('Auto-Fill Today\'s Rates (تازہ ریٹس بھریں)', style: TextStyle(fontSize: 11)),
                      onPressed: _autoFillMandiRates,
                    ),
                    const Spacer(),
                    Text(
                      'Recipients: ${broadcastProvider.subscribers.length} subscribers',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Message Body
                Expanded(
                  child: TextFormField(
                    controller: _messageController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      labelText: 'Bulletin Message Content (پیغام کا متن) *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter message content' : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6B3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Save & Dispatch (ارسال کریں)'),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isSaving = true);

                              final campaign = await broadcastProvider.createCampaign(
                                title: _titleController.text.trim(),
                                channel: _channel,
                                audienceType: _audience,
                                templateType: _template,
                                messageBody: _messageController.text.trim(),
                              );

                              if (campaign != null) {
                                await broadcastProvider.dispatchCampaign(campaign);
                              }

                              setState(() => _isSaving = false);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Broadcast Bulletin Dispatched Successfully!')),
                                );
                              }
                            },
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
