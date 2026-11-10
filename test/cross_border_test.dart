import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/cross_border_pdf_generator.dart';
import 'package:mandi/data/models/cross_border_shipment_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrossBorderShipment Model & Math Tests', () {
    test('calculates dual-currency conversion and landed cost correctly', () {
      const shipment = CrossBorderShipment(
        id: 'cbs-001',
        shopId: 'shop-okara',
        shipmentNumber: 'CBS-2026-0042',
        originCountry: OriginCountry.afghanistan,
        originCity: 'Kandahar',
        borderCrossing: BorderCrossing.chaman,
        vehicleNumber: 'KBL-8976',
        driverName: 'Sher Khan',
        commodity: 'Kandahari Pomegranate (Anaar)',
        packageType: 'Wooden Crate',
        packageCount: 500,
        grossWeightKg: 10000.0, // 250 Maunds
        currency: TradeCurrency.usd,
        exchangeRateToPkr: 278.50,
        foreignContractAmount: 10000.0, // $10,000 USD
        customsDutyPkr: 250000.0,
        borderFreightPkr: 200000.0,
        clearingChargesPkr: 35000.0,
        otherExpensesPkr: 15000.0,
        paidToSupplierForeign: 6000.0,
      );

      // Base Cargo = $10,000 * 278.50 = 2,785,000 PKR
      expect(shipment.computedBasePkr, equals(2785000.0));

      // Border Expenses = 250k + 200k + 35k + 15k = 500,000 PKR
      expect(shipment.totalBorderExpensesPkr, equals(500000.0));

      // Landed Cost = 2,785,000 + 500,000 = 3,285,000 PKR
      expect(shipment.computedTotalLandedCostPkr, equals(3285000.0));

      // Maunds = 10,000 KG / 40.0 = 250 Maunds
      expect(shipment.maunds, equals(250.0));

      // Cost per KG = 3,285,000 / 10,000 = 328.5 PKR
      expect(shipment.costPerKgPkr, equals(328.5));

      // Cost per Maund = 328.5 * 40 = 13,140 PKR
      expect(shipment.costPerMaundPkr, equals(13140.0));

      // Cost per Package = 3,285,000 / 500 crates = 6,570 PKR
      expect(shipment.costPerPackagePkr, equals(6570.0));

      // Remaining Foreign Debt = $10,000 - $6,000 = $4,000 USD
      expect(shipment.computedRemainingSupplierForeign, equals(4000.0));

      // Remaining Debt in PKR = $4,000 * 278.50 = 1,114,000 PKR
      expect(shipment.computedRemainingSupplierPkr, equals(1114000.0));

      // Settlement Progress = 6,000 / 10,000 = 0.60
      expect(shipment.settlementRatio, closeTo(0.60, 0.001));
    });

    test('serializes toMap and deserializes fromMap accurately', () {
      final now = DateTime(2026, 4, 15);
      final shipment = CrossBorderShipment(
        id: 'cbs-iran-01',
        shopId: 'shop-peshawar',
        shipmentNumber: 'CBS-2026-099',
        originCountry: OriginCountry.iran,
        originCity: 'Zahedan',
        borderCrossing: BorderCrossing.taftan,
        vehicleNumber: 'IR-7788',
        driverName: 'Reza Pahlavi',
        commodity: 'Iranian Apple (سیب)',
        packageType: 'Carton Box',
        packageCount: 800,
        grossWeightKg: 16000.0,
        currency: TradeCurrency.afn,
        exchangeRateToPkr: 3.95,
        foreignContractAmount: 400000.0,
        customsDutyPkr: 300000.0,
        borderFreightPkr: 250000.0,
        clearingChargesPkr: 40000.0,
        otherExpensesPkr: 10000.0,
        paidToSupplierForeign: 400000.0,
        status: CrossBorderShipmentStatus.settled,
        createdAt: now,
      );

      final map = shipment.toMap();
      expect(map['origin_country'], equals('iran'));
      expect(map['border_crossing'], equals('taftan'));
      expect(map['currency'], equals('AFN'));
      expect(map['status'], equals('settled'));
      expect(map['foreign_contract_amount'], equals(400000.0));
      expect(map['base_pkr_amount'], equals(1580000.0)); // 400,000 * 3.95

      final fromDb = CrossBorderShipment.fromMap('cbs-iran-01', map);
      expect(fromDb.originCountry, equals(OriginCountry.iran));
      expect(fromDb.borderCrossing, equals(BorderCrossing.taftan));
      expect(fromDb.currency, equals(TradeCurrency.afn));
      expect(fromDb.status, equals(CrossBorderShipmentStatus.settled));
      expect(fromDb.computedRemainingSupplierForeign, equals(0.0));
      expect(fromDb.settlementRatio, equals(1.0));
    });

    test('copyWith updates properties properly', () {
      const shipment = CrossBorderShipment(
        id: 'cbs-1',
        shopId: 's1',
        shipmentNumber: 'CBS-001',
        foreignContractAmount: 5000.0,
        paidToSupplierForeign: 1000.0,
      );

      final updated = shipment.copyWith(
        paidToSupplierForeign: 5000.0,
        status: CrossBorderShipmentStatus.settled,
        customsGdNumber: 'GD-9988',
      );

      expect(updated.paidToSupplierForeign, equals(5000.0));
      expect(updated.computedRemainingSupplierForeign, equals(0.0));
      expect(updated.status, equals(CrossBorderShipmentStatus.settled));
      expect(updated.customsGdNumber, equals('GD-9988'));
    });
  });

  group('CrossBorderSummary Portfolio Tests', () {
    test('aggregates summary metrics from shipments list', () {
      final list = [
        const CrossBorderShipment(
          id: 's1',
          shopId: 'shop1',
          shipmentNumber: 'CBS-1',
          grossWeightKg: 8000.0, // 200 Maunds
          foreignContractAmount: 5000.0,
          exchangeRateToPkr: 278.50,
          customsDutyPkr: 100000.0,
          borderFreightPkr: 80000.0,
          status: CrossBorderShipmentStatus.inTransit,
        ),
        const CrossBorderShipment(
          id: 's2',
          shopId: 'shop1',
          shipmentNumber: 'CBS-2',
          grossWeightKg: 12000.0, // 300 Maunds
          foreignContractAmount: 8000.0,
          exchangeRateToPkr: 278.50,
          customsDutyPkr: 150000.0,
          borderFreightPkr: 120000.0,
          paidToSupplierForeign: 8000.0, // Fully paid
          status: CrossBorderShipmentStatus.settled,
        ),
      ];

      final summary = CrossBorderSummary.fromShipments(list);

      expect(summary.totalShipments, equals(2));
      expect(summary.activeShipments, equals(1)); // only s1 is active
      expect(summary.totalCargoMaunds, equals(500.0)); // 200 + 300
      expect(summary.totalCustomsFreightPkr, equals(450000.0)); // 180k + 270k
      expect(summary.totalOutstandingSupplierPkr, equals(5000.0 * 278.50));
    });
  });

  group('CrossBorderPdfGenerator Tests', () {
    test('generates valid non-empty PDF bytes for Single Cargo Manifest', () async {
      final shipment = CrossBorderShipment(
        id: 'cbs-test',
        shopId: 'shop-1',
        shipmentNumber: 'CBS-2026-MANIFEST-01',
        originCountry: OriginCountry.afghanistan,
        originCity: 'Kandahar',
        borderCrossing: BorderCrossing.torkham,
        vehicleNumber: 'AF-4455',
        driverName: 'Jan Mohammad',
        driverPhone: '+93-700-123456',
        customsGdNumber: 'TK-2026-9081',
        customsClearanceDate: DateTime(2026, 4, 10),
        clearingAgentName: 'Khyber Border Logistics Ltd.',
        supplierName: 'Haji Gul Exporters',
        commodity: 'Fresh Grapes (Angoor)',
        packageType: 'Wooden Crate',
        packageCount: 600,
        grossWeightKg: 12000.0,
        currency: TradeCurrency.usd,
        exchangeRateToPkr: 278.50,
        foreignContractAmount: 15000.0,
        customsDutyPkr: 400000.0,
        borderFreightPkr: 320000.0,
        clearingChargesPkr: 50000.0,
        otherExpensesPkr: 20000.0,
        paidToSupplierForeign: 5000.0,
        status: CrossBorderShipmentStatus.clearedAtBorder,
        createdAt: DateTime(2026, 4, 10),
      );

      final pdfBytes = await CrossBorderPdfGenerator.generateCargoManifestPdf(
        shipment: shipment,
        shopName: 'Khyber Mandi Commission Agency',
        shopCity: 'Peshawar',
        shopPhone: '0300-9876543',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
      final headerStr = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(headerStr, equals('%PDF-'));
    });

    test('generates valid non-empty PDF bytes for Cross-Border Register', () async {
      final shipments = [
        const CrossBorderShipment(
          id: 'cbs-1',
          shopId: 'shop-1',
          shipmentNumber: 'CBS-001',
          originCountry: OriginCountry.afghanistan,
          borderCrossing: BorderCrossing.torkham,
          vehicleNumber: 'TLR-101',
          commodity: 'Grapes',
          packageCount: 500,
          grossWeightKg: 10000.0,
          currency: TradeCurrency.usd,
          foreignContractAmount: 10000.0,
        ),
        const CrossBorderShipment(
          id: 'cbs-2',
          shopId: 'shop-1',
          shipmentNumber: 'CBS-002',
          originCountry: OriginCountry.iran,
          borderCrossing: BorderCrossing.taftan,
          vehicleNumber: 'IR-502',
          commodity: 'Apples',
          packageCount: 700,
          grossWeightKg: 14000.0,
          currency: TradeCurrency.afn,
          exchangeRateToPkr: 3.95,
          foreignContractAmount: 350000.0,
        ),
      ];

      final pdfBytes = await CrossBorderPdfGenerator.generateBorderRegisterPdf(
        shipments: shipments,
        shopName: 'Ittehad Fruit Mandi',
        shopCity: 'Quetta',
        shopPhone: '0301-1122334',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
      final headerStr = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(headerStr, equals('%PDF-'));
    });
  });
}
