import 'dart:convert';

/// Supported SMS Gateway Providers for Mandi Commission Shops.
enum SmsProviderType {
  mock, // Simulation & offline testing
  twilio, // Twilio REST API (International standard)
  genericHttp, // Generic HTTP Webhook (Local Pakistani aggregators e.g., Telenor, Jazz, Zong, Infobip)
  telcoPakistan; // Direct Telco Branded Shortcode API

  String get labelEnglish {
    switch (this) {
      case SmsProviderType.mock:
        return 'Mock Simulator (Offline / Test)';
      case SmsProviderType.twilio:
        return 'Twilio Cloud SMS';
      case SmsProviderType.genericHttp:
        return 'Generic HTTP Gateway / Telco API';
      case SmsProviderType.telcoPakistan:
        return 'Pakistan Telco Branded SMS';
    }
  }

  String get labelUrdu {
    switch (this) {
      case SmsProviderType.mock:
        return 'فرضی ٹیسٹ سمیلیٹر';
      case SmsProviderType.twilio:
        return 'ٹوئیلیو ایس ایم ایس';
      case SmsProviderType.genericHttp:
        return 'لوکل پاکستانی ایس ایم ایس گیٹ وے';
      case SmsProviderType.telcoPakistan:
        return 'ٹیلکو برانڈڈ شارٹ کوڈ';
    }
  }

  static SmsProviderType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'twilio':
        return SmsProviderType.twilio;
      case 'generic_http':
      case 'generichttp':
        return SmsProviderType.genericHttp;
      case 'telco_pakistan':
      case 'telcopakistan':
        return SmsProviderType.telcoPakistan;
      case 'mock':
      default:
        return SmsProviderType.mock;
    }
  }

  String toDbString() {
    switch (this) {
      case SmsProviderType.mock:
        return 'mock';
      case SmsProviderType.twilio:
        return 'twilio';
      case SmsProviderType.genericHttp:
        return 'generic_http';
      case SmsProviderType.telcoPakistan:
        return 'telco_pakistan';
    }
  }
}

/// Mandi transactional events triggering automated SMS dispatch.
enum SmsEventType {
  invoice,
  payment,
  boli,
  weighbridge,
  farmerAdvance,
  recoveryReminder,
  manualTest;

  String get labelEnglish {
    switch (this) {
      case SmsEventType.invoice:
        return 'Sales Invoice';
      case SmsEventType.payment:
        return 'Payment Receipt';
      case SmsEventType.boli:
        return 'Auction Winning Bid';
      case SmsEventType.weighbridge:
        return 'Weighbridge Kanda';
      case SmsEventType.farmerAdvance:
        return 'Farmer Advance / Loan';
      case SmsEventType.recoveryReminder:
        return 'Payment Recovery Reminder';
      case SmsEventType.manualTest:
        return 'Manual / Test Message';
    }
  }

  String get labelUrdu {
    switch (this) {
      case SmsEventType.invoice:
        return 'سیلز بل رسید';
      case SmsEventType.payment:
        return 'وصولی پرچہ';
      case SmsEventType.boli:
        return 'بولی کامیابی پرچہ';
      case SmsEventType.weighbridge:
        return 'دھرم کنڈا پرچی';
      case SmsEventType.farmerAdvance:
        return 'زمیندار ایڈوانس کٹوتی';
      case SmsEventType.recoveryReminder:
        return 'تقاضا کھاتہ پیغام';
      case SmsEventType.manualTest:
        return 'ٹیسٹ پیغام';
    }
  }

  static SmsEventType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'invoice':
        return SmsEventType.invoice;
      case 'payment':
        return SmsEventType.payment;
      case 'boli':
        return SmsEventType.boli;
      case 'weighbridge':
        return SmsEventType.weighbridge;
      case 'farmer_advance':
      case 'farmeradvance':
        return SmsEventType.farmerAdvance;
      case 'recovery_reminder':
      case 'recoveryreminder':
        return SmsEventType.recoveryReminder;
      case 'manual_test':
      case 'manualtest':
      default:
        return SmsEventType.manualTest;
    }
  }

  String toDbString() {
    switch (this) {
      case SmsEventType.invoice:
        return 'invoice';
      case SmsEventType.payment:
        return 'payment';
      case SmsEventType.boli:
        return 'boli';
      case SmsEventType.weighbridge:
        return 'weighbridge';
      case SmsEventType.farmerAdvance:
        return 'farmer_advance';
      case SmsEventType.recoveryReminder:
        return 'recovery_reminder';
      case SmsEventType.manualTest:
        return 'manual_test';
    }
  }
}

