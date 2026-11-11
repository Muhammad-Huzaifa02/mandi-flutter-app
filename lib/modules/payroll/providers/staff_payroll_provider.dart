import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/data/models/staff_payroll_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Central provider managing Staff Attendance, Overtime Tracking,
/// and Monthly Payroll Ledgers (*عملہ حاضری اور تنخواہ کھاتہ*).
class StaffPayrollProvider extends ChangeNotifier {
  String? _currentShopId;

  List<ShopMember> _staffMembers = [];
  List<StaffDailyAttendance> _dailyAttendance = [];
  List<StaffPayrollVoucher> _monthlyPayroll = [];

  bool _isLoadingStaff = false;
  bool _isLoadingAttendance = false;
  bool _isLoadingPayroll = false;

  DateTime _selectedAttendanceDate = DateTime.now();
  String _selectedPayrollMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  StreamSubscription? _attendanceSub;
  StreamSubscription? _payrollSub;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<ShopMember> get staffMembers => _staffMembers;
  List<StaffDailyAttendance> get dailyAttendance => _dailyAttendance;
  List<StaffPayrollVoucher> get monthlyPayroll => _monthlyPayroll;

  bool get isLoading =>
      _isLoadingStaff || _isLoadingAttendance || _isLoadingPayroll;
  bool get isLoadingAttendance => _isLoadingAttendance;
  bool get isLoadingPayroll => _isLoadingPayroll;

  DateTime get selectedAttendanceDate => _selectedAttendanceDate;
  String get selectedPayrollMonth => _selectedPayrollMonth;

  // Attendance metrics for the selected date
  int get presentCount => _dailyAttendance
      .where((a) => a.status == AttendanceStatus.present)
      .length;
  int get absentCount => _dailyAttendance
      .where((a) => a.status == AttendanceStatus.absent)
      .length;
  int get halfDayCount => _dailyAttendance
      .where((a) => a.status == AttendanceStatus.halfDay)
      .length;
  int get leaveCount => _dailyAttendance
      .where((a) => a.status == AttendanceStatus.leave)
      .length;

  // Payroll metrics for the selected month
  double get totalBaseSalaryBudget => _monthlyPayroll.fold(
      0.0, (sum, v) => sum + v.baseMonthlySalary);
  double get totalOvertimePayout => _monthlyPayroll.fold(
      0.0, (sum, v) => sum + v.overtimeAllowancePkr);
  double get totalBonusPayout => _monthlyPayroll.fold(
      0.0, (sum, v) => sum + v.bonusIncentivePkr);
  double get totalDeductions => _monthlyPayroll.fold(
      0.0,
      (sum, v) =>
          sum + v.absenteeDeductionPkr + v.advanceSalaryDeductionPkr);
  double get totalNetPayable => _monthlyPayroll.fold(
      0.0, (sum, v) => sum + v.netPayableSalaryPkr);
  double get totalPaidDisbursed => _monthlyPayroll
      .where((v) => v.status == PayrollStatus.paid)
      .fold(0.0, (sum, v) => sum + v.netPayableSalaryPkr);

  int get draftVouchersCount =>
      _monthlyPayroll.where((v) => v.status == PayrollStatus.draft).length;
  int get approvedVouchersCount =>
      _monthlyPayroll.where((v) => v.status == PayrollStatus.approved).length;
  int get paidVouchersCount =>
      _monthlyPayroll.where((v) => v.status == PayrollStatus.paid).length;

  // ── Shop Life-cycle ──────────────────────────────────────────────────────

  void updateShop(String? shopId) {
    if (_currentShopId != shopId) {
      _currentShopId = shopId;
      _cancelSubscriptions();
      if (shopId != null && shopId.isNotEmpty) {
        loadStaffRoster();
        loadDailyAttendance();
        loadMonthlyPayroll();
        _subscribeToStreams(shopId);
      } else {
        _staffMembers = [];
        _dailyAttendance = [];
        _monthlyPayroll = [];
        notifyListeners();
      }
    }
  }

