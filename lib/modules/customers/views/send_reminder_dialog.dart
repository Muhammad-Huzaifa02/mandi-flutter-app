import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/recovery_messaging_service.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/models/shop_model.dart';
import 'package:mandi/data/models/sms_gateway_model.dart';
import 'package:mandi/modules/sms/providers/sms_provider.dart';

/// Interactive modal sheet to preview, adjust tone/language, and dispatch payment recovery notices.
class SendReminderDialog extends StatefulWidget {
  final Customer customer;
  final Shop? shop;

  const SendReminderDialog({
    super.key,
    required this.customer,
    this.shop,
  });

  @override
  State<SendReminderDialog> createState() => _SendReminderDialogState();
}

class _SendReminderDialogState extends State<SendReminderDialog> {
  ReminderLanguage _language = ReminderLanguage.urdu;
  ReminderTone _tone = ReminderTone.polite;
  late TextEditingController _messageCtrl;

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController(text: _generateMessage());
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  String _generateMessage() {
    return RecoveryMessagingService.formatRecoveryMessage(
      customerName: widget.customer.name,
      pendingBalance: widget.customer.runningBalance,
      shopName: widget.shop?.name ?? 'Mandi Commission Shop',
      shopPhone: widget.shop?.phone,
      shopCity: widget.shop?.city,
      tone: _tone,
      language: _language,
    );
  }

  void _onSettingChanged() {
    setState(() {
      _messageCtrl.text = _generateMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.campaign_outlined, color: MColors.gold),
          const SizedBox(width: MSpacing.xs),
          Expanded(
            child: Text(
              'Payment Reminder: ${widget.customer.name}',
              style: MText.titleMd.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Outstanding Balance (بقایا):',
                    style: MText.caption.copyWith(color: Colors.white70),
                  ),
                  Text(
                    'Rs. ${widget.customer.runningBalance.toStringAsFixed(0)}',
                    style: MText.titleMd.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpacing.md),

            // Language Selector
            Row(
              children: [
                Text('Language:', style: MText.caption.copyWith(color: Colors.grey)),
                const SizedBox(width: MSpacing.sm),
                ChoiceChip(
                  label: const Text('Urdu (اردو)'),
                  selected: _language == ReminderLanguage.urdu,
                  onSelected: (val) {
                    if (val) {
                      _language = ReminderLanguage.urdu;
                      _onSettingChanged();
                    }
                  },
                ),
                const SizedBox(width: MSpacing.xs),
                ChoiceChip(
                  label: const Text('English'),
                  selected: _language == ReminderLanguage.english,
                  onSelected: (val) {
                    if (val) {
                      _language = ReminderLanguage.english;
                      _onSettingChanged();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: MSpacing.xs),

            // Tone Selector
            Row(
              children: [
                Text('Tone:', style: MText.caption.copyWith(color: Colors.grey)),
                const SizedBox(width: MSpacing.sm),
                ChoiceChip(
                  label: const Text('Polite (شائستہ)'),
                  selected: _tone == ReminderTone.polite,
                  onSelected: (val) {
                    if (val) {
                      _tone = ReminderTone.polite;
                      _onSettingChanged();
                    }
                  },
                ),
                const SizedBox(width: MSpacing.xs),
                ChoiceChip(
                  label: const Text('Formal (رسمی)'),
                  selected: _tone == ReminderTone.formal,
                  onSelected: (val) {
                    if (val) {
                      _tone = ReminderTone.formal;
                      _onSettingChanged();
                    }
                  },
                ),
                const SizedBox(width: MSpacing.xs),
                ChoiceChip(
                  label: const Text('Urgent (فوری)'),
                  selected: _tone == ReminderTone.urgent,
                  selectedColor: Colors.redAccent.withValues(alpha: 0.3),
                  onSelected: (val) {
                    if (val) {
                      _tone = ReminderTone.urgent;
                      _onSettingChanged();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: MSpacing.md),

            // Message Body (Editable)
            TextField(
              controller: _messageCtrl,
              maxLines: 8,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Message Body (پیغام کا متن)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy'),
          onPressed: () async {
            await RecoveryMessagingService.copyToClipboard(_messageCtrl.text.trim());
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message copied to clipboard!')),
              );
            }
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.sms_outlined, size: 16),
          label: const Text('Device SMS'),
          onPressed: () async {
            Navigator.pop(context);
            await RecoveryMessagingService.launchSms(
              phone: widget.customer.phone,
              message: _messageCtrl.text.trim(),
            );
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.send_to_mobile_rounded, size: 16),
          label: const Text('Gateway SMS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: MColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final smsProvider = context.read<SmsProvider>();
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);

            final res = await smsProvider.sendSms(
              recipientPhone: widget.customer.phone,
              recipientName: widget.customer.name,
              message: _messageCtrl.text.trim(),
              eventType: SmsEventType.recoveryReminder,
            );

            if (res.success) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Recovery SMS dispatched via Gateway to ${widget.customer.name}!'),
                  backgroundColor: MColors.primary,
                ),
              );
            } else {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('SMS Gateway failed: ${res.errorMessage}'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // WhatsApp Green
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.pop(context);
            await RecoveryMessagingService.launchWhatsApp(
              phone: widget.customer.phone,
              message: _messageCtrl.text.trim(),
            );
          },
        ),
      ],
    );
  }
}
