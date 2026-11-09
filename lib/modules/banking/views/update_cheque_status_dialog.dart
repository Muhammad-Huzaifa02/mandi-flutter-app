import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  static const List<String> _commonBounceReasons = [
    'Insufficient Funds / فنڈز کی کمی',
    'Signature Mismatch / دستخط میں فرق',
    'Payment Stopped by Drawer / ادائیگی روکی گئی',
    'Account Frozen or Closed / اکاؤنٹ منجمد یا بند',
    'Post-Dated Presented Early / قبل از وقت جمع کرایا گیا',
    'Other reason / دیگر وجہ',
  ];

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
          throw Exception('Please select a Bank Account where cheque is deposited.');
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
          throw Exception('Please provide a reason for the bounced cheque.');
        }
        await bankProv.markAsBounced(
          chequeId: widget.cheque.id,
          bounceReason: reason,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cheque status updated successfully.'),
            backgroundColor: MColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: MColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankAccounts = context.watch<BankProvider>().bankAccounts;

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
                    'Update Cheque Status (سٹیٹس تبدیل کریں)',
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
                          'Cheque #${widget.cheque.chequeNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Party: ${widget.cheque.partyName} (${widget.cheque.bankName})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Due Date: ${_dateFmt.format(widget.cheque.dueDate)}',
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
                'Select New Status: ',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              _buildStatusOption(
                status: ChequeStatus.deposited,
                title: 'Mark as Deposited (بینک میں جمع کر دیا)',
                subtitle: 'Sent to bank for clearance process',
                color: Colors.blueAccent,
                icon: Icons.upload_file_outlined,
              ),
              const SizedBox(height: 6),
              _buildStatusOption(
                status: ChequeStatus.cleared,
                title: 'Mark as Cleared (کلیئر ہو گیا - رقم موصول)',
                subtitle: 'Funds successfully realized into bank account',
                color: MColors.primary,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 6),
              _buildStatusOption(
                status: ChequeStatus.bounced,
                title: 'Mark as Bounced / Dishonored (باؤنس ہو گیا)',
                subtitle: 'Cheque returned unpaid with bank memo',
                color: MColors.danger,
                icon: Icons.error_outline,
              ),

              const Divider(height: 24),

              // Conditional Fields based on action
              if (_selectedAction == ChequeStatus.deposited) ...[
                DropdownButtonFormField<String>(
                  initialValue: _targetBankAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Select Bank Account Where Deposited *',
                    prefixIcon: Icon(Icons.account_balance),
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
                  decoration: const InputDecoration(
                    labelText: 'Bounce Reason (وجہ باؤنس) *',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                  items: _commonBounceReasons.map((r) {
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
                  decoration: const InputDecoration(
                    labelText: 'Custom Reason or Memo Details',
                    hintText: 'e.g. Return memo #482 insufficient funds',
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
                  decoration: const InputDecoration(
                    labelText: 'Action Date (تاریخ)',
                    prefixIcon: Icon(Icons.calendar_today, size: 18),
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
                    label: const Text('Apply Status'),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

