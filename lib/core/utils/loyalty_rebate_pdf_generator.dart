import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/customer_loyalty_rebate_model.dart';

/// Professional A4 PDF Generator for Customer Loyalty Volume Rebate Statements
/// and Official Mandi Credit Notes (*گاہک رعایت نامہ و کریڈٹ واؤچر*).
class LoyaltyRebatePdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');
  static final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  // =========================================================================
  // 1. OFFICIAL REBATE CREDIT NOTE & SETTLEMENT CERTIFICATE (A4 PORTRAIT)
  // =========================================================================

  static Future<Uint8List> generateCreditNotePdf({
    required CustomerLoyaltyRebate rebate,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();
    final issueDate = rebate.creditedAt != null
        ? DateFormat('dd MMMM yyyy').format(rebate.creditedAt!)
        : DateFormat('dd MMMM yyyy').format(DateTime.now());

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
                      if (shopAddress != null && shopAddress.isNotEmpty)
                        pw.Text(shopAddress,
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                      if (shopPhone != null && shopPhone.isNotEmpty)
                        pw.Text('Tel: $shopPhone',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'CUSTOMER VOLUME REBATE & CREDIT NOTE',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.teal800, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(6),
                      color: PdfColors.teal50,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'CREDIT NOTE VOUCHER',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          rebate.creditNoteNumber.isNotEmpty
                              ? rebate.creditNoteNumber
                              : 'CRN-${DateTime.now().year}-DRAFT',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.Text('Date: $issueDate',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: PdfColors.grey800)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.blueGrey800),
              pw.SizedBox(height: 8),

              // Customer & Tier Banner
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: _buildInfoBox(
                      title: 'CUSTOMER / BUYER DETAILS',
                      rows: [
                        ['Customer Name:', rebate.customerName],
                        ['Contact Phone:', rebate.customerPhone.isNotEmpty ? rebate.customerPhone : '-'],
                        ['Season / Program:', '${rebate.seasonYear} (${rebate.programName})'],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 2,
                    child: _buildInfoBox(
                      title: 'LOYALTY REBATE TIER',
                      rows: [
                        ['Tier Status:', rebate.tierLevel.labelEnglish],
                        ['Incentive Rate:', '${rebate.rebatePercentage}% Commission Rebate'],
                        ['Voucher Status:', rebate.status.labelEnglish],
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // Summary KPI Metrics
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blueGrey200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _metricCol('Qualifying Turnover (Maunds)',
                        '${_numberFmt.format(rebate.qualifyingMaunds)} M'),
                    _metricCol('Total Purchase Volume',
                        'Rs. ${_currencyFmt.format(rebate.qualifyingTurnoverPkr)}'),
                    _metricCol('Rebate Incentive Rate',
                        '${rebate.rebatePercentage}%'),
                    _metricCol(
                      'NET CREDITED AMOUNT',
                      'Rs. ${_currencyFmt.format(rebate.rebateAmountPkr)}',
                      isBoldHighlight: true,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Accounting Settlement Terms Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      _th('#', isWhite: true),
                      _th('Description & Trading Milestone', isWhite: true),
                      _th('Turnover Base', isWhite: true),
                      _th('Rebate Credit (PKR)', isWhite: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td('1', alignRight: true),
                      _td(
                          'Volume Brokerage Incentive & Commercial Rebate\nSeason: ${rebate.seasonYear} | Tier: ${rebate.tierLevel.labelEnglish}'),
                      _td(
                          '${_numberFmt.format(rebate.qualifyingMaunds)} M\nRs. ${_currencyFmt.format(rebate.qualifyingTurnoverPkr)}',
                          alignRight: true),
                      _td('Rs. ${_currencyFmt.format(rebate.rebateAmountPkr)}',
                          isBold: true, alignRight: true),
                    ],
                  ),
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _td(''),
                      _td('TOTAL ADJUSTMENT APPLIED TO RUNNING KHATA',
                          isBold: true),
                      _td(''),
                      _td('Rs. ${_currencyFmt.format(rebate.rebateAmountPkr)}',
                          isBold: true, alignRight: true),
                    ],
                  ),
                ],
              ),

              if (rebate.notes.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text('Notes / Audit Memo: ${rebate.notes}',
                    style: const pw.TextStyle(
                        fontSize: 8.5, color: PdfColors.grey800)),
              ],

              pw.Spacer(),

              // Verification & Authorization Box
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Notice: This credit note represents an official seasonal trading incentive and volume discount issued under agreed Mandi commission rebate terms. The credited balance has been posted directly to reduce the customer\'s outstanding ledger balance.',
                  style: const pw.TextStyle(
                      fontSize: 7.5, color: PdfColors.grey700),
                ),
              ),

              pw.SizedBox(height: 36),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _signCol('Customer / Buyer Signature'),
                  _signCol('Head Munshi / Accountant'),
                  _signCol('Proprietor / Mandi Arth Seal'),
                ],
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- Helper Widgets ---

  static pw.Widget _buildInfoBox({
    required String title,
    required List<List<String>> rows,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800),
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey300),
          pw.SizedBox(height: 2),
          ...rows.map((r) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(r[0],
                        style: const pw.TextStyle(
                            fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text(r[1],
                        style: pw.TextStyle(
                            fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _metricCol(String title, String val,
      {bool isBoldHighlight = false}) {
    return pw.Column(
      children: [
        pw.Text(title,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 3),
        pw.Text(
          val,
          style: pw.TextStyle(
            fontSize: isBoldHighlight ? 10.5 : 9,
            fontWeight: pw.FontWeight.bold,
            color: isBoldHighlight ? PdfColors.teal900 : PdfColors.blueGrey900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _signCol(String title) {
    return pw.Column(
      children: [
        pw.Container(width: 140, height: 0.5, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(title,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7.5)),
      ],
    );
  }

  static pw.Widget _th(String text, {bool isWhite = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: isWhite ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _td(String text,
      {bool isBold = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Direct print trigger for Credit Note
  static Future<void> printCreditNote({
    required CustomerLoyaltyRebate rebate,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdfBytes = await generateCreditNotePdf(
      rebate: rebate,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Credit_Note_${rebate.creditNoteNumber}.pdf',
    );
  }
}
