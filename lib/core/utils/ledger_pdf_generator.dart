import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/models/farmer_model.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/models/ledger_entry_model.dart';
import 'package:mandi/core/utils/ledger_calculator.dart';

/// PDF Generation utility for Customer and Supplier Account Ledgers.
/// Implements full itemized transaction statements with chronological running balances.
class LedgerPdfGenerator {
  /// Generates a complete itemized PDF Account Statement for a Customer.
  static Future<Uint8List> generateCustomerLedgerPdf({
    required Customer customer,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    List<LedgerEntry> entries = const [],
  }) async {
    final pdf = pw.Document();
    final dateStr =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    final summary = LedgerCalculator.calculateSummary(
      customer.openingBalance,
      entries,
      isCustomer: true,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
                        'CUSTOMER KHATA STATEMENT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Date: $dateStr',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Customer Details Card
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Customer: ${customer.name}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      if (customer.phone.isNotEmpty)
                        pw.Text('Phone: ${customer.phone}',
                            style: const pw.TextStyle(fontSize: 10)),
                      if (customer.city.isNotEmpty)
                        pw.Text('City: ${customer.city}',
                            style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Opening Balance: Rs. ${customer.openingBalance.toStringAsFixed(0)}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        'Current Net: Rs. ${customer.runningBalance.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: customer.runningBalance > 0
                              ? PdfColors.red800
                              : PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Summary Totals
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.green800),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: <String>[
                'Opening Bal',
                'Total Invoiced (Dr)',
                'Total Received (Cr)',
                'Closing Balance'
              ],
              data: [
                [
                  'Rs. ${summary.openingBalance.toStringAsFixed(0)}',
                  'Rs. ${summary.totalDebit.toStringAsFixed(0)}',
                  'Rs. ${summary.totalCredit.toStringAsFixed(0)}',
                  'Rs. ${summary.closingBalance.toStringAsFixed(0)}',
                ]
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Text('Itemized Transaction History',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 8),

            // Itemized Transaction Table
            if (entries.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                child: pw.Text('No transactions recorded for this customer yet.',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.green900),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                headers: <String>[
                  'Date',
                  'Ref #',
                  'Description',
                  'Debit (Dr)',
                  'Credit (Cr)',
                  'Balance'
                ],
                data: entries.map((e) {
                  return [
                    e.formattedDate,
                    e.reference,
                    e.description,
                    e.debit > 0 ? 'Rs. ${e.debit.toStringAsFixed(0)}' : '-',
                    e.credit > 0 ? 'Rs. ${e.credit.toStringAsFixed(0)}' : '-',
                    'Rs. ${e.runningBalance.toStringAsFixed(0)}',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 20),

            // Final Status Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
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
                  pw.Text('Net Khata Balance Payable by Customer:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                    'Rs. ${customer.runningBalance.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                      color: customer.runningBalance > 0
                          ? PdfColors.red800
                          : PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 140,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 140,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Arhti Stamp', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a complete itemized PDF Account Statement for a Supplier.
  static Future<Uint8List> generateSupplierLedgerPdf({
    required Supplier supplier,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    List<LedgerEntry> entries = const [],
  }) async {
    final pdf = pw.Document();
    final dateStr =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    final summary = LedgerCalculator.calculateSummary(
      supplier.openingBalance,
      entries,
      isCustomer: false,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
                        'SUPPLIER / FARMER KHATA STATEMENT',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Date: $dateStr',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Supplier Details Card
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Farmer / Supplier: ${supplier.name}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      if (supplier.phone.isNotEmpty)
                        pw.Text('Phone: ${supplier.phone}',
                            style: const pw.TextStyle(fontSize: 10)),
                      if (supplier.productsSupplied.isNotEmpty)
                        pw.Text('Crops: ${supplier.productsSupplied}',
                            style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Opening Balance: Rs. ${supplier.openingBalance.toStringAsFixed(0)}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        'Current Payable: Rs. ${supplier.runningBalance.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: supplier.runningBalance > 0
                              ? PdfColors.red800
                              : PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Summary Totals
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.green800),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: <String>[
                'Opening Bal',
                'Produce Supplied (Cr)',
                'Payments Paid (Dr)',
                'Net Payable'
              ],
              data: [
                [
                  'Rs. ${summary.openingBalance.toStringAsFixed(0)}',
                  'Rs. ${summary.totalCredit.toStringAsFixed(0)}',
                  'Rs. ${summary.totalDebit.toStringAsFixed(0)}',
                  'Rs. ${summary.closingBalance.toStringAsFixed(0)}',
                ]
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Text('Itemized Crop Deliveries & Payout History',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 8),

            if (entries.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                child: pw.Text('No transactions recorded for this supplier yet.',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.green900),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                headers: <String>[
                  'Date',
                  'Ref #',
                  'Description',
                  'Payout Paid (Dr)',
                  'Crop Value (Cr)',
                  'Balance'
                ],
                data: entries.map((e) {
                  return [
                    e.formattedDate,
                    e.reference,
                    e.description,
                    e.debit > 0 ? 'Rs. ${e.debit.toStringAsFixed(0)}' : '-',
                    e.credit > 0 ? 'Rs. ${e.credit.toStringAsFixed(0)}' : '-',
                    'Rs. ${e.runningBalance.toStringAsFixed(0)}',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 20),

            // Final Status Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
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
                  pw.Text('Net Payable to Farmer / Supplier:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                    'Rs. ${supplier.runningBalance.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                      color: supplier.runningBalance > 0
                          ? PdfColors.red800
                          : PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 140,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Farmer Signature', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 140,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Shop Stamp / Signature', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
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
    List<LedgerEntry> entries = const [],
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) => generateCustomerLedgerPdf(
        customer: customer,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        entries: entries,
      ),
    );
  }

  /// Prints or shares a Supplier Ledger PDF.
  static Future<void> printSupplierLedger({
    required Supplier supplier,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    List<LedgerEntry> entries = const [],
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) => generateSupplierLedgerPdf(
        supplier: supplier,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        entries: entries,
      ),
    );
  }

  /// Generates a complete itemized PDF Account Statement for a Farmer.
  static Future<Uint8List> generateFarmerLedgerPdf({
    required Farmer farmer,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    List<LedgerEntry> entries = const [],
  }) =>
      generateSupplierLedgerPdf(
        supplier: farmer,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        entries: entries,
      );

  /// Prints or shares a Farmer Ledger PDF.
  static Future<void> printFarmerLedger({
    required Farmer farmer,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    List<LedgerEntry> entries = const [],
  }) =>
      printSupplierLedger(
        supplier: farmer,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        entries: entries,
      );
}
