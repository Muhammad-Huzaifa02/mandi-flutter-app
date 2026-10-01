import 'package:url_launcher/url_launcher.dart';

import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/core/utils/pk_phone.dart';
import 'package:mandi/data/models/invoice_model.dart';

/// Service to send WhatsApp messages, Email invoices, and payment reminders.
class WhatsAppShareService {
  /// Opens WhatsApp with a pre-filled text message to the target phone number.
  static Future<bool> launchWhatsApp({
    required String phone,
    required String message,
  }) async {
    final e164 = PkPhone.toE164(phone) ?? phone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = e164.replaceAll('+', '');

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: universal WhatsApp URL
      final fallbackUrl = Uri.parse(
          'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMessage');
      return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Sends a formatted Mandi invoice summary over WhatsApp.
  static Future<bool> shareInvoice({
    required String phone,
    required Invoice invoice,
    required String shopName,
  }) {
    final dateStr = invoice.createdAt != null
        ? '${invoice.createdAt!.day}/${invoice.createdAt!.month}/${invoice.createdAt!.year}'
        : '';

    final buffer = StringBuffer();
    buffer.writeln('*$shopName*');
    buffer.writeln('Invoice #: *${invoice.invoiceNumber}*');
    buffer.writeln('Customer: ${invoice.customerName.isNotEmpty ? invoice.customerName : "Walk-in Customer"}');
    if (dateStr.isNotEmpty) buffer.writeln('Date: $dateStr');
    buffer.writeln();

    buffer.writeln('*Items:*');
    for (final item in invoice.items) {
      final manns = MandiCalculator.kgToMann(item.weightKg);
      buffer.writeln(
          '• ${item.productName}: ${item.weightKg} KG (${manns.toStringAsFixed(2)} Mann) @ Rs. ${item.unitPrice.toStringAsFixed(0)} = Rs. ${item.lineTotal.toStringAsFixed(0)}');
    }
    buffer.writeln();

    buffer.writeln('*Summary:*');
    buffer.writeln('Subtotal: Rs. ${invoice.subtotal.toStringAsFixed(0)}');
    if (invoice.commission > 0) {
      buffer.writeln('Mandi Commission: Rs. ${invoice.commission.toStringAsFixed(0)}');
    }
    if (invoice.expenses > 0) {
      buffer.writeln('Expenses: Rs. ${invoice.expenses.toStringAsFixed(0)}');
    }
    if (invoice.discount > 0) {
      buffer.writeln('Discount: -Rs. ${invoice.discount.toStringAsFixed(0)}');
    }
    buffer.writeln('*Grand Total: Rs. ${invoice.total.toStringAsFixed(0)}*');
    buffer.writeln('Received: Rs. ${invoice.receivedAmount.toStringAsFixed(0)}');
    if (invoice.pendingAmount > 0) {
      buffer.writeln('*Pending Balance: Rs. ${invoice.pendingAmount.toStringAsFixed(0)}*');
    }

    buffer.writeln();
    buffer.writeln('Thank you for your business!');

    return launchWhatsApp(phone: phone, message: buffer.toString());
  }

  /// Opens the device mail app with a pre-filled invoice summary.
  static Future<bool> shareInvoiceViaEmail({
    required String email,
    required Invoice invoice,
    required String shopName,
  }) async {
    final dateStr = invoice.createdAt != null
        ? '${invoice.createdAt!.day}/${invoice.createdAt!.month}/${invoice.createdAt!.year}'
        : '';

    final subject = Uri.encodeComponent('$shopName - Sales Invoice #${invoice.invoiceNumber}');

    final buffer = StringBuffer();
    buffer.writeln(shopName);
    buffer.writeln('Sales Invoice #: ${invoice.invoiceNumber}');
    buffer.writeln('Customer: ${invoice.customerName.isNotEmpty ? invoice.customerName : "Walk-in Customer"}');
    if (dateStr.isNotEmpty) buffer.writeln('Date: $dateStr');
    buffer.writeln();

    buffer.writeln('Purchased Items:');
    for (final item in invoice.items) {
      final manns = MandiCalculator.kgToMann(item.weightKg);
      buffer.writeln(
          ' - ${item.productName}: ${item.weightKg} KG (${manns.toStringAsFixed(2)} Mann) @ Rs. ${item.unitPrice.toStringAsFixed(0)} = Rs. ${item.lineTotal.toStringAsFixed(0)}');
    }
    buffer.writeln();

    buffer.writeln('Summary:');
    buffer.writeln('Subtotal: Rs. ${invoice.subtotal.toStringAsFixed(0)}');
    if (invoice.commission > 0) {
      buffer.writeln('Mandi Commission: Rs. ${invoice.commission.toStringAsFixed(0)}');
    }
    if (invoice.expenses > 0) {
      buffer.writeln('Expenses: Rs. ${invoice.expenses.toStringAsFixed(0)}');
    }
    if (invoice.discount > 0) {
      buffer.writeln('Discount: -Rs. ${invoice.discount.toStringAsFixed(0)}');
    }
    buffer.writeln('Grand Total: Rs. ${invoice.total.toStringAsFixed(0)}');
    buffer.writeln('Received: Rs. ${invoice.receivedAmount.toStringAsFixed(0)}');
    if (invoice.pendingAmount > 0) {
      buffer.writeln('Pending Balance: Rs. ${invoice.pendingAmount.toStringAsFixed(0)}');
    }

    buffer.writeln();
    buffer.writeln('Thank you for your business!');

    final body = Uri.encodeComponent(buffer.toString());
    final mailUrl = Uri.parse('mailto:$email?subject=$subject&body=$body');

    if (await canLaunchUrl(mailUrl)) {
      return await launchUrl(mailUrl);
    }
    return false;
  }

  /// Sends a friendly payment balance reminder over WhatsApp.
  static Future<bool> sharePaymentReminder({
    required String phone,
    required String name,
    required double pendingBalance,
    required String shopName,
  }) {
    final message = '''
Assalam-o-Alaikum *$name*,

This is a friendly payment reminder from *$shopName*.

Your current ledger balance is: *Rs. ${pendingBalance.toStringAsFixed(0)}*.

Kindly clear your pending balance at your earliest convenience.

Thank you!
''';

    return launchWhatsApp(phone: phone, message: message);
  }
}
