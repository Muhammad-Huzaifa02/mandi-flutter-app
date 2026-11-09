import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/consignment_lot_model.dart';

/// PDF Generation utility for Pakistani Mandi Daily Auction Boli Sheet
/// and individual Lot Weighing Slips (Dheri Parcha).
class BoliSheetPdfGenerator {
  const BoliSheetPdfGenerator._();

  /// Generates an A4 PDF document of the Daily Auction Sheet.
  static Future<Uint8List> generateBoliSheetPdf({
    required List<ConsignmentLot> lots,
    required DateTime date,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final pdf = pw.Document();
    final dayStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    final totalBags = lots.fold<int>(0, (sum, l) => sum + l.bagCount);
    final totalWeightKg = lots.fold<double>(0.0, (sum, l) => sum + l.weightKg);
    final totalMaunds = totalWeightKg / 40.0;
    final totalAuctionValue = lots
        .where((l) => l.isSold)
        .fold<double>(0.0, (sum, l) => sum + l.estimatedTotal);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
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
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      if (shopCity != null && shopCity.isNotEmpty)
                        pw.Text('Grain Market (Ghalla Mandi), $shopCity',
                            style: const pw.TextStyle(fontSize: 9)),
                      if (shopPhone != null && shopPhone.isNotEmpty)
                        pw.Text('Phone: $shopPhone',
                            style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DAILY AUCTION BOLI SHEET (Boli Register)',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text('Date: $dayStr',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          )),
                      pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Metrics Row
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _metricBlock('Total Lots (Dherian)', '${lots.length}'),
                  _metricBlock('Total Bags (Boriyan)', '$totalBags'),
                  _metricBlock(
                      'Total Weight (Wazan)', '${totalMaunds.toStringAsFixed(1)} Maunds (${totalWeightKg.toStringAsFixed(0)} KG)'),
                  _metricBlock('Total Auction (Nilami)',
                      'Rs. ${totalAuctionValue.toStringAsFixed(0)}'),
                ],
              ),
            ),

            if (lots.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 24),
                child: pw.Center(
                  child: pw.Text(
                    'No consignment lots recorded for this date.',
                    style: const pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey600),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                  color: PdfColors.white,
                ),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.green800),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                headers: [
                  'Lot #',
                  'Farmer / Supplier',
                  'Commodity',
                  'Vehicle #',
                  'Bags',
                  'Weight (Maunds)',
                  'Winning Buyer',
                  'Bid Rate (/Maund)',
                  'Total Value (Rs.)',
                  'Status',
                ],
                data: lots.map((l) {
                  return [
                    l.lotNumber,
                    l.supplierName.isNotEmpty ? l.supplierName : '-',
                    l.productName.isNotEmpty ? l.productName : 'Produce',
                    l.vehicleNumber.isNotEmpty ? l.vehicleNumber : '-',
                    '${l.bagCount}',
                    '${l.maunds.toStringAsFixed(1)} (${l.weightKg.toStringAsFixed(0)} kg)',
                    l.winningBuyerName.isNotEmpty ? l.winningBuyerName : '-',
                    l.ratePerMaund > 0
                        ? 'Rs. ${l.ratePerMaund.toStringAsFixed(0)}'
                        : '-',
                    l.isSold
                        ? 'Rs. ${l.estimatedTotal.toStringAsFixed(0)}'
                        : '-',
                    l.status.englishName,
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 24),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Boli Munshi / Recorder',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('(Dastakhat Munshi)',
                        style: const pw.TextStyle(fontSize: 7.5)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Mandi Commission Agent / Aarthi',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('(Dastakhat Malik / Aarthi)',
                        style: const pw.TextStyle(fontSize: 7.5)),
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

  /// Generates a single-page Weighing Scale / Boli Slip (Dheri Parcha) for an individual lot.
  static Future<Uint8List> generateLotSlipPdf({
    required ConsignmentLot lot,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final pdf = pw.Document();
    final dayStr = lot.createdAt != null
        ? '${lot.createdAt!.day.toString().padLeft(2, '0')}/${lot.createdAt!.month.toString().padLeft(2, '0')}/${lot.createdAt!.year}'
        : 'Today';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green800, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    shopName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ),
                if (shopCity != null && shopCity.isNotEmpty)
                  pw.Center(
                    child: pw.Text('Grain Market, $shopCity',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 6),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'CONSIGNMENT LOT SLIP (Dheri Parcha)',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      lot.lotNumber,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
                pw.Text('Date: $dayStr', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 12),

                _detailRow('Farmer / Supplier (Zamindar):', lot.supplierName),
                _detailRow('Produce / Commodity (Jins):', lot.productName),
                _detailRow('Vehicle # (Gari Number):', lot.vehicleNumber),
                _detailRow('Bags Count (Boriyan):', '${lot.bagCount} bags'),
                _detailRow('Weight in KG (Wazan KG):',
                    '${lot.weightKg.toStringAsFixed(1)} KG'),
                _detailRow('Weight in Manns (Wazan Mann):',
                    '${lot.maunds.toStringAsFixed(2)} Manns (40 KG)'),

                if (lot.ratePerMaund > 0) ...[
                  pw.SizedBox(height: 6),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                  _detailRow('Winning Buyer (Kharidar):', lot.winningBuyerName),
                  _detailRow('Auction Rate (Boli Rate):',
                      'Rs. ${lot.ratePerMaund.toStringAsFixed(0)} / Mann'),
                  _detailRow('Estimated Total (Meezan):',
                      'Rs. ${lot.estimatedTotal.toStringAsFixed(0)}',
                      isBold: true),
                ],

                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Weighbridge Stamp (Kanta Mohar): ____________',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Munshi Sign: ____________',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _metricBlock(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            )),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _detailRow(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value.isNotEmpty ? value : '-',
              style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  /// Triggers system print or share dialog for the daily Boli sheet.
  static Future<void> printOrShareBoliSheet({
    required List<ConsignmentLot> lots,
    required DateTime date,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final bytes = await generateBoliSheetPdf(
      lots: lots,
      date: date,
      shopName: shopName,
      shopPhone: shopPhone,
      shopCity: shopCity,
    );
    final dayStr =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'BoliSheet_${shopName.replaceAll(' ', '_')}_$dayStr.pdf',
    );
  }

  /// Triggers system print for an individual lot weighing slip.
  static Future<void> printLotSlip({
    required ConsignmentLot lot,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final bytes = await generateLotSlipPdf(
      lot: lot,
      shopName: shopName,
      shopPhone: shopPhone,
      shopCity: shopCity,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'LotSlip_${lot.lotNumber}.pdf',
    );
  }
}
