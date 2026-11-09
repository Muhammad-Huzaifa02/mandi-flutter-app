import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/utils/recovery_messaging_service.dart';

void main() {
  group('RecoveryMessagingService Tests', () {
    test('formats Urdu polite reminder with correct variables', () {
      final message = RecoveryMessagingService.formatRecoveryMessage(
        customerName: 'Haji Aslam',
        pendingBalance: 125000.0,
        shopName: 'Al-Rehman Commission Shop',
        shopPhone: '03001234567',
        shopCity: 'Multan',
        tone: ReminderTone.polite,
        language: ReminderLanguage.urdu,
      );

      expect(message, contains('Haji Aslam'));
      expect(message, contains('125000'));
      expect(message, contains('Al-Rehman Commission Shop'));
      expect(message, contains('شائستہ یاد دہانی'));
      expect(message, contains('Multan'));
      expect(message, contains('03001234567'));
    });

    test('formats Urdu urgent notice with immediate payment call to action', () {
      final message = RecoveryMessagingService.formatRecoveryMessage(
        customerName: 'Babu Khan',
        pendingBalance: 450000.0,
        shopName: 'Ittifaq Traders',
        tone: ReminderTone.urgent,
        language: ReminderLanguage.urdu,
      );

      expect(message, contains('Babu Khan'));
      expect(message, contains('450000'));
      expect(message, contains('اہم و فوری نوٹس'));
      expect(message, contains('آج ہی رابطہ کر کے بقایا جات کلیئر فرمائیں'));
    });

    test('formats English formal notice with bank and Raast details', () {
      final message = RecoveryMessagingService.formatRecoveryMessage(
        customerName: 'Malik Tariq',
        pendingBalance: 75000.0,
        shopName: 'Punjab Grain Market',
        tone: ReminderTone.formal,
        language: ReminderLanguage.english,
        bankName: 'Meezan Bank Ltd',
        accountTitle: 'Punjab Grain Mandi Shop',
        accountNoOrIban: 'PK12MEZN00001234567890',
        raastId: '03009988776',
      );

      expect(message, contains('Malik Tariq'));
      expect(message, contains('75000'));
      expect(message, contains('PAYMENT REMINDER NOTICE'));
      expect(message, contains('Meezan Bank Ltd'));
      expect(message, contains('Punjab Grain Mandi Shop'));
      expect(message, contains('PK12MEZN00001234567890'));
      expect(message, contains('03009988776'));
    });

    test('formats Urdu notice with online bank account info', () {
      final message = RecoveryMessagingService.formatRecoveryMessage(
        customerName: 'Chaudhry Akram',
        pendingBalance: 200000.0,
        shopName: 'Bismillah Aarth',
        tone: ReminderTone.formal,
        language: ReminderLanguage.urdu,
        bankName: 'Habib Bank Limited',
        accountTitle: 'Bismillah Aarth Mandi',
        accountNoOrIban: '0123456789',
        raastId: '03001122334',
      );

      expect(message, contains('آن لائن ادائیگی کی تفصیل:'));
      expect(message, contains('Habib Bank Limited'));
      expect(message, contains('Bismillah Aarth Mandi'));
      expect(message, contains('0123456789'));
      expect(message, contains('03001122334'));
    });
  });
}
