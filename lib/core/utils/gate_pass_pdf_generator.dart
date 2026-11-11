// Printable PDF Slip Generator for Mandi Gate Pass & Inward Token
// (*گیٹ انٹری ٹوکن سلپ اور گیٹ آؤٹ کلیرنس پاس*).

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/data/models/gate_pass_model.dart';

class GatePassPdfGenerator {
  static final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  // =========================================================================
  // 1. INWARD GATE ENTRY TOKEN SLIP (80mm Roll or A6 Slip)
  // =========================================================================

  static Future<Uint8List> generateTokenSlipPdf({
    required GatePassModel gatePass,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          150 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                shopName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (shopAddress != null && shopAddress.isNotEmpty)
                pw.Text(
                  shopAddress,
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
              if (shopPhone != null && shopPhone.isNotEmpty)
                pw.Text(
                  'Tel: $shopPhone',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.teal800,
                ),
                child: pw.Text(
                  'MANDI INWARD TOKEN / گیٹ ٹوکن',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 6),

              // Large Token Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal800, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('TOKEN NUMBER / ٹوکن نمبر',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      gatePass.tokenNumber,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                    if (gatePass.assignedPlatform != null && gatePass.assignedPlatform!.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Assigned: ${gatePass.assignedPlatform}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Details Table
              _buildRow('Vehicle / گاڑی:', gatePass.vehicleNumber),
              _buildRow('Driver / ڈرائیور:', gatePass.driverName),
              if (gatePass.driverPhone != null && gatePass.driverPhone!.isNotEmpty)
                _buildRow('Phone / فون:', gatePass.driverPhone!),
              _buildRow('Farmer / زمیندار:', gatePass.farmerName),
              _buildRow('Crop / جنس:', gatePass.commodityName),
              _buildRow('Est. Bags / متوقع بوریاں:', '${gatePass.estimatedBags}'),
              _buildRow('Inward Time / آمد:', gatePass.inwardTimeFormatted),

              if (gatePass.grossWeightKg != null)
                _buildRow('Gross Wt / وزن:', '${_numberFmt.format(gatePass.grossWeightKg)} kg'),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey500),
              pw.SizedBox(height: 4),

              pw.BarcodeWidget(
                data: 'GATE-${gatePass.tokenNumber}-${gatePass.id.substring(0, 8)}',
                barcode: pw.Barcode.code128(),
                width: 140,
                height: 26,
                drawText: false,
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'براہ کرم ٹوکن نمبر پکارنے پر گاڑی پھڑ پر لائیں۔',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // =========================================================================
  // 2. GATE-OUT SECURITY CLEARANCE PASS (A5 Landscape)
  // =========================================================================

  static Future<Uint8List> generateGateOutPassPdf({
    required GatePassModel gatePass,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
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
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('SECURITY GATE-OUT PASS / گیٹ آؤٹ کلیئرنس پاس',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.green800,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'CLEARED / پاس',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.blueGrey800),
              pw.SizedBox(height: 8),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildRow('Token No:', gatePass.tokenNumber),
                        _buildRow('Vehicle No:', gatePass.vehicleNumber),
                        _buildRow('Driver Name:', gatePass.driverName),
                        _buildRow('Farmer / Zamindar:', gatePass.farmerName),
                        _buildRow('Commodity:', gatePass.commodityName),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildRow('Inward Time:', gatePass.inwardTimeFormatted),
                        _buildRow('Outward Time:', gatePass.outwardTimeFormatted ?? DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())),
                        _buildRow('Gross Weight:', '${_numberFmt.format(gatePass.grossWeightKg ?? 0)} kg'),
                        _buildRow('Tare Weight:', '${_numberFmt.format(gatePass.tareWeightKg ?? 0)} kg'),
                        _buildRow('Net Crop Weight:', '${_numberFmt.format(gatePass.netWeightKg ?? 0)} kg (${(gatePass.netMaunds ?? 0).toStringAsFixed(2)} Maunds)'),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 100, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('Weighbridge Operator', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 100, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('Munshi / Shop In-Charge', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 100, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('Gate Security Officer', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
          pw.Text(value, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }
}