/// Real-time delivery status of dispatched SMS messages.
enum SmsDeliveryStatus {
  pending,
  sent,
  delivered,
  failed;

  String get labelEnglish {
    switch (this) {
      case SmsDeliveryStatus.pending:
        return 'Pending';
      case SmsDeliveryStatus.sent:
        return 'Sent';
      case SmsDeliveryStatus.delivered:
        return 'Delivered';
      case SmsDeliveryStatus.failed:
        return 'Failed';
    }
  }

  String get labelUrdu {
    switch (this) {
      case SmsDeliveryStatus.pending:
        return 'زیر انتظار';
      case SmsDeliveryStatus.sent:
        return 'ارسال شدہ';
      case SmsDeliveryStatus.delivered:
        return 'موصول شدہ';
      case SmsDeliveryStatus.failed:
        return 'ناکام';
    }
  }

  static SmsDeliveryStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'sent':
        return SmsDeliveryStatus.sent;
      case 'delivered':
        return SmsDeliveryStatus.delivered;
      case 'failed':
        return SmsDeliveryStatus.failed;
      case 'pending':
      default:
        return SmsDeliveryStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case SmsDeliveryStatus.pending:
        return 'pending';
      case SmsDeliveryStatus.sent:
        return 'sent';
      case SmsDeliveryStatus.delivered:
        return 'delivered';
      case SmsDeliveryStatus.failed:
        return 'failed';
    }
  }
}

