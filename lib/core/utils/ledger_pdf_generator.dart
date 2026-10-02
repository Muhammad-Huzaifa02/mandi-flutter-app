import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/models/supplier_model.dart';

/// PDF Generation utility for Customer and Supplier Account Ledgers.
class LedgerPdfGenerator {
  /// Generates a PDF Account Statement for a Customer.
  static Future<Uint8List> generateCustomerLedgerPdf({
    required Customer customer,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final pdf = pw.Document();
    final dateStr =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

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
                        'CUSTOMER LEDGER STATEMENT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Date Generated: $dateStr'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Customer Details Card
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer Name: ${customer.name}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    if (customer.phone.isNotEmpty)
                      pw.Text('Phone: ${customer.phone}',
                          style: const pw.TextStyle(fontSize: 10)),
                    if (customer.city.isNotEmpty)
                      pw.Text('City: ${customer.city}',
                          style: const pw.TextStyle(fontSize: 10)),
                    if (customer.address.isNotEmpty)
                      pw.Text('Address: ${customer.address}',
                          style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Ledger Summary Table
              pw.Text('Account Summary',
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.green800),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                headers: <String>['Description', 'Amount (PKR)'],
                data: [
                  ['Opening Balance', 'Rs. ${customer.openingBalance.toStringAsFixed(0)}'],
                  ['Current Net Balance', 'Rs. ${customer.runningBalance.toStringAsFixed(0)}'],
                ],
              ),

              pw.SizedBox(height: 16),

              // Status Summary Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: customer.runningBalance > 0
                      ? PdfColors.red50
                      : PdfColors.green50,
                  border: pw.Border.all(
                    color: customer.runningBalance > 0
                        ? PdfColors.red400
                        : PdfColors.green400,
                  ),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Outstanding Ledger Balance:',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12),
                    ),
                    pw.Text(
                      'Rs. ${customer.runningBalance.toStringAsFixed(0)} ${customer.runningBalance > 0 ? "(Customer Owes)" : "(Settled)"}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                        color: customer.runningBalance > 0
                            ? PdfColors.red800
                            : PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Official Ledger Statement generated by $shopName',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a PDF Account Statement for a Supplier.
  static Future<Uint8List> generateSupplierLedgerPdf({
    required Supplier supplier,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final pdf = pw.Document();
    final dateStr =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

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
                        'SUPPLIER LEDGER STATEMENT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Date Generated: $dateStr'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Supplier Details Card
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Supplier Name: ${supplier.name}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    if (supplier.phone.isNotEmpty)
                      pw.Text('Phone: ${supplier.phone}',
                          style: const pw.TextStyle(fontSize: 10)),
                    if (supplier.productsSupplied.isNotEmpty)
                      pw.Text('Products Supplied: ${supplier.productsSupplied}',
                          style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Ledger Summary Table
              pw.Text('Account Summary',
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.green800),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                headers: <String>['Description', 'Amount (PKR)'],
                data: [
                  ['Opening Balance', 'Rs. ${supplier.openingBalance.toStringAsFixed(0)}'],
                  ['Current Payable Balance', 'Rs. ${supplier.runningBalance.toStringAsFixed(0)}'],
                ],
              ),

              pw.SizedBox(height: 16),

              // Status Summary Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: supplier.runningBalance > 0
                      ? PdfColors.red50
                      : PdfColors.green50,
                  border: pw.Border.all(
                    color: supplier.runningBalance > 0
                        ? PdfColors.red400
                        : PdfColors.green400,
                  ),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Outstanding Payable Balance:',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12),
                    ),
                    pw.Text(
                      'Rs. ${supplier.runningBalance.toStringAsFixed(0)} ${supplier.runningBalance > 0 ? "(Payable to Supplier)" : "(Settled)"}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                        color: supplier.runningBalance > 0
                            ? PdfColors.red800
                            : PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Official Ledger Statement generated by $shopName',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Prints or shares a Customer Ledger PDF.
  static Future<void> printCustomerLedger({
    required Customer customer,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) => generateCustomerLedgerPdf(
        customer: customer,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
      ),
    );
  }

  /// Prints or shares a Supplier Ledger PDF.
  static Future<void> printSupplierLedger({
    required Supplier supplier,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) => generateSupplierLedgerPdf(
        supplier: supplier,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
      ),
    );
  }
}
