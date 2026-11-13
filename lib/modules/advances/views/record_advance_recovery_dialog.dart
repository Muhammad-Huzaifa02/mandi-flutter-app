import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/farmer_advance_model.dart';
import 'package:mandi/modules/advances/providers/farmer_advance_provider.dart';

/// Modal dialog to record a loan recovery deduction against a farmer advance.
class RecordAdvanceRecoveryDialog extends StatefulWidget {
  final FarmerAdvance advance;

  const RecordAdvanceRecoveryDialog({super.key, required this.advance});

  @override
  State<RecordAdvanceRecoveryDialog> createState() =>
      _RecordAdvanceRecoveryDialogState();
}

class _RecordAdvanceRecoveryDialogState
    extends State<RecordAdvanceRecoveryDialog> {
  final _formKey = GlobalKey<FormState>();

  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _recoveryMethod = 'consignment_deduction';
  bool _isSaving = false;

  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    // Default to full remaining balance
    _amountCtrl.text =
        widget.advance.computedRemainingBalance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setPreset(double ratio) {
    final amt = widget.advance.computedRemainingBalance * ratio;
    _amountCtrl.text = amt.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _saveRecovery() async {
    if (!_formKey.currentState!.validate()) return;

    final recoveryAmt = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (recoveryAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a recovery amount > 0 Rs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (recoveryAmt > widget.advance.computedRemainingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recovery amount (Rs. ${_currencyFmt.format(recoveryAmt)}) cannot exceed remaining balance (Rs. ${_currencyFmt.format(widget.advance.computedRemainingBalance)})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prov = context.read<FarmerAdvanceProvider>();
      await prov.recordRecovery(
        advanceId: widget.advance.id,
        recoveryAmount: recoveryAmt,
        recoveryMethod: _recoveryMethod,
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recovery deduction recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record recovery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remBalance = widget.advance.computedRemainingBalance;
    final enteredAmt = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final newBalance = (remBalance - enteredAmt).clamp(0.0, double.infinity);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: MRadius.sm,
                          ),
                          child: const Icon(
                            Icons.price_check,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.val(
                                context,
                                en: 'Record Advance Recovery',
                                ur: 'قرض کٹوتی اندراج',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${AppStrings.val(context, en: "Farmer", ur: "زمیندار")}: ${widget.advance.farmerName} (${AppStrings.val(context, en: widget.advance.advanceType.labelEnglish, ur: widget.advance.advanceType.labelUrdu)})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),

                // ── Body ──────────────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Advance Summary Reference Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: MRadius.md,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.val(
                                      context,
                                      en: 'Total Loan (Principal + Markup):',
                                      ur: 'کل قرضہ (اصل + منافع):',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${_currencyFmt.format(widget.advance.computedTotalPayable)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.val(
                                      context,
                                      en: 'Already Recovered:',
                                      ur: 'وصول شدہ رقم:',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${_currencyFmt.format(widget.advance.recoveredAmount)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.val(
                                      context,
                                      en: 'Remaining Balance:',
                                      ur: 'بقایا قرضہ:',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${_currencyFmt.format(remBalance)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Quick Presets
                        Row(
                          children: [
                            Text(
                              AppStrings.val(
                                context,
                                en: 'Quick Presets:',
                                ur: 'تیز انتخاب:',
                              ),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            _buildPresetChip(
                              AppStrings.val(context, en: 'Full (100%)', ur: 'مکمل (100%)'),
                              () => _setPreset(1.0),
                            ),
                            const SizedBox(width: 6),
                            _buildPresetChip(
                              '50%',
                              () => _setPreset(0.5),
                            ),
                            const SizedBox(width: 6),
                            _buildPresetChip(
                              '25%',
                              () => _setPreset(0.25),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Recovery Amount Input
                        TextFormField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          decoration: InputDecoration(
                            labelText: AppStrings.val(
                              context,
                              en: 'Recovery Amount (Rs.) *',
                              ur: 'وصولی رقم روپے *',
                            ),
                            prefixText: 'Rs. ',
                            border: OutlineInputBorder(
                              borderRadius: MRadius.sm,
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return AppStrings.val(context, en: 'Amount required', ur: 'رقم لازمی ہے');
                            }
                            final num = double.tryParse(val.trim());
                            if (num == null || num <= 0) {
                              return AppStrings.val(context, en: 'Must be > 0', ur: '0 سے زیادہ ہو');
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Recovery Method
                        DropdownButtonFormField<String>(
                          initialValue: _recoveryMethod,
                          decoration: InputDecoration(
                            labelText: AppStrings.val(
                              context,
                              en: 'Recovery Method',
                              ur: 'طریقہ کٹوتی',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: MRadius.sm,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'consignment_deduction',
                              child: Text(
                                AppStrings.val(
                                  context,
                                  en: 'Auction Consignment Deduction',
                                  ur: 'ڈھیری نیلامی کٹوتی',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'cash_payment',
                              child: Text(
                                AppStrings.val(
                                  context,
                                  en: 'Direct Cash Payment',
                                  ur: 'براہ راست نقد ادائیگی',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'bank_transfer',
                              child: Text(
                                AppStrings.val(
                                  context,
                                  en: 'Bank Transfer',
                                  ur: 'بینک ٹرانسفر',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _recoveryMethod = val);
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        // Balance Preview after Deduction
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MColors.primary.withValues(alpha: 0.06),
                            borderRadius: MRadius.md,
                            border: Border.all(
                              color: MColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.val(
                                  context,
                                  en: 'New Remaining Loan Balance:',
                                  ur: 'نیا بقایا قرضہ بیلنس:',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                newBalance <= 0
                                    ? AppStrings.val(
                                        context,
                                        en: 'Fully Cleared!',
                                        ur: 'مکمل بیباق!',
                                      )
                                    : 'Rs. ${_currencyFmt.format(newBalance)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: newBalance <= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Notes
                        TextFormField(
                          controller: _notesCtrl,
                          decoration: InputDecoration(
                            labelText: AppStrings.val(
                              context,
                              en: 'Notes / Reference',
                              ur: 'تفصیل و حوالہ نمبر',
                            ),
                            hintText: AppStrings.val(
                              context,
                              en: 'e.g. Deducted from Wheat Lot #DH-402',
                              ur: 'مثلاً گندم ڈھیری سے کٹوتی #DH-402',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: MRadius.sm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),

                // ── Actions ───────────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveRecovery,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSaving
                            ? AppStrings.val(context, en: 'Saving...', ur: 'محفوظ ہو رہا ہے...')
                            : AppStrings.val(context, en: 'Record Recovery', ur: 'کٹوتی درج کریں'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: MRadius.sm,
                        ),
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

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
