import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mandi/core/utils/sms_gateway_service.dart';
import 'package:mandi/data/models/sms_gateway_model.dart';
import 'package:mandi/modules/sms/providers/sms_provider.dart';

void main() {
  group('SMS Gateway Character & Segmentation Math Tests', () {
    test('calculates single-part GSM-7 character capacity correctly (<=160 chars)', () {
      const shortMsg = 'Mandi Bill #INV-001: Total Rs. 15,000. Balance: Rs. 5,000.';
      final info = SmsGatewayService.calculateParts(shortMsg);

      expect(info.isUnicode, isFalse);
      expect(info.partsCount, equals(1));
      expect(info.charCount, equals(shortMsg.length));
      expect(info.maxCharsInCurrentPart, equals(160));
      expect(info.remainingCharsInPart, equals(160 - shortMsg.length));
    });

    test('calculates multi-part GSM-7 character segmentation correctly (>160 chars)', () {
      // 170 characters of standard GSM text
      final longMsg = 'A' * 170;
      final info = SmsGatewayService.calculateParts(longMsg);

      expect(info.isUnicode, isFalse);
      // GSM multi-part capacity is 153 chars/part -> 170 chars = 2 parts
      expect(info.partsCount, equals(2));
      expect(info.charCount, equals(170));
      expect(info.maxCharsInCurrentPart, equals(306)); // 153 * 2
      expect(info.remainingCharsInPart, equals(306 - 170));
    });

    test('detects Unicode characters (Urdu text) and recalculates 70/67 limits', () {
      const urduMsg = 'محترم گاہک صاحب، آپ کا منڈی بل تیار ہے۔';
      final info = SmsGatewayService.calculateParts(urduMsg);

      expect(info.isUnicode, isTrue);
      expect(info.partsCount, equals(1));
      expect(info.charCount, equals(urduMsg.length));
      expect(info.maxCharsInCurrentPart, equals(70));
      expect(info.remainingCharsInPart, equals(70 - urduMsg.length));
    });

    test('calculates multi-part Unicode segmentation correctly (>70 chars)', () {
      final longUrdu = 'آپ کا منڈی بل تیار ہے۔ برائے مہربانی فوری رابطہ کر کے کھاتہ کلیئر فرمائیں تاکہ مستقبل کا کاروبار جاری رہ سکے۔ شکریہ۔' * 2;
      final info = SmsGatewayService.calculateParts(longUrdu);

      expect(info.isUnicode, isTrue);
      expect(info.partsCount, greaterThan(1));
      // Unicode multi-part capacity is 67 chars/part
      final expectedParts = (longUrdu.length / 67).ceil();
      expect(info.partsCount, equals(expectedParts));
    });
  });

  group('Transactional Mandi SMS Message Formatters', () {
    test('formats sales invoice SMS with grand total, paid, and balance', () {
      final msg = SmsGatewayService.formatInvoiceSms(
        shopName: 'Al-Madina Fruits',
        invoiceNumber: 'INV-2026-101',
        customerName: 'Haji Aslam',
        grandTotal: 154000.0,
        receivedAmount: 100000.0,
        pendingBalance: 54000.0,
        cropPreview: 'Kandahari Pomegranate (50 Crates)',
        shopPhone: '0300-1234567',
      );

      expect(msg, contains('Mandi Bill #INV-2026-101'));
      expect(msg, contains('Customer: Haji Aslam'));
      expect(msg, contains('Total: Rs 154,000 | Paid: Rs 100,000'));
      expect(msg, contains('Balance: Rs 54,000'));
      expect(msg, contains('Al-Madina Fruits (0300-1234567)'));
    });

    test('formats payment receipt SMS with running balance update', () {
      final msg = SmsGatewayService.formatPaymentSms(
        shopName: 'Bismillah Sabzi Mandi',
        receiptNumber: 'REC-902',
        partyName: 'Chaudhry Akram',
        amountReceived: 25000.0,
        previousBalance: 85000.0,
        currentBalance: 60000.0,
        paymentMethod: 'Cash',
        shopPhone: '0301-9988776',
      );

      expect(msg, contains('Payment Receipt #REC-902'));
      expect(msg, contains('Received: Rs 25,000 (Cash)'));
      expect(msg, contains('Old Bal: Rs 85,000 | New Bal: Rs 60,000'));
      expect(msg, contains('Bismillah Sabzi Mandi'));
    });

    test('formats auction Boli winning bid SMS', () {
      final msg = SmsGatewayService.formatBoliWinningSms(
        shopName: 'Punjab Commission Shop',
        lotNumber: 'LOT-441',
        buyerName: 'Malik Tariq',
        commodity: 'Fresh Grapes',
        bags: 100,
        maunds: 125.0,
        ratePerMaund: 4500.0,
        totalAmount: 562500.0,
      );

      expect(msg, contains('Boli Confirmed: Lot #LOT-441'));
      expect(msg, contains('Buyer: Malik Tariq'));
      expect(msg, contains('100 Bags (125.00 Mann) @ Rs 4,500/Mann'));
      expect(msg, contains('Total: Rs 562,500'));
    });

    test('formats weighbridge Kanda ticket SMS', () {
      final msg = SmsGatewayService.formatWeighbridgeSms(
        shopName: 'Ittefaq Dharam Kanda',
        ticketNumber: 'WB-0089',
        vehicleNumber: 'LES-9921',
        partyName: 'Zamindar Qasim',
        grossWeightKg: 14500.0,
        tareWeightKg: 4500.0,
        netWeightKg: 10000.0,
        billableMaunds: 250.0,
      );

      expect(msg, contains('Kanda Slip #WB-0089'));
      expect(msg, contains('Vehicle: LES-9921'));
      expect(msg, contains('Gross: 14,500.00 KG | Tare: 4,500.00 KG'));
      expect(msg, contains('Net: 10,000.00 KG (250.00 Mann)'));
    });

    test('formats farmer advance loan recovery SMS', () {
      final msg = SmsGatewayService.formatFarmerAdvanceSms(
        shopName: 'Rehman Arht Shop',
        farmerName: 'Khan Mohammad',
        deductedAmount: 40000.0,
        remainingBalance: 60000.0,
        lotNumber: 'LOT-99',
      );

      expect(msg, contains('Farmer Advance Deduction'));
      expect(msg, contains('Farmer: Khan Mohammad'));
      expect(msg, contains('Deducted: Rs 40,000 from Lot #LOT-99'));
      expect(msg, contains('Remaining Loan: Rs 60,000'));
    });
  });

  group('SMS Gateway Model & Serialization Tests', () {
    test('serializes and deserializes SmsGatewaySettings correctly', () {
      const settings = SmsGatewaySettings(
        id: 'gw-001',
        shopId: 'shop-lahore',
        provider: SmsProviderType.twilio,
        isEnabled: true,
        senderId: 'AL-MADINA',
        accountSid: 'AC1234567890abcdef',
        apiSecret: 'secret_token_123',
        fromNumber: '+14155552671',
        autoSendOnInvoice: true,
        autoSendOnPayment: true,
        autoSendOnBoli: true,
        smsCreditBalance: 2500.0,
      );

      expect(settings.isConfigured, isTrue);

      final map = settings.toMap();
      expect(map['provider'], equals('twilio'));
      expect(map['sender_id'], equals('AL-MADINA'));
      expect(map['is_enabled'], isTrue);
      expect(map['account_sid'], equals('AC1234567890abcdef'));

      final fromDb = SmsGatewaySettings.fromMap('gw-001', map);
      expect(fromDb.provider, equals(SmsProviderType.twilio));
      expect(fromDb.senderId, equals('AL-MADINA'));
      expect(fromDb.accountSid, equals('AC1234567890abcdef'));
      expect(fromDb.fromNumber, equals('+14155552671'));
      expect(fromDb.autoSendOnBoli, isTrue);
      expect(fromDb.smsCreditBalance, equals(2500.0));
    });

    test('serializes and deserializes SmsLog correctly', () {
      final now = DateTime(2026, 4, 15, 10, 30);
      final log = SmsLog(
        id: 'log-001',
        shopId: 'shop-lahore',
        recipientPhone: '+923001234567',
        recipientName: 'Haji Aslam',
        messageBody: 'Test Message Body',
        eventType: SmsEventType.invoice,
        provider: SmsProviderType.twilio,
        status: SmsDeliveryStatus.sent,
        externalMessageId: 'SM998877',
        partsCount: 1,
        costPkr: 2.50,
        createdAt: now,
      );

      final map = log.toMap();
      expect(map['event_type'], equals('invoice'));
      expect(map['status'], equals('sent'));
      expect(map['parts_count'], equals(1));
      expect(map['cost_pkr'], equals(2.50));

      final fromDb = SmsLog.fromMap('log-001', map);
      expect(fromDb.recipientPhone, equals('+923001234567'));
      expect(fromDb.status, equals(SmsDeliveryStatus.sent));
      expect(fromDb.eventType, equals(SmsEventType.invoice));
      expect(fromDb.externalMessageId, equals('SM998877'));
    });

    test('aggregates SmsSummary correctly from log items', () {
      final now = DateTime.now();
      final logs = [
        SmsLog(
          id: '1',
          shopId: 's1',
          recipientPhone: '03001',
          messageBody: 'msg1',
          status: SmsDeliveryStatus.delivered,
          partsCount: 1,
          costPkr: 2.0,
          createdAt: now,
        ),
        SmsLog(
          id: '2',
          shopId: 's1',
          recipientPhone: '03002',
          messageBody: 'msg2',
          status: SmsDeliveryStatus.sent,
          partsCount: 2,
          costPkr: 4.0,
          createdAt: now,
        ),
        SmsLog(
          id: '3',
          shopId: 's1',
          recipientPhone: '03003',
          messageBody: 'msg3',
          status: SmsDeliveryStatus.failed,
          partsCount: 1,
          costPkr: 0.0,
          createdAt: now,
        ),
      ];

      final summary = SmsSummary.fromLogs(logs);
      expect(summary.totalCount, equals(3));
      expect(summary.deliveredCount, equals(1));
      expect(summary.sentCount, equals(1));
      expect(summary.failedCount, equals(1));
      expect(summary.totalParts, equals(4));
      expect(summary.totalCostPkr, equals(6.0));
      expect(summary.todayCount, equals(3));
    });
  });

  group('HTTP Gateway Dispatcher Tests', () {
    test('dispatches mock SMS instantly with successful status', () async {
      const mockSettings = SmsGatewaySettings(
        shopId: 's1',
        provider: SmsProviderType.mock,
        isEnabled: true,
      );

      final result = await SmsGatewayService.dispatchSms(
        settings: mockSettings,
        toPhone: '03001234567',
        message: 'Hello World',
      );

      expect(result.success, isTrue);
      expect(result.messageId, startsWith('MOCK-SMS-'));
      expect(result.statusCode, equals(200));
    });

    test('dispatches Twilio SMS via mock HTTP client correctly', () async {
      const twilioSettings = SmsGatewaySettings(
        shopId: 's1',
        provider: SmsProviderType.twilio,
        isEnabled: true,
        accountSid: 'AC_TEST_ACCOUNT_123',
        apiSecret: 'AUTH_SECRET_456',
        fromNumber: '+14155552671',
      );

      final mockHttpClient = MockClient((request) async {
        expect(request.url.toString(), contains('api.twilio.com/2010-04-01/Accounts/AC_TEST_ACCOUNT_123/Messages.json'));
        expect(request.method, equals('POST'));
        expect(request.bodyFields['From'], equals('+14155552671'));
        expect(request.bodyFields['To'], equals('+923001234567'));
        expect(request.bodyFields['Body'], equals('Mandi Bill Test'));

        return http.Response(
          jsonEncode({
            'sid': 'SM1234567890abcdef',
            'status': 'queued',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await SmsGatewayService.dispatchSms(
        settings: twilioSettings,
        toPhone: '03001234567',
        message: 'Mandi Bill Test',
        client: mockHttpClient,
      );

      expect(result.success, isTrue);
      expect(result.messageId, equals('SM1234567890abcdef'));
      expect(result.statusCode, equals(201));
    });

    test('dispatches Generic HTTP Webhook with parameter interpolation', () async {
      const webhookSettings = SmsGatewaySettings(
        shopId: 's1',
        provider: SmsProviderType.genericHttp,
        isEnabled: true,
        senderId: 'AL-REHMAN',
        apiKey: 'SECRET-API-KEY-99',
        webhookUrl: 'https://api.gateway.pk/v1/sms/send?apiKey={api_key}',
        httpMethod: 'POST',
        httpPayloadTemplate: '{"to": "{to}", "message": "{message}", "sender": "{sender}"}',
      );

      final mockHttpClient = MockClient((request) async {
        expect(request.url.queryParameters['apiKey'], equals('SECRET-API-KEY-99'));
        expect(request.headers['Content-Type'], equals('application/json'));

        final body = jsonDecode(request.body);
        expect(body['to'], equals('+923007654321'));
        expect(body['sender'], equals('AL-REHMAN'));
        expect(body['message'], equals('Generic Mandi Message'));

        return http.Response(
          jsonEncode({'id': 'TELCO-MSG-8877', 'status': 'success'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await SmsGatewayService.dispatchSms(
        settings: webhookSettings,
        toPhone: '03007654321',
        message: 'Generic Mandi Message',
        client: mockHttpClient,
      );

      expect(result.success, isTrue);
      expect(result.messageId, equals('TELCO-MSG-8877'));
      expect(result.statusCode, equals(200));
    });
  });

  group('SmsProvider State Management Tests', () {
    test('filters logs accurately by status, event type, and search query', () {
      final provider = SmsProvider();

      // Test default state
      expect(provider.allLogs, isEmpty);
      expect(provider.filteredLogs, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.statusFilter, isNull);

      provider.setSearchQuery('aslam');
      expect(provider.searchQuery, equals('aslam'));

      provider.setStatusFilter('failed');
      expect(provider.statusFilter, equals('failed'));

      provider.setEventFilter(SmsEventType.invoice);
      expect(provider.eventFilter, equals(SmsEventType.invoice));

      provider.resetFilters();
      expect(provider.searchQuery, isEmpty);
      expect(provider.statusFilter, isNull);
      expect(provider.eventFilter, isNull);
    });
  });
}
