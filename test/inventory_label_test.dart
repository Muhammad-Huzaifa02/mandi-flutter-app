import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/inventory_label_pdf_generator.dart';
import 'package:mandi/data/models/inventory_label_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Inventory Labels & Barcode / QR Tracking Tests', () {
    test('InventoryLabelType enum serialization, parsing and localized labels', () {
      for (final type in InventoryLabelType.values) {
        final dbStr = type.toDbString();
        final parsed = InventoryLabelType.fromString(dbStr);
        expect(parsed, equals(type));
        expect(type.labelUrdu.isNotEmpty, isTrue);
        expect(type.labelEnglish.isNotEmpty, isTrue);
      }

      expect(InventoryLabelType.fromString('pallet_stack'), equals(InventoryLabelType.palletStack));
      expect(InventoryLabelType.fromString('pallet'), equals(InventoryLabelType.palletStack));
      expect(InventoryLabelType.fromString('godown_bay'), equals(InventoryLabelType.godownBay));
      expect(InventoryLabelType.fromString('bay'), equals(InventoryLabelType.godownBay));
      expect(InventoryLabelType.fromString('dispatch_challan'), equals(InventoryLabelType.dispatchChallan));
      expect(InventoryLabelType.fromString('dispatch'), equals(InventoryLabelType.dispatchChallan));
      expect(InventoryLabelType.fromString('lot'), equals(InventoryLabelType.lot));
    });

    test('PackageType enum serialization, default tare and localized labels', () {
      for (final pkg in PackageType.values) {
        final dbStr = pkg.toDbString();
        final parsed = PackageType.fromString(dbStr);
        expect(parsed, equals(pkg));
        expect(pkg.labelUrdu.isNotEmpty, isTrue);
        expect(pkg.labelEnglish.isNotEmpty, isTrue);
        expect(pkg.defaultTareKg, greaterThanOrEqualTo(0.0));
      }

      expect(PackageType.juteBag.defaultTareKg, equals(1.0));
      expect(PackageType.ppBag.defaultTareKg, equals(0.15));
      expect(PackageType.woodenCrate.defaultTareKg, equals(1.8));
      expect(PackageType.plasticCrate.defaultTareKg, equals(1.4));
      expect(PackageType.bulk.defaultTareKg, equals(0.0));
    });

    test('LabelStatus enum serialization, parsing and localized labels', () {
      for (final status in LabelStatus.values) {
        final dbStr = status.toDbString();
        final parsed = LabelStatus.fromString(dbStr);
        expect(parsed, equals(status));
        expect(status.labelUrdu.isNotEmpty, isTrue);
        expect(status.labelEnglish.isNotEmpty, isTrue);
      }

      expect(LabelStatus.fromString('active'), equals(LabelStatus.active));
      expect(LabelStatus.fromString('dispatched'), equals(LabelStatus.dispatched));
      expect(LabelStatus.fromString('sold'), equals(LabelStatus.dispatched));
      expect(LabelStatus.fromString('damaged'), equals(LabelStatus.damaged));
      expect(LabelStatus.fromString('archived'), equals(LabelStatus.archived));
    });

    test('InventoryLabel.computeWeightMath accurately computes tare and Maunds', () {
      // Scenario 1: 100 Jute bags (1.0 KG tare each)
      // Gross weight = 10,100 KG
      // Total tare = 100 * 1.0 = 100 KG
      // Net weight = 10,000 KG
      // Net Maunds = 10,000 / 40.0 = 250.0 Maunds
      final res1 = InventoryLabel.computeWeightMath(
        grossWeightKg: 10100.0,
        bagCount: 100,
        packageType: PackageType.juteBag,
      );

      expect(res1['totalTareKg'], equals(100.0));
      expect(res1['netWeightKg'], equals(10000.0));
      expect(res1['netWeightMaunds'], equals(250.0));

      // Scenario 2: 200 PP Woven Bags (0.15 KG tare each)
      // Gross weight = 10,030 KG
      // Total tare = 200 * 0.15 = 30 KG
      // Net weight = 10,000 KG
      // Net Maunds = 10,000 / 40.0 = 250.0 Maunds
      final res2 = InventoryLabel.computeWeightMath(
        grossWeightKg: 10030.0,
        bagCount: 200,
        packageType: PackageType.ppBag,
      );

      expect(res2['totalTareKg'], closeTo(30.0, 0.001));
      expect(res2['netWeightKg'], closeTo(10000.0, 0.001));
      expect(res2['netWeightMaunds'], closeTo(250.0, 0.001));

      // Scenario 3: Custom packaging tare override (e.g. 1.2 kg per heavy wooden box)
      final res3 = InventoryLabel.computeWeightMath(
        grossWeightKg: 5000.0,
        bagCount: 500,
        packageType: PackageType.woodenCrate,
        customTarePerBag: 1.2,
      );
      expect(res3['totalTareKg'], equals(600.0));
      expect(res3['netWeightKg'], equals(4400.0));
      expect(res3['netWeightMaunds'], equals(110.0));
    });

    test('InventoryLabel.generateQrPayload produces valid structured JSON', () {
      final jsonStr = InventoryLabel.generateQrPayload(
        shopId: 'shop-xyz',
        labelCode: 'PLT-2611-0005',
        commodityName: 'Super Basmati Rice',
        bagCount: 150,
        netWeightKg: 15000.0,
        netWeightMaunds: 375.0,
        qualityGrade: 'grade_a_super',
        facilityName: 'Main Mandi Godown',
        bayOrStack: 'Bay 3, Stack 8',
        date: DateTime(2026, 11, 11, 10, 0),
      );

      expect(jsonStr, isNotEmpty);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['app'], equals('MandiERP'));
      expect(decoded['shop'], equals('shop-xyz'));
      expect(decoded['code'], equals('PLT-2611-0005'));
      expect(decoded['crop'], equals('Super Basmati Rice'));
      expect(decoded['bags'], equals(150));
      expect(decoded['kg'], equals('15000.0'));
      expect(decoded['maunds'], equals('375.00'));
      expect(decoded['grade'], equals('grade_a_super'));
      expect(decoded['loc'], equals('Main Mandi Godown:Bay 3, Stack 8'));
    });

    test('InventoryLabel model serialization and deserialization roundtrip', () {
      final label = InventoryLabel(
        id: 'lbl-001',
        shopId: 'shop-1',
        lotId: 'lot-99',
        storageId: 'store-02',
        labelCode: 'LBL-2611-0012',
        barcodeValue: 'MNDLBL0012',
        qrPayload: '{"code":"LBL-2611-0012"}',
        labelType: InventoryLabelType.palletStack,
        commodityName: 'Wheat (گندم)',
        variety: 'Faisalabad-2008',
        partyName: 'Chaudhry Akram & Brothers',
        vehicleNumber: 'LES-4921',
        bagCount: 200,
        packageType: PackageType.juteBag,
        grossWeightKg: 20200.0,
        netWeightKg: 20000.0,
        netWeightMaunds: 500.0,
        qualityGrade: 'grade_a_super',
        facilityName: 'Sargodha Grain Godown',
        bayOrStack: 'Bay C-02, Stack 4',
        notes: 'Fumigated and stacked on wooden pallets',
        status: LabelStatus.active,
        createdBy: 'user-01',
        createdAt: DateTime(2026, 11, 11, 9, 30),
        updatedAt: DateTime(2026, 11, 11, 9, 30),
      );

      expect(label.isActive, isTrue);
      expect(label.isDispatched, isFalse);
      expect(label.displayCommodity, contains('Faisalabad-2008'));
      expect(label.displayLocation, contains('Bay C-02'));

      final map = label.toMap();
      expect(map['label_code'], equals('LBL-2611-0012'));
      expect(map['barcode_value'], equals('MNDLBL0012'));
      expect(map['label_type'], equals('pallet_stack'));
      expect(map['package_type'], equals('jute_bag'));
      expect(map['net_weight_maunds'], equals(500.0));
      expect(map['status'], equals('active'));

      final restored = InventoryLabel.fromMap('lbl-001', map);
      expect(restored.labelCode, equals('LBL-2611-0012'));
      expect(restored.barcodeValue, equals('MNDLBL0012'));
      expect(restored.labelType, equals(InventoryLabelType.palletStack));
      expect(restored.packageType, equals(PackageType.juteBag));
      expect(restored.bagCount, equals(200));
      expect(restored.netWeightKg, equals(20000.0));
      expect(restored.netWeightMaunds, equals(500.0));
      expect(restored.facilityName, equals('Sargodha Grain Godown'));
      expect(restored.bayOrStack, equals('Bay C-02, Stack 4'));
    });

    test('InventoryLabelPdfGenerator generates valid non-empty documents', () async {
      final label = InventoryLabel(
        id: 'lbl-002',
        shopId: 'shop-1',
        labelCode: 'PLT-2611-0088',
        barcodeValue: 'PLT26110088',
        qrPayload: '{"code":"PLT-2611-0088","crop":"Wheat","bags":250}',
        labelType: InventoryLabelType.palletStack,
        commodityName: 'Wheat (گندم)',
        variety: 'Galaxy-2013',
        partyName: 'Malik Tariq Mehmood',
        vehicleNumber: 'FD-7721',
        bagCount: 250,
        packageType: PackageType.juteBag,
        grossWeightKg: 25250.0,
        netWeightKg: 25000.0,
        netWeightMaunds: 625.0,
        qualityGrade: 'grade_a_super',
        facilityName: 'Central Mandi Godown # 1',
        bayOrStack: 'Chamber 2, Stack 14',
        notes: 'Dry grain storage. Do not expose to moisture.',
        createdAt: DateTime(2026, 11, 11, 10, 15),
      );

      final placardBytes = await InventoryLabelPdfGenerator.generateSinglePalletPlacardPdf(
        label: label,
        shopName: 'Al-Madina Commission Shop',
        shopAddress: 'Shop # 45, Grain Market, Sargodha',
        shopPhone: '0300-9876543',
      );
      expect(placardBytes, isNotNull);
      expect(placardBytes.length, greaterThan(1000));

      final stickerBytes = await InventoryLabelPdfGenerator.generate4UpAdhesiveStickerSheetPdf(
        labels: [label, label, label, label],
        shopName: 'Al-Madina Commission Shop',
      );
      expect(stickerBytes, isNotNull);
      expect(stickerBytes.length, greaterThan(1000));

      final rosterBytes = await InventoryLabelPdfGenerator.generateInventoryRosterPdf(
        labels: [label],
        shopName: 'Al-Madina Commission Shop',
        shopAddress: 'Shop # 45, Grain Market, Sargodha',
      );
      expect(rosterBytes, isNotNull);
      expect(rosterBytes.length, greaterThan(1000));
    });
  });
}
