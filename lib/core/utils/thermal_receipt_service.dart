import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Thermal Receipt Printing Utility for 58mm and 80mm POS Printers.
class ThermalReceiptService {
  /// Generates a roll paper ESC/POS PDF layout (e.g. 58mm / 80mm width).
  static Future<Uint8List> generateThermalReceiptPdf({
    required Invoice invoice,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double rollWidthMm = 80, // 58 or 80 mm
  }) async {
    final pdf = pw.Document();

    final dateStr = invoice.createdAt != null
        ? '${invoice.createdAt!.day}/${invoice.createdAt!.month}/${invoice.createdAt!.year}'
        : '';

    // Page Format for roll paper (80mm width x dynamic height)
    final rollFormat = PdfPageFormat(
      rollWidthMm * PdfPageFormat.mm,
      double.infinity,
      marginAll: 8,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (shopCity != null && shopCity.isNotEmpty)
                pw.Center(
                  child: pw.Text('Mandi: $shopCity',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              if (shopPhone != null && shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text('Ph: $shopPhone',
                      style: const pw.TextStyle(fontSize: 8)),
                ),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),

              pw.Text('Invoice #: ${invoice.invoiceNumber}',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              if (dateStr.isNotEmpty)
                pw.Text('Date: $dateStr',
                    style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                  'Party: ${invoice.customerName.isNotEmpty ? invoice.customerName : (invoice.supplierName.isNotEmpty ? invoice.supplierName : "Walk-in")}',
                  style: const pw.TextStyle(fontSize: 8)),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              // Items
              pw.Text('ITEMS',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),

              ...invoice.items.map((item) {
                final manns = MandiCalculator.kgToMann(item.weightKg);
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(item.productName,
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Rs. ${item.lineTotal.toStringAsFixed(0)}',
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Text(
                        '${item.quantity.toStringAsFixed(0)} Bags • ${item.weightKg.toStringAsFixed(0)}KG (${manns.toStringAsFixed(2)} Mann) @ Rs. ${item.unitPrice.toStringAsFixed(0)}',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              // Summary
              _row('Subtotal:', 'Rs. ${invoice.subtotal.toStringAsFixed(0)}'),
              if (invoice.commission > 0)
                _row('Commission:',
                    '+Rs. ${invoice.commission.toStringAsFixed(0)}'),
              if (invoice.expenses > 0)
                _row('Expenses:',
                    '+Rs. ${invoice.expenses.toStringAsFixed(0)}'),
              if (invoice.discount > 0)
                _row('Discount:',
                    '-Rs. ${invoice.discount.toStringAsFixed(0)}'),
              pw.Divider(thickness: 0.5),
              _row('TOTAL:', 'Rs. ${invoice.total.toStringAsFixed(0)}',
                  isBold: true),
              _row('Received:',
                  'Rs. ${invoice.receivedAmount.toStringAsFixed(0)}'),
              if (invoice.pendingAmount > 0)
                _row('Pending:',
                    'Rs. ${invoice.pendingAmount.toStringAsFixed(0)}',
                    isBold: true),

              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('*** Thank You! ***',
                    style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _row(String label, String value, {bool isBold = false}) {
    final style = pw.TextStyle(
      fontSize: 8,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }

  /// Direct layout print trigger for 58mm / 80mm thermal printer
  static Future<void> printThermalSlip({
    required Invoice invoice,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double rollWidthMm = 80,
  }) async {
    var fullInvoice = invoice;
    if (fullInvoice.items.isEmpty && fullInvoice.id.isNotEmpty) {
      final fetchedItems =
          await SupabaseService.getInvoiceItems(fullInvoice.id);
      fullInvoice = fullInvoice.copyWith(items: fetchedItems);
    }

    await Printing.layoutPdf(
      onLayout: (_) => generateThermalReceiptPdf(
        invoice: fullInvoice,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        rollWidthMm: rollWidthMm,
      ),
    );
  }
}
