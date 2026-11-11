import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/mandi_rate_board_pdf_generator.dart';
import 'package:mandi/core/utils/staff_payroll_pdf_generator.dart';
import 'package:mandi/data/models/mandi_rate_model.dart';
import 'package:mandi/data/models/staff_payroll_model.dart';
import 'package:mandi/modules/rates/providers/mandi_rate_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mandi Price Intelligence & Rate Board Tests', () {
    test('MandiCommodityRate pricePerKg and trend metrics compute correctly', () {
      // 1. Price per KG: 4400 / 40.0 = 110.0
      final rate = MandiCommodityRate(
        id: 'rate-1',
        shopId: 'shop-1',
        commodityName: 'Wheat (گندم)',
        variety: 'Desi Special',
        rateDate: DateTime(2026, 11, 10),
        minRatePerMaund: 4300.0,
        maxRatePerMaund: 4500.0,
        modalRatePerMaund: 4400.0,
        previousModalRate: 4200.0,
        arrivalsMaunds: 850.0,
        qualityGrade: 'Grade A',
        createdAt: DateTime(2026, 11, 10, 8, 30),
      );

      expect(rate.pricePerKgPkr, equals(110.0));

      // 2. Trend Metrics: 4400 vs 4200 -> +200 PKR (+4.76% change), Bullish
      final bullishMetrics =
          MandiCommodityRate.computeTrendMetrics(4400.0, 4200.0);
      expect(bullishMetrics['trend'], equals(MarketTrend.bullish));
      expect(bullishMetrics['changePkr'], equals(200.0));
      expect((bullishMetrics['changePercent'] as double).toStringAsFixed(2),
          equals('4.76'));

      // 3. Bearish Trend: 3800 vs 4000 -> -200 PKR (-5.0% change)
      final bearishMetrics =
          MandiCommodityRate.computeTrendMetrics(3800.0, 4000.0);
      expect(bearishMetrics['trend'], equals(MarketTrend.bearish));
      expect(bearishMetrics['changePkr'], equals(-200.0));
      expect(bearishMetrics['changePercent'], equals(-5.0));

      // 4. Stable Trend: 4000 vs 4000
      final stableMetrics =
          MandiCommodityRate.computeTrendMetrics(4000.0, 4000.0);
      expect(stableMetrics['trend'], equals(MarketTrend.stable));
      expect(stableMetrics['changePkr'], equals(0.0));
      expect(stableMetrics['changePercent'], equals(0.0));

      // 5. Zero previous rate
      final zeroPrevMetrics =
          MandiCommodityRate.computeTrendMetrics(4000.0, 0.0);
      expect(zeroPrevMetrics['trend'], equals(MarketTrend.stable));
    });

    test('MandiCommodityRate serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 11, 10, 9, 0);
      final original = MandiCommodityRate(
        id: 'rate-123',
        shopId: 'shop-abc',
        commodityName: 'Basmati Super Kernel',
        variety: '1121 Kainat',
        rateDate: DateTime(2026, 11, 10),
        minRatePerMaund: 11000.0,
        maxRatePerMaund: 12000.0,
        modalRatePerMaund: 11500.0,
        previousModalRate: 11200.0,
        priceChangePkr: 300.0,
        priceChangePercent: 2.68,
        marketTrend: MarketTrend.bullish,
        arrivalsMaunds: 1500.0,
        qualityGrade: 'Grade A Super',
        notes: 'High demand from exporters',
        createdAt: now,
      );

      final map = original.toMap();
      expect(map['commodity_name'], equals('Basmati Super Kernel'));
      expect(map['modal_rate_per_maund'], equals(11500.0));
      expect(map['market_trend'], equals('bullish'));

      final restored = MandiCommodityRate.fromMap('rate-123', map);
      expect(restored.commodityName, equals(original.commodityName));
      expect(restored.modalRatePerMaund, equals(original.modalRatePerMaund));
      expect(restored.marketTrend, equals(MarketTrend.bullish));
      expect(restored.pricePerKgPkr, equals(11500.0 / 40.0));
    });

    test('MandiRateBoardPdfGenerator builds non-empty PDF bytes', () async {
      final rates = [
        MandiCommodityRate(
          id: 'r-1',
          shopId: 's-1',
          commodityName: 'Wheat (گندم)',
          variety: 'Desi 2026',
          rateDate: DateTime(2026, 11, 10),
          minRatePerMaund: 4200.0,
          maxRatePerMaund: 4400.0,
          modalRatePerMaund: 4350.0,
          previousModalRate: 4300.0,
          priceChangePkr: 50.0,
          priceChangePercent: 1.16,
          marketTrend: MarketTrend.bullish,
          arrivalsMaunds: 1200.0,
          qualityGrade: 'Grade A',
          createdAt: DateTime.now(),
        ),
        MandiCommodityRate(
          id: 'r-2',
          shopId: 's-1',
          commodityName: 'Cotton (پھٹی)',
          variety: 'Silver Seed',
          rateDate: DateTime(2026, 11, 10),
          minRatePerMaund: 8000.0,
          maxRatePerMaund: 8600.0,
          modalRatePerMaund: 8400.0,
          previousModalRate: 8500.0,
          priceChangePkr: -100.0,
          priceChangePercent: -1.18,
          marketTrend: MarketTrend.bearish,
          arrivalsMaunds: 400.0,
          qualityGrade: 'Grade B',
          createdAt: DateTime.now(),
        ),
      ];

      final pdfBytes = await MandiRateBoardPdfGenerator.generateRateBoardPdf(
        rates: rates,
        shopName: 'Chaudhry Commission Shop & Grain Traders',
        shopAddress: 'Shop # 45, Grain Market, Okara',
        shopPhone: '0300-1234567',
        date: DateTime(2026, 11, 10),
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('MandiRateProvider broadcast text message contains key info', () {
      final provider = MandiRateProvider();
      final msg = provider.generateBroadcastMessage(
        shopName: 'Kisan Dost Commission Shop',
        city: 'Vehari',
        date: DateTime(2026, 11, 10),
      );

      expect(msg.contains('KISAN DOST COMMISSION SHOP'), isTrue);
      expect(msg.contains('Vehari'), isTrue);
      expect(msg.contains('روزانہ منڈی ریٹ بورڈ'), isTrue);
    });
  });

  group('Munshi Staff Attendance & Payroll Ledger Tests', () {
    test('StaffDailyAttendance status and serialization roundtrip', () {
      final now = DateTime(2026, 11, 10, 8, 15);
      final att = StaffDailyAttendance(
        id: 'att-1',
        shopId: 'shop-1',
        memberId: 'member-10',
        staffName: 'Muhammad Aslam (Munshi)',
        attendanceDate: DateTime(2026, 11, 10),
        status: AttendanceStatus.present,
        checkInTime: now,
        overtimeHours: 2.5,
        notes: 'Grain weighing duty',
        createdAt: now,
      );

      final map = att.toMap();
      expect(map['status'], equals('present'));
      expect(map['overtime_hours'], equals(2.5));
      expect(map['staff_name'], equals('Muhammad Aslam (Munshi)'));

      final restored = StaffDailyAttendance.fromMap('att-1', map);
      expect(restored.status, equals(AttendanceStatus.present));
      expect(restored.overtimeHours, equals(2.5));
      expect(restored.staffName, equals('Muhammad Aslam (Munshi)'));

      // Status conversions
      expect(AttendanceStatus.fromString('absent'), equals(AttendanceStatus.absent));
      expect(AttendanceStatus.fromString('half_day'), equals(AttendanceStatus.halfDay));
      expect(AttendanceStatus.fromString('leave'), equals(AttendanceStatus.leave));
    });

    test('StaffPayrollVoucher mathematical wage computation engine', () {
      // Base salary: PKR 30,000 for 30 days
      // Daily wage = 30,000 / 30 = PKR 1,000 / day
      // Hourly rate = 1,000 / 8 = PKR 125 / hour
      // Absent: 2 days -> 2 * 1,000 = 2,000
      // Half-day: 1 day -> 1 * 0.5 * 1,000 = 500
      // Total Absentee deduction = 2,500
      // Overtime: 10 hours @ 1.5x -> 10 * 125 * 1.5 = PKR 1,875
      // Bonus: PKR 2,000
      // Advance deduction: PKR 5,000
      // Gross: 30,000 + 1,875 + 2,000 = 33,875
      // Deductions: 2,500 + 5,000 = 7,500
      // Net Payable: 33,875 - 7,500 = PKR 26,375

      final breakdown = StaffPayrollVoucher.computePayrollBreakdown(
        baseSalary: 30000.0,
        daysPresent: 27,
        daysAbsent: 2,
        daysHalfDay: 1,
        overtimeHours: 10.0,
        bonus: 2000.0,
        advanceDeduction: 5000.0,
        daysInMonth: 30,
      );

      expect(breakdown['dailyWage'], equals(1000.0));
      expect(breakdown['absenteeDeduction'], equals(2500.0));
      expect(breakdown['overtimeAllowance'], equals(1875.0));
      expect(breakdown['grossPayable'], equals(33875.0));
      expect(breakdown['totalDeductions'], equals(7500.0));
      expect(breakdown['netPayable'], equals(26375.0));
    });

    test('StaffPayrollVoucher serialization and status roundtrip', () {
      final now = DateTime(2026, 11, 10, 18, 0);
      final voucher = StaffPayrollVoucher(
        id: 'vouch-99',
        shopId: 'shop-1',
        memberId: 'mem-5',
        staffName: 'Rashid Munshi',
        monthYear: 'November 2026',
        baseMonthlySalary: 35000.0,
        daysPresent: 28,
        daysAbsent: 1,
        daysHalfDay: 1,
        overtimeHours: 8.0,
        overtimeAllowancePkr: 1750.0,
        bonusIncentivePkr: 1500.0,
        advanceSalaryDeductionPkr: 3000.0,
        absenteeDeductionPkr: 1750.0,
        netPayableSalaryPkr: 33500.0,
        status: PayrollStatus.approved,
        voucherNumber: 'PAY-2611-1234',
        createdAt: now,
      );

      final map = voucher.toMap();
      expect(map['status'], equals('approved'));
      expect(map['net_payable_salary_pkr'], equals(33500.0));

      final restored = StaffPayrollVoucher.fromMap('vouch-99', map);
      expect(restored.status, equals(PayrollStatus.approved));
      expect(restored.voucherNumber, equals('PAY-2611-1234'));
      expect(restored.netPayableSalaryPkr, equals(33500.0));
    });

    test('StaffPayrollPdfGenerator generates Pay Slip and Disbursement Register PDFs', () async {
      final voucher = StaffPayrollVoucher(
        id: 'v-10',
        shopId: 'shop-1',
        memberId: 'mem-1',
        staffName: 'Haji Ghulam Rasool',
        monthYear: 'November 2026',
        baseMonthlySalary: 40000.0,
        daysPresent: 29,
        daysAbsent: 1,
        daysHalfDay: 0,
        overtimeHours: 12.0,
        overtimeAllowancePkr: 3000.0,
        bonusIncentivePkr: 2500.0,
        advanceSalaryDeductionPkr: 5000.0,
        absenteeDeductionPkr: 1333.33,
        netPayableSalaryPkr: 39166.67,
        status: PayrollStatus.paid,
        paidAt: DateTime(2026, 11, 10),
        voucherNumber: 'PAY-2611-5432',
        notes: 'Monthly salary paid via Cash',
        createdAt: DateTime.now(),
      );

      // 1. Individual Pay Slip PDF
      final paySlipBytes = await StaffPayrollPdfGenerator.generatePaySlipPdf(
        voucher: voucher,
        shopName: 'Al-Madina Grain & Commission Traders',
        shopAddress: 'New Ghalla Mandi, Sahiwal',
        shopPhone: '0301-9876543',
      );
      expect(paySlipBytes, isNotNull);
      expect(paySlipBytes.length, greaterThan(1000));

      // 2. Monthly Disbursement Register PDF
      final registerBytes = await StaffPayrollPdfGenerator.generateDisbursementRegisterPdf(
        vouchers: [voucher],
        shopName: 'Al-Madina Grain & Commission Traders',
        monthYear: 'November 2026',
      );
      expect(registerBytes, isNotNull);
      expect(registerBytes.length, greaterThan(1000));
    });
  });
}
