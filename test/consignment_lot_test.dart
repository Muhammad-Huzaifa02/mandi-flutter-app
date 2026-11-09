import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/data/models/consignment_lot_model.dart';
import 'package:mandi/core/utils/boli_sheet_pdf_generator.dart';

void main() {
  group('ConsignmentLot Model Tests', () {
    test('computes Maunds and estimated total correctly', () {
      const lot = ConsignmentLot(
        id: 'lot1',
        shopId: 'shop1',
        lotNumber: 'DH-101',
        supplierName: 'Chaudhry Bashir',
        productName: 'Basmati Rice 86',
        vehicleNumber: 'Trolley 12',
        bagCount: 50,
        weightKg: 2000.0, // 2000 kg / 40 = 50 Maunds
        ratePerMaund: 4500.0,
        status: ConsignmentLotStatus.arrived,
      );

      // Verify Mandi maund calculation: 2000 kg / 40 = 50.0 Maunds
      expect(lot.maunds, 50.0);

      // Verify estimated total: 50 * 4500 = 225,000
      expect(lot.estimatedTotal, 225000.0);

      expect(lot.isSold, false);
      expect(lot.isAuctionActive, false);
    });

    test('verifies serialization toMap and fromMap', () {
      const lot = ConsignmentLot(
        id: 'lot2',
        shopId: 'shop1',
        lotNumber: 'DH-202',
        supplierId: 'supp1',
        supplierName: 'Haji Aslam',
        productId: 'prod1',
        productName: 'Wheat Super',
        vehicleNumber: 'Truck MN-9901',
        bagCount: 120,
        weightKg: 4800.0, // 120 Maunds
        ratePerMaund: 3900.0,
        winningBuyerId: 'cust1',
        winningBuyerName: 'Malik Tariq',
        status: ConsignmentLotStatus.sold,
      );

      final map = lot.toMap();
      expect(map['lot_number'], 'DH-202');
      expect(map['status'], 'sold');
      expect(map['rate_per_maund'], 3900.0);
      expect(map['winning_buyer_name'], 'Malik Tariq');

      final reconstituted = ConsignmentLot.fromMap('lot2', map);
      expect(reconstituted.id, 'lot2');
      expect(reconstituted.lotNumber, 'DH-202');
      expect(reconstituted.maunds, 120.0);
      expect(reconstituted.estimatedTotal, 468000.0);
      expect(reconstituted.status, ConsignmentLotStatus.sold);
      expect(reconstituted.isSold, true);
    });

    test('generates Boli Sheet PDF bytes successfully', () async {
      final lots = [
        const ConsignmentLot(
          id: 'lot1',
          shopId: 'shop1',
          lotNumber: 'DH-101',
          supplierName: 'Chaudhry Bashir',
          productName: 'Basmati Rice',
          vehicleNumber: 'Trolley 12',
          bagCount: 50,
          weightKg: 2000.0,
          ratePerMaund: 4500.0,
          winningBuyerName: 'Seth Munir',
          status: ConsignmentLotStatus.sold,
        ),
      ];

      final bytes = await BoliSheetPdfGenerator.generateBoliSheetPdf(
        lots: lots,
        date: DateTime.now(),
        shopName: 'Al-Madina Commission Shop',
        shopCity: 'Faisalabad',
        shopPhone: '03001234567',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('generates Lot Slip PDF bytes successfully', () async {
      const lot = ConsignmentLot(
        id: 'lot1',
        shopId: 'shop1',
        lotNumber: 'DH-101',
        supplierName: 'Chaudhry Bashir',
        productName: 'Basmati Rice',
        vehicleNumber: 'Trolley 12',
        bagCount: 50,
        weightKg: 2000.0,
        ratePerMaund: 4500.0,
      );

      final bytes = await BoliSheetPdfGenerator.generateLotSlipPdf(
        lot: lot,
        shopName: 'Al-Madina Commission Shop',
        shopCity: 'Faisalabad',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });
  });
}
