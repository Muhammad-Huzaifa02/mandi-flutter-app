import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:mandi/core/utils/pk_phone.dart';
import 'package:mandi/data/models/sms_gateway_model.dart';

/// Detailed character and segment breakdown for SMS delivery calculation.
class SmsPartInfo {
  final int charCount;
  final int partsCount;
  final bool isUnicode;
  final int maxCharsInCurrentPart;
  final int remainingCharsInPart;

  const SmsPartInfo({
    required this.charCount,
    required this.partsCount,
    required this.isUnicode,
    required this.maxCharsInCurrentPart,
    required this.remainingCharsInPart,
  });
}

/// Central SMS compilation, character segmentation, and HTTP gateway dispatcher
/// for Mandi Commission Shops and Dharam Kandas (*خودکار منڈی ایس ایم ایس سروس*).
class SmsGatewayService {
  const SmsGatewayService._();

  static final _currencyFmt = NumberFormat('#,##0', 'en_US');
  static final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  // =========================================================================
  // 1. GSM-7 & UNICODE CHARACTER ENCODING & PARTS CALCULATOR
  // =========================================================================

  /// Basic GSM 03.38 character set.
  static const String _gsm7Alphabet =
      "@£\$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞ\x1BÆæßÉ !\"#¤%&'()*+,-./0123456789:;<=>?"
      "¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà";

