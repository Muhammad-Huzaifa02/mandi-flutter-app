import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/voice_dictation_parser.dart';
import 'package:mandi/core/utils/loyalty_rebate_pdf_generator.dart';
import 'package:mandi/data/models/audio_voice_note_model.dart';
import 'package:mandi/data/models/customer_loyalty_rebate_model.dart';

void main() {
  group('Munshi Voice Dictation Parser Tests', () {
    test('Extracts party name, amount in PKR, maunds, and intent accurately from Urdu speech', () {
      const speech = 'چوہدری اکرم سے 120 من گندم کی 50000 روپے وصولی جمع ہوئی ہے';
      final res = VoiceDictationParser.parse(speech);

      expect(res.detectedPartyName, 'چوہدری اکرم');
      expect(res.parsedMaunds, 120.0);
      expect(res.parsedAmountPkr, 50000.0);
      expect(res.detectedCommodity, 'Wheat (گندم)');
      expect(res.suspectedAction, 'payment_recovery');
    });

    test('Parses English / Roman Urdu text with numbers and units', () {
      const speech = 'Haji Saleem 200 maunds rice Rs 75,000 received';
      final res = VoiceDictationParser.parse(speech);

      expect(res.parsedMaunds, 200.0);
      expect(res.parsedAmountPkr, 75000.0);
      expect(res.detectedCommodity, 'Rice / Paddy (دھان)');
      expect(res.suspectedAction, 'payment_recovery');
    });

    test('Handles bag counts and words like hazar / lakh', () {
      const speech = 'ملک اسلم 50 بوری چاول 2 لاکھ روپے';
      final res = VoiceDictationParser.parse(speech);

      expect(res.detectedPartyName, 'ملک اسلم');
      expect(res.parsedBags, 50);
      expect(res.parsedAmountPkr, 200000.0);
    });

    test('AudioVoiceNote serialization and duration formatting', () {
      final now = DateTime.now();
      final note = AudioVoiceNote(
        id: 'note-001',
        shopId: 'shop-01',
        title: 'Morning Auction Note',
        durationSeconds: 125, // 2m 05s
        fileSizeBytes: 64000,
        transcriptionText: 'Testing voice note',
        status: AudioNoteStatus.pending,
        entityType: AudioEntityType.consignmentLot,
        createdAt: now,
      );

      expect(note.durationFormatted, '02:05');
      expect(note.fileSizeFormatted, '62.5 KB');

      final map = note.toMap();
      expect(map['duration_seconds'], 125);
      expect(map['entity_type'], 'consignment_lot');
      expect(map['status'], 'pending');

      final reconstructed = AudioVoiceNote.fromMap('note-001', map);
      expect(reconstructed.id, note.id);
      expect(reconstructed.title, note.title);
      expect(reconstructed.durationSeconds, 125);
      expect(reconstructed.entityType, AudioEntityType.consignmentLot);
    });
  });

  group('Customer Loyalty & Volume Rebate Tests', () {
    test('Calculates tier levels and rebate payouts correctly based on seasonal volume', () {
      // Standard (<1,000 Maunds)
      expect(RebateTierLevel.fromMaunds(500), RebateTierLevel.standard);
      expect(RebateTierLevel.standard.defaultPercentage, 0.5);

      // Silver (1,000 - 4,999 Maunds)
      expect(RebateTierLevel.fromMaunds(1500), RebateTierLevel.silver);
      expect(RebateTierLevel.silver.defaultPercentage, 1.0);

      // Gold (5,000 - 9,999 Maunds)
      expect(RebateTierLevel.fromMaunds(6000), RebateTierLevel.gold);
      expect(RebateTierLevel.gold.defaultPercentage, 2.0);

      // Platinum (>=10,000 Maunds)
      expect(RebateTierLevel.fromMaunds(12000), RebateTierLevel.platinum);
      expect(RebateTierLevel.platinum.defaultPercentage, 3.0);

      // Payout Math: 10,000,000 turnover * 2.0% (Gold) = Rs. 200,000 rebate
      final rebateAmount = CustomerLoyaltyRebate.computeRebateAmount(10000000, 2.0);
      expect(rebateAmount, 200000.0);
    });

    test('CustomerLoyaltyRebate model serialization toMap and fromMap roundtrip', () {
      final now = DateTime.now();
      final original = CustomerLoyaltyRebate(
        id: 'reb-101',
        shopId: 'shop-01',
        customerId: 'cust-505',
        customerName: 'Chaudhry Akram & Sons',
        customerPhone: '03001234567',
        programName: 'Wheat Season Rebate',
        seasonYear: 'Rabi 2026',
        qualifyingMaunds: 5500.0,
        qualifyingTurnoverPkr: 22000000.0,
        tierLevel: RebateTierLevel.gold,
        rebatePercentage: 2.0,
        rebateAmountPkr: 440000.0,
        creditNoteNumber: 'CRN-2026-0044',
        status: RebateStatus.approved,
        createdAt: now,
      );

      final map = original.toMap();
      expect(map['customer_name'], 'Chaudhry Akram & Sons');
      expect(map['tier_level'], 'gold');
      expect(map['rebate_amount_pkr'], 440000.0);
      expect(map['credit_note_number'], 'CRN-2026-0044');

      final reconstructed = CustomerLoyaltyRebate.fromMap('reb-101', map);
      expect(reconstructed.id, original.id);
      expect(reconstructed.customerName, original.customerName);
      expect(reconstructed.qualifyingMaunds, 5500.0);
      expect(reconstructed.tierLevel, RebateTierLevel.gold);
      expect(reconstructed.status, RebateStatus.approved);
    });

    test('generateCreditNotePdf produces valid non-empty PDF bytes', () async {
      final rebate = CustomerLoyaltyRebate(
        id: 'reb-999',
        shopId: 'shop-01',
        customerId: 'cust-777',
        customerName: 'Malik Aslam Grain Traders',
        customerPhone: '03217654321',
        programName: 'Rice Harvest Incentive',
        seasonYear: 'Kharif 2026',
        qualifyingMaunds: 8000.0,
        qualifyingTurnoverPkr: 32000000.0,
        tierLevel: RebateTierLevel.gold,
        rebatePercentage: 2.0,
        rebateAmountPkr: 640000.0,
        creditNoteNumber: 'CRN-2026-0999',
        status: RebateStatus.credited,
        creditedAt: DateTime(2026, 11, 11, 11, 0),
        createdAt: DateTime(2026, 11, 1),
      );

      final pdfBytes = await LoyaltyRebatePdfGenerator.generateCreditNotePdf(
        rebate: rebate,
        shopName: 'Haji Aslam & Sons Commission Shop',
        shopAddress: 'Ghalla Mandi, Sargodha',
        shopPhone: '0300-1234567',
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]); // %PDF-
    });
  });
}
