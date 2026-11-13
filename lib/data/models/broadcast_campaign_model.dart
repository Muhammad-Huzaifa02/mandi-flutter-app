import 'dart:convert';

/// Delivery platform channel
enum BroadcastChannel {
  whatsapp,
  telegram,
  both;

  String get value => name;

  String get labelEn {
    switch (this) {
      case BroadcastChannel.whatsapp:
        return 'WhatsApp Business API';
      case BroadcastChannel.telegram:
        return 'Telegram Broadcast Channel';
      case BroadcastChannel.both:
        return 'Both (WhatsApp & Telegram)';
    }
  }

  String get labelUr {
    switch (this) {
      case BroadcastChannel.whatsapp:
        return 'واٹس ایپ براڈکاسٹ';
      case BroadcastChannel.telegram:
        return 'ٹیلیگرام چینل';
      case BroadcastChannel.both:
        return 'دونوں (واٹس ایپ اور ٹیلیگرام)';
    }
  }

  static BroadcastChannel fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'whatsapp':
        return BroadcastChannel.whatsapp;
      case 'telegram':
        return BroadcastChannel.telegram;
      case 'both':
      default:
        return BroadcastChannel.both;
    }
  }
}

/// Recipient audience segment
enum AudienceType {
  allFarmers,
  allBuyers,
  commissionAgents,
  transporters,
  custom;

  String get value {
    switch (this) {
      case AudienceType.allFarmers:
        return 'all_farmers';
      case AudienceType.allBuyers:
        return 'all_buyers';
      case AudienceType.commissionAgents:
        return 'commission_agents';
      case AudienceType.transporters:
        return 'transporters';
      case AudienceType.custom:
        return 'custom';
    }
  }

  String get labelEn {
    switch (this) {
      case AudienceType.allFarmers:
        return 'Registered Farmers';
      case AudienceType.allBuyers:
        return 'Millers & Buyers';
      case AudienceType.commissionAgents:
        return 'Commission Agents';
      case AudienceType.transporters:
        return 'Transporters & Drivers';
      case AudienceType.custom:
        return 'Custom Contact List';
    }
  }

  String get labelUr {
    switch (this) {
      case AudienceType.allFarmers:
        return 'تمام رجسٹرڈ زمیندار';
      case AudienceType.allBuyers:
        return 'تمام خریدار و مل مالکان';
      case AudienceType.commissionAgents:
        return 'کمیشن ایجنٹس و آڑھتی';
      case AudienceType.transporters:
        return 'ٹرانسپورٹرز و ڈرائیورز';
      case AudienceType.custom:
        return 'مخصوص منتخب افراد';
    }
  }

  static AudienceType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'all_farmers':
      case 'allfarmers':
        return AudienceType.allFarmers;
      case 'all_buyers':
      case 'allbuyers':
        return AudienceType.allBuyers;
      case 'commission_agents':
      case 'commissionagents':
        return AudienceType.commissionAgents;
      case 'transporters':
        return AudienceType.transporters;
      case 'custom':
      default:
        return AudienceType.custom;
    }
  }
}

/// Template category for the broadcast bulletin
enum TemplateType {
  dailyRates,
  boliAlert,
  khataReminder,
  customAnnouncement;

  String get value {
    switch (this) {
      case TemplateType.dailyRates:
        return 'daily_rates';
      case TemplateType.boliAlert:
        return 'boli_alert';
      case TemplateType.khataReminder:
        return 'khata_reminder';
      case TemplateType.customAnnouncement:
        return 'custom_announcement';
    }
  }

  String get labelEn {
    switch (this) {
      case TemplateType.dailyRates:
        return 'Daily Mandi Bhav Rates';
      case TemplateType.boliAlert:
        return 'Live Auction (Boli) Alert';
      case TemplateType.khataReminder:
        return 'Farmer Khata Statement Reminder';
      case TemplateType.customAnnouncement:
        return 'Mandi Committee Announcement';
    }
  }

