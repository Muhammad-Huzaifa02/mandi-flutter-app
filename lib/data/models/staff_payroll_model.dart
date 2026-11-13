// Domain models for Munshi Staff Attendance & Payroll Ledger
// (*عملہ حاضری، اوور ٹائم اور تنخواہ کھاتہ واؤچر*).

import 'package:intl/intl.dart';

enum AttendanceStatus {
  present,
  absent,
  halfDay,
  leave;

  String toDbString() {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.halfDay:
        return 'half_day';
      case AttendanceStatus.leave:
        return 'leave';
    }
  }

  String get labelUrdu {
    switch (this) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غیر حاضر';
      case AttendanceStatus.halfDay:
        return 'نصف دن';
      case AttendanceStatus.leave:
        return 'رخصت';
    }
  }

  String get labelEnglish {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.leave:
        return 'Leave';
    }
  }

  static AttendanceStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'half_day':
      case 'halfday':
        return AttendanceStatus.halfDay;
      case 'leave':
      default:
        return AttendanceStatus.leave;
    }
  }
}

class StaffDailyAttendance {
  final String id;
  final String shopId;
  final String memberId;
  final String staffName;
  final DateTime attendanceDate;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double overtimeHours;
  final String notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StaffDailyAttendance({
    this.id = '',
    required this.shopId,
    required this.memberId,
    required this.staffName,
    required this.attendanceDate,
    this.status = AttendanceStatus.present,
    this.checkInTime,
    this.checkOutTime,
    this.overtimeHours = 0.0,
    this.notes = '',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory StaffDailyAttendance.fromMap(String id, Map<String, dynamic> data) {
    return StaffDailyAttendance(
      id: id,
      shopId: data['shop_id']?.toString() ?? '',
      memberId: data['member_id']?.toString() ?? '',
      staffName: data['staff_name']?.toString() ?? '',
      attendanceDate: data['attendance_date'] != null
          ? DateTime.tryParse(data['attendance_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: AttendanceStatus.fromString(data['status']?.toString() ?? 'present'),
      checkInTime: data['check_in_time'] != null
          ? DateTime.tryParse(data['check_in_time'].toString())
          : null,
      checkOutTime: data['check_out_time'] != null
          ? DateTime.tryParse(data['check_out_time'].toString())
          : null,
      overtimeHours: (data['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes']?.toString() ?? '',
      createdBy: data['created_by']?.toString(),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'member_id': memberId,
      'staff_name': staffName,
      'attendance_date': DateFormat('yyyy-MM-dd').format(attendanceDate),
      'status': status.toDbString(),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'overtime_hours': overtimeHours,
      'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}

enum PayrollStatus {
  draft,
  approved,
  paid;

  String toDbString() {
    switch (this) {
      case PayrollStatus.draft:
        return 'draft';
      case PayrollStatus.approved:
        return 'approved';
      case PayrollStatus.paid:
        return 'paid';
    }
  }

  String get labelUrdu {
    switch (this) {
      case PayrollStatus.draft:
        return 'کچا رجسٹر';
      case PayrollStatus.approved:
        return 'منظور شدہ';
      case PayrollStatus.paid:
        return 'ادا شدہ';
    }
  }

  String get labelEnglish {
    switch (this) {
      case PayrollStatus.draft:
        return 'Draft';
      case PayrollStatus.approved:
        return 'Approved';
      case PayrollStatus.paid:
        return 'Paid';
    }
  }

  static PayrollStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'paid':
        return PayrollStatus.paid;
      case 'approved':
        return PayrollStatus.approved;
      case 'draft':
      default:
        return PayrollStatus.draft;
    }
  }
}

class StaffPayrollVoucher {
  final String id;
  final String shopId;
  final String memberId;
  final String staffName;
  final String monthYear;
  final double baseMonthlySalary;
  final int daysPresent;
  final int daysAbsent;
  final int daysHalfDay;
  final double overtimeHours;
  final double overtimeAllowancePkr;
  final double bonusIncentivePkr;
  final double advanceSalaryDeductionPkr;
  final double absenteeDeductionPkr;
  final double netPayableSalaryPkr;
  final PayrollStatus status;
  final String paymentMethod;
  final DateTime? paidAt;
  final String voucherNumber;
  final String notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StaffPayrollVoucher({
    this.id = '',
    required this.shopId,
    required this.memberId,
    required this.staffName,
    required this.monthYear,
    required this.baseMonthlySalary,
    this.daysPresent = 0,
    this.daysAbsent = 0,
    this.daysHalfDay = 0,
    this.overtimeHours = 0.0,
    this.overtimeAllowancePkr = 0.0,
    this.bonusIncentivePkr = 0.0,
    this.advanceSalaryDeductionPkr = 0.0,
    this.absenteeDeductionPkr = 0.0,
    required this.netPayableSalaryPkr,
    this.status = PayrollStatus.draft,
    this.paymentMethod = 'cash',
    this.paidAt,
    this.voucherNumber = '',
    this.notes = '',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// Mathematical calculation engine for standard staff payroll in Pakistan Mandi.
  /// Standard month is 30 days. Daily wage = baseSalary / 30.
  /// Absentee deduction = (daysAbsent * dailyWage) + (daysHalfDay * 0.5 * dailyWage).
  /// Overtime allowance = overtimeHours * (dailyWage / 8.0) * 1.5 (unless custom specified).
  /// Net payable = baseSalary - absenteeDeduction - advanceDeduction + overtimeAllowance + bonus.
  static Map<String, double> computePayrollBreakdown({
    required double baseSalary,
    required int daysPresent,
    required int daysAbsent,
    required int daysHalfDay,
    required double overtimeHours,
    double? customOvertimeAllowance,
    double bonus = 0.0,
    double advanceDeduction = 0.0,
    int daysInMonth = 30,
  }) {
    final dailyWage = daysInMonth > 0 ? (baseSalary / daysInMonth) : 0.0;
    final hourlyRate = dailyWage > 0 ? (dailyWage / 8.0) : 0.0;

    final absenteeDeduction =
        (daysAbsent * dailyWage) + (daysHalfDay * 0.5 * dailyWage);

    final overtimeAllowance = customOvertimeAllowance ?? (overtimeHours * hourlyRate * 1.5);

    final grossPayable = baseSalary + overtimeAllowance + bonus;
    final totalDeductions = absenteeDeduction + advanceDeduction;
    final netPayable = (grossPayable - totalDeductions).clamp(0.0, double.infinity);

    return {
      'dailyWage': dailyWage,
      'absenteeDeduction': absenteeDeduction,
      'overtimeAllowance': overtimeAllowance,
      'bonus': bonus,
      'advanceDeduction': advanceDeduction,
      'grossPayable': grossPayable,
      'totalDeductions': totalDeductions,
      'netPayable': netPayable,
    };
  }

  factory StaffPayrollVoucher.fromMap(String id, Map<String, dynamic> data) {
    return StaffPayrollVoucher(
      id: id,
      shopId: data['shop_id']?.toString() ?? '',
      memberId: data['member_id']?.toString() ?? '',
      staffName: data['staff_name']?.toString() ?? '',
      monthYear: data['month_year']?.toString() ?? '',
      baseMonthlySalary: (data['base_monthly_salary'] as num?)?.toDouble() ?? 0.0,
      daysPresent: (data['days_present'] as num?)?.toInt() ?? 0,
      daysAbsent: (data['days_absent'] as num?)?.toInt() ?? 0,
      daysHalfDay: (data['days_half_day'] as num?)?.toInt() ?? 0,
      overtimeHours: (data['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      overtimeAllowancePkr: (data['overtime_allowance_pkr'] as num?)?.toDouble() ?? 0.0,
      bonusIncentivePkr: (data['bonus_incentive_pkr'] as num?)?.toDouble() ?? 0.0,
      advanceSalaryDeductionPkr: (data['advance_salary_deduction_pkr'] as num?)?.toDouble() ?? 0.0,
      absenteeDeductionPkr: (data['absentee_deduction_pkr'] as num?)?.toDouble() ?? 0.0,
      netPayableSalaryPkr: (data['net_payable_salary_pkr'] as num?)?.toDouble() ?? 0.0,
      status: PayrollStatus.fromString(data['status']?.toString() ?? 'draft'),
      paymentMethod: data['payment_method']?.toString() ?? 'cash',
      paidAt: data['paid_at'] != null
          ? DateTime.tryParse(data['paid_at'].toString())
          : null,
      voucherNumber: data['voucher_number']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      createdBy: data['created_by']?.toString(),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'member_id': memberId,
      'staff_name': staffName,
      'month_year': monthYear,
      'base_monthly_salary': baseMonthlySalary,
      'days_present': daysPresent,
      'days_absent': daysAbsent,
      'days_half_day': daysHalfDay,
      'overtime_hours': overtimeHours,
      'overtime_allowance_pkr': overtimeAllowancePkr,
      'bonus_incentive_pkr': bonusIncentivePkr,
      'advance_salary_deduction_pkr': advanceSalaryDeductionPkr,
      'absentee_deduction_pkr': absenteeDeductionPkr,
      'net_payable_salary_pkr': netPayableSalaryPkr,
      'status': status.toDbString(),
      'payment_method': paymentMethod,
      'paid_at': paidAt?.toIso8601String(),
      'voucher_number': voucherNumber,
      'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}
