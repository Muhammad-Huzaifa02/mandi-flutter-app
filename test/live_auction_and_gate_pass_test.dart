// Comprehensive Test Suite for Live Auction (Boli) Floor Terminal
// and Mandi Gate Pass, Inward Token & Unloading Queue.

import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/data/models/gate_pass_model.dart';
import 'package:mandi/modules/auction_boli/providers/auction_boli_provider.dart';
import 'package:mandi/core/utils/gate_pass_pdf_generator.dart';

void main() {
  group('Live Auction (Boli) Floor Terminal Tests', () {
    late AuctionBoliProvider auctionProvider;

    setUp(() {
      auctionProvider = AuctionBoliProvider();
    });

    test('Initializes Lot with heap details and calculates gross value', () {
      auctionProvider.initializeLot(
        lotCode: 'HEAP-42',
        cropCommodity: 'Wheat Super (گندم)',
        farmerName: 'Chaudhry Riaz',
        heapMaunds: 100.0,
        estimatedBags: 100,
        basePricePerMaund: 3900.0,
      );

      expect(auctionProvider.lotCode, equals('HEAP-42'));
      expect(auctionProvider.cropCommodity, equals('Wheat Super (گندم)'));
      expect(auctionProvider.heapMaunds, equals(100.0));
      expect(auctionProvider.currentBidPerMaund, equals(3900.0));
      expect(auctionProvider.currentTotalGrossValue, equals(390000.0));
      expect(auctionProvider.isAuctionLocked, isFalse);
      expect(auctionProvider.gavelCount, equals(0));
    });

    test('Increments bid with +10, +25, +50 and records bid log', () {
      auctionProvider.initializeLot(
        lotCode: 'HEAP-42',
        cropCommodity: 'Basmati Rice',
        farmerName: 'Malik Aslam',
        heapMaunds: 50.0,
        estimatedBags: 50,
        basePricePerMaund: 4000.0,
      );

      auctionProvider.selectBuyer(paddleNumber: 15, buyerName: 'Al-Madina Mills');
      auctionProvider.incrementBid(25.0);

      expect(auctionProvider.currentBidPerMaund, equals(4025.0));
      expect(auctionProvider.bidHistory.length, equals(1));
      expect(auctionProvider.bidHistory.first.paddleNumber, equals(15));
      expect(auctionProvider.bidHistory.first.bidPerMaund, equals(4025.0));

      auctionProvider.selectBuyer(paddleNumber: 24, buyerName: 'Kashmir Traders');
      auctionProvider.incrementBid(50.0);

      expect(auctionProvider.currentBidPerMaund, equals(4075.0));
      expect(auctionProvider.bidHistory.length, equals(2));
      expect(auctionProvider.currentTotalGrossValue, equals(50.0 * 4075.0));
    });

    test('Gavel strike sequence: 1, 2, 3 (SOLD!) locks auction & triggers sound cue', () {
      auctionProvider.initializeLot(
        lotCode: 'HEAP-99',
        cropCommodity: 'Gram (چنا)',
        farmerName: 'Rana Bashir',
        heapMaunds: 40.0,
        estimatedBags: 40,
        basePricePerMaund: 6500.0,
      );

      // Strike 1
      auctionProvider.strikeGavel();
      expect(auctionProvider.gavelCount, equals(1));
      expect(auctionProvider.gavelMessage, contains('ایک!'));
      expect(auctionProvider.isAuctionLocked, isFalse);

      // Strike 2
      auctionProvider.strikeGavel();
      expect(auctionProvider.gavelCount, equals(2));
      expect(auctionProvider.gavelMessage, contains('دو!'));
      expect(auctionProvider.isAuctionLocked, isFalse);

      // Strike 3 - Sold!
      auctionProvider.strikeGavel();
      expect(auctionProvider.gavelCount, equals(3));
      expect(auctionProvider.gavelMessage, contains('تین — ہو گیا!'));
      expect(auctionProvider.isAuctionLocked, isTrue);
      expect(auctionProvider.soundCueTriggered, isTrue);

      // Verify no further increments are allowed once locked
      auctionProvider.incrementBid(50.0);
      expect(auctionProvider.currentBidPerMaund, equals(6500.0));
    });

    test('Reset auction clears state and unlocks terminal', () {
      auctionProvider.initializeLot(
        lotCode: 'HEAP-01',
        cropCommodity: 'Wheat',
        farmerName: 'Test Farmer',
        heapMaunds: 10.0,
        estimatedBags: 10,
        basePricePerMaund: 3500.0,
      );
      auctionProvider.strikeGavel();
      auctionProvider.strikeGavel();
      auctionProvider.strikeGavel();
      expect(auctionProvider.isAuctionLocked, isTrue);

      auctionProvider.resetAuction();
      expect(auctionProvider.isAuctionLocked, isFalse);
      expect(auctionProvider.gavelCount, equals(0));
      expect(auctionProvider.currentBidPerMaund, equals(3500.0));
    });
  });

  group('Mandi Gate Pass & Inward Queue Tests', () {
    final sampleInwardTime = DateTime(2026, 11, 11, 8, 30);

    final samplePass = GatePassModel(
      id: 'pass_123',
      shopId: 'shop_001',
      tokenNumber: 'TKN-042',
      vehicleNumber: 'LHR-9821',
      driverName: 'Sajid Ali',
      driverPhone: '0300-9876543',
      farmerName: 'Chaudhry Munir',
      commodityName: 'Super Basmati Paddy (دھان)',
      estimatedBags: 120,
      inwardTime: sampleInwardTime,
      assignedPlatform: 'پھڑ نمبر 3',
      grossWeightKg: 5800.0,
      tareWeightKg: 1400.0,
      netWeightKg: 4400.0,
      status: GatePassStatus.weighed,
      createdAt: sampleInwardTime,
      updatedAt: sampleInwardTime,
    );

    test('GatePassModel converts net KG to Maunds accurately (40kg = 1 Maund)', () {
      expect(samplePass.netWeightKg, equals(4400.0));
      expect(samplePass.netMaunds, equals(4400.0 / 40.0)); // 110.0 Maunds
      expect(samplePass.netMaunds, equals(110.0));
    });

    test('GatePassStatus labels and db mappings', () {
      expect(GatePassStatus.queued.toDbString(), equals('queued'));
      expect(GatePassStatus.unloading.toDbString(), equals('unloading'));
      expect(GatePassStatus.weighed.toDbString(), equals('weighed'));
      expect(GatePassStatus.clearedGateOut.toDbString(), equals('cleared_gate_out'));

      expect(GatePassStatus.fromString('unloading'), equals(GatePassStatus.unloading));
      expect(GatePassStatus.fromString('cleared_gate_out'), equals(GatePassStatus.clearedGateOut));
    });

    test('Generates Inward Token Slip PDF bytes successfully', () async {
      final pdfBytes = await GatePassPdfGenerator.generateTokenSlipPdf(
        gatePass: samplePass,
        shopName: 'Bismillah Commission Shop',
        shopAddress: 'Galla Mandi, Okara',
        shopPhone: '0300-1122334',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });

    test('Generates Gate-Out Clearance Pass PDF bytes successfully', () async {
      final pdfBytes = await GatePassPdfGenerator.generateGateOutPassPdf(
        gatePass: samplePass,
        shopName: 'Bismillah Commission Shop',
        shopAddress: 'Galla Mandi, Okara',
        shopPhone: '0300-1122334',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });
  });
}
