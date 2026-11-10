import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/data/models/multi_shop_transfer_model.dart';
import 'package:mandi/core/utils/consolidated_balance_sheet_pdf_generator.dart';

void main() {
  group('InterShopTransfer & Maund Economics Math Tests', () {
    test('Calculates total delivered cost and effective cost per Maund accurately', () {
      final transfer = InterShopTransfer(
        id: 'trf-101',
        transferNumber: 'TRF-2026-00101',
        sourceShopId: 'shop-lahore',
        sourceShopName: 'Lahore Mandi Branch',
        destinationShopId: 'shop-multan',
        destinationShopName: 'Multan Mandi Branch',
        commodityName: 'Kinnu (پیٹی کنو)',
        quantityKg: 6000.0, // 6,000 KG
        quantityMaunds: 150.0, // 6000 / 40 = 150 Maunds
        packageType: 'Crate',
        packageCount: 300,
        unitCostPkr: 3200.0, // Rs. 3,200 per Maund
        totalValuePkr: 480000.0, // 150 * 3,200 = Rs. 480,000
        transitFreightPkr: 20000.0, // Rs. 20,000 Freight
        vehicleNumber: 'FD-7840',
        driverName: 'Ghulam Rasool',
        driverPhone: '03001234567',
        dispatchedAt: DateTime(2026, 11, 11, 10, 0),
        status: StockTransferStatus.inTransit,
      );

      // Total delivered cost = 480,000 (stock value) + 20,000 (freight) = 500,000 PKR
      expect(transfer.totalDeliveredCostPkr, 500000.0);

      // Effective cost per Maund = 500,000 / 150 = Rs. 3,333.33 / Maund
      expect(transfer.effectiveCostPerMaundPkr, closeTo(3333.33, 0.01));

      // Landed cost per KG = 500,000 / 6000 = Rs. 83.33 / KG
      expect(transfer.landedCostPerKgPkr, closeTo(83.33, 0.01));
    });

    test('Serialization toMap and fromMap roundtrip preserves data integrity', () {
      final now = DateTime.now();
      final original = InterShopTransfer(
        id: 'trf-202',
        transferNumber: 'TRF-2026-00202',
        sourceShopId: 'shop-fsd',
        sourceShopName: 'Faisalabad Branch',
        destinationShopId: 'shop-sargodha',
        destinationShopName: 'Sargodha Branch',
        commodityName: 'Wheat (گندم)',
        quantityKg: 4000.0,
        quantityMaunds: 100.0,
        packageType: 'Bori',
        packageCount: 100,
        unitCostPkr: 4200.0,
        totalValuePkr: 420000.0,
        transitFreightPkr: 15000.0,
        vehicleNumber: 'LHR-9988',
        driverName: 'Muhammad Aslam',
        driverPhone: '03219876543',
        dispatchedAt: now,
        status: StockTransferStatus.received,
        notes: 'Premium grain lot',
      );

      final map = original.toMap();
      expect(map['transfer_number'], 'TRF-2026-00202');
      expect(map['status'], 'received');
      expect(map['total_value_pkr'], 420000.0);

      final reconstructed = InterShopTransfer.fromMap(
        'trf-202',
        map,
        sourceName: 'Faisalabad Branch',
        destinationName: 'Sargodha Branch',
      );

      expect(reconstructed.id, original.id);
      expect(reconstructed.transferNumber, original.transferNumber);
      expect(reconstructed.sourceShopId, original.sourceShopId);
      expect(reconstructed.sourceShopName, 'Faisalabad Branch');
      expect(reconstructed.destinationShopId, original.destinationShopId);
      expect(reconstructed.quantityMaunds, 100.0);
      expect(reconstructed.status, StockTransferStatus.received);
      expect(reconstructed.notes, 'Premium grain lot');
    });

    test('StockTransferStatus enum labels match Urdu and English specifications', () {
      expect(StockTransferStatus.inTransit.labelUrdu, 'راستہ میں / روانہ شدہ');
      expect(StockTransferStatus.inTransit.labelEnglish, 'In Transit');
      expect(StockTransferStatus.received.labelUrdu, 'موصول شدہ');
      expect(StockTransferStatus.received.labelEnglish, 'Received');
      expect(StockTransferStatus.cancelled.labelUrdu, 'منسوخ شدہ');
      expect(StockTransferStatus.cancelled.labelEnglish, 'Cancelled');
    });
  });

  group('Multi-Branch Consolidated Balance Sheet Aggregation Tests', () {
    test('Calculates individual branch profit, net equity, and enterprise totals', () {
      const branchLahore = ShopBranchFinancialMetrics(
        shopId: 'shop-lhr',
        shopName: 'Lahore Badami Bagh',
        city: 'Lahore',
        totalSalesPkr: 5000000.0,
        totalCommissionPkr: 250000.0,
        totalExpensesPkr: 70000.0,
        totalReceivablesPkr: 1200000.0,
        totalPayablesPkr: 800000.0,
        liquidCashPkr: 400000.0,
        stockValuePkr: 900000.0,
      );

      const branchMultan = ShopBranchFinancialMetrics(
        shopId: 'shop-mux',
        shopName: 'Multan Ghalla Mandi',
        city: 'Multan',
        totalSalesPkr: 3500000.0,
        totalCommissionPkr: 175000.0,
        totalExpensesPkr: 45000.0,
        totalReceivablesPkr: 850000.0,
        totalPayablesPkr: 600000.0,
        liquidCashPkr: 250000.0,
        stockValuePkr: 500000.0,
      );

      // Lahore Branch checks
      // Net Profit = 250,000 - 70,000 = Rs. 180,000
      expect(branchLahore.netProfitPkr, 180000.0);
      expect(branchLahore.netOperatingProfitPkr, 180000.0);
      // Net Equity = (400,000 cash + 1,200,000 rec + 900,000 stock) - 800,000 pay = Rs. 1,700,000
      expect(branchLahore.netBranchEquityPkr, 1700000.0);

      // Multan Branch checks
      // Net Profit = 175,000 - 45,000 = Rs. 130,000
      expect(branchMultan.netProfitPkr, 130000.0);
      // Net Equity = (250,000 + 850,000 + 500,000) - 600,000 = Rs. 1,000,000
      expect(branchMultan.netBranchEquityPkr, 1000000.0);

      // Consolidated Balance Sheet checks
      final sheet = ConsolidatedBalanceSheet(
        branches: [branchLahore, branchMultan],
        asOfDate: DateTime(2026, 11, 11),
      );

      expect(sheet.totalBranchesCount, 2);
      expect(sheet.totalEnterpriseSalesPkr, 8500000.0);
      expect(sheet.totalEnterpriseCommissionPkr, 425000.0);
      expect(sheet.totalEnterpriseExpensesPkr, 115000.0);
      expect(sheet.totalEnterpriseOperatingProfitPkr, 310000.0); // 180,000 + 130,000
      expect(sheet.totalEnterpriseReceivablesPkr, 2050000.0); // 1.2M + 850K
      expect(sheet.totalEnterprisePayablesPkr, 1400000.0); // 800K + 600K
      expect(sheet.totalEnterpriseStockValuePkr, 1400000.0); // 900K + 500K
      expect(sheet.aggregateLiquidCashPkr, 650000.0); // 400K + 250K

      // Enterprise Net Equity = (650,000 + 2,050,000 + 1,400,000) - 1,400,000 = Rs. 2,700,000
      expect(sheet.totalNetEnterpriseEquityPkr, 2700000.0);
      expect(sheet.aggregateEnterpriseEquityPkr, 2700000.0);
    });
  });

  group('Consolidated Balance Sheet & Gate Pass PDF Generation Tests', () {
    test('generateConsolidatedPdf produces valid non-empty PDF bytes', () async {
      final sheet = ConsolidatedBalanceSheet(
        branches: [
          const ShopBranchFinancialMetrics(
            shopId: 'b-1',
            shopName: 'Branch 1 - Lahore',
            city: 'Lahore',
            totalSalesPkr: 1000000,
            totalCommissionPkr: 50000,
            totalExpensesPkr: 15000,
            totalReceivablesPkr: 200000,
            totalPayablesPkr: 150000,
            liquidCashPkr: 50000,
            stockValuePkr: 100000,
          ),
          const ShopBranchFinancialMetrics(
            shopId: 'b-2',
            shopName: 'Branch 2 - Multan',
            city: 'Multan',
            totalSalesPkr: 800000,
            totalCommissionPkr: 40000,
            totalExpensesPkr: 12000,
            totalReceivablesPkr: 180000,
            totalPayablesPkr: 120000,
            liquidCashPkr: 40000,
            stockValuePkr: 80000,
          ),
        ],
        asOfDate: DateTime(2026, 11, 11),
      );

      final pdfBytes =
          await ConsolidatedBalanceSheetPdfGenerator.generateConsolidatedPdf(
        sheet: sheet,
        groupTitle: 'Haji Aslam & Sons Commission Group',
        contactPhone: '0300-1234567',
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(1000));
      // PDF header check "%PDF-"
      expect(pdfBytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
    });

    test('generateTransferGatePassPdf produces valid non-empty PDF bytes', () async {
      final transfer = InterShopTransfer(
        id: 'trf-505',
        transferNumber: 'TRF-2026-00505',
        sourceShopId: 'shop-fsd',
        sourceShopName: 'Faisalabad Mandi',
        destinationShopId: 'shop-sargodha',
        destinationShopName: 'Sargodha Mandi',
        commodityName: 'Potato',
        quantityKg: 8000.0,
        quantityMaunds: 200.0,
        packageType: 'Bori',
        packageCount: 160,
        unitCostPkr: 2500.0,
        totalValuePkr: 500000.0,
        transitFreightPkr: 25000.0,
        vehicleNumber: 'MN-4422',
        driverName: 'Rafiq Ahmed',
        driverPhone: '0312-3456789',
        dispatchedAt: DateTime(2026, 11, 11, 8, 30),
        status: StockTransferStatus.inTransit,
      );

      final pdfBytes =
          await ConsolidatedBalanceSheetPdfGenerator.generateTransferGatePassPdf(
        transfer: transfer,
        sendingShopName: 'Faisalabad Mandi Branch',
        receivingShopName: 'Sargodha Mandi Branch',
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
    });
  });
}
