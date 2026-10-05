import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// PDF Generation utility for Mandi Sales Receipts.
class InvoicePdfGenerator {
  /// Generates a PDF document for an invoice.
  static Future<Uint8List> generatePdf({
    required Invoice invoice,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final pdf = pw.Document();

    final dateStr = invoice.createdAt != null
        ? '${invoice.createdAt!.day}/${invoice.createdAt!.month}/${invoice.createdAt!.year}'
        : '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      if (shopCity != null && shopCity.isNotEmpty)
                        pw.Text('Grain Market, $shopCity',
                            style: const pw.TextStyle(fontSize: 10)),
                      if (shopPhone != null && shopPhone.isNotEmpty)
                        pw.Text('Phone: $shopPhone',
                            style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SALES INVOICE',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                      if (dateStr.isNotEmpty) pw.Text('Date: $dateStr'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // Customer Details
              pw.Text(
                'Customer: ${invoice.customerName.isNotEmpty ? invoice.customerName : "Walk-in Customer"}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),

              pw.SizedBox(height: 16),

              // Itemized Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(6),
                headers: <String>[
                  '#',
                  'Product',
                  'Weight (KG)',
                  'Manns',
                  'Rate / 40kg',
                  'Total (PKR)',
                ],
                data: List<List<String>>.generate(invoice.items.length, (i) {
                  final item = invoice.items[i];
                  final manns = MandiCalculator.kgToMann(item.weightKg);
                  return [
                    '${i + 1}',
                    item.productName.isNotEmpty ? item.productName : 'Item',
                    '${item.weightKg.toStringAsFixed(0)} KG',
                    '${manns.toStringAsFixed(2)} Mann',
                    'Rs. ${item.unitPrice.toStringAsFixed(0)}',
                    'Rs. ${item.lineTotal.toStringAsFixed(0)}',
                  ];
                }),
              ),

              pw.SizedBox(height: 16),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Column(
                      children: [
                        _pdfRow('Subtotal:', 'Rs. ${invoice.subtotal.toStringAsFixed(0)}'),
                        _pdfRow('Mandi Commission:', 'Rs. ${invoice.commission.toStringAsFixed(0)}'),
                        if (invoice.expenses > 0)
                          _pdfRow('Expenses:', 'Rs. ${invoice.expenses.toStringAsFixed(0)}'),
                        if (invoice.discount > 0)
                          _pdfRow('Discount:', '-Rs. ${invoice.discount.toStringAsFixed(0)}'),
                        pw.Divider(),
                        _pdfRow(
                          'Grand Total:',
                          'Rs. ${invoice.total.toStringAsFixed(0)}',
                          isBold: true,
                        ),
                        _pdfRow('Received:', 'Rs. ${invoice.receivedAmount.toStringAsFixed(0)}'),
                        if (invoice.pendingAmount > 0)
                          _pdfRow(
                            'Pending Balance:',
                            'Rs. ${invoice.pendingAmount.toStringAsFixed(0)}',
                            isBold: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for trading with $shopName!',
                  style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                      fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfRow(String label, String value, {bool isBold = false}) {
    final style = pw.TextStyle(
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: 10,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  /// Displays the PDF Print/Save preview sheet.
  static Future<void> printOrShareInvoice({
    required Invoice invoice,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    var fullInvoice = invoice;
    if (fullInvoice.items.isEmpty && fullInvoice.id.isNotEmpty) {
      final fetchedItems =
          await SupabaseService.getInvoiceItems(fullInvoice.id);
      fullInvoice = fullInvoice.copyWith(items: fetchedItems);
    }

    await Printing.layoutPdf(
      onLayout: (_) => generatePdf(
        invoice: fullInvoice,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
      ),
    );
  }
}