  void _subscribeToStreams(String shopId) {
    _cancelSubscriptions();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedAttendanceDate);
    _attendanceSub =
        SupabaseService.staffAttendanceStream(shopId, dateStr).listen(
      (rows) {
        _dailyAttendance = rows
            .map((r) => StaffDailyAttendance.fromMap(
                r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) =>
          debugPrint('[StaffPayrollProvider] Attendance Stream error: $err'),
    );

    _payrollSub =
        SupabaseService.staffPayrollStream(shopId, _selectedPayrollMonth)
            .listen(
      (rows) {
        _monthlyPayroll = rows
            .map((r) =>
                StaffPayrollVoucher.fromMap(r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) =>
          debugPrint('[StaffPayrollProvider] Payroll Stream error: $err'),
    );
  }

  void _cancelSubscriptions() {
    _attendanceSub?.cancel();
    _attendanceSub = null;
    _payrollSub?.cancel();
    _payrollSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  // ── Staff Roster ─────────────────────────────────────────────────────────

  Future<void> loadStaffRoster() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoadingStaff = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.shopMembersForShop(shopId);
      _staffMembers = rows
          .map((r) => ShopMember.fromMap(r['id']?.toString() ?? '', r))
          .where((m) => m.isActive)
          .toList();
    } catch (e) {
      debugPrint('[StaffPayrollProvider] Error loading staff: $e');
    } finally {
      _isLoadingStaff = false;
      notifyListeners();
    }
  }

  // ── Daily Attendance ──────────────────────────────────────────────────────

  void setSelectedAttendanceDate(DateTime d) {
    _selectedAttendanceDate = d;
    final shopId = _currentShopId;
    if (shopId != null && shopId.isNotEmpty) {
      _subscribeToStreams(shopId);
      loadDailyAttendance();
    }
    notifyListeners();
  }

  Future<void> loadDailyAttendance() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoadingAttendance = true;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedAttendanceDate);
      final rows = await SupabaseService.getStaffAttendance(shopId, dateStr);
      _dailyAttendance = rows
          .map((r) => StaffDailyAttendance.fromMap(
              r['id']?.toString() ?? '', r))
          .toList();
    } catch (e) {
      debugPrint('[StaffPayrollProvider] Error loading attendance: $e');
    } finally {
      _isLoadingAttendance = false;
      notifyListeners();
    }
  }

  StaffDailyAttendance? getAttendanceForMember(String memberId) {
    try {
      return _dailyAttendance.firstWhere((a) => a.memberId == memberId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> markStaffAttendance({
    required String memberId,
    required String staffName,
    required AttendanceStatus status,
    double overtimeHours = 0.0,
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedAttendanceDate);
    final now = DateTime.now();

    final data = {
      'shop_id': shopId,
      'member_id': memberId,
      'staff_name': staffName,
      'attendance_date': dateStr,
      'status': status.toDbString(),
      'overtime_hours': overtimeHours,
      'notes': notes,
      'check_in_time':
          status == AttendanceStatus.present || status == AttendanceStatus.halfDay
              ? now.toIso8601String()
              : null,
    };

    try {
      await SupabaseService.upsertStaffAttendance(data);
      await loadDailyAttendance();
      return true;
    } catch (e) {
      debugPrint('[StaffPayrollProvider] Error marking attendance: $e');
      return false;
    }
  }

  Future<bool> markAllPresent() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty || _staffMembers.isEmpty) return false;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedAttendanceDate);
    final now = DateTime.now();

    try {
      for (final m in _staffMembers) {
        final data = {
          'shop_id': shopId,
          'member_id': m.id,
          'staff_name': m.name,
          'attendance_date': dateStr,
          'status': AttendanceStatus.present.toDbString(),
          'overtime_hours': 0.0,
          'check_in_time': now.toIso8601String(),
          'notes': 'Marked Present via 1-Tap All-Present',
        };
        await SupabaseService.upsertStaffAttendance(data);
      }
      await loadDailyAttendance();
      return true;
    } catch (e) {
      debugPrint('[StaffPayrollProvider] Error marking all present: $e');
      return false;
    }
  }

  // ── Monthly Payroll ───────────────────────────────────────────────────────

  void setSelectedPayrollMonth(String m) {
    _selectedPayrollMonth = m;
    final shopId = _currentShopId;
    if (shopId != null && shopId.isNotEmpty) {
      _subscribeToStreams(shopId);
      loadMonthlyPayroll();
    }
    notifyListeners();
  }

  Future<void> loadMonthlyPayroll() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoadingPayroll = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.getStaffPayroll(
          shopId, _selectedPayrollMonth);
      _monthlyPayroll = rows
          .map((r) =>
              StaffPayrollVoucher.fromMap(r['id']?.toString() ?? '', r))
          .toList();
    } catch (e) {
      debugPrint('[StaffPayrollProvider] Error loading payroll: $e');
    } finally {
      _isLoadingPayroll = false;
      notifyListeners();
    }
  }

  Future<bool> createPayrollVoucher({
    required String memberId,
    required String staffName,
    required double baseMonthlySalary,
    required int daysPresent,
    required int daysAbsent,
    required int daysHalfDay,
    required double overtimeHours,
    double? customOvertimeAllowance,
    double bonusIncentivePkr = 0.0,
    double advanceSalaryDeductionPkr = 0.0,
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    final breakdown = StaffPayrollVoucher.computePayrollBreakdown(
      baseSalary: baseMonthlySalary,
      daysPresent: daysPresent,
      daysAbsent: daysAbsent,
      daysHalfDay: daysHalfDay,
      overtimeHours: overtimeHours,
      customOvertimeAllowance: customOvertimeAllowance,
      bonus: bonusIncentivePkr,
      advanceDeduction: advanceSalaryDeductionPkr,
    );

    final randomSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
    final voucherNum =
        'PAY-${DateFormat("yyMM").format(DateTime.now())}-$randomSuffix';

    final data = {
      'shop_id': shopId,
      'member_id': memberId,
      'staff_name': staffName,
      'month_year': _selectedPayrollMonth,
      'base_monthly_salary': baseMonthlySalary,
      'days_present': daysPresent,
      'days_absent': daysAbsent,
      'days_half_day': daysHalfDay,
      'overtime_hours': overtimeHours,
      'overtime_allowance_pkr': breakdown['overtimeAllowance'],
      'bonus_incentive_pkr': bonusIncentivePkr,
      'advance_salary_deduction_pkr': advanceSalaryDeductionPkr,
      'absentee_deduction_pkr': breakdown['absenteeDeduction'],
      'net_payable_salary_pkr': breakdown['netPayable'],
      'status': PayrollStatus.draft.toDbString(),
      'payment_method': 'cash',
      'voucher_number': voucherNum,
      'notes': notes,
    };

    try {
      await SupabaseService.createStaffPayroll(data);
      await loadMonthlyPayroll();
      return true;
    } catch (e) {
      debugPrint('[StaffPayrollProvider] Error creating payroll voucher: $e');
      return false;
    }
  }

  Future<bool> approveVoucher(String voucherId) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      await SupabaseService.updateStaffPayrollStatus(
        payrollId: voucherId,
        shopId: shopId,
        status: PayrollStatus.approved.toDbString(),
      );
      await loadMonthlyPayroll();
      return true;
    } catch (e) {
      debugPrint('[StaffPayrollProvider] Error approving voucher: $e');
      return false;
    }
  }

  Future<bool> disburseAndMarkPaid({
    required String voucherId,
    required String paymentMethod,
    required String voucherNumber,
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      await SupabaseService.updateStaffPayrollStatus(
        payrollId: voucherId,
        shopId: shopId,
        status: PayrollStatus.paid.toDbString(),
        paymentMethod: paymentMethod,
        voucherNumber: voucherNumber,
        notes: notes,
      );
      await loadMonthlyPayroll();
      return true;
    } catch (e) {
      debugPrint('[StaffPayrollProvider] Error marking voucher paid: $e');
      return false;
    }
  }
}
