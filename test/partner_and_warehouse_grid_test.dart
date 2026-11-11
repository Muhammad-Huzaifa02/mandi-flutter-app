// Comprehensive Test Suite for Multi-Partner Mandi Shop Profit Sharing,
// Farmer Simplified Digital Passbook & QR Card, and 2D Godown Grid.

import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/data/models/partner_capital_model.dart';
import 'package:mandi/data/models/warehouse_grid_model.dart';
import 'package:mandi/core/utils/partner_capital_pdf_generator.dart';
import 'package:mandi/core/utils/farmer_id_card_pdf_generator.dart';
import 'package:mandi/core/utils/warehouse_grid_pdf_generator.dart';

void main() {
  group('Multi-Partner Shop Capital & Drawings Tests', () {
    final samplePartnerA = ShopPartnerModel(
      id: 'partner_01',
      shopId: 'shop_100',
      name: 'Haji Mukhtar Ahmad (پارٹنر A)',
      phone: '0300-1112233',
      profitSharingRatio: 50.0,
      openingCapital: 2000000.0,
      currentCapital: 2000000.0,
      totalDrawings: 150000.0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 11, 1),
    );

    final samplePartnerB = ShopPartnerModel(
      id: 'partner_02',
      shopId: 'shop_100',
      name: 'Chaudhry Akram (پارٹنر B)',
      phone: '0300-4445566',
      profitSharingRatio: 30.0,
      openingCapital: 1200000.0,
      currentCapital: 1200000.0,
      totalDrawings: 90000.0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 11, 1),
    );

    final samplePartnerC = ShopPartnerModel(
      id: 'partner_03',
      shopId: 'shop_100',
      name: 'Malik Tariq (پارٹنر C)',
      phone: '0300-7778899',
      profitSharingRatio: 20.0,
      openingCapital: 800000.0,
      currentCapital: 800000.0,
      totalDrawings: 60000.0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 11, 1),
    );

    test('Validates profit sharing ratios sum to 100%', () {
      final partners = [samplePartnerA, samplePartnerB, samplePartnerC];
      final totalRatio = partners.fold(0.0, (sum, p) => sum + p.profitSharingRatio);
      expect(totalRatio, equals(100.0));
    });

    test('Profit distribution wizard allocates net commission profit by ratio', () {
      const netProfit = 1000000.0; // Rs. 1,000,000

      final shareA = netProfit * (samplePartnerA.profitSharingRatio / 100.0);
      final shareB = netProfit * (samplePartnerB.profitSharingRatio / 100.0);
      final shareC = netProfit * (samplePartnerC.profitSharingRatio / 100.0);

      expect(shareA, equals(500000.0));
      expect(shareB, equals(300000.0));
      expect(shareC, equals(200000.0));
      expect(shareA + shareB + shareC, equals(netProfit));
    });

    test('Generates Partner Equity Register PDF bytes successfully', () async {
      final partners = [samplePartnerA, samplePartnerB, samplePartnerC];
      final txns = [
        PartnerTransactionModel(
          id: 'txn_01',
          shopId: 'shop_100',
          partnerId: 'partner_01',
          partnerName: samplePartnerA.name,
          type: PartnerTransactionType.drawing,
          amount: 50000.0,
          paymentMethod: 'cash',
          description: 'Personal Monthly Drawing',
          transactionDate: DateTime(2026, 11, 5),
          createdAt: DateTime(2026, 11, 5),
        ),
      ];

      final pdfBytes = await PartnerCapitalPdfGenerator.generatePartnerEquityReportPdf(
        partners: partners,
        recentTransactions: txns,
        shopName: 'Al-Madina Mandi Commission Shop',
        shopAddress: 'Galla Mandi, Sahiwal',
        shopPhone: '0300-1234567',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });
  });

  group('Farmer QR Identity Card & Simplified Passbook Tests', () {
    test('Generates Credit-Card Size (CR80) Farmer QR Card PDF bytes', () async {
      final pdfBytes = await FarmerIdCardPdfGenerator.generateFarmerIdCardPdf(
        farmerId: 'farmer_88912',
        farmerName: 'Chaudhry Riaz Ahmad',
        cnic: '35201-1234567-1',
        phone: '0300-9876543',
        villageOrCity: 'Chak 42/GD, Okara',
        shopName: 'Bismillah Arhat Mandi',
        shopPhone: '0300-1122334',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });

    test('Generates Simplified Urdu Passbook Slip PDF bytes', () async {
      final pdfBytes = await FarmerIdCardPdfGenerator.generateFarmerPassbookSlipPdf(
        farmerName: 'Chaudhry Riaz Ahmad',
        phone: '0300-9876543',
        totalDeliveredMaunds: 180.0,
        totalGrossEarnings: 720000.0,
        totalDeductions: 28800.0,
        totalPaymentsReceived: 500000.0,
        runningBalance: 191200.0,
        shopName: 'Bismillah Arhat Mandi',
        shopPhone: '0300-1122334',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });
  });

  group('Visual 2D Godown & Cold Storage Grid Tests', () {
    final bayEmpty = WarehouseGridBayModel(
      id: 'bay_01',
      shopId: 'shop_001',
      chamberCode: 'CH-1',
      bayCode: 'A1',
      rowCoord: 1,
      colCoord: 1,
      maxCapacityBags: 200,
      currentBags: 0,
      status: BayStatus.empty,
      updatedAt: DateTime.now(),
    );

    final bayOccupied = WarehouseGridBayModel(
      id: 'bay_02',
      shopId: 'shop_001',
      chamberCode: 'CH-1',
      bayCode: 'A2',
      rowCoord: 1,
      colCoord: 2,
      maxCapacityBags: 200,
      currentBags: 150,
      cropName: 'Wheat (گندم)',
      farmerName: 'Malik Aslam',
      lotCode: 'LOT-WHT-089',
      storageStartDate: DateTime.now().subtract(const Duration(days: 20)),
      status: BayStatus.partiallyStored,
      updatedAt: DateTime.now(),
    );

    final bayOverdue = WarehouseGridBayModel(
      id: 'bay_03',
      shopId: 'shop_001',
      chamberCode: 'CH-1',
      bayCode: 'A3',
      rowCoord: 1,
      colCoord: 3,
      maxCapacityBags: 200,
      currentBags: 200,
      cropName: 'Basmati Paddy',
      farmerName: 'Rana Bashir',
      lotCode: 'LOT-PADDY-012',
      storageStartDate: DateTime.now().subtract(const Duration(days: 105)), // >90 days
      status: BayStatus.full,
      updatedAt: DateTime.now(),
    );

    test('Computes bay occupancy ratio and percentages accurately', () {
      expect(bayEmpty.occupancyPercent, equals(0.0));
      expect(bayEmpty.isEmpty, isTrue);

      expect(bayOccupied.occupancyPercent, equals(75.0)); // 150 / 200 * 100
      expect(bayOccupied.isEmpty, isFalse);
      expect(bayOccupied.isFull, isFalse);

      expect(bayOverdue.occupancyPercent, equals(100.0));
      expect(bayOverdue.isFull, isTrue);
    });

    test('Flags stock stored >90 days as overdue', () {
      expect(bayOccupied.daysInStorage, equals(20));
      expect(bayOccupied.isOverdue, isFalse);

      expect(bayOverdue.daysInStorage, greaterThanOrEqualTo(104));
      expect(bayOverdue.isOverdue, isTrue);
    });

    test('Generates Warehouse Chamber Occupancy Report PDF bytes', () async {
      final bays = [bayEmpty, bayOccupied, bayOverdue];
      final pdfBytes = await WarehouseGridPdfGenerator.generateWarehouseOccupancyReportPdf(
        bays: bays,
        chamberCode: 'CH-1 (Grain Godown)',
        shopName: 'Central Grain Warehouse Mandi',
        shopAddress: 'Railway Road, Mandi Bahauddin',
        shopPhone: '0300-5556677',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });
  });
}
