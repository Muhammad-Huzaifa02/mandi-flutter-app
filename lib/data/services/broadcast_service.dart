import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/broadcast_campaign_model.dart';
import '../models/mandi_rate_model.dart';
import 'supabase_service.dart';

/// Service for formatting, previewing, and dispatching multi-channel Mandi bulletins
class BroadcastService {
  static final BroadcastService instance = BroadcastService._internal();
  BroadcastService._internal();

  /// Synthesizes a rich bilingual Mandi Bhav bulletin from today's commodity rates
  String generateDailyRatesBulletin({
    required String marketName,
    required DateTime date,
    required List<MandiCommodityRate> rates,
    String? munshiPhone,
    String? shopName,
    String? customNote,
  }) {
    final dateFormatUrdu = DateFormat('dd MMMM yyyy').format(date);
    final buffer = StringBuffer();

    buffer.writeln('🌾 *غلہ منڈی روزانہ ریٹ لسٹ (بھاؤ)* 🌾');
    buffer.writeln('📍 *منڈی:* ${marketName.isNotEmpty ? marketName : 'مرکزی غلہ منڈی'}');
    buffer.writeln('📅 *تاریخ:* $dateFormatUrdu');
    if (shopName != null && shopName.isNotEmpty) {
      buffer.writeln('🏢 *آڑھت:* $shopName');
    }
    buffer.writeln('──────────────────');

    if (rates.isEmpty) {
      buffer.writeln('آج کے ریٹس منڈی بورڈ پر جلد جاری کیے جائیں گے۔');
    } else {
      for (final r in rates) {
        final emoji = _getCommodityEmoji(r.commodityName);
        final trendIcon = r.marketTrend == MarketTrend.bullish
            ? '📈 تیز'
            : (r.marketTrend == MarketTrend.bearish ? '📉 مندا' : '⚖️ مستحکم');

        buffer.writeln('$emoji *${r.commodityName}* (${r.variety})');
        buffer.writeln(
            '   ریٹ فی 40 کلو: Rs. ${r.minRatePerMaund.toStringAsFixed(0)} - ${r.maxRatePerMaund.toStringAsFixed(0)}');
        buffer.writeln('   رجحان: $trendIcon | آمد: ${r.arrivalsMaunds.toStringAsFixed(0)} من');
      }
    }

    buffer.writeln('──────────────────');
    buffer.writeln('⏰ *بولی کے اوقات:* صبح 08:00 بجے تا دوپہر 01:00 بجے');
    if (munshiPhone != null && munshiPhone.isNotEmpty) {
      buffer.writeln('📞 *رابطہ منشی:* $munshiPhone');
    }
    if (customNote != null && customNote.isNotEmpty) {
      buffer.writeln('📝 *نوٹ:* $customNote');
    }
    buffer.writeln('✨ _نوٹ: تمام ریٹس شفاف نیلامی کے مطابق ہیں۔_');

    return buffer.toString();
  }

