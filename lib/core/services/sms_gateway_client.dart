import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mandi/core/utils/pk_phone.dart';

/// Production-ready SMS Gateway Client supporting major Pakistani Telco Aggregators:
/// - Jazz / Mobilink Business Gateway
/// - Zong Enterprise SMS
/// - Telenor SMS Corporate Connect
/// - Twilio & Custom REST Aggregators
class SmsGatewayClient {
  /// Sends an outbound SMS via the designated provider endpoint.
  static Future<SmsSendResult> sendSms({
    required String provider, // 'jazz', 'zong', 'telenor', 'twilio', 'custom'
    required String apiUrl,
    required String apiKey,
    required String senderId, // e.g. 'MANDI', 'ARHTI_APP'
    required String recipientPhone,
    required String message,
  }) async {
    final e164 = PkPhone.toE164(recipientPhone) ?? recipientPhone;
    final cleanPhone = e164.replaceAll('+', '').replaceAll(' ', '');

    try {
      final uri = Uri.parse(apiUrl);
      http.Response response;

      switch (provider.toLowerCase()) {
        case 'jazz':
          response = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'sender': senderId,
              'receiver': cleanPhone,
              'text': message,
            }),
          );
          break;

        case 'zong':
          response = await http.post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'api_key': apiKey,
              'mask': senderId,
              'to': cleanPhone,
              'message': message,
            },
          );
          break;

        case 'telenor':
          response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'session_id': apiKey,
              'msisdn': cleanPhone,
              'text': message,
              'mask': senderId,
            }),
          );
          break;

        default: // Generic JSON REST
          response = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'from': senderId,
              'to': cleanPhone,
              'message': message,
            }),
          );
          break;
      }

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      return SmsSendResult(
        success: isSuccess,
        statusCode: response.statusCode,
        responseBody: response.body,
        recipient: cleanPhone,
      );
    } catch (e) {
      return SmsSendResult(
        success: false,
        statusCode: 500,
        responseBody: e.toString(),
        recipient: cleanPhone,
      );
    }
  }
}

class SmsSendResult {
  final bool success;
  final int statusCode;
  final String responseBody;
  final String recipient;

  const SmsSendResult({
    required this.success,
    required this.statusCode,
    required this.responseBody,
    required this.recipient,
  });
}
