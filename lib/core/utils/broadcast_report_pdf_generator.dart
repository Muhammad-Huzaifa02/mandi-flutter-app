import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/broadcast_campaign_model.dart';

class BroadcastReportPdfGenerator {
  /// Generates A4 Official Daily Mandi Bhav Broadcast & Telegram Distribution Certificate
  static Future<Uint8List> generateBroadcastCampaignPdf({
    required String shopName,
    required String shopAddress,
    required BroadcastCampaign campaign,
    required List<BroadcastSubscriber> sampleSubscribers,
  }) async {
    final pdf = pw.Document();
    final sentStr = campaign.sentAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(campaign.sentAt!)
        : 'In Queue / Draft';

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
                  color: PdfColors.teal800,
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
                          'MANDI BHAV BROADCAST DISTRIBUTION CERTIFICATE',
                          style: const pw.TextStyle(
                            color: PdfColors.teal100,
                            fontSize: 10,
                          ),
                        ),
                        if (shopAddress.isNotEmpty)
                          pw.Text(
                            shopAddress,
                            style: const pw.TextStyle(
                              color: PdfColors.teal200,
                              fontSize: 8,
                            ),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'CAMPAIGN ID: ${campaign.id.substring(0, 8).toUpperCase()}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'CHANNEL: ${campaign.channel.labelEn.toUpperCase()}',
                          style: const pw.TextStyle(
                            color: PdfColors.teal100,
                            fontSize: 8.5,
                          ),
                        ),
                        pw.Text(
                          'DISPATCHED: $sentStr',
                          style: const pw.TextStyle(
                            color: PdfColors.teal200,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // KPI Metrics
              pw.Row(
                children: [
                  _buildKpiCard('TOTAL RECIPIENTS', '${campaign.totalRecipients}', PdfColors.blueGrey800),
                  pw.SizedBox(width: 8),
                  _buildKpiCard('DELIVERED', '${campaign.deliveredCount}', PdfColors.green700),
                  pw.SizedBox(width: 8),
                  _buildKpiCard('FAILED', '${campaign.failedCount}', PdfColors.red700),
                  pw.SizedBox(width: 8),
                  _buildKpiCard(
                    'DELIVERY SUCCESS',
                    '${campaign.deliveryRatePercentage.toStringAsFixed(1)}%',
                    PdfColors.teal700,
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Message Body Box
              pw.Text(
                'DISSEMINATED MANDI BULLETIN (MESSAGE CONTENT)',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
                ),
                child: pw.Text(
                  campaign.messageBody,
                  style: const pw.TextStyle(fontSize: 8, lineSpacing: 1.5),
                ),
              ),
              pw.SizedBox(height: 14),

              // Recipient Roster
              pw.Text(
                'RECIPIENT SUBSCRIBER SAMPLES',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['SUBSCRIBER NAME', 'PHONE / CHAT ID', 'PLATFORM', 'TYPE', 'STATUS'],
                data: sampleSubscribers.isEmpty
                    ? [
                        ['ALL REGISTERED MANDI SUBSCRIBERS', 'BROADCAST LIST', campaign.channel.name.toUpperCase(), 'COMMUNITY', 'DELIVERED'],
                      ]
                    : sampleSubscribers.take(8).map((s) => [
                          s.name,
                          s.phoneOrChatId,
                          s.platform.name.toUpperCase(),
                          s.subscriberType.toUpperCase(),
                          'DELIVERED',
                        ]).toList(),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
              pw.Spacer(),

              // Signature Footer
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
                        pw.Text('Broadcast Operator / Munshi Signature:', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 25),
                        pw.Text('____________________________________', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Market Committee Notification Registry:', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 25),
                        pw.Text('OFFICIAL TELEGRAM & WHATSAPP BULLETIN',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
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

  static pw.Widget _buildKpiCard(String label, String value, PdfColor color) {
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
  static Future<void> printBroadcastCampaignReport({
    required String shopName,
    required String shopAddress,
    required BroadcastCampaign campaign,
    required List<BroadcastSubscriber> sampleSubscribers,
  }) async {
    final bytes = await generateBroadcastCampaignPdf(
      shopName: shopName,
      shopAddress: shopAddress,
      campaign: campaign,
      sampleSubscribers: sampleSubscribers,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Broadcast_Report_${campaign.id.substring(0, 8)}.pdf',
    );
  }
}
