import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/data/models/weighbridge_ticket_model.dart';

/// Generates high-fidelity printable Weighbridge Slips (دھرم کنڈا وزن پرچی)
/// and Daily Weighbridge Register Reports in A4 Landscape and Slip formats.
class WeighbridgeSlipPdfGenerator {
  static final _numberFormat = NumberFormat('#,##0.00', 'en_US');
  static final _intFormat = NumberFormat('#,##0', 'en_US');
  static final _dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

  /// Generates an official 2-Up / Single Official Weighbridge Certificate Slip.
  static Future<Uint8List> generateSlipPdf({
    required String shopName,
    required WeighbridgeTicket ticket,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey800, width: 1.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shopName.isEmpty ? 'Mandi Commission Shop' : shopName,
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Mandi Dharam Kanda / Electronic Weighbridge Ticket',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.Text(
                          'دھرم کنڈا وزن کمپیوٹرائزڈ رسید',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        border: pw.Border.all(color: PdfColors.green800, width: 1.2),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Slip No: ${ticket.ticketNumber}',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Status: ${ticket.status.labelEnglish}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: ticket.isAwaitingTare
                                  ? PdfColors.amber800
                                  : PdfColors.green800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColors.grey400, thickness: 1),
                pw.SizedBox(height: 8),

                // ── Vehicle & Party Meta ─────────────────────────────────────────────
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.2),
                    1: pw.FlexColumnWidth(2.0),
                    2: pw.FlexColumnWidth(1.2),
                    3: pw.FlexColumnWidth(2.0),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        _buildLabel('Vehicle No:'),
                        _buildValue(ticket.vehicleNumber, isBold: true),
                        _buildLabel('Vehicle Type:'),
                        _buildValue(ticket.vehicleType.labelEnglish),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildLabel('Driver Name:'),
                        _buildValue(
                          ticket.driverName.isEmpty
                              ? 'N/A'
                              : '${ticket.driverName} (${ticket.driverPhone})',
                        ),
                        _buildLabel('Commodity:'),
                        _buildValue(
                          ticket.commodityName.isEmpty
                              ? 'General Mandi Crop'
                              : ticket.commodityName,
                          isBold: true,
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildLabel('Party / Farmer:'),
                        _buildValue(
                          ticket.partyName.isEmpty ? 'Walk-in Party' : ticket.partyName,
                          isBold: true,
                        ),
                        _buildLabel('Total Bags:'),
                        _buildValue('${_intFormat.format(ticket.bagCount)} Bags'),
                      ],
                    ),
                    if (ticket.operatorName.isNotEmpty)
                      pw.TableRow(
                        children: [
                          _buildLabel('Scale Operator:'),
                          _buildValue(ticket.operatorName),
                          _buildLabel('Printed At:'),
                          _buildValue(_dateFormat.format(DateTime.now())),
                        ],
                      ),
                  ],
                ),

                pw.SizedBox(height: 14),

                // ── Weight Measurements Box ──────────────────────────────────────────
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(
                      inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                    ),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2.5),
                      1: pw.FlexColumnWidth(1.8),
                      2: pw.FlexColumnWidth(1.8),
                      3: pw.FlexColumnWidth(2.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _buildTh('Weight Stage (مرحلہ)'),
                          _buildTh('Weight (KG)'),
                          _buildTh('Maunds (من)'),
                          _buildTh('Date & Time'),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _buildTd('1st Weight (Gross / بھری گاڑی)'),
                          _buildTd(
                            '${_numberFormat.format(ticket.grossWeightKg)} KG',
                            isBold: true,
                          ),
                          _buildTd('${_numberFormat.format(ticket.grossMaunds)} Maunds'),
                          _buildTd(_dateFormat.format(ticket.grossWeighedAt)),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _buildTd('2nd Weight (Tare / خالی گاڑی)'),
                          _buildTd(
                            ticket.tareWeightKg > 0
                                ? '${_numberFormat.format(ticket.tareWeightKg)} KG'
                                : 'Pending Tare...',
                            isBold: ticket.tareWeightKg > 0,
                            color: ticket.tareWeightKg > 0
                                ? PdfColors.black
                                : PdfColors.amber800,
                          ),
                          _buildTd(
                            ticket.tareWeightKg > 0
                                ? '${_numberFormat.format(ticket.tareMaunds)} Maunds'
                                : '-',
                          ),
                          _buildTd(
                            ticket.tareWeighedAt != null
                                ? _dateFormat.format(ticket.tareWeighedAt!)
                                : 'Awaiting 2nd Weight',
                          ),
                        ],
                      ),
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                        children: [
                          _buildTd('Net Weight (صاف وزن گاڑی)'),
                          _buildTd(
                            '${_numberFormat.format(ticket.computedNetWeightKg)} KG',
                            isBold: true,
                            color: PdfColors.blue900,
                          ),
                          _buildTd(
                            '${_numberFormat.format(ticket.netMaunds)} Maunds',
                            isBold: true,
                            color: PdfColors.blue900,
                          ),
                          _buildTd('Gross - Tare'),
                        ],
                      ),
                      if (ticket.deductionKg > 0)
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.red50),
                          children: [
                            _buildTd(
                              'Deduction / Katoti (${ticket.deductionReason.isEmpty ? 'Moisture/Trash' : ticket.deductionReason})',
                              color: PdfColors.red800,
                            ),
                            _buildTd(
                              '-${_numberFormat.format(ticket.deductionKg)} KG',
                              color: PdfColors.red800,
                              isBold: true,
                            ),
                            _buildTd(
                              '-${_numberFormat.format(ticket.deductionKg / 40.0)} Maunds',
                              color: PdfColors.red800,
                            ),
                            _buildTd('Deduction'),
                          ],
                        ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 14),

                // ── Final Certified Payable Weight ───────────────────────────────────
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green800, width: 2),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'FINAL BILLABLE WEIGHT | خالص قابلِ ادائیگی وزن',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Certified net weight for commercial settlement',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                '${_numberFormat.format(ticket.computedFinalWeightKg)} KG',
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green900,
                                ),
                              ),
                              pw.Text(
                                '${_numberFormat.format(ticket.maunds)} Maunds (من)',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // ── Fee & Notes ──────────────────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Weighbridge Fee: Rs. ${_numberFormat.format(ticket.kandaFee)} (Paid by: ${ticket.feePaidBy.labelEnglish})',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    if (ticket.notes.isNotEmpty)
                      pw.Text(
                        'Note: ${ticket.notes}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),

                pw.Spacer(),

                // ── Signature Footer ─────────────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(color: PdfColors.grey700, width: 1),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Driver / Party Signature\n(دستخط ڈرائیور / مالک مال)',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(color: PdfColors.grey700, width: 1),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Weighmaster Signature & Seal\n(دستخط کنڈا انچارج و مہر)',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                        ),
                      ],
                    ),
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

  /// Generates a comprehensive A4 Landscape Daily Register of all weighbridge tickets.
  static Future<Uint8List> generateRegisterPdf({
    required String shopName,
    required List<WeighbridgeTicket> tickets,
    required WeighbridgeSummary summary,
  }) async {
    final pdf = pw.Document();
    final printTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // ── Header ──────────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      shopName.isEmpty ? 'Mandi Commission Shop' : shopName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Daily Weighbridge Operations & Dharam Kanda Register',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Printed: $printTime',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.green300),
                      ),
                      child: pw.Text(
                        'Total Tickets: ${summary.totalTicketsCount}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),

            // ── Summary KPI Cards ────────────────────────────────────────────────
            pw.Row(
              children: [
                _buildKpiCard(
                  'Awaiting Tare',
                  '${summary.awaitingTareCount} Vehicles',
                  summary.awaitingTareCount > 0 ? PdfColors.amber100 : PdfColors.grey100,
                  summary.awaitingTareCount > 0 ? PdfColors.amber900 : PdfColors.grey800,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Completed Slips',
                  '${summary.completedCount}',
                  PdfColors.green100,
                  PdfColors.green900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Total Net Weighed',
                  '${_numberFormat.format(summary.totalFinalWeightKg)} KG',
                  PdfColors.blue100,
                  PdfColors.blue900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Total Maunds (من)',
                  '${_numberFormat.format(summary.totalFinalMaunds)} Maunds',
                  PdfColors.teal100,
                  PdfColors.teal900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Kanda Fee Revenue',
                  'Rs. ${_numberFormat.format(summary.totalKandaFee)}',
                  PdfColors.purple100,
                  PdfColors.purple900,
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Tickets Table ────────────────────────────────────────────────────
            if (tickets.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(20),
                child: pw.Text(
                  'No weighbridge tickets recorded for this period.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.2), // Slip #
                  1: pw.FlexColumnWidth(1.5), // Vehicle
                  2: pw.FlexColumnWidth(1.4), // Type
                  3: pw.FlexColumnWidth(2.0), // Party
                  4: pw.FlexColumnWidth(1.6), // Commodity
                  5: pw.FlexColumnWidth(1.2), // Gross KG
                  6: pw.FlexColumnWidth(1.2), // Tare KG
                  7: pw.FlexColumnWidth(1.3), // Final KG
                  8: pw.FlexColumnWidth(1.3), // Maunds
                  9: pw.FlexColumnWidth(1.0), // Fee
                  10: pw.FlexColumnWidth(1.2), // Status
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    children: [
                      _buildHeaderCell('Slip #'),
                      _buildHeaderCell('Vehicle #'),
                      _buildHeaderCell('Vehicle Type'),
                      _buildHeaderCell('Party Name'),
                      _buildHeaderCell('Commodity'),
                      _buildHeaderCell('Gross (KG)'),
                      _buildHeaderCell('Tare (KG)'),
                      _buildHeaderCell('Final (KG)'),
                      _buildHeaderCell('Maunds'),
                      _buildHeaderCell('Fee'),
                      _buildHeaderCell('Status'),
                    ],
                  ),
                  ...tickets.map((t) {
                    final statusColor = t.isAwaitingTare
                        ? PdfColors.amber900
                        : (t.status == WeighbridgeStatus.completed
                            ? PdfColors.green900
                            : PdfColors.grey700);

                    return pw.TableRow(
                      decoration: t.isAwaitingTare
                          ? const pw.BoxDecoration(color: PdfColors.amber50)
                          : null,
                      children: [
                        _buildCell(t.ticketNumber, isBold: true),
                        _buildCell(t.vehicleNumber, isBold: true),
                        _buildCell(t.vehicleType.labelEnglish),
                        _buildCell(t.partyName.isEmpty ? '-' : t.partyName),
                        _buildCell(t.commodityName.isEmpty ? '-' : t.commodityName),
                        _buildCell(_numberFormat.format(t.grossWeightKg), alignRight: true),
                        _buildCell(
                          t.tareWeightKg > 0 ? _numberFormat.format(t.tareWeightKg) : 'Pending',
                          alignRight: true,
                          color: t.tareWeightKg > 0 ? PdfColors.black : PdfColors.amber900,
                        ),
                        _buildCell(
                          _numberFormat.format(t.computedFinalWeightKg),
                          alignRight: true,
                          isBold: true,
                        ),
                        _buildCell(
                          _numberFormat.format(t.maunds),
                          alignRight: true,
                          isBold: true,
                        ),
                        _buildCell('Rs. ${_intFormat.format(t.kandaFee)}', alignRight: true),
                        _buildCell(t.status.labelEnglish, color: statusColor, isBold: true),
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

  static pw.Widget _buildKpiCard(
    String title,
    String value,
    PdfColor bgColor,
    PdfColor textColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 8,
                color: textColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isBold = false,
    bool alignRight = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildLabel(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    );
  }

  static pw.Widget _buildValue(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildTh(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildTd(
    String text, {
    bool isBold = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}
