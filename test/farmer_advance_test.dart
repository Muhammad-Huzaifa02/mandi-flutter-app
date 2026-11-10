import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/farmer_advance_pdf_generator.dart';
import 'package:mandi/data/models/farmer_advance_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FarmerAdvance Model Tests', () {
    test('serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime.now();
      final harvestDate = now.add(const Duration(days: 90));

      final advance = FarmerAdvance(
        id: 'adv-001',
        shopId: 'shop-xyz',
        supplierId: 'sup-123',
        farmerName: 'Chaudhry Riaz Gujjar',
        farmerPhone: '03001234567',
        advanceType: FarmerAdvanceType.fertilizer,
        description: '50 Bags Sona Urea + 20 Bags DAP',
        principalAmount: 350000.0,
        markupPercent: 3.0,
        markupAmount: 10500.0,
        totalPayable: 360500.0,
        recoveredAmount: 100000.0,
        remainingBalance: 260500.0,
        disbursementDate: now,
        expectedHarvestDate: harvestDate,
        targetCrop: 'Basmati Rice (دھان)',
        status: FarmerAdvanceStatus.partiallyRecovered,
        paymentMethod: 'cash',
        notes: 'Promised to bring 400 Maunds Paddy to Mandi',
        createdAt: now,
      );

      final map = advance.toMap();
      expect(map['shop_id'], 'shop-xyz');
      expect(map['supplier_id'], 'sup-123');
      expect(map['farmer_name'], 'Chaudhry Riaz Gujjar');
      expect(map['advance_type'], 'fertilizer');
      expect(map['description'], '50 Bags Sona Urea + 20 Bags DAP');
      expect(map['principal_amount'], 350000.0);
      expect(map['markup_percent'], 3.0);
      expect(map['markup_amount'], 10500.0);
      expect(map['total_payable'], 360500.0);
      expect(map['recovered_amount'], 100000.0);
      expect(map['remaining_balance'], 260500.0);
      expect(map['target_crop'], 'Basmati Rice (دھان)');
      expect(map['status'], 'partially_recovered');

      final parsed = FarmerAdvance.fromMap('adv-001', map);
      expect(parsed.id, 'adv-001');
      expect(parsed.farmerName, 'Chaudhry Riaz Gujjar');
      expect(parsed.advanceType, FarmerAdvanceType.fertilizer);
      expect(parsed.principalAmount, 350000.0);
      expect(parsed.markupAmount, 10500.0);
      expect(parsed.recoveredAmount, 100000.0);
      expect(parsed.remainingBalance, 260500.0);
      expect(parsed.status, FarmerAdvanceStatus.partiallyRecovered);
      expect(parsed.isOverdue, isFalse);
    });

    test('calculates computedMarkupAmount, computedTotalPayable, and remaining balance correctly', () {
      final now = DateTime.now();
      // Principal 200,000, markup 2.5% -> 5,000 markup -> 205,000 total
      // Recovered 50,000 -> remaining 155,000
      final advance = FarmerAdvance(
        id: '1',
        shopId: 's1',
        supplierId: 'sup-1',
        farmerName: 'Malik Nasir',
        principalAmount: 200000.0,
        markupPercent: 2.5,
        totalPayable: 0.0, // test auto-computed
        remainingBalance: 0.0,
        recoveredAmount: 50000.0,
        disbursementDate: now,
      );

      expect(advance.computedMarkupAmount, 5000.0);
      expect(advance.computedTotalPayable, 205000.0);
      expect(advance.computedRemainingBalance, 155000.0);
      expect(advance.recoveryRatio, closeTo(50000.0 / 205000.0, 0.001));
    });

    test('detects isOverdue accurately when harvest date has passed', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 15));
      final overdueAdvance = FarmerAdvance(
        id: '2',
        shopId: 's1',
        supplierId: 'sup-2',
        farmerName: 'Haji Asghar',
        principalAmount: 150000.0,
        totalPayable: 150000.0,
        remainingBalance: 150000.0,
        disbursementDate: pastDate.subtract(const Duration(days: 90)),
        expectedHarvestDate: pastDate, // overdue
        status: FarmerAdvanceStatus.active,
      );

      expect(overdueAdvance.isOverdue, isTrue);

      // Once fully recovered, isOverdue must be false even if harvest date passed
      final clearedAdvance = overdueAdvance.copyWith(
        recoveredAmount: 150000.0,
        remainingBalance: 0.0,
        status: FarmerAdvanceStatus.fullyRecovered,
      );
      expect(clearedAdvance.isOverdue, isFalse);
    });

    test('returns localized labels for advance types and statuses', () {
      expect(FarmerAdvanceType.cash.labelEnglish, 'Cash Advance');
      expect(FarmerAdvanceType.cash.labelUrdu, 'نقد رقم ایڈوانس');
      expect(FarmerAdvanceType.fertilizer.labelEnglish, 'Fertilizer (کھاد)');
      expect(FarmerAdvanceType.seed.labelUrdu, 'زرعی بیج');
      expect(FarmerAdvanceType.pesticide.labelUrdu, 'سپرے / زرعی ادویات');

      expect(FarmerAdvanceStatus.active.labelEnglish, 'Active (Pending)');
      expect(FarmerAdvanceStatus.active.labelUrdu, 'واپسی واجب الادا');
      expect(FarmerAdvanceStatus.fullyRecovered.labelEnglish, 'Fully Recovered');
      expect(FarmerAdvanceStatus.fullyRecovered.labelUrdu, 'مکمل بیباق (وصول)');
    });

    test('copyWith updates properties properly', () {
      final now = DateTime.now();
      final advance = FarmerAdvance(
        id: 'adv-1',
        shopId: 's1',
        supplierId: 'sup-1',
        farmerName: 'Rana Bashir',
        principalAmount: 100000.0,
        totalPayable: 100000.0,
        remainingBalance: 100000.0,
        disbursementDate: DateTime(2025, 1, 1),
      );

      final updated = advance.copyWith(
        recoveredAmount: 40000.0,
        remainingBalance: 60000.0,
        disbursementDate: now,
      );

      expect(updated.recoveredAmount, 40000.0);
      expect(updated.remainingBalance, 60000.0);
      expect(updated.farmerName, 'Rana Bashir');
    });
  });

  group('FarmerAdvanceRecovery Model Tests', () {
    test('serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime.now();
      final rec = FarmerAdvanceRecovery(
        id: 'rec-01',
        shopId: 's1',
        advanceId: 'adv-001',
        consignmentLotId: 'lot-99',
        invoiceId: 'inv-88',
        recoveredAmount: 45000.0,
        recoveryDate: now,
        recoveryMethod: 'consignment_deduction',
        notes: 'Deducted from Wheat Lot #99 auction',
      );

      final map = rec.toMap();
      expect(map['shop_id'], 's1');
      expect(map['advance_id'], 'adv-001');
      expect(map['consignment_lot_id'], 'lot-99');
      expect(map['recovered_amount'], 45000.0);
      expect(map['recovery_method'], 'consignment_deduction');

      final parsed = FarmerAdvanceRecovery.fromMap('rec-01', map);
      expect(parsed.id, 'rec-01');
      expect(parsed.advanceId, 'adv-001');
      expect(parsed.recoveredAmount, 45000.0);
      expect(parsed.recoveryMethod, 'consignment_deduction');
    });
  });

  group('FarmerAdvanceSummary Tests', () {
    test('aggregates advances metrics accurately and excludes written-off', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 10));

      final advances = [
        FarmerAdvance(
          id: '1',
          shopId: 's1',
          supplierId: 'sup-1',
          farmerName: 'Farmer A',
          principalAmount: 100000.0,
          markupAmount: 5000.0,
          totalPayable: 105000.0,
          recoveredAmount: 105000.0,
          remainingBalance: 0.0,
          disbursementDate: now,
          status: FarmerAdvanceStatus.fullyRecovered,
        ),
        FarmerAdvance(
          id: '2',
          shopId: 's1',
          supplierId: 'sup-2',
          farmerName: 'Farmer B',
          principalAmount: 200000.0,
          markupAmount: 10000.0,
          totalPayable: 210000.0,
          recoveredAmount: 60000.0,
          remainingBalance: 150000.0,
          disbursementDate: now,
          expectedHarvestDate: pastDate, // overdue!
          status: FarmerAdvanceStatus.partiallyRecovered,
        ),
        FarmerAdvance(
          id: '3',
          shopId: 's1',
          supplierId: 'sup-3',
          farmerName: 'Farmer C',
          principalAmount: 50000.0,
          markupAmount: 0.0,
          totalPayable: 50000.0,
          recoveredAmount: 0.0,
          remainingBalance: 50000.0,
          disbursementDate: now,
          status: FarmerAdvanceStatus.active,
        ),
        FarmerAdvance(
          id: '4',
          shopId: 's1',
          supplierId: 'sup-4',
          farmerName: 'Farmer D',
          principalAmount: 80000.0,
          totalPayable: 80000.0,
          remainingBalance: 80000.0,
          disbursementDate: now,
          status: FarmerAdvanceStatus.writtenOff, // should be excluded
        ),
      ];

      final summary = FarmerAdvanceSummary.fromAdvances(advances);

      // Total count (excluding writtenOff): 3
      expect(summary.totalAdvancesCount, 3);
      // Active count (partially + active): 2
      expect(summary.activeCount, 2);
      // Fully recovered: 1
      expect(summary.fullyRecoveredCount, 1);
      // Overdue: 1 (Farmer B)
      expect(summary.overdueCount, 1);

      // Principal: 100,000 + 200,000 + 50,000 = 350,000
      expect(summary.totalPrincipalDisbursed, 350000.0);
      // Markup: 5,000 + 10,000 + 0 = 15,000
      expect(summary.totalMarkupAccrued, 15000.0);
      // Total payable: 105,000 + 210,000 + 50,000 = 365,000
      expect(summary.totalPayable, 365000.0);
      // Recovered: 105,000 + 60,000 = 165,000
      expect(summary.totalRecovered, 165000.0);
      // Net Outstanding: 365,000 - 165,000 = 200,000
      expect(summary.netOutstandingBalance, 200000.0);
    });
  });

  group('FarmerAdvancePdfGenerator Tests', () {
    test('generates valid non-empty PDF bytes for Farmer Statement', () async {
      final now = DateTime.now();
      final advances = [
        FarmerAdvance(
          id: '1',
          shopId: 's1',
          supplierId: 'sup-1',
          farmerName: 'Chaudhry Akram',
          farmerPhone: '03001122334',
          advanceType: FarmerAdvanceType.cash,
          principalAmount: 150000.0,
          markupAmount: 4500.0,
          totalPayable: 154500.0,
          recoveredAmount: 50000.0,
          remainingBalance: 104500.0,
          disbursementDate: now.subtract(const Duration(days: 30)),
        ),
        FarmerAdvance(
          id: '2',
          shopId: 's1',
          supplierId: 'sup-1',
          farmerName: 'Chaudhry Akram',
          advanceType: FarmerAdvanceType.fertilizer,
          description: '25 Bags DAP',
          principalAmount: 225000.0,
          totalPayable: 225000.0,
          recoveredAmount: 0.0,
          remainingBalance: 225000.0,
          disbursementDate: now.subtract(const Duration(days: 15)),
        ),
      ];

      final recoveries = [
        FarmerAdvanceRecovery(
          id: 'rec-1',
          shopId: 's1',
          advanceId: '1',
          recoveredAmount: 50000.0,
          recoveryDate: now,
          recoveryMethod: 'consignment_deduction',
          notes: 'Deducted from Wheat Lot #44',
        ),
      ];

      final pdfBytes = await FarmerAdvancePdfGenerator.generateFarmerStatementPdf(
        shopName: 'Bismillah Commission Shop',
        farmerName: 'Chaudhry Akram',
        farmerPhone: '03001122334',
        advances: advances,
        recoveries: recoveries,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('generates valid non-empty PDF bytes for Advances Register', () async {
      final now = DateTime.now();
      final advances = [
        FarmerAdvance(
          id: '1',
          shopId: 's1',
          supplierId: 'sup-1',
          farmerName: 'Farmer One',
          principalAmount: 100000.0,
          totalPayable: 100000.0,
          remainingBalance: 50000.0,
          recoveredAmount: 50000.0,
          disbursementDate: now,
        ),
      ];
      final summary = FarmerAdvanceSummary.fromAdvances(advances);

      final pdfBytes = await FarmerAdvancePdfGenerator.generateAdvancesRegisterPdf(
        shopName: 'Bismillah Commission Shop',
        advances: advances,
        summary: summary,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
