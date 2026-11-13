import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/data/models/staff_payroll_model.dart';
import 'package:mandi/modules/payroll/providers/staff_payroll_provider.dart';

/// Modal dialog to record or update daily staff biometric / manual attendance.
class MarkDailyAttendanceDialog extends StatefulWidget {
  final ShopMember? preselectedMember;

  const MarkDailyAttendanceDialog({super.key, this.preselectedMember});

  @override
  State<MarkDailyAttendanceDialog> createState() =>
      _MarkDailyAttendanceDialogState();
}

class _MarkDailyAttendanceDialogState extends State<MarkDailyAttendanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _overtimeCtrl = TextEditingController(text: '0.0');
  final _notesCtrl = TextEditingController();

  ShopMember? _selectedMember;
  AttendanceStatus _status = AttendanceStatus.present;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.preselectedMember;
    if (_selectedMember != null) {
      final existing = context
          .read<StaffPayrollProvider>()
          .getAttendanceForMember(_selectedMember!.id);
      if (existing != null) {
        _status = existing.status;
        _overtimeCtrl.text = existing.overtimeHours.toString();
        _notesCtrl.text = existing.notes;
      }
    }
  }

  @override
  void dispose() {
    _overtimeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffPayrollProvider>();
    final staffList = provider.staffMembers;
    final selectedDate = provider.selectedAttendanceDate;
    final isUrdu = AppStrings.isUrdu(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                      child: const Icon(Icons.how_to_reg, color: MColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Mark Attendance',
                              ur: 'حاضری اندراج',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${AppStrings.val(context, en: "Date:", ur: "تاریخ:")} ${DateFormat('dd MMMM yyyy').format(selectedDate)}',
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

                // Select Staff Member
                Text(
                  AppStrings.val(
                    context,
                    en: 'Staff Member *',
                    ur: 'ملازم *',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                        final existing =
                            provider.getAttendanceForMember(val.id);
                        if (existing != null) {
                          _status = existing.status;
                          _overtimeCtrl.text =
                              existing.overtimeHours.toString();
                          _notesCtrl.text = existing.notes;
                        }
                      });
                    }
                  },
                  validator: (val) => val == null
                      ? AppStrings.val(
                          context,
                          en: 'Please select a staff member',
                          ur: 'براہ کرم ملازم منتخب کریں',
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Attendance Status Options
                Text(
                  AppStrings.val(
                    context,
                    en: 'Attendance Status *',
                    ur: 'کیفیت حاضری *',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AttendanceStatus.values.map((s) {
                    final isSelected = _status == s;
                    final color = s == AttendanceStatus.present
                        ? Colors.green
                        : s == AttendanceStatus.absent
                            ? Colors.red
                            : s == AttendanceStatus.halfDay
                                ? Colors.orange
                                : Colors.blueGrey;

                    return ChoiceChip(
                      label: Text(isUrdu ? s.labelUrdu : s.labelEnglish),
                      selected: isSelected,
                      selectedColor: color.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: isSelected ? color : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color : Colors.black87,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _status = s);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Overtime Hours
                Text(
                  AppStrings.val(
                    context,
                    en: 'Overtime Hours',
                    ur: 'اضافی گھنٹے',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _overtimeCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: AppStrings.val(
                      context,
                      en: 'e.g. 2.0 Hours',
                      ur: 'مثلاً 2.0 گھنٹے',
                    ),
                    suffixText: AppStrings.val(
                      context,
                      en: 'Hours',
                      ur: 'گھنٹے',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                Text(
                  AppStrings.val(
                    context,
                    en: 'Remarks',
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
                      en: 'e.g. Night auction unloading duty',
                      ur: 'مثلاً رات کی بولی میں لوڈنگ ڈیوٹی',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
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
                      onPressed: _isSaving ? null : _saveAttendance,
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
                        en: 'Save Attendance',
                        ur: 'حاضری محفوظ کریں',
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

  Future<void> _saveAttendance() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null) return;

    final isUrdu = AppStrings.isUrdu(context);
    setState(() => _isSaving = true);

    final overtime = double.tryParse(_overtimeCtrl.text.trim()) ?? 0.0;
    final provider = context.read<StaffPayrollProvider>();

    final success = await provider.markStaffAttendance(
      memberId: _selectedMember!.id,
      staffName: _selectedMember!.name,
      status: _status,
      overtimeHours: overtime,
      notes: _notesCtrl.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUrdu
                ? 'عملے کی حاضری کامیابی سے درج کر لی گئی!'
                : 'Staff attendance marked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUrdu
                ? 'حاضری درج کرنے میں ناکامی۔ دوبارہ کوشش کریں۔'
                : 'Failed to mark attendance. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
