import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/data/models/bardana_model.dart';
import 'package:mandi/data/models/storage_allocation_model.dart';
import 'package:mandi/data/models/storage_location_model.dart';

/// Generates professional A4 PDF printouts for Godown / Cold Storage Inventory
/// and Bardana (Sacks & Crates) Ledger Statements.
class StorageAndBardanaPdfGenerator {
  static final _currencyFormat = NumberFormat('#,##0', 'en_US');
  static final _numberFormat = NumberFormat('#,##0', 'en_US');
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Generates printable Godown & Cold Storage Inventory Report.
  static Future<Uint8List> generateStorageReportPdf({
    required String shopName,
    required List<StorageLocation> locations,
    required List<StorageAllocation> allocations,
  }) async {
    final pdf = pw.Document();
    final printTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    final totalCapacity =
        locations.fold<int>(0, (sum, l) => sum + l.capacityBags);
    final totalStored =
        locations.fold<int>(0, (sum, l) => sum + l.currentBags);
    final totalEstimatedRent = allocations
        .where((a) =>
            a.status == AllocationStatus.inStore ||
            a.status == AllocationStatus.partiallyDispatched)
        .fold<double>(0.0, (sum, a) => sum + a.estimatedAccruedRent);

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
                      'Godown & Cold Storage Stock Allocation Report (گودام و کولڈ سٹوریج رجسٹر)',
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
                        'Facilities: ${locations.length} | Batches: ${allocations.length}',
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

            // ── KPI Summary Row ───────────────────────────────────────────────
            pw.Row(
              children: [
                _buildKpiCard(
                  title: 'Total Capacity',
                  subtitle: '${locations.length} Facilities',
                  value: '${_numberFormat.format(totalCapacity)} Bags',
                  color: PdfColors.blueGrey800,
                  bgColor: PdfColors.blueGrey50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Current Bags In Store',
                  subtitle:
                      'Utilization: ${totalCapacity > 0 ? ((totalStored / totalCapacity) * 100).toStringAsFixed(1) : 0}%',
                  value: '${_numberFormat.format(totalStored)} Bags',
                  color: PdfColors.green800,
                  bgColor: PdfColors.green50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Available Capacity',
                  subtitle: 'Free space in godowns',
                  value:
                      '${_numberFormat.format((totalCapacity - totalStored).clamp(0, 9999999))} Bags',
                  color: PdfColors.amber800,
                  bgColor: PdfColors.amber50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Est. Accrued Rent',
                  subtitle: 'Prorated monthly rent',
                  value: 'Rs. ${_currencyFormat.format(totalEstimatedRent)}',
                  color: PdfColors.teal800,
                  bgColor: PdfColors.teal50,
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Storage Facilities Summary ────────────────────────────────────
            pw.Text(
              '1. Storage Facilities Overview (سہولیات)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 6),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.6), // Sr
                1: pw.FlexColumnWidth(2.5), // Name
                2: pw.FlexColumnWidth(1.4), // Type
                3: pw.FlexColumnWidth(1.2), // Capacity
                4: pw.FlexColumnWidth(1.2), // Stored
                5: pw.FlexColumnWidth(1.2), // Free
                6: pw.FlexColumnWidth(1.2), // Rent/Bag
                7: pw.FlexColumnWidth(2.0), // Contact
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  children: [
                    _buildHeaderCell('#'),
                    _buildHeaderCell('Facility Name'),
                    _buildHeaderCell('Type'),
                    _buildHeaderCell('Capacity'),
                    _buildHeaderCell('Current Stored'),
                    _buildHeaderCell('Available'),
                    _buildHeaderCell('Rent/Bag/M'),
                    _buildHeaderCell('Contact / Phone'),
                  ],
                ),
                for (int i = 0; i < locations.length; i++)
                  _buildLocationRow(i + 1, locations[i]),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Active Stored Batches Table ───────────────────────────────────
            pw.Text(
              '2. Itemized Crop Batches in Storage (موجود فصل لاٹس)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 6),

            if (allocations.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(20),
                child: pw.Text(
                  'No batches currently allocated to storage.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.6), // Sr
                  1: pw.FlexColumnWidth(2.2), // Facility
                  2: pw.FlexColumnWidth(1.8), // Commodity
                  3: pw.FlexColumnWidth(1.2), // Lot #
                  4: pw.FlexColumnWidth(2.0), // Farmer / Party
                  5: pw.FlexColumnWidth(1.0), // Bags
                  6: pw.FlexColumnWidth(1.2), // Maunds
                  7: pw.FlexColumnWidth(1.2), // Inward Date
                  8: pw.FlexColumnWidth(1.0), // Days
                  9: pw.FlexColumnWidth(1.2), // Est Rent
                  10: pw.FlexColumnWidth(1.2), // Status
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    children: [
                      _buildHeaderCell('#'),
                      _buildHeaderCell('Facility'),
                      _buildHeaderCell('Product'),
                      _buildHeaderCell('Lot #'),
                      _buildHeaderCell('Party Name'),
                      _buildHeaderCell('Bags'),
                      _buildHeaderCell('Maunds'),
                      _buildHeaderCell('Inward Date'),
                      _buildHeaderCell('Days'),
                      _buildHeaderCell('Est Rent'),
                      _buildHeaderCell('Status'),
                    ],
                  ),
                  for (int i = 0; i < allocations.length; i++)
                    _buildAllocationRow(i + 1, allocations[i]),
                ],
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates printable Bardana (Bags / Sacks / Crates) Ledger Statement.
  static Future<Uint8List> generateBardanaReportPdf({
    required String shopName,
    required List<BardanaTransaction> transactions,
  }) async {
    final pdf = pw.Document();
    final summary = BardanaSummary.fromTransactions(transactions);
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
                      'Bardana (Sacks & Crates) Ledger Statement | باردانہ کھاتہ',
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
                        'Total Entries: ${transactions.length}',
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

            // ── Bardana KPI Ribbon ─────────────────────────────────────────────
            pw.Row(
              children: [
                _buildKpiCard(
                  title: 'Total Bardana Issued',
                  subtitle: 'Given to farmers / buyers',
                  value:
                      '${_numberFormat.format(summary.totalIssuedCount)} Bags',
                  color: PdfColors.orange900,
                  bgColor: PdfColors.orange50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Total Returned',
                  subtitle: 'Returned to shop vault',
                  value:
                      '${_numberFormat.format(summary.totalReturnedCount)} Bags',
                  color: PdfColors.green800,
                  bgColor: PdfColors.green50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Net Pending in Market',
                  subtitle: 'Awaiting return by parties',
                  value:
                      '${_numberFormat.format(summary.netPendingWithParties)} Bags',
                  color: PdfColors.red800,
                  bgColor: PdfColors.red50,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Deposit Receivable',
                  subtitle: 'Security value at risk',
                  value:
                      'Rs. ${_currencyFormat.format(summary.totalDepositReceivable)}',
                  color: PdfColors.blueGrey800,
                  bgColor: PdfColors.blueGrey50,
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Bardana Transactions Table ─────────────────────────────────────
            if (transactions.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(32),
                child: pw.Text(
                  'No Bardana records found.',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.6), // Sr
                  1: pw.FlexColumnWidth(1.4), // Date
                  2: pw.FlexColumnWidth(2.2), // Party Name
                  3: pw.FlexColumnWidth(1.2), // Party Type
                  4: pw.FlexColumnWidth(1.8), // Bardana Type
                  5: pw.FlexColumnWidth(1.2), // Movement
                  6: pw.FlexColumnWidth(1.0), // Bags
                  7: pw.FlexColumnWidth(1.2), // Rate/Bag
                  8: pw.FlexColumnWidth(1.4), // Deposit Total
                  9: pw.FlexColumnWidth(1.2), // Status
                  10: pw.FlexColumnWidth(1.4), // Due Date
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    children: [
                      _buildHeaderCell('#'),
                      _buildHeaderCell('Date'),
                      _buildHeaderCell('Party Name'),
                      _buildHeaderCell('Party'),
                      _buildHeaderCell('Type'),
                      _buildHeaderCell('Movement'),
                      _buildHeaderCell('Count'),
                      _buildHeaderCell('Deposit/Bag'),
                      _buildHeaderCell('Deposit Total'),
                      _buildHeaderCell('Status'),
                      _buildHeaderCell('Return Due'),
                    ],
                  ),
                  for (int i = 0; i < transactions.length; i++)
                    _buildBardanaRow(i + 1, transactions[i]),
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
    required String subtitle,
    required String value,
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
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11.5,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey700,
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
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  static pw.TableRow _buildLocationRow(int index, StorageLocation loc) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('$index',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(loc.name,
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(loc.typeLabelEnglish,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(_numberFormat.format(loc.capacityBags),
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(_numberFormat.format(loc.currentBags),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(_numberFormat.format(loc.availableCapacityBags),
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
              loc.monthlyRentPerBag > 0
                  ? 'Rs. ${_currencyFormat.format(loc.monthlyRentPerBag)}'
                  : 'Free / Shop',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
              loc.contactPerson.isNotEmpty
                  ? '${loc.contactPerson} (${loc.phone})'
                  : '—',
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
      ],
    );
  }

  static pw.TableRow _buildAllocationRow(int index, StorageAllocation alloc) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('$index',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(alloc.storageLocationName ?? '—',
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(alloc.productName,
              style:
                  pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(alloc.lotNumber.isNotEmpty ? alloc.lotNumber : '—',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(alloc.partyName.isNotEmpty ? alloc.partyName : '—',
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('${alloc.bagCount}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('${alloc.maunds.toStringAsFixed(1)} Maunds',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(_dateFormat.format(alloc.inwardDate),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('${alloc.daysInStorage}d',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
              'Rs. ${_currencyFormat.format(alloc.estimatedAccruedRent)}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
            decoration: pw.BoxDecoration(
              color: alloc.status == AllocationStatus.inStore
                  ? PdfColors.green50
                  : PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              alloc.statusLabelEnglish,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: alloc.status == AllocationStatus.inStore
                    ? PdfColors.green900
                    : PdfColors.grey800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildBardanaRow(int index, BardanaTransaction tx) {
    final isIssue = tx.direction == BardanaDirection.issued;

    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('$index',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(_dateFormat.format(tx.transactionDate),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(tx.partyName.isNotEmpty ? tx.partyName : '—',
              style:
                  pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(tx.partyType.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(tx.bardanaTypeLabelEnglish,
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(tx.directionLabelEnglish,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: isIssue ? PdfColors.orange900 : PdfColors.green900,
              )),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('${tx.bagCount}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('Rs. ${_currencyFormat.format(tx.unitDepositRate)}',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
              'Rs. ${_currencyFormat.format(tx.totalDepositAmount)}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(tx.status.name.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: tx.isOverdue ? PdfColors.red900 : PdfColors.black,
              )),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
              tx.dueReturnDate != null
                  ? _dateFormat.format(tx.dueReturnDate!)
                  : '—',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7)),
        ),
      ],
    );
  }
}
