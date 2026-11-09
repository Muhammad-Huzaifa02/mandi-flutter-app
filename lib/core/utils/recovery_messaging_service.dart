import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mandi/core/utils/pk_phone.dart';

enum ReminderTone {
  polite, // Friendly greeting & gentle balance reminder
  formal, // Commercial reminder with account & shop details
  urgent, // Urgent final notice requiring immediate contact
}

enum ReminderLanguage {
  urdu,
  english,
}

/// Robust messaging and dispatch service for Mandi customer payment recovery (تقاضا کھاتہ).
class RecoveryMessagingService {
  const RecoveryMessagingService._();

  /// Compiles a formatted recovery message based on tone, language, and optional bank details.
  static String formatRecoveryMessage({
    required String customerName,
    required double pendingBalance,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    ReminderTone tone = ReminderTone.polite,
    ReminderLanguage language = ReminderLanguage.urdu,
    String? bankName,
    String? accountTitle,
    String? accountNoOrIban,
    String? raastId,
  }) {
    final balanceStr = pendingBalance.toStringAsFixed(0);
    final buffer = StringBuffer();

    if (language == ReminderLanguage.urdu) {
      switch (tone) {
        case ReminderTone.polite:
          buffer.writeln('السلام علیکم محترم *$customerName* صاحب،');
          buffer.writeln();
          buffer.writeln('امید ہے آپ خیریت سے ہوں گے۔ یہ ایک شائستہ یاد دہانی ہے کہ آپ کے غلہ منڈی کھاتہ کا بقایا بیلنس بمبلغ *Rs. $balanceStr* روپے واجب الادا ہے۔');
          buffer.writeln('برائے مہربانی سہولت کے مطابق جلد ادائیگی فرما کر کھاتہ اپ ڈیٹ کروا لیں۔');
          break;

        case ReminderTone.formal:
          buffer.writeln('*ادائیگی کا رسمی تقاضا*');
          buffer.writeln('محترم *$customerName* صاحب،');
          buffer.writeln();
          buffer.writeln('آپ کے کھاتہ کی تفصیل کے مطابق بقایا رقم *Rs. $balanceStr* واجب الوصول ہے۔');
          buffer.writeln('برائے مہربانی اس واجب الادا رقم کی جلد از جلد ادائیگی یقینی بنائیں۔');
          break;

        case ReminderTone.urgent:
          buffer.writeln('*اہم و فوری نوٹس برائے ادائیگی*');
          buffer.writeln('محترم *$customerName* صاحب،');
          buffer.writeln();
          buffer.writeln('آپ کے غلہ منڈی کھاتہ کی بقایا رقم بمبلغ *Rs. $balanceStr* کافی عرصے سے زیر التواء ہے۔');
          buffer.writeln('آپ سے گزارش ہے کہ آج ہی رابطہ کر کے بقایا جات کلیئر فرمائیں تاکہ مستقبل کا لین دین متاثر نہ ہو۔');
          break;
      }

      // Bank Details in Urdu
      if ((bankName != null && bankName.isNotEmpty) ||
          (accountNoOrIban != null && accountNoOrIban.isNotEmpty) ||
          (raastId != null && raastId.isNotEmpty)) {
        buffer.writeln();
        buffer.writeln('*آن لائن ادائیگی کی تفصیل:*');
        if (bankName != null && bankName.isNotEmpty) {
          buffer.writeln('بینک: $bankName');
        }
        if (accountTitle != null && accountTitle.isNotEmpty) {
          buffer.writeln('اکاؤنٹ ٹائٹل: $accountTitle');
        }
        if (accountNoOrIban != null && accountNoOrIban.isNotEmpty) {
          buffer.writeln('اکاؤنٹ / IBAN: $accountNoOrIban');
        }
        if (raastId != null && raastId.isNotEmpty) {
          buffer.writeln('راست آئی ڈی (Raast): $raastId');
        }
      }

      buffer.writeln();
      buffer.writeln('شکریہ،');
      buffer.writeln('*$shopName*');
      if (shopCity != null && shopCity.isNotEmpty) {
        buffer.writeln('غلہ منڈی، $shopCity');
      }
      if (shopPhone != null && shopPhone.isNotEmpty) {
        buffer.writeln('رابطہ نمبر: $shopPhone');
      }
    } else {
      // English Templates
      switch (tone) {
        case ReminderTone.polite:
          buffer.writeln('Assalam-o-Alaikum *$customerName*,');
          buffer.writeln();
          buffer.writeln('This is a gentle reminder that your pending ledger balance at *$shopName* is *Rs. $balanceStr*.');
          buffer.writeln('Kindly arrange the payment at your earliest convenience to keep your account current.');
          break;

        case ReminderTone.formal:
          buffer.writeln('*PAYMENT REMINDER NOTICE*');
          buffer.writeln('Dear *$customerName*,');
          buffer.writeln();
          buffer.writeln('According to our khata records, your outstanding balance is *Rs. $balanceStr*.');
          buffer.writeln('Please settle this outstanding balance at your earliest convenience.');
          break;

        case ReminderTone.urgent:
          buffer.writeln('*URGENT PAYMENT NOTICE*');
          buffer.writeln('Dear *$customerName*,');
          buffer.writeln();
          buffer.writeln('Your outstanding khata balance of *Rs. $balanceStr* is significantly overdue.');
          buffer.writeln('Please contact us today to settle this balance immediately and avoid disruption to future trading.');
          break;
      }

      // Bank Details in English
      if ((bankName != null && bankName.isNotEmpty) ||
          (accountNoOrIban != null && accountNoOrIban.isNotEmpty) ||
          (raastId != null && raastId.isNotEmpty)) {
        buffer.writeln();
        buffer.writeln('*Bank / Online Payment Details:*');
        if (bankName != null && bankName.isNotEmpty) {
          buffer.writeln('Bank: $bankName');
        }
        if (accountTitle != null && accountTitle.isNotEmpty) {
          buffer.writeln('Title: $accountTitle');
        }
        if (accountNoOrIban != null && accountNoOrIban.isNotEmpty) {
          buffer.writeln('A/C or IBAN: $accountNoOrIban');
        }
        if (raastId != null && raastId.isNotEmpty) {
          buffer.writeln('Raast ID: $raastId');
        }
      }

      buffer.writeln();
      buffer.writeln('Regards,');
      buffer.writeln('*$shopName*');
      if (shopCity != null && shopCity.isNotEmpty) {
        buffer.writeln('Grain Market, $shopCity');
      }
      if (shopPhone != null && shopPhone.isNotEmpty) {
        buffer.writeln('Phone: $shopPhone');
      }
    }

    return buffer.toString().trim();
  }

  /// Opens WhatsApp with the pre-filled recovery message.
  static Future<bool> launchWhatsApp({
    required String phone,
    required String message,
  }) async {
    final e164 = PkPhone.toE164(phone) ?? phone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = e164.replaceAll('+', '');
    final encoded = Uri.encodeComponent(message);

    final url = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final fallbackUrl = Uri.parse(
          'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded');
      return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Opens native SMS app with the pre-filled message.
  static Future<bool> launchSms({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final encoded = Uri.encodeComponent(message);
    final smsUri = Uri.parse('sms:$cleanPhone?body=$encoded');

    if (await canLaunchUrl(smsUri)) {
      return await launchUrl(smsUri);
    }
    return false;
  }

  /// Initiates a phone call.
  static Future<bool> launchPhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final telUri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(telUri)) {
      return await launchUrl(telUri);
    }
    return false;
  }

  /// Copies message to system clipboard.
  static Future<void> copyToClipboard(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
  }
}
