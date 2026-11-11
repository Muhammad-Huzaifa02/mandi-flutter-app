import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/quality_inspection_pdf_generator.dart';
import 'package:mandi/data/models/quality_inspection_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quality Inspection & Cold Chain Lab Tests', () {
    test('QualityGrade enum serialization, parsing and localized labels', () {
      for (final grade in QualityGrade.values) {
        final dbStr = grade.toDbString();
        final parsed = QualityGrade.fromString(dbStr);
        expect(parsed, equals(grade));
        expect(grade.labelUrdu.isNotEmpty, isTrue);
        expect(grade.labelEnglish.isNotEmpty, isTrue);
      }

      // Check special aliases
      expect(QualityGrade.fromString('grade_a'), equals(QualityGrade.gradeASuper));
      expect(QualityGrade.fromString('super'), equals(QualityGrade.gradeASuper));
      expect(QualityGrade.fromString('grade_b'), equals(QualityGrade.gradeBFaq));
      expect(QualityGrade.fromString('faq'), equals(QualityGrade.gradeBFaq));
      expect(QualityGrade.fromString('grade_c'), equals(QualityGrade.gradeCSubstandard));
      expect(QualityGrade.fromString('substandard'), equals(QualityGrade.gradeCSubstandard));
      expect(QualityGrade.fromString('rejected'), equals(QualityGrade.rejected));
    });

    test('ColdChainStatus enum serialization, parsing and localized labels', () {
      for (final status in ColdChainStatus.values) {
        final dbStr = status.toDbString();
        final parsed = ColdChainStatus.fromString(dbStr);
        expect(parsed, equals(status));
        expect(status.labelUrdu.isNotEmpty, isTrue);
        expect(status.labelEnglish.isNotEmpty, isTrue);
      }

      expect(ColdChainStatus.fromString('optimal'), equals(ColdChainStatus.optimal));
      expect(ColdChainStatus.fromString('warning'), equals(ColdChainStatus.warning));
      expect(ColdChainStatus.fromString('critical'), equals(ColdChainStatus.critical));
    });

    test('QualityInspection.computeDeductions accurately computes moisture & refraction deductions', () {
      // Scenario 1: Moisture below base moisture (e.g. 12% moisture, base 14%)
      // Clean grain: 0.5% foreign, 1.0% broken, 0% damaged
      // Broken ratio is 0.5:1 -> broken ded = 0.5%
      // Total deduction % = 0.0 + 0.5 + 0.5 + 0.0 = 1.0%
      // Gross weight = 20,000 KG
      // Deduction KG = 20,000 * 0.01 = 200 KG
      // Net Weight KG = 19,800 KG
      // Net Maunds = 19,800 / 40.0 = 495.0 Maunds
      final res1 = QualityInspection.computeDeductions(
        moisturePercentage: 12.0,
        baseMoisturePercentage: 14.0,
        foreignMatterPercentage: 0.5,
        brokenGrainPercentage: 1.0,
        damagedGrainPercentage: 0.0,
        grossWeightKg: 20000.0,
      );

      expect(res1['excessMoisture'], equals(0.0));
      expect(res1['totalDeductionPct'], equals(1.0));
      expect(res1['deductionKg'], equals(200.0));
      expect(res1['netWeightKg'], equals(19800.0));
      expect(res1['netWeightMaunds'], equals(495.0));
      expect(res1['suggestedGrade'], equals(QualityGrade.gradeASuper));

      // Scenario 2: High moisture wheat (e.g. 18.0% moisture, base 14%)
      // Refraction: 1.5% foreign, 2.0% broken (x0.5 = 1.0%), 1.0% damaged (x0.75 = 0.75%)
      // Excess moisture = 18.0 - 14.0 = 4.0%
      // Total deduction % = 4.0 + 1.5 + 1.0 + 0.75 = 7.25%
      // Gross weight = 10,000 KG
      // Deduction KG = 10,000 * (7.25 / 100) = 725.0 KG
      // Net Weight KG = 9,275.0 KG
      // Net Maunds = 9,275.0 / 40.0 = 231.875 Maunds
      final res2 = QualityInspection.computeDeductions(
        moisturePercentage: 18.0,
        baseMoisturePercentage: 14.0,
        foreignMatterPercentage: 1.5,
        brokenGrainPercentage: 2.0,
        damagedGrainPercentage: 1.0,
        grossWeightKg: 10000.0,
      );

      expect(res2['excessMoisture'], equals(4.0));
      expect(res2['totalDeductionPct'], equals(7.25));
      expect(res2['deductionKg'], equals(725.0));
      expect(res2['netWeightKg'], equals(9275.0));
      expect(res2['netWeightMaunds'], equals(231.875));
      expect(res2['suggestedGrade'], equals(QualityGrade.gradeCSubstandard));

      // Scenario 3: Extreme water-soaked grain (Moisture > 24% or Damaged > 10%)
      final res3 = QualityInspection.computeDeductions(
        moisturePercentage: 26.5,
        baseMoisturePercentage: 14.0,
        foreignMatterPercentage: 3.0,
        brokenGrainPercentage: 4.0,
        damagedGrainPercentage: 5.0,
        grossWeightKg: 8000.0,
      );
      expect(res3['suggestedGrade'], equals(QualityGrade.rejected));
    });

    test('ColdChainLog.evaluateStatus correctly detects optimal, warning, and critical bands', () {
      // Safe threshold: 0.0 °C to 4.0 °C
      expect(
        ColdChainLog.evaluateStatus(temp: 2.0, minT: 0.0, maxT: 4.0),
        equals(ColdChainStatus.optimal),
      );
      expect(
        ColdChainLog.evaluateStatus(temp: 0.0, minT: 0.0, maxT: 4.0),
        equals(ColdChainStatus.optimal),
      );
      expect(
        ColdChainLog.evaluateStatus(temp: 4.0, minT: 0.0, maxT: 4.0),
        equals(ColdChainStatus.optimal),
      );

      // Warning band: between maxT and maxT + 3.0 (i.e. 4.1 to 7.0) or minT - 3.0 to minT
      expect(
        ColdChainLog.evaluateStatus(temp: 5.2, minT: 0.0, maxT: 4.0),
        equals(ColdChainStatus.warning),
      );
      expect(
        ColdChainLog.evaluateStatus(temp: -1.5, minT: 0.0, maxT: 4.0),
        equals(ColdChainStatus.warning),
      );

      // Critical breach: above maxT + 3.0 (e.g. 7.5 °C) or below minT - 3.0 (e.g. -3.5 °C)
      expect(
        ColdChainLog.evaluateStatus(temp: 8.5, minT: 0.0, maxT: 4.0),
        equals(ColdChainStatus.critical),
      );
      expect(
        ColdChainLog.evaluateStatus(temp: -4.5, minT: 0.0, maxT: 4.0),
        equals(ColdChainStatus.critical),
      );
    });

    test('QualityInspection model serialization and deserialization roundtrip', () {
      final inspection = QualityInspection(
        id: 'qc-001',
        shopId: 'shop-1',
        lotId: 'lot-88',
        certificateNumber: 'QC-202611-001',
        inspectionDate: DateTime(2026, 11, 10, 10, 15),
        commodityName: 'Super Basmati Rice (باسمتی چاول)',
        variety: 'Kainat 1121 Steam',
        vehicleNumber: 'LES-9021',
        partyName: 'Chaudhry Bashir & Sons',
        sampleWeightGrams: 500.0,
        moisturePercentage: 15.5,
        baseMoisturePercentage: 14.0,
        foreignMatterPercentage: 1.0,
        brokenGrainPercentage: 2.0,
        damagedGrainPercentage: 0.5,
        totalDeductionPercentage: 3.875,
        grossWeightKg: 12000.0,
        deductionWeightKg: 465.0,
        netWeightKg: 11535.0,
        netWeightMaunds: 288.375,
        qualityGrade: QualityGrade.gradeBFaq,
        temperatureCelsius: 22.0,
        humidityPercentage: 58.0,
        chamberOrLocation: 'Bay 4, Gate A',
        testerName: 'Muhammad Arshad (Lab Chemist)',
        notes: 'Slight excess moisture, acceptable for parboiled milling',
        status: 'certified',
        createdBy: 'user-01',
        createdAt: DateTime(2026, 11, 10, 10, 20),
        updatedAt: DateTime(2026, 11, 10, 10, 20),
      );

      expect(inspection.isCertified, isTrue);
      expect(inspection.isRejected, isFalse);

      final map = inspection.toMap();
      expect(map['certificate_number'], equals('QC-202611-001'));
      expect(map['commodity_name'], equals('Super Basmati Rice (باسمتی چاول)'));
      expect(map['quality_grade'], equals('grade_b_faq'));
      expect(map['total_deduction_percentage'], equals(3.875));
      expect(map['net_weight_maunds'], equals(288.375));

      final restored = QualityInspection.fromMap('qc-001', map);
      expect(restored.certificateNumber, equals('QC-202611-001'));
      expect(restored.commodityName, equals('Super Basmati Rice (باسمتی چاول)'));
      expect(restored.qualityGrade, equals(QualityGrade.gradeBFaq));
      expect(restored.grossWeightKg, equals(12000.0));
      expect(restored.netWeightKg, equals(11535.0));
      expect(restored.netWeightMaunds, equals(288.375));
      expect(restored.testerName, equals('Muhammad Arshad (Lab Chemist)'));
    });

    test('ColdChainLog model serialization and deserialization roundtrip', () {
      final log = ColdChainLog(
        id: 'ccl-101',
        shopId: 'shop-1',
        storageId: 'store-02',
        chamberName: 'Chamber 1 - Kinnow Cold Storage',
        recordedAt: DateTime(2026, 11, 10, 14, 0),
        temperatureCelsius: 3.2,
        humidityPercentage: 88.5,
        minTempThreshold: 0.0,
        maxTempThreshold: 4.0,
        status: ColdChainStatus.optimal,
        sensorDeviceId: 'BLE-TEMP-04',
        inspectorName: 'Munshi Akram',
        correctiveAction: 'Defrost cycle operating normally',
        createdAt: DateTime(2026, 11, 10, 14, 5),
      );

      final map = log.toMap();
      expect(map['chamber_name'], equals('Chamber 1 - Kinnow Cold Storage'));
      expect(map['temperature_celsius'], equals(3.2));
      expect(map['humidity_percentage'], equals(88.5));
      expect(map['status'], equals('optimal'));
      expect(map['sensor_device_id'], equals('BLE-TEMP-04'));

      final restored = ColdChainLog.fromMap('ccl-101', map);
      expect(restored.chamberName, equals('Chamber 1 - Kinnow Cold Storage'));
      expect(restored.temperatureCelsius, equals(3.2));
      expect(restored.humidityPercentage, equals(88.5));
      expect(restored.status, equals(ColdChainStatus.optimal));
      expect(restored.correctiveAction, equals('Defrost cycle operating normally'));
    });

    test('QualityInspectionPdfGenerator generates valid non-empty documents', () async {
      final inspection = QualityInspection(
        id: 'qc-002',
        shopId: 'shop-1',
        certificateNumber: 'QC-202611-002',
        inspectionDate: DateTime(2026, 11, 10, 11, 0),
        commodityName: 'Wheat (گندم)',
        variety: 'Faisalabad-2008',
        vehicleNumber: 'FD-4421',
        partyName: 'Haji Ghulam Rasool',
        sampleWeightGrams: 500.0,
        moisturePercentage: 16.0,
        baseMoisturePercentage: 14.0,
        foreignMatterPercentage: 1.0,
        brokenGrainPercentage: 2.0,
        damagedGrainPercentage: 1.0,
        totalDeductionPercentage: 4.75,
        grossWeightKg: 16000.0,
        deductionWeightKg: 760.0,
        netWeightKg: 15240.0,
        netWeightMaunds: 381.0,
        qualityGrade: QualityGrade.gradeBFaq,
        temperatureCelsius: 24.0,
        humidityPercentage: 55.0,
        chamberOrLocation: 'Platform A',
        testerName: 'Tariq Mehmood',
        notes: 'Grain tested clean, slight wetness due to morning harvest dew',
        createdAt: DateTime(2026, 11, 10, 11, 15),
      );

      final certBytes = await QualityInspectionPdfGenerator.generateQualityCertificatePdf(
        inspection: inspection,
        shopName: 'Al-Madina Commission Shop',
        shopAddress: 'Shop # 45, Grain Market, Sargodha',
        shopPhone: '0300-9876543',
      );

      expect(certBytes, isNotNull);
      expect(certBytes.length, greaterThan(1000));

      final logs = [
        ColdChainLog(
          id: 'ccl-1',
          shopId: 'shop-1',
          chamberName: 'Apple Controlled Atmosphere Room',
          recordedAt: DateTime(2026, 11, 10, 6, 0),
          temperatureCelsius: 1.5,
          humidityPercentage: 92.0,
          minTempThreshold: 0.0,
          maxTempThreshold: 2.0,
          status: ColdChainStatus.optimal,
          inspectorName: 'Rashid Ali',
          createdAt: DateTime(2026, 11, 10, 6, 5),
        ),
        ColdChainLog(
          id: 'ccl-2',
          shopId: 'shop-1',
          chamberName: 'Kinnow Citrus Chamber 2',
          recordedAt: DateTime(2026, 11, 10, 12, 0),
          temperatureCelsius: 5.8,
          humidityPercentage: 84.0,
          minTempThreshold: 3.0,
          maxTempThreshold: 5.0,
          status: ColdChainStatus.warning,
          correctiveAction: 'Compressor refrigerant valve adjusted',
          inspectorName: 'Rashid Ali',
          createdAt: DateTime(2026, 11, 10, 12, 5),
        ),
      ];

      final logSheetBytes = await QualityInspectionPdfGenerator.generateColdChainLogSheetPdf(
        logs: logs,
        shopName: 'Al-Madina Commission Shop',
        shopAddress: 'Shop # 45, Grain Market, Sargodha',
        shopPhone: '0300-9876543',
      );

      expect(logSheetBytes, isNotNull);
      expect(logSheetBytes.length, greaterThan(1000));
    });
  });
}
