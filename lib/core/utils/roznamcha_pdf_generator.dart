import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/roznamcha_entry_model.dart';

/// PDF Generation utility for Pakistani Mandi Daily Cash Day Book (روزنامچہ).
class RoznamchaPdfGenerator {
  const RoznamchaPdfGenerator._();

  /// Generates an A4 PDF document for the specified daily Roznamcha report.
  static Future<Uint8List> generateRoznamchaPdf({
    required RoznamchaDailyReport report,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final pdf = pw.Document();
    final dayStr =
        '${report.date.day.toString().padLeft(2, '0')}/${report.date.month.toString().padLeft(2, '0')}/${report.date.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
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
                        pw.Text('Grain Market (غلہ منڈی), $shopCity',
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
                        'DAILY CASH BOOK (روزنامچہ)',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text('Date: $dayStr',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          )),
                      pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Opening Balance Banner
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Opening Cash in Hand (ابتدائی نقد رقم):',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    'Rs. ${report.openingBalance.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ],
              ),
            ),

            // Cash Inflow Section Header
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              color: PdfColors.green50,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'CASH INFLOWS / RECEIPTS (آمدنی و وصولی)',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.Text(
                    'Total In: Rs. ${report.totalCashIn.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 4),

            if (report.cashInEntries.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  'No cash inflows recorded for this date.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                headers: ['Time', 'Ref #', 'Party / Source', 'Description', 'Amount (Rs.)'],
                columnWidths: {
                  0: const pw.FixedColumnWidth(45),
                  1: const pw.FixedColumnWidth(60),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2.5),
                  4: const pw.FixedColumnWidth(75),
                },
                data: report.cashInEntries.map((e) {
                  final timeStr =
                      '${e.dateTime.hour.toString().padLeft(2, '0')}:${e.dateTime.minute.toString().padLeft(2, '0')}';
                  return [
                    timeStr,
                    e.reference,
                    e.partyName,
                    e.description,
                    e.amount.toStringAsFixed(0),
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 14),

            // Cash Outflow Section Header
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              color: PdfColors.red50,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'CASH OUTFLOWS / PAYOUTS (ادائیگی و اخراجات)',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.red900,
                    ),
                  ),
                  pw.Text(
                    'Total Out: Rs. ${report.totalCashOut.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.red900,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 4),

            if (report.cashOutEntries.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  'No cash outflows recorded for this date.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                headers: ['Time', 'Ref #', 'Party / Category', 'Description', 'Amount (Rs.)'],
                columnWidths: {
                  0: const pw.FixedColumnWidth(45),
                  1: const pw.FixedColumnWidth(60),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2.5),
                  4: const pw.FixedColumnWidth(75),
                },
                data: report.cashOutEntries.map((e) {
                  final timeStr =
                      '${e.dateTime.hour.toString().padLeft(2, '0')}:${e.dateTime.minute.toString().padLeft(2, '0')}';
                  return [
                    timeStr,
                    e.reference,
                    e.partyName,
                    e.description,
                    e.amount.toStringAsFixed(0),
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 18),

            // Daily Reconciliation Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'DAILY CASH RECONCILIATION (میزان کیش بک)',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Opening Cash in Hand:',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Rs. ${report.openingBalance.toStringAsFixed(0)}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Cash Inflows (+):',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.green800)),
                      pw.Text('+ Rs. ${report.totalCashIn.toStringAsFixed(0)}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.green800)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Cash Outflows (-):',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.red800)),
                      pw.Text('- Rs. ${report.totalCashOut.toStringAsFixed(0)}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.red800)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Net Cash Movement:',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        '${report.netCashChange >= 0 ? '+' : ''}Rs. ${report.netCashChange.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: report.netCashChange >= 0
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'CLOSING CASH IN HAND (نقد موجود در گلہ):',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                        pw.Text(
                          'Rs. ${report.closingBalance.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 28),

            // Signatures Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Cashier / Munshi Signature',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('(دستخط منشی / کیشئر)',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Proprietor / Aarthi Signature',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('(دستخط مالک / آڑھتی)',
                        style: const pw.TextStyle(fontSize: 8)),
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

  /// Triggers the system print dialog or direct PDF preview.
  static Future<void> printOrShareRoznamcha({
    required RoznamchaDailyReport report,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final bytes = await generateRoznamchaPdf(
      report: report,
      shopName: shopName,
      shopPhone: shopPhone,
      shopCity: shopCity,
    );
    final dayStr =
        '${report.date.day.toString().padLeft(2, '0')}-${report.date.month.toString().padLeft(2, '0')}-${report.date.year}';
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Roznamcha_${shopName.replaceAll(' ', '_')}_$dayStr.pdf',
    );
  }
}
