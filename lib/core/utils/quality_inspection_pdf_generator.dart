// Professional A4 PDF Generator for Commodity Quality Analysis,
// Moisture Deductions & Cold Chain Temperature Compliance Certificates
// (*جنس لیب کوالٹی سرٹیفکیٹ، نمی کٹوتی پرچہ اور کولڈ روم لاگ رجسٹر*).

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/quality_inspection_model.dart';

class QualityInspectionPdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');

  // =========================================================================
  // 1. OFFICIAL QUALITY INSPECTION & MOISTURE CERTIFICATE (A4 PORTRAIT)
  // =========================================================================

  static Future<Uint8List> generateQualityCertificatePdf({
    required QualityInspection inspection,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();
    final dateStr =
        DateFormat('dd MMMM yyyy, hh:mm a').format(inspection.inspectionDate);

    final excessMoisture = (inspection.moisturePercentage -
            inspection.baseMoisturePercentage)
        .clamp(0.0, 50.0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
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
                      pw.Text(
                        'COMMODITY TESTING LAB & QUALITY GRADING WING',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.teal800),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'CERTIFICATE OF QUALITY',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.Text('کوالٹی و کٹوتی سرٹیفکیٹ',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Cert #: ${inspection.certificateNumber}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.5, color: PdfColors.teal),
              pw.SizedBox(height: 10),

              // Overview Key-Value Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildLabelValue(
                            'Commodity / جنس', inspection.commodityName),
                        pw.SizedBox(height: 4),
                        _buildLabelValue('Variety / قسم',
                            inspection.variety.isEmpty ? 'Standard' : inspection.variety),
                        pw.SizedBox(height: 4),
                        _buildLabelValue('Vehicle # / گاڑی نمبر',
                            inspection.vehicleNumber.isEmpty ? 'N/A' : inspection.vehicleNumber),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildLabelValue('Party / Grower',
                            inspection.partyName.isEmpty ? 'General Mandi Lot' : inspection.partyName),
                        pw.SizedBox(height: 4),
                        _buildLabelValue('Date & Time', dateStr),
                        pw.SizedBox(height: 4),
                        _buildLabelValue(
                            'Sample Weight', '${inspection.sampleWeightGrams.toStringAsFixed(0)} Grams'),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: _getGradePdfColor(inspection.qualityGrade),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'OVERALL GRADE',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.white),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            inspection.qualityGrade.labelEnglish.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Lab Test Parameters Table
              pw.Text(
                'LABORATORY PHYSICAL & MOISTURE ANALYSIS (لیبارٹری ٹیسٹ رپورٹ)',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    children: [
                      _th('Quality Parameter / ٹیسٹ پیرامیٹر'),
                      _th('Tested Value (حاصل کردہ)'),
                      _th('Permissible / Base Limit'),
                      _th('Deduction Rate'),
                      _th('Katoti % (کٹوتی)'),
                    ],
                  ),
                  _tr(
                    'Moisture Content / نمی کا تناسب',
                    '${inspection.moisturePercentage.toStringAsFixed(1)} %',
                    '${inspection.baseMoisturePercentage.toStringAsFixed(1)} %',
                    '1 : 1 (Shrinkage)',
                    '${excessMoisture.toStringAsFixed(2)} %',
                    isHighlight: excessMoisture > 0,
                  ),
                  _tr(
                    'Foreign Matter / کچرا و مٹی',
                    '${inspection.foreignMatterPercentage.toStringAsFixed(1)} %',
                    '1.0 %',
                    '1 : 1',
                    '${inspection.foreignMatterPercentage.toStringAsFixed(2)} %',
                    isHighlight: inspection.foreignMatterPercentage > 1.0,
                  ),
                  _tr(
                    'Broken Grain / ٹوٹا دانہ',
                    '${inspection.brokenGrainPercentage.toStringAsFixed(1)} %',
                    '2.0 %',
                    '0.5 : 1',
                    '${(inspection.brokenGrainPercentage * 0.5).toStringAsFixed(2)} %',
                  ),
                  _tr(
                    'Damaged / Weeviled / داغی دانہ',
                    '${inspection.damagedGrainPercentage.toStringAsFixed(1)} %',
                    '1.0 %',
                    '0.75 : 1',
                    '${(inspection.damagedGrainPercentage * 0.75).toStringAsFixed(2)} %',
                  ),
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _td('TOTAL DEDUCTION (کل کٹوتی تناسب)', isBold: true),
                      _td('-', align: pw.TextAlign.center),
                      _td('-', align: pw.TextAlign.center),
                      _td('-', align: pw.TextAlign.center),
                      _td(
                        '${inspection.totalDeductionPercentage.toStringAsFixed(2)} %',
                        isBold: true,
                        align: pw.TextAlign.right,
                        textColor: PdfColors.red900,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Weight Deduction & Net Certified Weight Banner
              pw.Text(
                'CERTIFIED WEIGHT & DEDUCTION SCHEDULE (حتمی تصدیق شدہ وزن)',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  border: pw.Border.all(color: PdfColors.teal400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Gross Weight (بھرا وزن)',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${_currencyFmt.format(inspection.grossWeightKg)} KG',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.Text(
                          '(${((inspection.grossWeightKg) / 40.0).toStringAsFixed(2)} Maunds)',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Container(height: 35, width: 1, color: PdfColors.teal200),
                    pw.Column(
                      children: [
                        pw.Text('Quality Deduction (کٹوتی وزن)',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '- ${_currencyFmt.format(inspection.deductionWeightKg)} KG',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red900,
                          ),
                        ),
                        pw.Text(
                          '(- ${(inspection.deductionWeightKg / 40.0).toStringAsFixed(2)} Maunds)',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.red700),
                        ),
                      ],
                    ),
                    pw.Container(height: 35, width: 1, color: PdfColors.teal200),
                    pw.Column(
                      children: [
                        pw.Text('Net Certified Weight (صاف وزن)',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${_currencyFmt.format(inspection.netWeightKg)} KG',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.Text(
                          '${inspection.netWeightMaunds.toStringAsFixed(2)} Maunds (من)',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Storage Conditions / Notes
              if (inspection.temperatureCelsius != null ||
                  inspection.humidityPercentage != null ||
                  inspection.chamberOrLocation.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (inspection.chamberOrLocation.isNotEmpty)
                        pw.Text(
                            'Chamber / Room: ${inspection.chamberOrLocation}',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey800)),
                      if (inspection.temperatureCelsius != null)
                        pw.Text(
                            'Core Temp: ${inspection.temperatureCelsius!.toStringAsFixed(1)} °C',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey800)),
                      if (inspection.humidityPercentage != null)
                        pw.Text(
                            'Relative Humidity: ${inspection.humidityPercentage!.toStringAsFixed(1)} % RH',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey800)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
              ],

              if (inspection.notes.isNotEmpty) ...[
                pw.Text('Inspector Notes / ہدایات:',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(inspection.notes,
                    style: const pw.TextStyle(
                        fontSize: 8.5, color: PdfColors.grey700)),
                pw.SizedBox(height: 14),
              ],

              pw.Spacer(),

              // Signatures & Stamp
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          inspection.testerName.isNotEmpty
                              ? inspection.testerName
                              : 'Quality Inspector',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('دستخط کوالٹی انسپکٹر',
                          style: const pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text('Farmer / Transporter',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('دستخط زمیندار / ڈرائیور',
                          style: const pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text('Mandi Commission Agent',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('مہر و دستخط منڈی آڑھتی',
                          style: const pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Certified under Mandi Lab Quality Standards • Cloud ERP',
                  style:
                      const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // =========================================================================
  // 2. COLD CHAIN CHAMBER COMPLIANCE LOG SHEET (A4 LANDSCAPE)
  // =========================================================================

  static Future<Uint8List> generateColdChainLogSheetPdf({
    required List<ColdChainLog> logs,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
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
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'COLD CHAIN STORAGE TEMPERATURE & HUMIDITY AUDIT REGISTER (کولڈ روم لاگ)',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.Text('Total Chamber Logs: ${logs.length}',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.teal),
              pw.SizedBox(height: 8),

              // Logs Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    children: [
                      _th('Date & Time'),
                      _th('Chamber / Cold Room'),
                      _th('Core Temp (°C)'),
                      _th('Safe Range (°C)'),
                      _th('Humidity (% RH)'),
                      _th('Status'),
                      _th('Sensor / Device'),
                      _th('Inspector'),
                      _th('Corrective Action Taken'),
                    ],
                  ),
                  ...logs.map((log) {
                    final statusColor = log.status == ColdChainStatus.optimal
                        ? PdfColors.green800
                        : (log.status == ColdChainStatus.warning
                            ? PdfColors.orange800
                            : PdfColors.red800);

                    return pw.TableRow(
                      children: [
                        _td(DateFormat('dd/MM hh:mm a').format(log.recordedAt)),
                        _td(log.chamberName, isBold: true),
                        _td('${log.temperatureCelsius.toStringAsFixed(1)} °C',
                            align: pw.TextAlign.right,
                            textColor: statusColor,
                            isBold: true),
                        _td(
                            '${log.minTempThreshold.toStringAsFixed(0)} - ${log.maxTempThreshold.toStringAsFixed(0)} °C',
                            align: pw.TextAlign.center),
                        _td('${log.humidityPercentage.toStringAsFixed(1)} %',
                            align: pw.TextAlign.right),
                        _td(log.status.labelEnglish,
                            textColor: statusColor, isBold: true),
                        _td(log.sensorDeviceId.isEmpty
                            ? 'Manual Probe'
                            : log.sensorDeviceId),
                        _td(log.inspectorName.isEmpty
                            ? 'Munshi'
                            : log.inspectorName),
                        _td(log.correctiveAction.isEmpty
                            ? '-'
                            : log.correctiveAction),
                      ],
                    );
                  }),
                ],
              ),
              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Official Cold Storage HACCP & Mandi Quality Record',
                      style: const pw.TextStyle(
                          fontSize: 7.5, color: PdfColors.grey500)),
                  pw.Text(
                    'Page 1 of 1 • Mandi Cloud ERP',
                    style: const pw.TextStyle(
                        fontSize: 7.5, color: PdfColors.grey500),
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

  // =========================================================================
  // PRINT HELPERS
  // =========================================================================

  static Future<void> printQualityCertificate({
    required QualityInspection inspection,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdfBytes = await generateQualityCertificatePdf(
      inspection: inspection,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'QC_${inspection.certificateNumber}_${inspection.commodityName}.pdf',
    );
  }

  static Future<void> printColdChainLogSheet({
    required List<ColdChainLog> logs,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdfBytes = await generateColdChainLogSheetPdf(
      logs: logs,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Cold_Chain_Audit_${DateFormat("yyyyMMdd").format(DateTime.now())}.pdf',
    );
  }

  // =========================================================================
  // PRIVATE TABLE HELPERS
  // =========================================================================

  static pw.Widget _buildLabelValue(String label, String value) {
    return pw.Row(
      children: [
        pw.Text('$label: ',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900)),
      ],
    );
  }

  static PdfColor _getGradePdfColor(QualityGrade grade) {
    switch (grade) {
      case QualityGrade.gradeASuper:
        return PdfColors.green800;
      case QualityGrade.gradeBFaq:
        return PdfColors.blue800;
      case QualityGrade.gradeCSubstandard:
        return PdfColors.orange800;
      case QualityGrade.rejected:
        return PdfColors.red800;
    }
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
      ),
    );
  }

  static pw.Widget _td(
    String text, {
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor textColor = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }

  static pw.TableRow _tr(
    String param,
    String value,
    String base,
    String rate,
    String deduction, {
    bool isHighlight = false,
  }) {
    return pw.TableRow(
      decoration: isHighlight
          ? const pw.BoxDecoration(color: PdfColors.amber50)
          : null,
      children: [
        _td(param, isBold: isHighlight),
        _td(value, align: pw.TextAlign.center, isBold: isHighlight),
        _td(base, align: pw.TextAlign.center),
        _td(rate, align: pw.TextAlign.center),
        _td(deduction,
            align: pw.TextAlign.right,
            isBold: isHighlight,
            textColor: isHighlight ? PdfColors.red800 : PdfColors.black),
      ],
    );
  }
}
