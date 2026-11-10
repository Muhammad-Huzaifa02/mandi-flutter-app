import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/data/models/farmer_advance_model.dart';

/// Generates professional A4 PDF printouts for Farmer Pre-Harvest Crop Advances,
/// Input Financed Khatas (کھاد بیج کھاتہ), and Recovery Deductions.
class FarmerAdvancePdfGenerator {
  static final _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final _intFormat = NumberFormat('#,##0', 'en_US');
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Generates a dedicated farmer crop financing & recovery statement.
  static Future<Uint8List> generateFarmerStatementPdf({
    required String shopName,
    required String farmerName,
    String farmerPhone = '',
    required List<FarmerAdvance> advances,
    List<FarmerAdvanceRecovery> recoveries = const [],
  }) async {
    final pdf = pw.Document();
    final printTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    final totalPrincipal = advances.fold<double>(
        0.0, (sum, a) => sum + a.principalAmount);
    final totalMarkup = advances.fold<double>(
        0.0, (sum, a) => sum + a.computedMarkupAmount);
    final totalPayable = advances.fold<double>(
        0.0, (sum, a) => sum + a.computedTotalPayable);
    final totalRecovered = advances.fold<double>(
        0.0, (sum, a) => sum + a.recoveredAmount);
    final netOutstanding =
        (totalPayable - totalRecovered).clamp(0.0, double.infinity);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
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
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Farmer Crop Advance & Input Financing Statement',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      'زمیندار ایڈوانس اور کھاد بیج کھاتہ پرچہ',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Printed: $printTime',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        border: pw.Border.all(color: PdfColors.green300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'Total Loans: ${advances.length}',
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
            pw.Divider(color: PdfColors.grey400, thickness: 1),
            pw.SizedBox(height: 8),

            // ── Farmer Profile Box ───────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Farmer / Borrower: $farmerName',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (farmerPhone.isNotEmpty)
                        pw.Text(
                          'Phone: $farmerPhone',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Net Balance Due (بقایا قرضہ):',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Rs. ${_currencyFormat.format(netOutstanding)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: netOutstanding > 0
                              ? PdfColors.red900
                              : PdfColors.green900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // ── Summary KPI Cards ────────────────────────────────────────────────
            pw.Row(
              children: [
                _buildKpiCard(
                  'Total Principal',
                  'Rs. ${_currencyFormat.format(totalPrincipal)}',
                  PdfColors.blue100,
                  PdfColors.blue900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Markup / Profit',
                  'Rs. ${_currencyFormat.format(totalMarkup)}',
                  PdfColors.purple100,
                  PdfColors.purple900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Total Payable',
                  'Rs. ${_currencyFormat.format(totalPayable)}',
                  PdfColors.orange100,
                  PdfColors.orange900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Recovered Payouts',
                  'Rs. ${_currencyFormat.format(totalRecovered)}',
                  PdfColors.green100,
                  PdfColors.green900,
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Advance Disbursements Table ──────────────────────────────────────
            pw.Text(
              '1. Disbursed Advances & Agricultural Inputs (ایڈوانس تفصیل)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2), // Date
                1: pw.FlexColumnWidth(1.4), // Type
                2: pw.FlexColumnWidth(2.2), // Description
                3: pw.FlexColumnWidth(1.4), // Principal
                4: pw.FlexColumnWidth(1.1), // Markup
                5: pw.FlexColumnWidth(1.4), // Recovered
                6: pw.FlexColumnWidth(1.4), // Remaining
                7: pw.FlexColumnWidth(1.2), // Status
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  children: [
                    _buildHeaderCell('Date'),
                    _buildHeaderCell('Type'),
                    _buildHeaderCell('Description / Crop'),
                    _buildHeaderCell('Principal'),
                    _buildHeaderCell('Markup'),
                    _buildHeaderCell('Recovered'),
                    _buildHeaderCell('Balance'),
                    _buildHeaderCell('Status'),
                  ],
                ),
                ...advances.map((a) {
                  return pw.TableRow(
                    children: [
                      _buildCell(_dateFormat.format(a.disbursementDate)),
                      _buildCell(a.advanceType.labelEnglish),
                      _buildCell(
                        a.description.isNotEmpty
                            ? a.description
                            : (a.targetCrop.isNotEmpty
                                ? 'Crop: ${a.targetCrop}'
                                : '-'),
                      ),
                      _buildCell(
                        'Rs. ${_intFormat.format(a.principalAmount)}',
                        alignRight: true,
                        isBold: true,
                      ),
                      _buildCell(
                        a.computedMarkupAmount > 0
                            ? 'Rs. ${_intFormat.format(a.computedMarkupAmount)}'
                            : '0',
                        alignRight: true,
                      ),
                      _buildCell(
                        'Rs. ${_intFormat.format(a.recoveredAmount)}',
                        alignRight: true,
                        color: PdfColors.green900,
                      ),
                      _buildCell(
                        'Rs. ${_intFormat.format(a.computedRemainingBalance)}',
                        alignRight: true,
                        isBold: true,
                        color: a.computedRemainingBalance > 0
                            ? PdfColors.red900
                            : PdfColors.green900,
                      ),
                      _buildCell(a.status.labelEnglish),
                    ],
                  );
                }),
              ],
            ),

            if (recoveries.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                '2. Consignment Auction Recovery Deductions (فصل پر کٹوتی)',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.5),
                  1: pw.FlexColumnWidth(2.5),
                  2: pw.FlexColumnWidth(2.0),
                  3: pw.FlexColumnWidth(2.0),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.green50),
                    children: [
                      _buildHeaderCell('Recovery Date'),
                      _buildHeaderCell('Method / Channel'),
                      _buildHeaderCell('Notes'),
                      _buildHeaderCell('Recovered Amount'),
                    ],
                  ),
                  ...recoveries.map((r) {
                    return pw.TableRow(
                      children: [
                        _buildCell(_dateFormat.format(r.recoveryDate)),
                        _buildCell(r.recoveryMethod == 'consignment_deduction'
                            ? 'Auction Consignment Deduction'
                            : r.recoveryMethod),
                        _buildCell(r.notes.isEmpty ? '-' : r.notes),
                        _buildCell(
                          'Rs. ${_currencyFormat.format(r.recoveredAmount)}',
                          alignRight: true,
                          isBold: true,
                          color: PdfColors.green900,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],

            pw.Spacer(),

            // ── Signature Footer ─────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 150,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(
                            color: PdfColors.grey700,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Farmer Signature / Thumbprint\n(دستخط یا انگوٹھا زمیندار)',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 150,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(
                            color: PdfColors.grey700,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Commission Shop Seal & Signature\n(مہر و دستخط کمیشن شاپ)',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey800,
                      ),
                    ),
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

  /// Generates a comprehensive A4 Landscape Portfolio Register of all farmer advances.
  static Future<Uint8List> generateAdvancesRegisterPdf({
    required String shopName,
    required List<FarmerAdvance> advances,
    required FarmerAdvanceSummary summary,
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
                      'Farmer Crop Advances & Input Financing Register (زمیندار ایڈوانس کھاتہ)',
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
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.green300),
                      ),
                      child: pw.Text(
                        'Total Advances: ${summary.totalAdvancesCount}',
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
                  'Active Loans',
                  '${summary.activeCount} Farmers',
                  PdfColors.orange100,
                  PdfColors.orange900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Fully Recovered',
                  '${summary.fullyRecoveredCount}',
                  PdfColors.green100,
                  PdfColors.green900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Total Disbursed',
                  'Rs. ${_intFormat.format(summary.totalPrincipalDisbursed)}',
                  PdfColors.blue100,
                  PdfColors.blue900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Total Recovered',
                  'Rs. ${_intFormat.format(summary.totalRecovered)}',
                  PdfColors.teal100,
                  PdfColors.teal900,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  'Net Outstanding Balance',
                  'Rs. ${_intFormat.format(summary.netOutstandingBalance)}',
                  PdfColors.red100,
                  PdfColors.red900,
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Advances Table ───────────────────────────────────────────────────
            if (advances.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(20),
                child: pw.Text(
                  'No farmer advances recorded for this shop.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.0), // Date
                  1: pw.FlexColumnWidth(2.0), // Farmer
                  2: pw.FlexColumnWidth(1.4), // Type
                  3: pw.FlexColumnWidth(1.4), // Crop
                  4: pw.FlexColumnWidth(1.4), // Principal
                  5: pw.FlexColumnWidth(1.2), // Markup
                  6: pw.FlexColumnWidth(1.4), // Total Due
                  7: pw.FlexColumnWidth(1.4), // Recovered
                  8: pw.FlexColumnWidth(1.4), // Outstanding
                  9: pw.FlexColumnWidth(1.2), // Status
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    children: [
                      _buildHeaderCell('Date'),
                      _buildHeaderCell('Farmer Name'),
                      _buildHeaderCell('Type'),
                      _buildHeaderCell('Target Crop'),
                      _buildHeaderCell('Principal'),
                      _buildHeaderCell('Markup'),
                      _buildHeaderCell('Total Due'),
                      _buildHeaderCell('Recovered'),
                      _buildHeaderCell('Outstanding'),
                      _buildHeaderCell('Status'),
                    ],
                  ),
                  ...advances.map((a) {
                    final statusColor =
                        a.status == FarmerAdvanceStatus.fullyRecovered
                            ? PdfColors.green900
                            : (a.isOverdue
                                ? PdfColors.red900
                                : PdfColors.orange900);

                    return pw.TableRow(
                      decoration: a.isOverdue
                          ? const pw.BoxDecoration(color: PdfColors.red50)
                          : null,
                      children: [
                        _buildCell(_dateFormat.format(a.disbursementDate)),
                        _buildCell(a.farmerName, isBold: true),
                        _buildCell(a.advanceType.labelEnglish),
                        _buildCell(
                          a.targetCrop.isEmpty ? '-' : a.targetCrop,
                        ),
                        _buildCell(
                          'Rs. ${_intFormat.format(a.principalAmount)}',
                          alignRight: true,
                        ),
                        _buildCell(
                          'Rs. ${_intFormat.format(a.computedMarkupAmount)}',
                          alignRight: true,
                        ),
                        _buildCell(
                          'Rs. ${_intFormat.format(a.computedTotalPayable)}',
                          alignRight: true,
                        ),
                        _buildCell(
                          'Rs. ${_intFormat.format(a.recoveredAmount)}',
                          alignRight: true,
                          color: PdfColors.green900,
                        ),
                        _buildCell(
                          'Rs. ${_intFormat.format(a.computedRemainingBalance)}',
                          alignRight: true,
                          isBold: true,
                          color: a.computedRemainingBalance > 0
                              ? PdfColors.red900
                              : PdfColors.green900,
                        ),
                        _buildCell(
                          a.status.labelEnglish,
                          color: statusColor,
                          isBold: true,
                        ),
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
}
