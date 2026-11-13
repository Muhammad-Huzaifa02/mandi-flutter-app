import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/cheque_model.dart';
import 'package:mandi/modules/banking/providers/bank_provider.dart';

/// Modal dialog allowing user to transition cheque lifecycle:
/// In-Hand -> Deposited -> Cleared / Bounced.
class UpdateChequeStatusDialog extends StatefulWidget {
  final Cheque cheque;

  const UpdateChequeStatusDialog({super.key, required this.cheque});

  @override
  State<UpdateChequeStatusDialog> createState() =>
      _UpdateChequeStatusDialogState();
}

class _UpdateChequeStatusDialogState extends State<UpdateChequeStatusDialog> {
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  late ChequeStatus _selectedAction;
  String? _targetBankAccountId;
  late DateTime _actionDate;
  late TextEditingController _bounceReasonCtrl;
  bool _isSaving = false;

  static List<String> _getBounceReasons(bool isUrdu) {
    if (isUrdu) {
      return const [
        'فنڈز کی کمی',
        'دستخط میں فرق',
        'ادائیگی روکی گئی',
        'اکاؤنٹ منجمد یا بند',
        'قبل از وقت جمع کرایا گیا',
        'دیگر وجہ',
      ];
    } else {
      return const [
        'Insufficient Funds',
        'Signature Mismatch',
        'Payment Stopped by Drawer',
        'Account Frozen or Closed',
        'Post-Dated Presented Early',
        'Other Reason',
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _actionDate = DateTime.now();
    _bounceReasonCtrl = TextEditingController(text: widget.cheque.bounceReason);
    _targetBankAccountId = widget.cheque.targetBankAccountId;

    // Default to the next logical step in the lifecycle
    switch (widget.cheque.status) {
      case ChequeStatus.inHand:
        _selectedAction = ChequeStatus.deposited;
        break;
      case ChequeStatus.deposited:
        _selectedAction = ChequeStatus.cleared;
        break;
      case ChequeStatus.cleared:
      case ChequeStatus.bounced:
      case ChequeStatus.returned:
        _selectedAction = widget.cheque.status;
        break;
    }
  }

  @override
  void dispose() {
    _bounceReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final bankProv = context.read<BankProvider>();

    try {
      if (_selectedAction == ChequeStatus.deposited) {
        if (_targetBankAccountId == null || _targetBankAccountId!.isEmpty) {
          throw Exception(AppStrings.val(
            context,
            en: 'Please select a Bank Account where cheque is deposited.',
            ur: 'براہ کرم بینک اکاؤنٹ منتخب کریں جہاں چیک جمع کرایا گیا ہو۔',
          ));
        }
        await bankProv.markAsDeposited(
          chequeId: widget.cheque.id,
          targetBankAccountId: _targetBankAccountId!,
          depositDate: _actionDate,
        );
      } else if (_selectedAction == ChequeStatus.cleared) {
        await bankProv.markAsCleared(
          chequeId: widget.cheque.id,
          clearanceDate: _actionDate,
        );
      } else if (_selectedAction == ChequeStatus.bounced) {
        final reason = _bounceReasonCtrl.text.trim();
        if (reason.isEmpty) {
          throw Exception(AppStrings.val(
            context,
            en: 'Please provide a reason for the bounced cheque.',
            ur: 'براہ کرم چیک باؤنس ہونے کی وجہ درج کریں۔',
          ));
        }
        await bankProv.markAsBounced(
          chequeId: widget.cheque.id,
          bounceReason: reason,
        );
      }

      if (mounted) {
        final msg = AppStrings.val(
          context,
          en: 'Cheque status updated successfully.',
          ur: 'چیک کا سٹیٹس کامیابی سے تبدیل ہو گیا۔',
        );
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: MColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.val(context, en: "Error:", ur: "خرابی:")} $e'),
            backgroundColor: MColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankAccounts = context.watch<BankProvider>().bankAccounts;
    final isUrdu = AppStrings.isUrdu(context);
    final bounceReasons = _getBounceReasons(isUrdu);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.val(
                      context,
                      en: 'Update Cheque Status',
                      ur: 'چیک سٹیٹس تبدیل کریں',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Cheque Info Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: MRadius.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.val(context, en: "Cheque #", ur: "چیک نمبر #")}${widget.cheque.chequeNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${AppStrings.val(context, en: "Party", ur: "پارٹی")}: ${widget.cheque.partyName} (${widget.cheque.bankName})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${AppStrings.val(context, en: "Due Date", ur: "مقررہ تاریخ")}: ${_dateFmt.format(widget.cheque.dueDate)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    Text(
                      'Rs. ${_currencyFmt.format(widget.cheque.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: MColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Choice Radio/Cards
              Text(
                AppStrings.val(
                  context,
                  en: 'Select New Status:',
                  ur: 'نیا سٹیٹس منتخب کریں:',
                ),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              _buildStatusOption(
                status: ChequeStatus.deposited,
                title: AppStrings.val(
                  context,
                  en: 'Mark as Deposited',
                  ur: 'بینک میں جمع کر دیا',
                ),
                subtitle: AppStrings.val(
                  context,
                  en: 'Sent to bank for clearance process',
                  ur: 'کلیئرنس کے عمل کے لیے بینک جمع کروا دیا گیا',
                ),
                color: Colors.blueAccent,
                icon: Icons.upload_file_outlined,
              ),
              const SizedBox(height: 6),
              _buildStatusOption(
                status: ChequeStatus.cleared,
                title: AppStrings.val(
                  context,
                  en: 'Mark as Cleared',
                  ur: 'کلیئر ہو گیا - رقم موصول',
                ),
                subtitle: AppStrings.val(
                  context,
                  en: 'Funds successfully realized into bank account',
                  ur: 'رقم کامیابی کے ساتھ بینک اکاؤنٹ میں منتقل ہو گئی',
                ),
                color: MColors.primary,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 6),
              _buildStatusOption(
                status: ChequeStatus.bounced,
                title: AppStrings.val(
                  context,
                  en: 'Mark as Bounced / Dishonored',
                  ur: 'باؤنس ہو گیا',
                ),
                subtitle: AppStrings.val(
                  context,
                  en: 'Cheque returned unpaid with bank memo',
                  ur: 'چیک بغیر ادائیگی بینک میمو کے ساتھ واپس آ گیا',
                ),
                color: MColors.danger,
                icon: Icons.error_outline,
              ),

              const Divider(height: 24),

              // Conditional Fields based on action
              if (_selectedAction == ChequeStatus.deposited) ...[
                DropdownButtonFormField<String>(
                  initialValue: _targetBankAccountId,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(
                      context,
                      en: 'Select Bank Account Where Deposited *',
                      ur: 'بینک اکاؤنٹ منتخب کریں جہاں جمع کرایا گیا *',
                    ),
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                  items: bankAccounts.map((b) {
                    return DropdownMenuItem(
                      value: b.id,
                      child: Text(b.displayName),
                    );
                  }).toList(),
                  onChanged: (id) =>
                      setState(() => _targetBankAccountId = id),
                ),
                const SizedBox(height: 12),
              ],

              if (_selectedAction == ChequeStatus.bounced) ...[
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppStrings.val(
                      context,
                      en: 'Bounce Reason *',
                      ur: 'باؤنس ہونے کی وجہ *',
                    ),
                    prefixIcon: const Icon(Icons.warning_amber_rounded),
                  ),
                  items: bounceReasons.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (r) {
                    if (r != null) {
                      setState(() => _bounceReasonCtrl.text = r);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bounceReasonCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(
                      context,
                      en: 'Custom Reason or Memo Details',
                      ur: 'تفصیلی وجہ یا میمو تفصیلات',
                    ),
                    hintText: AppStrings.val(
                      context,
                      en: 'e.g. Return memo #482 insufficient funds',
                      ur: 'مثلاً میمو نمبر 482 فنڈز کی کمی',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _actionDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _actionDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppStrings.val(
                      context,
                      en: 'Action Date',
                      ur: 'تاریخ',
                    ),
                    prefixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(_dateFmt.format(_actionDate)),
                ),
              ),

              const SizedBox(height: 24),

              // Submit & Cancel
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(AppStrings.val(
                      context,
                      en: 'Cancel',
                      ur: 'منسوخ',
                    )),
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
                    label: Text(AppStrings.val(
                      context,
                      en: 'Apply Status',
                      ur: 'سٹیٹس لاگو کریں',
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required ChequeStatus status,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedAction == status;
    return InkWell(
      onTap: () => setState(() => _selectedAction = status),
      borderRadius: MRadius.md,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: MRadius.md,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? color : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
