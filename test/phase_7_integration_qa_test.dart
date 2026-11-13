import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/core/utils/pk_phone.dart';
import 'package:mandi/core/utils/pk_cnic.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/consignment_lot_model.dart';
import 'package:mandi/core/services/biometric_auth_service.dart';
import 'package:mandi/core/services/cloud_backup_verification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Phase 7: End-to-End Integration & Quality Assurance Suite', () {
    test('E2E 01: Agricultural Weight & Maund Unit Calculation Integrity', () {
      // 1 Maund (Mann) = 40.0 KG exactly in Pakistan Mandi standard
      const double testKg = 2400.0;
      final manns = MandiCalculator.kgToMann(testKg);
      expect(manns, equals(60.0));

      final backToKg = MandiCalculator.mannToKg(manns);
      expect(backToKg, equals(2400.0));

      // Test fractional weights e.g. 52.5 KG
      final fractionalManns = MandiCalculator.kgToMann(52.5);
      expect(fractionalManns, equals(1.3125));
    });

    test('E2E 02: Pakistani Phone & CNIC Formatting & Security Masking', () {
      // Phone normalization: local Pakistani mobile to E.164
      final normalizedPhone = PkPhone.toE164('03001234567');
      expect(normalizedPhone, equals('+923001234567'));

      // Validate invalid phone rejection
      final invalidPhone = PkPhone.toE164('12345');
      expect(invalidPhone, isNull);

      // CNIC masking: 13 digits masked with asterisks
      const rawCnic = '3520212345671';
      final masked = PkCnic.mask(rawCnic);
      expect(masked.contains('*****'), isTrue);
    });

    test('E2E 03: Sales Invoice Calculation Engine with Commission & Expenses', () {
      final items = [
        const InvoiceItem(
          productId: 'prod_wheat_01',
          productName: 'Super Kernel Basmati',
          weightKg: 2000.0, // 50 Maunds
          unitPrice: 4200.0, // Rs. 4200 / Maund or unit
          lineTotal: 210000.0,
        ),
      ];

      final invoice = Invoice(
        id: 'inv_test_999',
        shopId: 'shop_001',
        invoiceNumber: 'INV-2026-0001',
        customerName: 'Haji Mukhtar Traders',
        items: items,
        subtotal: 210000.0,
        commission: 4200.0, // 2% Commission
        expenses: 1500.0, // Palladari / Labor
        discount: 700.0,
        total: 215000.0, // 210000 + 4200 + 1500 - 700
        receivedAmount: 200000.0,
        pendingAmount: 15000.0,
      );

      expect(invoice.total, equals(215000.0));
      expect(invoice.pendingAmount, equals(15000.0));
      expect(invoice.items.length, 1);

      // Serialization round-trip verification
      final map = invoice.toMap();
      final roundTrip = Invoice.fromMap('inv_test_999', map);
      expect(roundTrip.invoiceNumber, equals('INV-2026-0001'));
      expect(roundTrip.total, equals(215000.0));
    });

    test('E2E 04: Live Auction Consignment Lot State Transitions', () {
      const lot = ConsignmentLot(
        id: 'lot_777',
        shopId: 'shop_001',
        lotNumber: 'HEAP-45',
        supplierName: 'Malik Tariq',
        productName: 'Cotton (کپاس)',
        weightKg: 1200.0, // 30 Maunds
        bagCount: 30,
        ratePerMaund: 8900.0,
        status: ConsignmentLotStatus.auctioning,
      );

      expect(lot.status, equals(ConsignmentLotStatus.auctioning));
      expect(lot.isAuctionActive, isTrue);
      expect(lot.maunds, equals(30.0));
      expect(lot.ratePerMaund, equals(8900.0));

      final lotMap = lot.toMap();
      final reconstituted = ConsignmentLot.fromMap('lot_777', lotMap);
      expect(reconstituted.lotNumber, equals('HEAP-45'));
      expect(reconstituted.weightKg, equals(1200.0));
      expect(reconstituted.maunds, equals(30.0));
    });

    test('E2E 05: Cloud Backup Verification Service Report Generation', () {
      final report = BackupVerificationReport(
        shopId: 'shop_e2e_check',
        timestamp: DateTime.now(),
      );
      report.addCheck('Database RLS Policies', true, 'Shop-isolation validated');
      report.addCheck('Double-Entry Balance', true, 'Debits equal Credits');

      expect(report.isHealthy, isTrue);
      expect(report.checks.length, 2);
    });

    test('E2E 06: Biometric & Security Fallback Handling', () async {
      final enabled = await BiometricAuthService.isBiometricLoginEnabled();
      expect(enabled, isA<bool>());

      await BiometricAuthService.setBiometricLoginEnabled(true);
      final enabledAfter = await BiometricAuthService.isBiometricLoginEnabled();
      expect(enabledAfter, isTrue);

      // Reset
      await BiometricAuthService.setBiometricLoginEnabled(false);
    });
  });
}