/// Configuration settings for a Shop's automated SMS Gateway integration.
class SmsGatewaySettings {
  final String id;
  final String shopId;
  final SmsProviderType provider;
  final bool isEnabled;
  final String senderId; // Mask or sender number e.g. AL-REHMAN / MANDI-ERP
  final String apiKey;
  final String apiSecret; // Twilio Auth Token or Gateway Secret
  final String accountSid; // Twilio Account SID or Gateway Username
  final String fromNumber; // Twilio Number e.g. +14155552671
  final String webhookUrl; // Custom HTTP Endpoint URL
  final String httpMethod; // 'POST' or 'GET'
  final Map<String, String> httpHeaders;
  final String httpPayloadTemplate; // Template JSON with {to}, {message}, {sender}
  final bool autoSendOnInvoice;
  final bool autoSendOnPayment;
  final bool autoSendOnBoli;
  final bool autoSendOnWeighbridge;
  final bool autoSendOnAdvance;
  final double smsCreditBalance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SmsGatewaySettings({
    this.id = '',
    required this.shopId,
    this.provider = SmsProviderType.mock,
    this.isEnabled = false,
    this.senderId = 'MANDI-ERP',
    this.apiKey = '',
    this.apiSecret = '',
    this.accountSid = '',
    this.fromNumber = '',
    this.webhookUrl = '',
    this.httpMethod = 'POST',
    this.httpHeaders = const {},
    this.httpPayloadTemplate = '{"to": "{to}", "message": "{message}", "sender": "{sender}"}',
    this.autoSendOnInvoice = true,
    this.autoSendOnPayment = true,
    this.autoSendOnBoli = false,
    this.autoSendOnWeighbridge = false,
    this.autoSendOnAdvance = false,
    this.smsCreditBalance = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  /// True if required credentials for the chosen provider are populated.
  bool get isConfigured {
    switch (provider) {
      case SmsProviderType.mock:
        return true;
      case SmsProviderType.twilio:
        return accountSid.trim().isNotEmpty &&
            apiSecret.trim().isNotEmpty &&
            fromNumber.trim().isNotEmpty;
      case SmsProviderType.genericHttp:
      case SmsProviderType.telcoPakistan:
        return webhookUrl.trim().isNotEmpty;
    }
  }

  factory SmsGatewaySettings.defaultSettings(String shopId) {
    return SmsGatewaySettings(
      shopId: shopId,
      provider: SmsProviderType.mock,
      isEnabled: false,
      senderId: 'MANDI-ERP',
    );
  }

  factory SmsGatewaySettings.fromMap(String id, Map<String, dynamic> map) {
    Map<String, String> parsedHeaders = {};
    if (map['http_headers_json'] != null) {
      if (map['http_headers_json'] is Map) {
        parsedHeaders = (map['http_headers_json'] as Map).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
      } else if (map['http_headers_json'] is String) {
        try {
          final decoded = jsonDecode(map['http_headers_json'] as String);
          if (decoded is Map) {
            parsedHeaders = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        } catch (_) {}
      }
    }

    return SmsGatewaySettings(
      id: id,
      shopId: map['shop_id']?.toString() ?? '',
      provider: SmsProviderType.fromString(map['provider']?.toString() ?? 'mock'),
      isEnabled: map['is_enabled'] == true,
      senderId: map['sender_id']?.toString() ?? 'MANDI-ERP',
      apiKey: map['api_key']?.toString() ?? '',
      apiSecret: map['api_secret']?.toString() ?? '',
      accountSid: map['account_sid']?.toString() ?? '',
      fromNumber: map['from_number']?.toString() ?? '',
      webhookUrl: map['webhook_url']?.toString() ?? '',
      httpMethod: map['http_method']?.toString() ?? 'POST',
      httpHeaders: parsedHeaders,
      httpPayloadTemplate: map['http_payload_template']?.toString() ??
          '{"to": "{to}", "message": "{message}", "sender": "{sender}"}',
      autoSendOnInvoice: map['auto_send_on_invoice'] ?? true,
      autoSendOnPayment: map['auto_send_on_payment'] ?? true,
      autoSendOnBoli: map['auto_send_on_boli'] ?? false,
      autoSendOnWeighbridge: map['auto_send_on_weighbridge'] ?? false,
      autoSendOnAdvance: map['auto_send_on_advance'] ?? false,
      smsCreditBalance: (map['sms_credit_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'provider': provider.toDbString(),
      'is_enabled': isEnabled,
      'sender_id': senderId,
      'api_key': apiKey,
      'api_secret': apiSecret,
      'account_sid': accountSid,
      'from_number': fromNumber,
      'webhook_url': webhookUrl,
      'http_method': httpMethod,
      'http_headers_json': httpHeaders,
      'http_payload_template': httpPayloadTemplate,
      'auto_send_on_invoice': autoSendOnInvoice,
      'auto_send_on_payment': autoSendOnPayment,
      'auto_send_on_boli': autoSendOnBoli,
      'auto_send_on_weighbridge': autoSendOnWeighbridge,
      'auto_send_on_advance': autoSendOnAdvance,
      'sms_credit_balance': smsCreditBalance,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  SmsGatewaySettings copyWith({
    String? id,
    String? shopId,
    SmsProviderType? provider,
    bool? isEnabled,
    String? senderId,
    String? apiKey,
    String? apiSecret,
    String? accountSid,
    String? fromNumber,
    String? webhookUrl,
    String? httpMethod,
    Map<String, String>? httpHeaders,
    String? httpPayloadTemplate,
    bool? autoSendOnInvoice,
    bool? autoSendOnPayment,
    bool? autoSendOnBoli,
    bool? autoSendOnWeighbridge,
    bool? autoSendOnAdvance,
    double? smsCreditBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmsGatewaySettings(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      provider: provider ?? this.provider,
      isEnabled: isEnabled ?? this.isEnabled,
      senderId: senderId ?? this.senderId,
      apiKey: apiKey ?? this.apiKey,
      apiSecret: apiSecret ?? this.apiSecret,
      accountSid: accountSid ?? this.accountSid,
      fromNumber: fromNumber ?? this.fromNumber,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      httpHeaders: httpHeaders ?? this.httpHeaders,
      httpPayloadTemplate: httpPayloadTemplate ?? this.httpPayloadTemplate,
      autoSendOnInvoice: autoSendOnInvoice ?? this.autoSendOnInvoice,
      autoSendOnPayment: autoSendOnPayment ?? this.autoSendOnPayment,
      autoSendOnBoli: autoSendOnBoli ?? this.autoSendOnBoli,
      autoSendOnWeighbridge: autoSendOnWeighbridge ?? this.autoSendOnWeighbridge,
      autoSendOnAdvance: autoSendOnAdvance ?? this.autoSendOnAdvance,
      smsCreditBalance: smsCreditBalance ?? this.smsCreditBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Audit record of an individual SMS transmission attempt.
class SmsLog {
  final String id;
  final String shopId;
  final String recipientPhone;
  final String recipientName;
  final String messageBody;
  final SmsEventType eventType;
  final SmsProviderType provider;
  final SmsDeliveryStatus status;
  final String externalMessageId;
  final String? errorMessage;
  final int partsCount;
  final double costPkr;
  final DateTime createdAt;

  const SmsLog({
    this.id = '',
    required this.shopId,
    required this.recipientPhone,
    this.recipientName = '',
    required this.messageBody,
    this.eventType = SmsEventType.manualTest,
    this.provider = SmsProviderType.mock,
    this.status = SmsDeliveryStatus.pending,
    this.externalMessageId = '',
    this.errorMessage,
    this.partsCount = 1,
    this.costPkr = 0.0,
    required this.createdAt,
  });

  factory SmsLog.fromMap(String id, Map<String, dynamic> map) {
    return SmsLog(
      id: id,
      shopId: map['shop_id']?.toString() ?? '',
      recipientPhone: map['recipient_phone']?.toString() ?? '',
      recipientName: map['recipient_name']?.toString() ?? '',
      messageBody: map['message_body']?.toString() ?? '',
      eventType: SmsEventType.fromString(map['event_type']?.toString() ?? 'manual_test'),
      provider: SmsProviderType.fromString(map['provider']?.toString() ?? 'mock'),
      status: SmsDeliveryStatus.fromString(map['status']?.toString() ?? 'pending'),
      externalMessageId: map['external_message_id']?.toString() ?? '',
      errorMessage: map['error_message']?.toString(),
      partsCount: (map['parts_count'] as num?)?.toInt() ?? 1,
      costPkr: (map['cost_pkr'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'recipient_phone': recipientPhone,
      'recipient_name': recipientName,
      'message_body': messageBody,
      'event_type': eventType.toDbString(),
      'provider': provider.toDbString(),
      'status': status.toDbString(),
      'external_message_id': externalMessageId,
      'error_message': errorMessage,
      'parts_count': partsCount,
      'cost_pkr': costPkr,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SmsLog copyWith({
    String? id,
    String? shopId,
    String? recipientPhone,
    String? recipientName,
    String? messageBody,
    SmsEventType? eventType,
    SmsProviderType? provider,
    SmsDeliveryStatus? status,
    String? externalMessageId,
    String? errorMessage,
    int? partsCount,
    double? costPkr,
    DateTime? createdAt,
  }) {
    return SmsLog(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientName: recipientName ?? this.recipientName,
      messageBody: messageBody ?? this.messageBody,
      eventType: eventType ?? this.eventType,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      externalMessageId: externalMessageId ?? this.externalMessageId,
      errorMessage: errorMessage ?? this.errorMessage,
      partsCount: partsCount ?? this.partsCount,
      costPkr: costPkr ?? this.costPkr,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Result returned from the gateway dispatcher.
class SmsDispatchResult {
  final bool success;
  final String messageId;
  final String? errorMessage;
  final int? statusCode;

  const SmsDispatchResult({
    required this.success,
    this.messageId = '',
    this.errorMessage,
    this.statusCode,
  });
}

/// Aggregated statistical overview of shop SMS communications.
class SmsSummary {
  final int totalCount;
  final int sentCount;
  final int deliveredCount;
  final int failedCount;
  final int todayCount;
  final int totalParts;
  final double totalCostPkr;

  const SmsSummary({
    this.totalCount = 0,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.todayCount = 0,
    this.totalParts = 0,
    this.totalCostPkr = 0.0,
  });

  factory SmsSummary.fromLogs(List<SmsLog> logs) {
    int sent = 0;
    int delivered = 0;
    int failed = 0;
    int today = 0;
    int parts = 0;
    double cost = 0.0;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final l in logs) {
      if (l.status == SmsDeliveryStatus.sent) sent++;
      if (l.status == SmsDeliveryStatus.delivered) delivered++;
      if (l.status == SmsDeliveryStatus.failed) failed++;
      if (l.createdAt.isAfter(todayStart)) today++;
      parts += l.partsCount;
      cost += l.costPkr;
    }

    return SmsSummary(
      totalCount: logs.length,
      sentCount: sent,
      deliveredCount: delivered,
      failedCount: failed,
      todayCount: today,
      totalParts: parts,
      totalCostPkr: cost,
    );
  }
}
