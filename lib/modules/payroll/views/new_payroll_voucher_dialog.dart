import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/data/models/staff_payroll_model.dart';
import 'package:mandi/modules/payroll/providers/staff_payroll_provider.dart';

/// Modal dialog to compute and generate monthly salary disbursement vouchers
/// (*ماہانہ تنخواہ واؤچر تیاری و حساب کتاب*).
class NewPayrollVoucherDialog extends StatefulWidget {
  final ShopMember? preselectedMember;

  const NewPayrollVoucherDialog({super.key, this.preselectedMember});

  @override
  State<NewPayrollVoucherDialog> createState() =>
      _NewPayrollVoucherDialogState();
}

class _NewPayrollVoucherDialogState extends State<NewPayrollVoucherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  final _baseSalaryCtrl = TextEditingController(text: '30000');
  final _daysPresentCtrl = TextEditingController(text: '28');
  final _daysAbsentCtrl = TextEditingController(text: '1');
  final _daysHalfDayCtrl = TextEditingController(text: '1');
  final _overtimeHoursCtrl = TextEditingController(text: '0.0');
  final _bonusCtrl = TextEditingController(text: '0');
  final _advanceDeductionCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  ShopMember? _selectedMember;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.preselectedMember;
    if (_selectedMember != null && _selectedMember!.salary != null) {
      _baseSalaryCtrl.text = _selectedMember!.salary!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _baseSalaryCtrl.dispose();
    _daysPresentCtrl.dispose();
    _daysAbsentCtrl.dispose();
    _daysHalfDayCtrl.dispose();
    _overtimeHoursCtrl.dispose();
    _bonusCtrl.dispose();
    _advanceDeductionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _baseSalary => double.tryParse(_baseSalaryCtrl.text.trim()) ?? 0.0;
  int get _daysPresent => int.tryParse(_daysPresentCtrl.text.trim()) ?? 0;
  int get _daysAbsent => int.tryParse(_daysAbsentCtrl.text.trim()) ?? 0;
  int get _daysHalfDay => int.tryParse(_daysHalfDayCtrl.text.trim()) ?? 0;
  double get _overtimeHours =>
      double.tryParse(_overtimeHoursCtrl.text.trim()) ?? 0.0;
  double get _bonus => double.tryParse(_bonusCtrl.text.trim()) ?? 0.0;
  double get _advanceDeduction =>
      double.tryParse(_advanceDeductionCtrl.text.trim()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffPayrollProvider>();
    final staffList = provider.staffMembers;
    final selectedMonth = provider.selectedPayrollMonth;

    final breakdown = StaffPayrollVoucher.computePayrollBreakdown(
      baseSalary: _baseSalary,
      daysPresent: _daysPresent,
      daysAbsent: _daysAbsent,
      daysHalfDay: _daysHalfDay,
      overtimeHours: _overtimeHours,
      bonus: _bonus,
      advanceDeduction: _advanceDeduction,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
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
                        color: MColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long, color: MColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Generate Salary Voucher (تنخواہ واؤچر)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pay Period: $selectedMonth',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
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
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Select Staff & Base Salary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Staff Member / ملازم *',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<ShopMember>(
                            initialValue: _selectedMember ??
                                (staffList.isNotEmpty ? staffList.first : null),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            items: staffList.map((m) {
                              return DropdownMenuItem<ShopMember>(
                                value: m,
                                child: Text('${m.name} (${m.roleId})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedMember = val;
                                  if (val.salary != null && val.salary! > 0) {
                                    _baseSalaryCtrl.text =
                                        val.salary!.toStringAsFixed(0);
                                  }
                                });
                              }
                            },
                            validator: (val) =>
                                val == null ? 'Select staff' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Base Salary (بنیادی) *',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _baseSalaryCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Attendance Days Inputs (Present, Absent, Half Day)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Present (حاضر)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _daysPresentCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: 'Days',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Absent (چھٹی)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _daysAbsentCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: 'Days',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Half-Days (نصف)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _daysHalfDayCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: 'Days',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Overtime Hours & Bonus
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overtime (اوور ٹائم)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _overtimeHoursCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              suffixText: 'Hrs',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bonus / انعام (PKR)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _bonusCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Advance Ded (پیشگی)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _advanceDeductionCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Real-time Wage Computation Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildCalcRow(
                        'Daily Wage Rate (یومیہ اجرت):',
                        'Rs. ${_currencyFmt.format(breakdown["dailyWage"])} / day',
                      ),
                      _buildCalcRow(
                        'Overtime Allowance (+ الاؤنس):',
                        '+ Rs. ${_currencyFmt.format(breakdown["overtimeAllowance"])}',
                        color: Colors.green.shade800,
                      ),
                      _buildCalcRow(
                        'Absenteeism Deduction (- کٹوتی):',
                        '- Rs. ${_currencyFmt.format(breakdown["absenteeDeduction"])}',
                        color: Colors.red.shade800,
                      ),
                      _buildCalcRow(
                        'Advance Recovery (- پیشگی):',
                        '- Rs. ${_currencyFmt.format(breakdown["advanceDeduction"])}',
                        color: Colors.red.shade800,
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Net Payable Wage (خالص تنخواہ):',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: MColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Rs. ${_currencyFmt.format(breakdown["netPayable"])}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: MColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Remarks
                const Text(
                  'Notes / تفصیل',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Monthly salary voucher approved by Munshi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _saveVoucher,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Save Voucher (محفوظ کریں)'),
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

  Widget _buildCalcRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.blueGrey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null) return;

    setState(() => _isSaving = true);

    final provider = context.read<StaffPayrollProvider>();
    final success = await provider.createPayrollVoucher(
      memberId: _selectedMember!.id,
      staffName: _selectedMember!.name,
      baseMonthlySalary: _baseSalary,
      daysPresent: _daysPresent,
      daysAbsent: _daysAbsent,
      daysHalfDay: _daysHalfDay,
      overtimeHours: _overtimeHours,
      bonusIncentivePkr: _bonus,
      advanceSalaryDeductionPkr: _advanceDeduction,
      notes: _notesCtrl.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salary voucher generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate salary voucher.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
