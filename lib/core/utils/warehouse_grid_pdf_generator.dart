// Printable A4 PDF Generator for Visual 2D Godown & Cold Storage Floor Grid
// (*گودام اور کولڈ سٹوریج کا تصویری نقشہ رپورٹ*).

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/data/models/warehouse_grid_model.dart';

class WarehouseGridPdfGenerator {
  static final _numberFmt = NumberFormat('#,##0', 'en_US');

  // =========================================================================
  // 1. WAREHOUSE & COLD STORAGE FLOOR OCCUPANCY REPORT (A4 PORTRAIT)
  // =========================================================================

  static Future<Uint8List> generateWarehouseOccupancyReportPdf({
    required List<WarehouseGridBayModel> bays,
    required String chamberCode,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

    int totalCapacity = 0;
    int totalStored = 0;
    int occupiedBays = 0;
    int overdueBays = 0;

    for (final bay in bays) {
      totalCapacity += bay.maxCapacityBags;
      totalStored += bay.currentBags;
      if (bay.currentBags > 0) {
        occupiedBays++;
      }
      if (bay.isOverdue) {
        overdueBays++;
      }
    }

    final overallOccupancy = totalCapacity > 0
        ? (totalStored / totalCapacity * 100).toStringAsFixed(1)
        : '0.0';

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
                        'GODOWN FLOOR PLAN & BAY OCCUPANCY / گودام سٹوریج نقشہ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                      pw.Text('Chamber / سیکشن: $chamberCode',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
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
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.teal900),
              pw.SizedBox(height: 8),

              // KPI Summary
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildKpiBox('Total Capacity / کل گنجائش', '${_numberFmt.format(totalCapacity)} Bags', PdfColors.blueGrey50),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _buildKpiBox('Current Stock / موجودہ مال', '${_numberFmt.format(totalStored)} Bags ($overallOccupancy%)', PdfColors.teal50),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _buildKpiBox('Active Bays / زیر استعمال', '$occupiedBays / ${bays.length}', PdfColors.amber50),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _buildKpiBox('Overdue >90 Days', '$overdueBays Bays', overdueBays > 0 ? PdfColors.red50 : PdfColors.grey100),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Detailed Bay Table
              pw.Text(
                'STORAGE BAYS DETAILED REGISTER / خانوں اور بوریوں کی تفصیل',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ),
              pw.SizedBox(height: 6),

              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal900),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                headers: [
                  'Bay (خانہ)',
                  'Crop / جنس',
                  'Farmer / کسان',
                  'Lot Code',
                  'Bags / Capacity',
                  'Occupancy',
                  'Days in Store',
                  'Status',
                ],
                data: bays.map((b) {
                  return [
                    b.bayCode,
                    b.cropName ?? '-',
                    b.farmerName ?? '-',
                    b.lotCode ?? '-',
                    '${b.currentBags} / ${b.maxCapacityBags}',
                    '${b.occupancyPercent.toStringAsFixed(0)}%',
                    b.currentBags > 0 ? '${b.daysInStorage} d' : '-',
                    b.isOverdue ? 'OVERDUE' : b.status.labelEnglish,
                  ];
                }).toList(),
              ),

              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Warehouse In-Charge: _______________________', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Mandi Munshi: _______________________', style: const pw.TextStyle(fontSize: 8)),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
          pw.SizedBox(height: 2),
          pw.Text(val, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
        ],
      ),
    );
  }
}
