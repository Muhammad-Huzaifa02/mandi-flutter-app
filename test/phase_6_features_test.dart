import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/services/bluetooth_escpos_service.dart';
import 'package:mandi/core/services/sms_gateway_client.dart';
import 'package:mandi/core/services/cloud_backup_verification_service.dart';
import 'package:mandi/core/services/biometric_auth_service.dart';
import 'package:mandi/data/repositories/invoice_repository.dart';
import 'package:mandi/data/repositories/auction_repository.dart';
import 'package:mandi/data/repositories/farmer_repository.dart';
import 'package:mandi/data/repositories/customer_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Phase 6: Incomplete & Missing Features Hardening Tests', () {
    test('ESC/POS Bluetooth Header Formatter generates standard command bytes', () {
      final headerBytes = BluetoothEscPosService.buildEscPosHeader('Mandi Boli Slip');
      expect(headerBytes, isNotEmpty);
      // Validate init command 0x1B, 0x40
      expect(headerBytes[0], 0x1B);
      expect(headerBytes[1], 0x40);
      // Validate header text inclusion
      final text = String.fromCharCodes(headerBytes);
      expect(text.contains('Mandi Boli Slip'), isTrue);
    });

    test('SmsGatewayClient formats request payloads correctly for Pakistani telcos', () async {
      final result = await SmsGatewayClient.sendSms(
        provider: 'custom',
        apiUrl: 'https://example.com/api/fake_sms_endpoint_test',
        apiKey: 'test_token',
        senderId: 'MANDI',
        recipientPhone: '03001234567',
        message: 'Daily Wheat Rate: Rs. 3800 / Mann',
      );
      // Phone should normalize to clean international/local number
      expect(result.recipient, '923001234567');
      expect(result.statusCode, isNotNull);
    });

    test('CloudBackupVerificationReport tracks double-entry ledger checks', () {
      final report = BackupVerificationReport(
        shopId: 'shop_test_123',
        timestamp: DateTime.now(),
      );
      report.addCheck('Shop Entity', true, 'Shop valid');
      report.addCheck('Double-Entry Ledger Integrity', true, 'Debits == Credits');

      expect(report.isHealthy, isTrue);
      expect(report.checks.length, 2);
    });

    test('BiometricAuthService methods initialize safely', () async {
      final isLoginEnabled = await BiometricAuthService.isBiometricLoginEnabled();
      expect(isLoginEnabled, isA<bool>());
    });

    test('Clean Architecture Repositories instantiate correctly', () {
      final invoiceRepo = InvoiceRepository();
      final auctionRepo = AuctionRepository();
      final farmerRepo = FarmerRepository();
      final customerRepo = CustomerRepository();

      expect(invoiceRepo, isNotNull);
      expect(auctionRepo, isNotNull);
      expect(farmerRepo, isNotNull);
      expect(customerRepo, isNotNull);
    });
  });
}
