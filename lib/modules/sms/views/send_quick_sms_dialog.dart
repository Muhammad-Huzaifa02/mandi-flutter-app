import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/sms_gateway_service.dart';
import 'package:mandi/data/models/sms_gateway_model.dart';
import 'package:mandi/modules/sms/providers/sms_provider.dart';

/// Interactive modal dialog to compose and dispatch an ad-hoc SMS to a customer,
/// supplier, or custom phone number with real-time GSM parts calculation.
class SendQuickSmsDialog extends StatefulWidget {
  final String? initialPhone;
  final String? initialName;
  final String? initialMessage;
  final SmsEventType eventType;

  const SendQuickSmsDialog({
    super.key,
    this.initialPhone,
    this.initialName,
    this.initialMessage,
    this.eventType = SmsEventType.manualTest,
  });

  @override
  State<SendQuickSmsDialog> createState() => _SendQuickSmsDialogState();
}

class _SendQuickSmsDialogState extends State<SendQuickSmsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _nameController;
  late final TextEditingController _messageController;

  late SmsPartInfo _partsInfo;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _messageController = TextEditingController(text: widget.initialMessage ?? '');
    _partsInfo = SmsGatewayService.calculateParts(_messageController.text);

    _messageController.addListener(() {
      setState(() {
        _partsInfo = SmsGatewayService.calculateParts(_messageController.text);
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _applyTemplate(String text) {
    _messageController.text = text;
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();

    final provider = context.read<SmsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final result = await provider.sendSms(
      recipientPhone: phone,
      recipientName: name,
      message: message,
      eventType: widget.eventType,
    );

    if (!mounted) return;

    if (result.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('SMS successfully dispatched to $phone! (ID: ${result.messageId})'),
          backgroundColor: MColors.primary,
        ),
      );
      nav.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send SMS: ${result.errorMessage ?? "Unknown error"}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final smsProvider = context.watch<SmsProvider>();
    final isEnabled = smsProvider.settings.isEnabled ||
        smsProvider.settings.provider == SmsProviderType.mock;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sms_rounded, color: MColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.val(context, en: 'Send Direct SMS', ur: 'براہ راست پیغام ارسال کریں'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppStrings.val(context, en: 'Automated SMS dispatch for customers and farmers', ur: 'گاہک یا زمیندار کو ایس ایم ایس الرٹ روانہ کریں'),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

              if (!isEnabled)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.val(
                            context,
                            en: 'SMS Gateway is disabled in settings. Enable it or use Mock Simulator.',
                            ur: 'گیٹ وے بند ہے۔ اسے سیٹنگز سے آن کریں یا ٹیسٹ سمیلیٹر استعمال کریں۔',
                          ),
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              // Recipient Phone & Name
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(context, en: 'Phone Number', ur: 'موبائل نمبر'),
                        hintText: '03001234567 or +92300...',
                        prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter recipient phone';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(context, en: 'Recipient Name', ur: 'وصول کنندہ کا نام'),
                        hintText: 'Haji Sahib',
                        prefixIcon: const Icon(Icons.person_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Message Body Field
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: AppStrings.val(context, en: 'SMS Message Body', ur: 'پیغام کا متن'),
                  alignLabelWithHint: true,
                  hintText: AppStrings.val(context, en: 'Write SMS message content...', ur: 'پیغام کا متن یہاں لکھیں...'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Message cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Character & Parts Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _partsInfo.isUnicode
                              ? Colors.purple.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _partsInfo.isUnicode
                                ? Colors.purple.shade200
                                : Colors.blue.shade200,
                          ),
                        ),
                        child: Text(
                          _partsInfo.isUnicode ? 'Unicode (Urdu)' : 'GSM-7 (Standard)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _partsInfo.isUnicode
                                ? Colors.purple.shade800
                                : Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_partsInfo.partsCount} ${_partsInfo.partsCount == 1 ? "SMS Part" : "SMS Parts"}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    '${_partsInfo.charCount} / ${_partsInfo.maxCharsInCurrentPart} chars (${_partsInfo.remainingCharsInPart} left)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Templates Chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.flash_on, size: 14),
                    label: const Text('Payment Reminder', style: TextStyle(fontSize: 11)),
                    onPressed: () => _applyTemplate(
                      'Mohtaram Customer, aap k Mandi khata ka baqi balance Rs. 25,000 wajib ul ada hai. Baraye meherbani jald adaigi farmayein. Shukriya.',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.receipt_long, size: 14),
                    label: const Text('Invoice Notice', style: TextStyle(fontSize: 11)),
                    onPressed: () => _applyTemplate(
                      'Mandi Bill Tayar Hai. Baraye meherbani dukaan par aakar apna bill aur receipt vasool karein. Shukriya.',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.gavel_rounded, size: 14),
                    label: const Text('Boli Notification', style: TextStyle(fontSize: 11)),
                    onPressed: () => _applyTemplate(
                      'Aap ki dheri ki boli kamyabi se mukammal ho chuki hai. Tafseelat k liye dukaan rabta karein.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ')),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: smsProvider.isSending ? null : _handleSend,
                    icon: smsProvider.isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      smsProvider.isSending
                          ? AppStrings.val(context, en: 'Sending...', ur: 'ارسال ہو رہا ہے...')
                          : AppStrings.val(context, en: 'Send SMS Now', ur: 'ابھی ارسال کریں'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