  String get labelUr {
    switch (this) {
      case TemplateType.dailyRates:
        return 'روزانہ منڈی ریٹ لسٹ (بھاؤ)';
      case TemplateType.boliAlert:
        return 'لائیو بولی و نیلامی اطلاع';
      case TemplateType.khataReminder:
        return 'کھاتہ بقایا رقم یاد دہانی';
      case TemplateType.customAnnouncement:
        return 'منڈی کمیٹی عمومی اعلان';
    }
  }

  static TemplateType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'daily_rates':
      case 'dailyrates':
        return TemplateType.dailyRates;
      case 'boli_alert':
      case 'bolialert':
        return TemplateType.boliAlert;
      case 'khata_reminder':
      case 'khatareminder':
        return TemplateType.khataReminder;
      case 'custom_announcement':
      default:
        return TemplateType.customAnnouncement;
    }
  }
}

/// Lifecycle delivery status of campaign
enum BroadcastStatus {
  draft,
  scheduled,
  sending,
  sent,
  failed;

  String get value => name;

  String get labelEn {
    switch (this) {
      case BroadcastStatus.draft:
        return 'Draft Bulletin';
      case BroadcastStatus.scheduled:
        return 'Scheduled for Dispatch';
      case BroadcastStatus.sending:
        return 'Broadcasting in Progress...';
      case BroadcastStatus.sent:
        return 'Delivered Successfully';
      case BroadcastStatus.failed:
        return 'Broadcast Failed';
    }
  }

  String get labelUr {
    switch (this) {
      case BroadcastStatus.draft:
        return 'ڈرافٹ پیغام';
      case BroadcastStatus.scheduled:
        return 'شیڈول شدہ';
      case BroadcastStatus.sending:
        return 'ارسال ہو رہا ہے...';
      case BroadcastStatus.sent:
        return 'کامیابی سے ترسیل شدہ';
      case BroadcastStatus.failed:
        return 'ترسیل ناکام';
    }
  }

  static BroadcastStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'scheduled':
        return BroadcastStatus.scheduled;
      case 'sending':
        return BroadcastStatus.sending;
      case 'sent':
        return BroadcastStatus.sent;
      case 'failed':
        return BroadcastStatus.failed;
      case 'draft':
      default:
        return BroadcastStatus.draft;
    }
  }
}

