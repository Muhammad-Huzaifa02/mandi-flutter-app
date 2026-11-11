// Printable A4 PDF Generator for Multi-Partner Mandi Shop Profit Sharing & Drawings
// (*شراکت داری اور منافع تقسیم کھاتہ*).

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/data/models/partner_capital_model.dart';

class PartnerCapitalPdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');

  // =========================================================================
  // 1. PARTNER EQUITY & PROFIT DISTRIBUTION SUMMARY (A4 PORTRAIT)
  // =========================================================================

  static Future<Uint8List> generatePartnerEquityReportPdf({
    required List<ShopPartnerModel> partners,
    required List<PartnerTransactionModel> recentTransactions,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

    double totalCapital = 0;
    double totalDrawings = 0;
    for (final p in partners) {
      totalCapital += p.currentCapital;
      totalDrawings += p.totalDrawings;
    }

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
                        shopName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'PARTNER EQUITY & DRAWINGS REGISTER / شراکت داری کھاتہ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                      if (shopAddress != null)
                        pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Report Date: $nowStr', style: const pw.TextStyle(fontSize: 9)),
                      if (shopPhone != null)
                        pw.Text('Contact: $shopPhone', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.teal900),
              pw.SizedBox(height: 8),

              // Summary KPI Cards
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildKpiBox('Total Partners / شراکت دار', '${partners.length}', PdfColors.blueGrey100),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _buildKpiBox('Total Capital / کل سرمایہ', 'Rs. ${_currencyFmt.format(totalCapital)}', PdfColors.teal50),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _buildKpiBox('Total Drawings / کل نکلوانا', 'Rs. ${_currencyFmt.format(totalDrawings)}', PdfColors.amber50),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Table of Partners
              pw.Text(
                'PARTNERS CAPITAL & PROFIT SHARE RATIOS / حصہ داری و سرمایہ تفصیل',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ),
              pw.SizedBox(height: 6),

              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal900),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                headers: [
                  'Partner Name (نام)',
                  'CNIC / Phone',
                  'Share % (تناسب)',
                  'Opening Capital',
                  'Drawings (نکلوانا)',
                  'Current Capital (موجودہ سرمایہ)',
                  'Status',
                ],
                data: partners.map((p) {
                  return [
                    p.name,
                    p.phone ?? p.cnic ?? '-',
                    p.profitRatioFormatted,
                    'Rs. ${_currencyFmt.format(p.openingCapital)}',
                    'Rs. ${_currencyFmt.format(p.totalDrawings)}',
                    'Rs. ${_currencyFmt.format(p.currentCapital)}',
                    p.isActive ? 'Active' : 'Inactive',
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 16),

              // Recent Transactions Table
              if (recentTransactions.isNotEmpty) ...[
                pw.Text(
                  'RECENT CAPITAL & DRAWING TRANSACTIONS / حالیہ ٹرانزیکشنز',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                ),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  context: context,
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  cellStyle: const pw.TextStyle(fontSize: 7.5),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                  headers: [
                    'Date',
                    'Partner',
                    'Type (قسم)',
                    'Method',
                    'Amount (رقم)',
                    'Description / Reference',
                  ],
                  data: recentTransactions.take(15).map((t) {
                    return [
                      t.formattedDate,
                      t.partnerName ?? t.partnerId.substring(0, 8),
                      t.type.labelEnglish,
                      t.paymentMethod.toUpperCase(),
                      'Rs. ${_currencyFmt.format(t.amount)}',
                      t.description ?? t.reference ?? '-',
                    ];
                  }).toList(),
                ),
              ],

              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Certified by Shop Partners / جملہ حصہ داران', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Signature & Stamp / دستخط و مہر: _______________________',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiBox(String title, String val, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
          pw.SizedBox(height: 3),
          pw.Text(val, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
        ],
      ),
    );
  }
}
