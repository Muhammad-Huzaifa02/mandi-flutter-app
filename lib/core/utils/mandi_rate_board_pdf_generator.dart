import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/mandi_rate_model.dart';

/// Professional A4 PDF Generator for Daily Mandi Commodity Rate Boards
/// (*روزانہ منڈی ریٹ لسٹ اور پرچہ نرخ نامہ*).
class MandiRateBoardPdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');
  static final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  static Future<Uint8List> generateRateBoardPdf({
    required List<MandiCommodityRate> rates,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
    required DateTime date,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy').format(date);

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
                        'DAILY MANDI COMMODITY RATE BOARD & PRICE INDEX',
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
                          'OFFICIAL RATE BOARD',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(dateStr,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900,
                            )),
                        pw.Text('Maund Standard (40 KG)',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey800)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.blueGrey800),
              pw.SizedBox(height: 10),

              // Rates Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3), // Commodity & Variety
                  1: const pw.FlexColumnWidth(2), // Quality Grade
                  2: const pw.FlexColumnWidth(2), // Min Rate
                  3: const pw.FlexColumnWidth(2), // Max Rate
                  4: const pw.FlexColumnWidth(2.5), // Modal Rate
                  5: const pw.FlexColumnWidth(2), // Rate / KG
                  6: const pw.FlexColumnWidth(2), // Trend
                  7: const pw.FlexColumnWidth(2), // Arrivals
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      _th('Commodity & Variety', isWhite: true),
                      _th('Grade', isWhite: true),
                      _th('Min Rate (40kg)', isWhite: true),
                      _th('Max Rate (40kg)', isWhite: true),
                      _th('Modal Rate (40kg)', isWhite: true),
                      _th('Rate / KG', isWhite: true),
                      _th('Trend', isWhite: true),
                      _th('Arrivals (M)', isWhite: true),
                    ],
                  ),
                  ...rates.map((r) {
                    final trendStr = r.marketTrend == MarketTrend.bullish
                        ? 'Bullish +${r.priceChangePkr.toStringAsFixed(0)}'
                        : r.marketTrend == MarketTrend.bearish
                            ? 'Bearish ${r.priceChangePkr.toStringAsFixed(0)}'
                            : 'Stable';

                    return pw.TableRow(
                      children: [
                        _td('${r.commodityName}\n(${r.variety.isNotEmpty ? r.variety : "-"})', isBold: true),
                        _td(r.qualityGrade),
                        _td('Rs. ${_currencyFmt.format(r.minRatePerMaund)}', alignRight: true),
                        _td('Rs. ${_currencyFmt.format(r.maxRatePerMaund)}', alignRight: true),
                        _td('Rs. ${_currencyFmt.format(r.modalRatePerMaund)}',
                            isBold: true, alignRight: true),
                        _td('Rs. ${_numberFmt.format(r.pricePerKgPkr)}', alignRight: true),
                        _td(trendStr),
                        _td('${_numberFmt.format(r.arrivalsMaunds)} M', alignRight: true),
                      ],
                    );
                  }),
                ],
              ),

              pw.Spacer(),

              // Verification & Authorization Notice
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Notice: These rates are certified auction commodity averages compiled during morning Mandi boli sessions. Rates fluctuate based on moisture content, dirt tare, and grade purity.',
                  style: const pw.TextStyle(
                      fontSize: 7.5, color: PdfColors.grey700),
                ),
              ),

              pw.SizedBox(height: 36),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _signCol('Auction Caller / Boli Incharge'),
                  _signCol('Head Munshi / Market Reporter'),
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

  /// Direct print trigger for Rate Board
  static Future<void> printRateBoard({
    required List<MandiCommodityRate> rates,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
    required DateTime date,
  }) async {
    final pdfBytes = await generateRateBoardPdf(
      rates: rates,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      date: date,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Mandi_Rate_Board_${DateFormat('yyyyMMdd').format(date)}.pdf',
    );
  }
}