/// Broadcast Campaign domain model
class BroadcastCampaign {
  final String id;
  final String shopId;
  final String title;
  final BroadcastChannel channel;
  final AudienceType audienceType;
  final TemplateType templateType;
  final String messageBody;
  final int totalRecipients;
  final int deliveredCount;
  final int failedCount;
  final BroadcastStatus status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final Map<String, dynamic> metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BroadcastCampaign({
    required this.id,
    required this.shopId,
    required this.title,
    this.channel = BroadcastChannel.both,
    this.audienceType = AudienceType.allFarmers,
    this.templateType = TemplateType.dailyRates,
    required this.messageBody,
    this.totalRecipients = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.status = BroadcastStatus.draft,
    this.scheduledAt,
    this.sentAt,
    this.metadata = const {},
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  double get deliveryRatePercentage {
    if (totalRecipients <= 0) return 0.0;
    return (deliveredCount / totalRecipients) * 100.0;
  }

  /// Generates a direct WhatsApp link for one-tap opening in WhatsApp Web or Mobile
  String generateWhatsAppUrl(String phone) {
    final cleanPhone = standardizePakistanPhone(phone);
    final encodedMsg = Uri.encodeComponent(messageBody);
    return 'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMsg';
  }

  /// Generates a Telegram channel share URL
  String generateTelegramShareUrl() {
    final encodedMsg = Uri.encodeComponent(messageBody);
    return 'https://t.me/share/url?url=&text=$encodedMsg';
  }

  static String standardizePakistanPhone(String input) {
    String clean = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('03')) {
      clean = '92${clean.substring(1)}';
    } else if (clean.startsWith('3') && clean.length == 10) {
      clean = '92$clean';
    } else if (!clean.startsWith('92') && clean.isNotEmpty) {
      clean = '92$clean';
    }
    return clean;
  }

  BroadcastCampaign copyWith({
    String? id,
    String? shopId,
    String? title,
    BroadcastChannel? channel,
    AudienceType? audienceType,
    TemplateType? templateType,
    String? messageBody,
    int? totalRecipients,
    int? deliveredCount,
    int? failedCount,
    BroadcastStatus? status,
    DateTime? scheduledAt,
    DateTime? sentAt,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BroadcastCampaign(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      title: title ?? this.title,
      channel: channel ?? this.channel,
      audienceType: audienceType ?? this.audienceType,
      templateType: templateType ?? this.templateType,
      messageBody: messageBody ?? this.messageBody,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      failedCount: failedCount ?? this.failedCount,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'title': title,
      'channel': channel.value,
      'audience_type': audienceType.value,
      'template_type': templateType.value,
      'message_body': messageBody,
      'total_recipients': totalRecipients,
      'delivered_count': deliveredCount,
      'failed_count': failedCount,
      'status': status.value,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BroadcastCampaign.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedMeta = {};
    if (map['metadata'] is Map) {
      parsedMeta = Map<String, dynamic>.from(map['metadata'] as Map);
    } else if (map['metadata'] is String) {
      try {
        parsedMeta = jsonDecode(map['metadata'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return BroadcastCampaign(
      id: map['id']?.toString() ?? '',
      shopId: map['shop_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      channel: BroadcastChannel.fromString(map['channel']?.toString() ?? ''),
      audienceType: AudienceType.fromString(map['audience_type']?.toString() ?? ''),
      templateType: TemplateType.fromString(map['template_type']?.toString() ?? ''),
      messageBody: map['message_body']?.toString() ?? '',
      totalRecipients: (map['total_recipients'] as num?)?.toInt() ?? 0,
      deliveredCount: (map['delivered_count'] as num?)?.toInt() ?? 0,
      failedCount: (map['failed_count'] as num?)?.toInt() ?? 0,
      status: BroadcastStatus.fromString(map['status']?.toString() ?? ''),
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.tryParse(map['scheduled_at'].toString())
          : null,
      sentAt: map['sent_at'] != null
          ? DateTime.tryParse(map['sent_at'].toString())
          : null,
      metadata: parsedMeta,
      createdBy: map['created_by']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Subscriber directory entry for broadcast dissemination
class BroadcastSubscriber {
  final String id;
  final String shopId;
  final String name;
  final String phoneOrChatId;
  final BroadcastChannel platform;
  final String subscriberType;
  final bool isActive;
  final String notes;
  final DateTime createdAt;

  const BroadcastSubscriber({
    required this.id,
    required this.shopId,
    required this.name,
    required this.phoneOrChatId,
    this.platform = BroadcastChannel.whatsapp,
    this.subscriberType = 'farmer',
    this.isActive = true,
    this.notes = '',
    required this.createdAt,
  });

  String get formattedPlatform {
    switch (platform) {
      case BroadcastChannel.whatsapp:
        return 'WhatsApp';
      case BroadcastChannel.telegram:
        return 'Telegram';
      case BroadcastChannel.both:
        return 'WhatsApp + Telegram';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'phone_or_chat_id': phoneOrChatId,
      'platform': platform.value,
      'subscriber_type': subscriberType,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BroadcastSubscriber.fromMap(Map<String, dynamic> map) {
    return BroadcastSubscriber(
      id: map['id']?.toString() ?? '',
      shopId: map['shop_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phoneOrChatId: map['phone_or_chat_id']?.toString() ?? '',
      platform: BroadcastChannel.fromString(map['platform']?.toString() ?? ''),
      subscriberType: map['subscriber_type']?.toString() ?? 'farmer',
      isActive: map['is_active'] == true || map['is_active'] == 1,
      notes: map['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