  /// Checks if string only contains standard GSM-7 characters.
  static bool isGsm7String(String text) {
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (!_gsm7Alphabet.contains(char)) {
        return false;
      }
    }
    return true;
  }

  /// Calculates the SMS segmentation parts based on telecom standards.
  /// GSM-7: 160 single, 153 per part for multi-part.
  /// Unicode (Urdu/Arabic/Emoji): 70 single, 67 per part for multi-part.
  static SmsPartInfo calculateParts(String message) {
    if (message.isEmpty) {
      return const SmsPartInfo(
        charCount: 0,
        partsCount: 1,
        isUnicode: false,
        maxCharsInCurrentPart: 160,
        remainingCharsInPart: 160,
      );
    }

    final isGsm = isGsm7String(message);
    final count = message.length;

    if (isGsm) {
      if (count <= 160) {
        return SmsPartInfo(
          charCount: count,
          partsCount: 1,
          isUnicode: false,
          maxCharsInCurrentPart: 160,
          remainingCharsInPart: 160 - count,
        );
      } else {
        const partCapacity = 153;
        final parts = (count / partCapacity).ceil();
        final maxCapacity = parts * partCapacity;
        return SmsPartInfo(
          charCount: count,
          partsCount: parts,
          isUnicode: false,
          maxCharsInCurrentPart: maxCapacity,
          remainingCharsInPart: maxCapacity - count,
        );
      }
    } else {
      // Unicode
      if (count <= 70) {
        return SmsPartInfo(
          charCount: count,
          partsCount: 1,
          isUnicode: true,
          maxCharsInCurrentPart: 70,
          remainingCharsInPart: 70 - count,
        );
      } else {
        const partCapacity = 67;
        final parts = (count / partCapacity).ceil();
        final maxCapacity = parts * partCapacity;
        return SmsPartInfo(
          charCount: count,
          partsCount: parts,
          isUnicode: true,
          maxCharsInCurrentPart: maxCapacity,
          remainingCharsInPart: maxCapacity - count,
        );
      }
    }
  }

  // =========================================================================
  // 2. MANDI TRANSACTIONAL MESSAGE FORMATTERS (Concise & High-Delivery GSM)
  // =========================================================================

  /// Standard Sales Invoice SMS
  static String formatInvoiceSms({
    required String shopName,
    required String invoiceNumber,
    required String customerName,
    required double grandTotal,
    required double receivedAmount,
    required double pendingBalance,
    String? cropPreview,
    String? shopPhone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Mandi Bill #$invoiceNumber');
    buffer.writeln('Customer: $customerName');
    if (cropPreview != null && cropPreview.trim().isNotEmpty) {
      buffer.writeln('Item: ${cropPreview.trim()}');
    }
    buffer.writeln(
        'Total: Rs ${_currencyFmt.format(grandTotal)} | Paid: Rs ${_currencyFmt.format(receivedAmount)}');
    buffer.writeln('Balance: Rs ${_currencyFmt.format(pendingBalance)}');
    final phoneSuffix =
        (shopPhone != null && shopPhone.isNotEmpty) ? ' ($shopPhone)' : '';
    buffer.write('Shop: $shopName$phoneSuffix');
    return buffer.toString();
  }

  /// Standard Payment Receipt SMS
  static String formatPaymentSms({
    required String shopName,
    required String receiptNumber,
    required String partyName,
    required double amountReceived,
    required double previousBalance,
    required double currentBalance,
    String paymentMethod = 'Cash',
    String? shopPhone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Payment Receipt #$receiptNumber');
    buffer.writeln(
        'Received: Rs ${_currencyFmt.format(amountReceived)} ($paymentMethod)');
    buffer.writeln('Party: $partyName');
    buffer.writeln(
        'Old Bal: Rs ${_currencyFmt.format(previousBalance)} | New Bal: Rs ${_currencyFmt.format(currentBalance)}');
    final phoneSuffix =
        (shopPhone != null && shopPhone.isNotEmpty) ? ' ($shopPhone)' : '';
    buffer.write('Shukriya, $shopName$phoneSuffix');
    return buffer.toString();
  }

  /// Auction Boli Winning Notification SMS
  static String formatBoliWinningSms({
    required String shopName,
    required String lotNumber,
    required String buyerName,
    required String commodity,
    required int bags,
    required double maunds,
    required double ratePerMaund,
    required double totalAmount,
    String? shopPhone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Boli Confirmed: Lot #$lotNumber');
    buffer.writeln('Buyer: $buyerName');
    buffer.writeln(
        '$commodity: $bags Bags (${_numberFmt.format(maunds)} Mann) @ Rs ${_currencyFmt.format(ratePerMaund)}/Mann');
    buffer.writeln('Total: Rs ${_currencyFmt.format(totalAmount)}');
    final phoneSuffix =
        (shopPhone != null && shopPhone.isNotEmpty) ? ' ($shopPhone)' : '';
    buffer.write('$shopName$phoneSuffix');
    return buffer.toString();
  }

  /// Weighbridge Kanda Scale Certificate SMS
  static String formatWeighbridgeSms({
    required String shopName,
    required String ticketNumber,
    required String vehicleNumber,
    required String partyName,
    required double grossWeightKg,
    required double tareWeightKg,
    required double netWeightKg,
    required double billableMaunds,
    String? shopPhone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Kanda Slip #$ticketNumber');
    buffer.writeln('Vehicle: $vehicleNumber | Party: $partyName');
    buffer.writeln(
        'Gross: ${_numberFmt.format(grossWeightKg)} KG | Tare: ${_numberFmt.format(tareWeightKg)} KG');
    buffer.writeln(
        'Net: ${_numberFmt.format(netWeightKg)} KG (${_numberFmt.format(billableMaunds)} Mann)');
    final phoneSuffix =
        (shopPhone != null && shopPhone.isNotEmpty) ? ' ($shopPhone)' : '';
    buffer.write('$shopName$phoneSuffix');
    return buffer.toString();
  }

  /// Farmer Advance Crop Financing Deduction SMS
  static String formatFarmerAdvanceSms({
    required String shopName,
    required String farmerName,
    required double deductedAmount,
    required double remainingBalance,
    String? lotNumber,
    String? shopPhone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Farmer Advance Deduction');
    buffer.writeln('Farmer: $farmerName');
    final lotSuffix =
        (lotNumber != null && lotNumber.isNotEmpty) ? ' from Lot #$lotNumber' : '';
    buffer.writeln('Deducted: Rs ${_currencyFmt.format(deductedAmount)}$lotSuffix');
    buffer.writeln(
        'Remaining Loan: Rs ${_currencyFmt.format(remainingBalance)}');
    final phoneSuffix =
        (shopPhone != null && shopPhone.isNotEmpty) ? ' ($shopPhone)' : '';
    buffer.write('$shopName$phoneSuffix');
    return buffer.toString();
  }

  // =========================================================================
  // 3. GATEWAY DISPATCH CLIENT (Twilio, Generic HTTP, Pak Telco, Mock)
  // =========================================================================

  /// Executes actual SMS transmission to telecom gateways.
  static Future<SmsDispatchResult> dispatchSms({
    required SmsGatewaySettings settings,
    required String toPhone,
    required String message,
    http.Client? client,
  }) async {
    if (!settings.isEnabled && settings.provider != SmsProviderType.mock) {
      return const SmsDispatchResult(
        success: false,
        errorMessage: 'SMS Gateway is currently disabled in shop settings.',
      );
    }

    if (toPhone.trim().isEmpty) {
      return const SmsDispatchResult(
        success: false,
        errorMessage: 'Recipient phone number cannot be empty.',
      );
    }

    // Format phone number to clean E.164 (+923001234567) or fallback to sanitized digits
    final normalizedPhone = PkPhone.toE164(toPhone) ??
        (toPhone.startsWith('+') ? toPhone.replaceAll(RegExp(r'\s+'), '') : '+92${toPhone.replaceAll(RegExp(r'\D'), '')}');

    // ── A. Mock Simulator ──────────────────────────────────────────────────
    if (settings.provider == SmsProviderType.mock) {
      final mockId = 'MOCK-SMS-${DateTime.now().millisecondsSinceEpoch}';
      return SmsDispatchResult(
        success: true,
        messageId: mockId,
        statusCode: 200,
      );
    }

    final httpClient = client ?? http.Client();

    try {
      // ── B. Twilio REST API ───────────────────────────────────────────────
      if (settings.provider == SmsProviderType.twilio) {
        if (settings.accountSid.isEmpty ||
            settings.apiSecret.isEmpty ||
            settings.fromNumber.isEmpty) {
          return const SmsDispatchResult(
            success: false,
            errorMessage:
                'Twilio credentials incomplete (Account SID, Auth Token, or From Number missing).',
          );
        }

        final url = Uri.parse(
          'https://api.twilio.com/2010-04-01/Accounts/${settings.accountSid}/Messages.json',
        );

        final authHeader =
            'Basic ${base64Encode(utf8.encode('${settings.accountSid}:${settings.apiSecret}'))}';

        final response = await httpClient.post(
          url,
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'To': normalizedPhone,
            'From': settings.fromNumber,
            'Body': message,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final sid = data['sid']?.toString() ?? 'TWILIO-SENT';
          return SmsDispatchResult(
            success: true,
            messageId: sid,
            statusCode: response.statusCode,
          );
        } else {
          String err = 'Twilio error: ${response.statusCode}';
          try {
            final data = jsonDecode(response.body);
            if (data['message'] != null) err = data['message'].toString();
          } catch (_) {}
          return SmsDispatchResult(
            success: false,
            errorMessage: err,
            statusCode: response.statusCode,
          );
        }
      }

      // ── C. Generic HTTP Webhook & Pakistan Telco API ─────────────────────
      if (settings.provider == SmsProviderType.genericHttp ||
          settings.provider == SmsProviderType.telcoPakistan) {
        if (settings.webhookUrl.trim().isEmpty) {
          return const SmsDispatchResult(
            success: false,
            errorMessage: 'Gateway Webhook API URL is not configured.',
          );
        }

        // Variable interpolation in URL & Payload
        final sender =
            settings.senderId.isNotEmpty ? settings.senderId : 'MANDI-ERP';
        final cleanLocalPhone = PkPhone.toLocalDisplay(toPhone).replaceAll(RegExp(r'\s+|-'), '');

        String finalUrl = settings.webhookUrl
            .replaceAll('{to}', normalizedPhone)
            .replaceAll('{local_to}', cleanLocalPhone)
            .replaceAll('{message}', Uri.encodeComponent(message))
            .replaceAll('{sender}', Uri.encodeComponent(sender))
            .replaceAll('{api_key}', settings.apiKey);

        final uri = Uri.parse(finalUrl);

        http.Response response;

        if (settings.httpMethod.toUpperCase() == 'GET') {
          response = await httpClient.get(
            uri,
            headers: settings.httpHeaders,
          );
        } else {
          // POST
          final escapedMsg = jsonEncode(message);
          // strip leading and trailing double quotes from jsonEncode
          final unquotedMsg = escapedMsg.substring(1, escapedMsg.length - 1);

          String body = settings.httpPayloadTemplate
              .replaceAll('{to}', normalizedPhone)
              .replaceAll('{local_to}', cleanLocalPhone)
              .replaceAll('{message}', unquotedMsg)
              .replaceAll('{sender}', sender)
              .replaceAll('{api_key}', settings.apiKey);

          final headers = Map<String, String>.from(settings.httpHeaders);
          if (!headers.containsKey('Content-Type')) {
            headers['Content-Type'] = 'application/json';
          }

          response = await httpClient.post(
            uri,
            headers: headers,
            body: body,
          );
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          String msgId = 'HTTP-${DateTime.now().millisecondsSinceEpoch}';
          try {
            final data = jsonDecode(response.body);
            if (data is Map && data['id'] != null) {
              msgId = data['id'].toString();
            } else if (data is Map && data['message_id'] != null) {
              msgId = data['message_id'].toString();
            }
          } catch (_) {}

          return SmsDispatchResult(
            success: true,
            messageId: msgId,
            statusCode: response.statusCode,
          );
        } else {
          return SmsDispatchResult(
            success: false,
            errorMessage: 'Gateway response failed with HTTP ${response.statusCode}: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }

      return const SmsDispatchResult(
        success: false,
        errorMessage: 'Unsupported SMS Provider configured.',
      );
    } catch (e) {
      return SmsDispatchResult(
        success: false,
        errorMessage: 'Network exception during SMS dispatch: $e',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
