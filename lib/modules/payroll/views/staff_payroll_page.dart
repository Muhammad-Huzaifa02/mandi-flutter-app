import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/staff_payroll_pdf_generator.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/data/models/staff_payroll_model.dart';
import 'package:mandi/modules/payroll/providers/staff_payroll_provider.dart';
import 'package:mandi/modules/payroll/views/mark_daily_attendance_dialog.dart';
import 'package:mandi/modules/payroll/views/new_payroll_voucher_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Central Hub for Munshi Staff Biometric/Manual Attendance & Monthly Payroll Ledger
/// (*عملہ حاضری، اوور ٹائم اور تنخواہ کھاتہ واؤچر*).
class StaffPayrollPage extends StatefulWidget {
  const StaffPayrollPage({super.key});

  @override
  State<StaffPayrollPage> createState() => _StaffPayrollPageState();
}

class _StaffPayrollPageState extends State<StaffPayrollPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<StaffPayrollProvider>();
      prov.loadStaffRoster();
      prov.loadDailyAttendance();
      prov.loadMonthlyPayroll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openMarkAttendanceDialog([ShopMember? member]) {
    showDialog(
      context: context,
      builder: (_) => MarkDailyAttendanceDialog(preselectedMember: member),
    );
  }

  void _openNewPayrollVoucherDialog([ShopMember? member]) {
    showDialog(
      context: context,
      builder: (_) => NewPayrollVoucherDialog(preselectedMember: member),
    );
  }

  void _printPaySlip(StaffPayrollVoucher voucher, String shopName,
      String? address, String? phone) {
    StaffPayrollPdfGenerator.printPaySlip(
      voucher: voucher,
      shopName: shopName,
      shopAddress: address,
      shopPhone: phone,
    );
  }

  void _printMonthlyRegister(List<StaffPayrollVoucher> vouchers, String shopName,
      String monthYear, String? address, String? phone) {
    if (vouchers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payroll vouchers to print for this month.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    StaffPayrollPdfGenerator.printDisbursementRegister(
      vouchers: vouchers,
      shopName: shopName,
      monthYear: monthYear,
      shopAddress: address,
      shopPhone: phone,
    );
  }

  Future<void> _disburseCashModal(StaffPayrollVoucher voucher) async {
    final methodCtrl = TextEditingController(text: 'cash');
    final voucherNumCtrl = TextEditingController(
        text: voucher.voucherNumber.isNotEmpty
            ? voucher.voucherNumber
            : 'VOUCH-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.payments, color: Colors.green),
            const SizedBox(width: 8),
            Text('Disburse Salary: ${voucher.staffName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Payable Amount: PKR ${_currencyFmt.format(voucher.netPayableSalaryPkr)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text('Payment Method / ادائیگی کا ذریعہ:'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: methodCtrl.text,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash (نقد کیش)')),
                DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('Bank Transfer (بینک آن لائن)')),
                DropdownMenuItem(
                    value: 'cheque', child: Text('Cheque (بینک چیک)')),
              ],
              onChanged: (val) {
                if (val != null) methodCtrl.text = val;
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Text('Voucher / Reference # :'),
            const SizedBox(height: 4),
            TextField(
              controller: voucherNumCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Text('Notes / کیش رسید نمبر:'),
            const SizedBox(height: 4),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                  hintText: 'e.g. Paid in full by Munshi',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Disbursement (ادائیگی درج کریں)'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await context.read<StaffPayrollProvider>().disburseAndMarkPaid(
                voucherId: voucher.id,
                paymentMethod: methodCtrl.text,
                voucherNumber: voucherNumCtrl.text,
                notes: notesCtrl.text,
              );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Salary disbursed and marked paid!'
                : 'Failed to record payment.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payrollProv = context.watch<StaffPayrollProvider>();
    final shopContext = context.watch<ShopContextProvider>();
    final activeShop = shopContext.currentShop;
    final shopName = activeShop?.name ?? 'Mandi Commission Shop';
    final shopAddress = activeShop?.address ?? '';
    final shopPhone = activeShop?.phone ?? '';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Attendance & Payroll (عملہ حاضری و تنخواہ)'),
        backgroundColor: MColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.how_to_reg),
              text: 'Daily Attendance (حاضری)',
            ),
            Tab(
              icon: Icon(Icons.account_balance_wallet),
              text: 'Monthly Payroll (تنخواہ کھاتہ)',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              payrollProv.loadStaffRoster();
              payrollProv.loadDailyAttendance();
              payrollProv.loadMonthlyPayroll();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Daily Attendance
            _buildAttendanceTab(payrollProv),

            // TAB 2: Monthly Payroll
            _buildPayrollTab(payrollProv, shopName, shopAddress, shopPhone),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: DAILY ATTENDANCE
  // =========================================================================

  Widget _buildAttendanceTab(StaffPayrollProvider prov) {
    final staff = prov.staffMembers;
    final selectedDate = prov.selectedAttendanceDate;

    return Column(
      children: [
        // Top Toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Date Display & Picker
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: MColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: MColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy')
                                  .format(selectedDate),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: MColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            prov.setSelectedAttendanceDate(picked);
                          }
                        },
                        child: const Text('Select Date'),
                      ),
                    ],
                  ),

                  // Quick Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final ok = await prov.markAllPresent();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'All active staff marked Present!'
                                    : 'Failed to mark all present.'),
                                backgroundColor:
                                    ok ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Mark All Present (تمام حاضر)'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _openMarkAttendanceDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Mark Attendance (اندراج)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Attendance Stats Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  label: 'Total Staff',
                  value: '${staff.length}',
                  icon: Icons.people_outline,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  label: 'Present (حاضر)',
                  value: '${prov.presentCount}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  label: 'Absent (چھٹی)',
                  value: '${prov.absentCount}',
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  label: 'Half Day / Leave',
                  value: '${prov.halfDayCount + prov.leaveCount}',
                  icon: Icons.hourglass_bottom,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),

        // Staff List
        Expanded(
          child: prov.isLoadingAttendance
              ? const Center(child: CircularProgressIndicator())
              : staff.isEmpty
                  ? const Center(
                      child: Text('No active staff members found in this shop.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: staff.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final member = staff[idx];
                        final att = prov.getAttendanceForMember(member.id);
                        return _buildStaffAttendanceTile(member, att);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStaffAttendanceTile(
      ShopMember member, StaffDailyAttendance? att) {
    final status = att?.status ?? AttendanceStatus.leave;
    final isMarked = att != null;

    final statusColor = status == AttendanceStatus.present
        ? Colors.green
        : status == AttendanceStatus.absent
            ? Colors.red
            : status == AttendanceStatus.halfDay
                ? Colors.orange
                : Colors.grey;

    return GlassCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: MColors.primary.withValues(alpha: 0.15),
          foregroundColor: MColors.primary,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : 'S',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                member.roleId.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                isMarked ? 'Status: ' : 'Attendance not marked yet',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              if (isMarked) ...[
                Text(
                  status.labelUrdu,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (att.overtimeHours > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    'OT: ${att.overtimeHours.toStringAsFixed(1)} hrs',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade800),
                  ),
                ],
              ],
            ],
          ),
        ),
        trailing: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          onPressed: () => _openMarkAttendanceDialog(member),
          icon: Icon(isMarked ? Icons.edit : Icons.check, size: 16),
          label: Text(isMarked ? 'Edit' : 'Mark'),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2: MONTHLY PAYROLL
  // =========================================================================

  Widget _buildPayrollTab(StaffPayrollProvider prov, String shopName,
      String? address, String? phone) {
    final vouchers = prov.monthlyPayroll;
    final selectedMonth = prov.selectedPayrollMonth;

    return Column(
      children: [
        // Top Toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Month Selector
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: MColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month,
                                size: 16, color: MColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              selectedMonth,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: MColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                        tooltip: 'Select Month',
                        onSelected: (month) =>
                            prov.setSelectedPayrollMonth(month),
                        itemBuilder: (ctx) {
                          final now = DateTime.now();
                          return List.generate(6, (i) {
                            final d = DateTime(now.year, now.month - i, 1);
                            final label = DateFormat('MMMM yyyy').format(d);
                            return PopupMenuItem(
                                value: label, child: Text(label));
                          });
                        },
                      ),
                    ],
                  ),

                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onPressed: () => _printMonthlyRegister(
                          vouchers,
                          shopName,
                          selectedMonth,
                          address,
                          phone,
                        ),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Print Register (رجسٹر پرنٹ)'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _openNewPayrollVoucherDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Generate Voucher (نیا واؤچر)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Payroll Budget Metrics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  label: 'Base Salary (بنیادی)',
                  value: 'Rs. ${_currencyFmt.format(prov.totalBaseSalaryBudget)}',
                  icon: Icons.account_balance,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  label: 'OT & Bonus (اضافی)',
                  value: '+ Rs. ${_currencyFmt.format(prov.totalOvertimePayout + prov.totalBonusPayout)}',
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  label: 'Deductions (کٹوتیاں)',
                  value: '- Rs. ${_currencyFmt.format(prov.totalDeductions)}',
                  icon: Icons.arrow_downward,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  label: 'Net Payable (خالص)',
                  value: 'Rs. ${_currencyFmt.format(prov.totalNetPayable)}',
                  icon: Icons.payments,
                  color: MColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Vouchers List
        Expanded(
          child: prov.isLoadingPayroll
              ? const Center(child: CircularProgressIndicator())
              : vouchers.isEmpty
                  ? _buildEmptyPayrollView()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: vouchers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final v = vouchers[idx];
                        return _buildPayrollVoucherCard(
                            v, shopName, address, phone);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPayrollVoucherCard(StaffPayrollVoucher voucher, String shopName,
      String? address, String? phone) {
    final status = voucher.status;
    final statusColor = status == PayrollStatus.paid
        ? Colors.green
        : status == PayrollStatus.approved
            ? Colors.blue
            : Colors.orange;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Staff Name, Voucher Number & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person,
                          color: MColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.staffName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: MColors.textPrimary,
                          ),
                        ),
                        Text(
                          voucher.voucherNumber.isNotEmpty
                              ? voucher.voucherNumber
                              : 'Draft Voucher',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status.labelEnglish.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Middle Grid: Base Salary, Attendance, Deductions, Net Wage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Base Salary',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      'Rs. ${_currencyFmt.format(voucher.baseMonthlySalary)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Days (P / A / H)',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      '${voucher.daysPresent} / ${voucher.daysAbsent} / ${voucher.daysHalfDay}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deductions',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      '- Rs. ${_currencyFmt.format(voucher.absenteeDeductionPkr + voucher.advanceSalaryDeductionPkr)}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Net Disbursable',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      'Rs. ${_currencyFmt.format(voucher.netPayableSalaryPkr)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: MColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.print_outlined, size: 20),
                  tooltip: 'Print Salary Slip A4',
                  onPressed: () =>
                      _printPaySlip(voucher, shopName, address, phone),
                ),
                if (voucher.status == PayrollStatus.draft) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => context
                        .read<StaffPayrollProvider>()
                        .approveVoucher(voucher.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                  ),
                ],
                if (voucher.status != PayrollStatus.paid) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _disburseCashModal(voucher),
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('Disburse Cash (ادائیگی)'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPayrollView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No Payroll Vouchers for this Month',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Click "+ Generate Voucher" to compute monthly wages and allowances.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _openNewPayrollVoucherDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Generate First Salary Voucher'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
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
