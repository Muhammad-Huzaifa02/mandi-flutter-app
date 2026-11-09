import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/data/models/bank_account_model.dart';
import 'package:mandi/data/models/cheque_model.dart';

/// Generates professional A4 PDF printouts for Mandi Cheque Register,
/// In-hand Post-Dated Cheques (PDC), and Bank Account Portfolios.
class ChequeRegisterPdfGenerator {
  static final _currencyFormat = NumberFormat('#,##0', 'en_US');
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Generates a printable A4 Landscape Cheque Register.
  static Future<Uint8List> generateRegisterPdf({
    required String shopName,
    required List<Cheque> cheques,
    required List<BankAccount> bankAccounts,
    String filterTitle = 'All Cheques & PDCs',
  }) async {
    final pdf = pw.Document();
    final summary = ChequeSummary.fromCheques(cheques);
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
                      'Cheque Register & PDC Portfolio Report (Mandi Banking Ledger)',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Report Type: $filterTitle',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
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
                        'Total Records: ${cheques.length}',
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

            pw.SizedBox(height: 14),

            // ── Summary KPI Cards Row ─────────────────────────────────────────
            pw.Row(
              children: [
                _buildKpiCard(
                  title: 'In-Hand PDC (Vault / Safe)',
                  count: summary.inHandCount,
                  amount: summary.inHandAmount,
                  color: PdfColors.amber800,
                  bgColor: PdfColors.amber50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Under Clearing (In Bank)',
                  count: summary.depositedCount,
                  amount: summary.depositedAmount,
                  color: PdfColors.blue800,
                  bgColor: PdfColors.blue50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Cleared (Realized)',
                  count: summary.clearedCount,
                  amount: summary.clearedAmount,
                  color: PdfColors.green800,
                  bgColor: PdfColors.green50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Bounced / Alert',
                  count: summary.bouncedCount,
                  amount: summary.bouncedAmount,
                  color: PdfColors.red800,
                  bgColor: PdfColors.red50,
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Cheques Table ──────────────────────────────────────────────────
            if (cheques.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(32),
                child: pw.Text(
                  'No cheques found for this selection.',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.8), // Sr
                  1: pw.FlexColumnWidth(1.4), // Cheque #
                  2: pw.FlexColumnWidth(1.0), // Type
                  3: pw.FlexColumnWidth(2.2), // Party Name
                  4: pw.FlexColumnWidth(1.8), // Drawn Bank
                  5: pw.FlexColumnWidth(1.2), // Issue Date
                  6: pw.FlexColumnWidth(1.2), // Due Date (PDC)
                  7: pw.FlexColumnWidth(1.6), // Amount (PKR)
                  8: pw.FlexColumnWidth(1.4), // Status
                  9: pw.FlexColumnWidth(1.6), // Target Bank
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey50,
                    ),
                    children: [
                      _buildHeaderCell('#'),
                      _buildHeaderCell('Cheque #'),
                      _buildHeaderCell('Type'),
                      _buildHeaderCell('Party Name'),
                      _buildHeaderCell('Drawn Bank'),
                      _buildHeaderCell('Issue Date'),
                      _buildHeaderCell('Due Date (PDC)'),
                      _buildHeaderCell('Amount (PKR)'),
                      _buildHeaderCell('Status'),
                      _buildHeaderCell('Deposit Bank'),
                    ],
                  ),
                  // Data Rows
                  for (int i = 0; i < cheques.length; i++)
                    _buildChequeRow(i + 1, cheques[i]),
                ],
              ),

            pw.SizedBox(height: 12),

            // ── Table Footer Summary ──────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'Total Cheque Value: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        'Rs. ${_currencyFormat.format(cheques.fold<double>(0.0, (sum, c) => sum + c.amount))}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: PdfColors.green900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiCard({
    required String title,
    required int count,
    required double amount,
    required PdfColor color,
    required PdfColor bgColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '$count cheques',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Rs. ${_currencyFormat.format(amount)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  static pw.TableRow _buildChequeRow(int index, Cheque cheque) {
    PdfColor statusColor = PdfColors.grey800;
    PdfColor statusBg = PdfColors.grey100;

    switch (cheque.status) {
      case ChequeStatus.inHand:
        statusColor = PdfColors.amber900;
        statusBg = PdfColors.amber50;
        break;
      case ChequeStatus.deposited:
        statusColor = PdfColors.blue900;
        statusBg = PdfColors.blue50;
        break;
      case ChequeStatus.cleared:
        statusColor = PdfColors.green900;
        statusBg = PdfColors.green50;
        break;
      case ChequeStatus.bounced:
        statusColor = PdfColors.red900;
        statusBg = PdfColors.red50;
        break;
      case ChequeStatus.returned:
        statusColor = PdfColors.grey800;
        statusBg = PdfColors.grey100;
        break;
    }

    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            index.toString(),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            cheque.chequeNumber,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            cheque.typeLabelEnglish,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 8,
              color: cheque.type == ChequeType.received
                  ? PdfColors.green800
                  : PdfColors.orange800,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            cheque.partyName.isEmpty ? '—' : cheque.partyName,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            cheque.bankName.isEmpty ? '—' : cheque.bankName,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            _dateFormat.format(cheque.issueDate),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            _dateFormat.format(cheque.dueDate),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight:
                  cheque.isPdc ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: cheque.isOverdue ? PdfColors.red800 : PdfColors.black,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            _currencyFormat.format(cheque.amount),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: pw.BoxDecoration(
              color: statusBg,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              cheque.statusLabelEnglish,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            cheque.targetBankAccountName ?? '—',
            style: const pw.TextStyle(fontSize: 7.5),
          ),
        ),
      ],
    );
  }
}
