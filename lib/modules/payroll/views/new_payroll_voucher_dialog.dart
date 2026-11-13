import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/data/models/staff_payroll_model.dart';
import 'package:mandi/modules/payroll/providers/staff_payroll_provider.dart';

/// Modal dialog to compute and generate monthly salary disbursement vouchers.
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Generate Salary Voucher',
                              ur: 'تنخواہ واؤچر بنائیں',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${AppStrings.val(context, en: "Pay Period:", ur: "مدت ادائیگی:")} $selectedMonth',
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Staff Member *',
                              ur: 'ملازم *',
                            ),
                            style: const TextStyle(
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
                            validator: (val) => val == null
                                ? AppStrings.val(
                                    context,
                                    en: 'Select staff',
                                    ur: 'ملازم منتخب کریں',
                                  )
                                : null,
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Base Salary *',
                              ur: 'بنیادی تنخواہ *',
                            ),
                            style: const TextStyle(
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
                            validator: (v) => v == null || v.isEmpty
                                ? AppStrings.val(
                                    context,
                                    en: 'Required',
                                    ur: 'ضروری ہے',
                                  )
                                : null,
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Present',
                              ur: 'حاضر',
                            ),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _daysPresentCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: AppStrings.val(
                                context,
                                en: 'Days',
                                ur: 'دن',
                              ),
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Absent',
                              ur: 'چھٹی',
                            ),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _daysAbsentCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: AppStrings.val(
                                context,
                                en: 'Days',
                                ur: 'دن',
                              ),
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Half-Days',
                              ur: 'نصف دن',
                            ),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _daysHalfDayCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixText: AppStrings.val(
                                context,
                                en: 'Days',
                                ur: 'دن',
                              ),
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Overtime',
                              ur: 'اوور ٹائم',
                            ),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _overtimeHoursCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              suffixText: AppStrings.val(
                                context,
                                en: 'Hrs',
                                ur: 'گھنٹے',
                              ),
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Bonus (PKR)',
                              ur: 'انعام (روپے)',
                            ),
                            style: const TextStyle(
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Advance Ded',
                              ur: 'پیشگی کٹوتی',
                            ),
                            style: const TextStyle(
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
                        AppStrings.val(
                          context,
                          en: 'Daily Wage Rate:',
                          ur: 'یومیہ اجرت:',
                        ),
                        'Rs. ${_currencyFmt.format(breakdown["dailyWage"])} ${AppStrings.val(context, en: "/ day", ur: "/ یوم")}',
                      ),
                      _buildCalcRow(
                        AppStrings.val(
                          context,
                          en: 'Overtime Allowance (+):',
                          ur: 'اوور ٹائم الاؤنس (+):',
                        ),
                        '+ Rs. ${_currencyFmt.format(breakdown["overtimeAllowance"])}',
                        color: Colors.green.shade800,
                      ),
                      _buildCalcRow(
                        AppStrings.val(
                          context,
                          en: 'Absenteeism Deduction (-):',
                          ur: 'غیر حاضری کٹوتی (-):',
                        ),
                        '- Rs. ${_currencyFmt.format(breakdown["absenteeDeduction"])}',
                        color: Colors.red.shade800,
                      ),
                      _buildCalcRow(
                        AppStrings.val(
                          context,
                          en: 'Advance Recovery (-):',
                          ur: 'پیشگی وصولی (-):',
                        ),
                        '- Rs. ${_currencyFmt.format(breakdown["advanceDeduction"])}',
                        color: Colors.red.shade800,
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Net Payable Wage:',
                              ur: 'خالص واجب الادا تنخواہ:',
                            ),
                            style: const TextStyle(
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
                Text(
                  AppStrings.val(
                    context,
                    en: 'Notes',
                    ur: 'تفصیل',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    hintText: AppStrings.val(
                      context,
                      en: 'e.g. Monthly salary voucher approved by Munshi',
                      ur: 'مثلاً ماہانہ تنخواہ واؤچر منشی سے منظور شدہ',
                    ),
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
                      child: Text(AppStrings.val(
                        context,
                        en: 'Cancel',
                        ur: 'منسوخ',
                      )),
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
                      label: Text(AppStrings.val(
                        context,
                        en: 'Save Voucher',
                        ur: 'واؤچر محفوظ کریں',
                      )),
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

    final isUrdu = AppStrings.isUrdu(context);
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
          SnackBar(
            content: Text(isUrdu
                ? 'تنخواہ واؤچر کامیابی سے تیار ہو گیا!'
                : 'Salary voucher generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUrdu
                ? 'تنخواہ واؤچر تیار کرنے میں ناکامی۔'
                : 'Failed to generate salary voucher.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
