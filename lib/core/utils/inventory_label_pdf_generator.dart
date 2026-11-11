// Professional A4 & Multi-Up Printable Barcode / QR Pallet Labels,
// Stack Placards & Warehouse Inventory Roster PDF Generator
// (*گودام پیلیٹ بارکوڈ، کیو آر چٹہ لیبلز اور اسٹاک روسٹر پرنٹر*).

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/inventory_label_model.dart';

class InventoryLabelPdfGenerator {
  static final _numberFmt = NumberFormat('#,##0', 'en_US');

  // =========================================================================
  // 1. OFFICIAL PALLET & LOT PLACARD (A4 LANDSCAPE)
  // =========================================================================

  static Future<Uint8List> generateSinglePalletPlacardPdf({
    required InventoryLabel label,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();
    final dateStr =
        DateFormat('dd MMMM yyyy, hh:mm a').format(label.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey800, width: 2.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
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
                                  fontSize: 8.5, color: PdfColors.grey700)),
                        pw.Text(
                          'GRAIN TERMINAL & COLD STORAGE INVENTORY PLACARD',
                          style: const pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.teal800),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.teal50,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            label.labelType.labelEnglish.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900,
                            ),
                          ),
                          pw.Text(
                            label.labelCode,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1.5, color: PdfColors.blueGrey700),
                pw.SizedBox(height: 8),

                // Main Commodity & Location Row
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left Column: Big Commodity & Specs
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            label.displayCommodity.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            children: [
                              _infoChip(
                                'Location / گودام',
                                label.displayLocation.isNotEmpty
                                    ? label.displayLocation
                                    : 'General Yard',
                                color: PdfColors.blueGrey100,
                                textColor: PdfColors.blueGrey900,
                              ),
                              pw.SizedBox(width: 8),
                              _infoChip(
                                'Quality Grade',
                                label.qualityGrade.toUpperCase().replaceAll('_', ' '),
                                color: PdfColors.green100,
                                textColor: PdfColors.green900,
                              ),
                              pw.SizedBox(width: 8),
                              _infoChip(
                                'Packaging',
                                label.packageType.labelEnglish,
                                color: PdfColors.amber100,
                                textColor: PdfColors.amber900,
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 12),

                          // Large Weight & Bag Summary Banner
                          pw.Container(
                            padding: const pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey100,
                              border: pw.Border.all(color: PdfColors.grey300),
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(6)),
                            ),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceAround,
                              children: [
                                _metricBox(
                                    'BAG COUNT', '${label.bagCount} Bags'),
                                _metricBox('GROSS WEIGHT',
                                    '${_numberFmt.format(label.grossWeightKg)} KG'),
                                _metricBox('NET CERTIFIED',
                                    '${_numberFmt.format(label.netWeightKg)} KG'),
                                _metricBox(
                                  'NET MAUNDS (من)',
                                  '${label.netWeightMaunds.toStringAsFixed(2)} Mnds',
                                  isHighlight: true,
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 10),

                          // Metadata details
                          pw.Table(
                            border: pw.TableBorder.all(
                                color: PdfColors.grey300, width: 0.5),
                            children: [
                              _metaRow('Party / Grower (زمیندار / بیوپاری):',
                                  label.partyName.isNotEmpty ? label.partyName : 'Standard Mandi Arrival'),
                              _metaRow('Vehicle / Carriage (گاڑی نمبر):',
                                  label.vehicleNumber.isNotEmpty ? label.vehicleNumber : 'Not Specified'),
                              _metaRow('Entry Timestamp (تاریخ آمد):', dateStr),
                              if (label.notes.isNotEmpty)
                                _metaRow('Inspection / Stack Notes:', label.notes),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),

                    // Right Column: Barcode & QR Code Section
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(
                              color: PdfColors.teal700, width: 1.5),
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'AUTOMATED SCANNING TAG',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal900,
                              ),
                            ),
                            pw.SizedBox(height: 8),

                            // 1D Code128 Barcode
                            pw.Container(
                              height: 65,
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.code128(),
                                data: label.barcodeValue.isNotEmpty
                                    ? label.barcodeValue
                                    : label.labelCode,
                                drawText: true,
                                textStyle: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.black,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                            pw.SizedBox(height: 8),

                            // 2D QR Code
                            pw.Container(
                              width: 100,
                              height: 100,
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: label.qrPayload.isNotEmpty
                                    ? label.qrPayload
                                    : label.labelCode,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Scan with Mandi Camera Reader',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                // Footer signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Stack Master / Warehouse Munshi (گودام منشی)',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('Certified under Mandi Barcode Logistics • Cloud ERP',
                        style: const pw.TextStyle(
                            fontSize: 7.5, color: PdfColors.grey600)),
                    pw.Text('Gate Pass / Security Officer (چوکیدار)',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
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

  // =========================================================================
  // 2. MULTI-UP ADHESIVE STICKERS (4 PER A4 PAGE)
  // =========================================================================

  static Future<Uint8List> generate4UpAdhesiveStickerSheetPdf({
    required List<InventoryLabel> labels,
    required String shopName,
  }) async {
    final pdf = pw.Document();

    // Group labels in chunks of 4
    for (var i = 0; i < labels.length; i += 4) {
      final chunk = labels.skip(i).take(4).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
              children: chunk.map((lbl) => _buildStickerCard(lbl, shopName)).toList(),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // =========================================================================
  // 3. WAREHOUSE MASTER LOT & PALLET ROSTER (A4 LANDSCAPE)
  // =========================================================================

  static Future<Uint8List> generateInventoryRosterPdf({
    required List<InventoryLabel> labels,
    required String shopName,
    String? shopAddress,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now());

    final totalBags = labels.fold<int>(0, (sum, e) => sum + e.bagCount);
    final totalNetKg = labels.fold<double>(0.0, (sum, e) => sum + e.netWeightKg);
    final totalNetMaunds =
        labels.fold<double>(0.0, (sum, e) => sum + e.netWeightMaunds);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
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
                        shopName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'WAREHOUSE INVENTORY & PALLET STACKING ROSTER',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.teal800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Report Date: $nowStr',
                          style: const pw.TextStyle(
                              fontSize: 8.5, color: PdfColors.grey700)),
                      pw.Text('Total Stacked Lots: ${labels.length}',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.blueGrey700),
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Total Bags: ${_numberFmt.format(totalBags)}',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900)),
                  pw.Text('Net Weight: ${_numberFmt.format(totalNetKg)} KG',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900)),
                  pw.Text(
                      'Total Maunds: ${totalNetMaunds.toStringAsFixed(2)} Mnds',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Table of labels
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('#'),
                    _th('Label Code'),
                    _th('Barcode Data'),
                    _th('Type'),
                    _th('Commodity & Variety'),
                    _th('Location / Bay'),
                    _th('Bags', align: pw.TextAlign.right),
                    _th('Net KG', align: pw.TextAlign.right),
                    _th('Maunds', align: pw.TextAlign.right),
                    _th('Status', align: pw.TextAlign.center),
                  ],
                ),
                ...labels.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final lbl = entry.value;
                  return pw.TableRow(
                    children: [
                      _td('$idx', align: pw.TextAlign.center),
                      _td(lbl.labelCode, isBold: true),
                      _td(lbl.barcodeValue),
                      _td(lbl.labelType.labelEnglish),
                      _td(lbl.displayCommodity),
                      _td(lbl.displayLocation.isNotEmpty ? lbl.displayLocation : '-'),
                      _td('${lbl.bagCount}', align: pw.TextAlign.right),
                      _td(_numberFmt.format(lbl.netWeightKg), align: pw.TextAlign.right),
                      _td(lbl.netWeightMaunds.toStringAsFixed(2),
                          align: pw.TextAlign.right, isBold: true),
                      _td(lbl.status.labelEnglish, align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================

  static pw.Widget _buildStickerCard(InventoryLabel lbl, String shopName) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey800, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                shopName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.Text(
                lbl.labelCode,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
            ],
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.Text(
            lbl.displayCommodity.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.Text(
            '${lbl.bagCount} Bags • ${lbl.netWeightMaunds.toStringAsFixed(2)} Mnds (${_numberFmt.format(lbl.netWeightKg)} KG)',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
          ),
          pw.Text(
            'Location: ${lbl.displayLocation.isNotEmpty ? lbl.displayLocation : "Yard"}',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.teal800),
          ),
          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                height: 38,
                width: 140,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: lbl.barcodeValue.isNotEmpty ? lbl.barcodeValue : lbl.labelCode,
                  drawText: true,
                  textStyle: const pw.TextStyle(fontSize: 6.5),
                ),
              ),
              pw.Container(
                width: 44,
                height: 44,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: lbl.qrPayload.isNotEmpty ? lbl.qrPayload : lbl.labelCode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoChip(
    String label,
    String value, {
    required PdfColor color,
    required PdfColor textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textColor)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, color: textColor)),
        ],
      ),
    );
  }

  static pw.Widget _metricBox(String title, String value,
      {bool isHighlight = false}) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: isHighlight ? PdfColors.teal900 : PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: isHighlight ? PdfColors.teal900 : PdfColors.blueGrey900,
          ),
        ),
      ],
    );
  }

  static pw.TableRow _metaRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(label,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  static pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _td(String text,
      {pw.TextAlign align = pw.TextAlign.left,
      bool isBold = false,
      PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColors.black,
        ),
      ),
    );
  }

  static Future<void> printSinglePalletPlacard({
    required InventoryLabel label,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdfBytes = await generateSinglePalletPlacardPdf(
      label: label,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
    );
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Pallet_${label.labelCode}.pdf',
    );
  }

  static Future<void> print4UpStickers({
    required List<InventoryLabel> labels,
    required String shopName,
  }) async {
    final pdfBytes = await generate4UpAdhesiveStickerSheetPdf(
      labels: labels,
      shopName: shopName,
    );
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Stickers_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> printInventoryRoster({
    required List<InventoryLabel> labels,
    required String shopName,
    String? shopAddress,
  }) async {
    final pdfBytes = await generateInventoryRosterPdf(
      labels: labels,
      shopName: shopName,
      shopAddress: shopAddress,
    );
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Inventory_Roster_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