  /// Synthesizes an urgent Live Auction (Boli) alert message
  String generateBoliAlertBulletin({
    required String commodityName,
    required String variety,
    required int totalBags,
    required double expectedRate,
    required String bayLocation,
    required String munshiPhone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🚨 *لائیو بولی و نیلامی اطلاع (AUCTION ALERT)* 🚨');
    buffer.writeln('🌾 *جنس:* $commodityName ($variety)');
    buffer.writeln('📦 *تعداد بوریاں:* $totalBags بوریاں');
    buffer.writeln('📍 *مقام:* $bayLocation');
    buffer.writeln('💰 *متوقع ریٹ:* تقریبا Rs. ${expectedRate.toStringAsFixed(0)} فی من');
    buffer.writeln('⏰ *بولی کا وقت:* فوری شروع ہو رہی ہے!');
    buffer.writeln('📞 *رابطہ:* $munshiPhone');
    return buffer.toString();
  }

  /// Synthesizes a formal farmer khata balance reminder
  String generateKhataReminderBulletin({
    required String farmerName,
    required double pendingBalance,
    required String shopName,
    required String munshiPhone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('محترم جناب *$farmerName* صاحب،');
    buffer.writeln('السلام علیکم ورحمۃ اللہ،');
    buffer.writeln(
        'آپ کے *$shopName* کے ساتھ کھاتے کی بقایا واجب الادا رقم *Rs. ${pendingBalance.toStringAsFixed(0)}* ہے۔');
    buffer.writeln(
        'براہ کرم فصل کی آمد یا سہولت کے مطابق ادائیگی کر کے کھاتہ کلیئر فرمائیں۔ شکریہ۔');
    buffer.writeln('📞 *رابطہ:* $munshiPhone');
    return buffer.toString();
  }

  /// Returns fitting emoji for agricultural commodities
  String _getCommodityEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('گندم') || lower.contains('wheat')) return '🌾';
    if (lower.contains('چاول') || lower.contains('rice') || lower.contains('paddy')) return '🍚';
    if (lower.contains('مکئی') || lower.contains('corn') || lower.contains('maize')) return '🌽';
    if (lower.contains('کپاس') || lower.contains('cotton') || lower.contains('phutti')) return '☁️';
    if (lower.contains('سرسوں') || lower.contains('mustard') || lower.contains('raya')) return '🌼';
    if (lower.contains('سورج مکھی') || lower.contains('sunflower')) return '🌻';
    if (lower.contains('چنا') || lower.contains('gram') || lower.contains('pulse')) return '🫘';
    if (lower.contains('آلو') || lower.contains('potato')) return '🥔';
    if (lower.contains('پیاز') || lower.contains('onion')) return '🧅';
    return '📦';
  }

  // --------------------------------------------------------------------------
  // DISPATCH METHODS
  // --------------------------------------------------------------------------

  /// Opens WhatsApp Web or Native App with pre-filled message and target recipient
  Future<bool> launchWhatsAppUrl(String phone, String message) async {
    final cleanPhone = BroadcastCampaign.standardizePakistanPhone(phone);
    final encodedMsg = Uri.encodeComponent(message);
    final url = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMsg');
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Shares message directly to Telegram app or web
  Future<bool> launchTelegramShare(String message) async {
    final encodedMsg = Uri.encodeComponent(message);
    final url = Uri.parse('https://t.me/share/url?url=&text=$encodedMsg');
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Sends message via Telegram Bot API directly
  Future<bool> sendTelegramBotMessage({
    required String botToken,
    required String chatId,
    required String text,
  }) async {
    if (botToken.isEmpty || chatId.isEmpty) return false;
    final url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': text,
          'parse_mode': 'Markdown',
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Simulates batch campaign delivery to subscribers with progress reporting
  Future<BroadcastCampaign> dispatchCampaignToSubscribers({
    required BroadcastCampaign campaign,
    required List<BroadcastSubscriber> subscribers,
    String? telegramBotToken,
    void Function(int current, int total)? onProgress,
  }) async {
    int delivered = 0;
    int failed = 0;
    final total = subscribers.length;

    for (int i = 0; i < subscribers.length; i++) {
      final sub = subscribers[i];
      bool success = false;

      if (campaign.channel == BroadcastChannel.telegram || campaign.channel == BroadcastChannel.both) {
        if (telegramBotToken != null && telegramBotToken.isNotEmpty && sub.phoneOrChatId.isNotEmpty) {
          success = await sendTelegramBotMessage(
            botToken: telegramBotToken,
            chatId: sub.phoneOrChatId,
            text: campaign.messageBody,
          );
        } else {
          // Simulated success for subscriber list
          success = true;
        }
      } else {
        // WhatsApp queue simulation
        success = sub.phoneOrChatId.isNotEmpty;
      }

      if (success) {
        delivered++;
      } else {
        failed++;
      }

      onProgress?.call(i + 1, total);
      // Small pause to prevent rate throttling
      await Future.delayed(const Duration(milliseconds: 30));
    }

    final updated = campaign.copyWith(
      totalRecipients: total,
      deliveredCount: delivered,
      failedCount: failed,
      status: failed == 0 ? BroadcastStatus.sent : (delivered > 0 ? BroadcastStatus.sent : BroadcastStatus.failed),
      sentAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Update in Supabase
    try {
      await SupabaseService.updateBroadcastCampaign(updated.id, updated.shopId, updated.toMap());
    } catch (_) {}

    return updated;
  }
}
