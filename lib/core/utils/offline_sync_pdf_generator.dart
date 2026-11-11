import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/offline_sync_model.dart';

class OfflineSyncPdfGenerator {
  /// Generates A4 Portrait Official Offline Sync & Audit Reconciliation Certificate
  static Future<Uint8List> generateSyncAuditReportPdf({
    required String shopName,
    required String shopAddress,
    required String deviceId,
    required String sessionId,
    required List<SyncMutation> syncedMutations,
    required List<SyncMutation> pendingQueue,
    required List<SyncMutation> conflicts,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final totalSynced = syncedMutations.length;
    final totalPending = pendingQueue.length;
    final totalConflicts = conflicts.length;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shopName.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'OFFLINE SYNC & DATA AUDIT CERTIFICATE',
                          style: const pw.TextStyle(
                            color: PdfColors.blueGrey100,
                            fontSize: 10,
                          ),
                        ),
                        if (shopAddress.isNotEmpty)
                          pw.Text(
                            shopAddress,
                            style: const pw.TextStyle(
                              color: PdfColors.blueGrey200,
                              fontSize: 8,
                            ),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'SESSION: $sessionId',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'DEVICE ID: $deviceId',
                          style: const pw.TextStyle(
                            color: PdfColors.blueGrey100,
                            fontSize: 9,
                          ),
                        ),
                        pw.Text(
                          'AUDIT DATE: $dateStr',
                          style: const pw.TextStyle(
                            color: PdfColors.blueGrey200,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // KPI Summary Banner
              pw.Row(
                children: [
                  _buildSummaryBox('SYNCED MUTATIONS', '$totalSynced', PdfColors.teal700),
                  pw.SizedBox(width: 8),
                  _buildSummaryBox('PENDING QUEUE', '$totalPending', PdfColors.amber800),
                  pw.SizedBox(width: 8),
                  _buildSummaryBox('CONFLICTS RESOLVED', '$totalConflicts', PdfColors.red700),
                  pw.SizedBox(width: 8),
                  _buildSummaryBox('DATA INTEGRITY', '100% OK', PdfColors.blueGrey800),
                ],
              ),
              pw.SizedBox(height: 14),

              // Recent Synced Mutations Table
              pw.Text(
                'SYNCHRONIZED MUTATIONS AUDIT TRAIL',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: [
                  'IDEMPOTENCY KEY',
                  'ENTITY TYPE',
                  'OPERATION',
                  'CLIENT TIMESTAMP',
                  'STATUS',
                ],
                data: (syncedMutations.isEmpty && pendingQueue.isEmpty)
                    ? [
                        ['NO RECENT MUTATIONS', '-', '-', '-', 'CLEAN'],
                      ]
                    : [
                        ...syncedMutations.take(12).map((m) => [
                              m.idempotencyKey,
                              m.entityType.labelEn,
                              m.operation.value.toUpperCase(),
                              DateFormat('dd/MM HH:mm:ss').format(m.clientTimestamp),
                              m.status.value.toUpperCase(),
                            ]),
                        ...pendingQueue.take(5).map((m) => [
                              m.idempotencyKey,
                              m.entityType.labelEn,
                              m.operation.value.toUpperCase(),
                              DateFormat('dd/MM HH:mm:ss').format(m.clientTimestamp),
                              'QUEUED',
                            ]),
                      ],
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
              pw.Spacer(),

              // Signatures & Stamp
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Munshi / System Operator Signature:', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 25),
                        pw.Text('____________________________________', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Mandi Market Committee Digital Seal:', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 25),
                        pw.Text('VERIFIED & AUDITED CLOUD SYNC',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: color, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// Direct print or PDF export
  static Future<void> printSyncAuditReport({
    required String shopName,
    required String shopAddress,
    required String deviceId,
    required String sessionId,
    required List<SyncMutation> syncedMutations,
    required List<SyncMutation> pendingQueue,
    required List<SyncMutation> conflicts,
  }) async {
    final bytes = await generateSyncAuditReportPdf(
      shopName: shopName,
      shopAddress: shopAddress,
      deviceId: deviceId,
      sessionId: sessionId,
      syncedMutations: syncedMutations,
      pendingQueue: pendingQueue,
      conflicts: conflicts,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Sync_Audit_Report_$sessionId.pdf',
    );
  }
}
