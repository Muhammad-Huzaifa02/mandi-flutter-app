import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/multi_shop_transfer_model.dart';

/// Professional A4 PDF Generator for Multi-Shop Consolidated Balance Sheets
/// and Inter-Shop Transfer Passnotes (*بین المانڈی مشترکہ گوشوارہ و گیٹ پاس*).
class ConsolidatedBalanceSheetPdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');
  static final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  // =========================================================================
  // 1. CONSOLIDATED MULTI-BRANCH ENTERPRISE BALANCE SHEET (LANDSCAPE A4)
  // =========================================================================

  static Future<Uint8List> generateConsolidatedPdf({
    required ConsolidatedBalanceSheet sheet,
    required String groupTitle,
    String? contactPhone,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy').format(sheet.asOfDate);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      groupTitle.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.Text(
                      'CONSOLIDATED MULTI-BRANCH BALANCE SHEET & FINANCIAL REPORT',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey700,
                      ),
                    ),
                    pw.Text(
                      'Multi-Mandi Enterprise Financial Standing',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('As of Date: $dateStr',
                        style: const pw.TextStyle(fontSize: 9)),
                    if (contactPhone != null && contactPhone.isNotEmpty)
                      pw.Text('Contact: $contactPhone',
                          style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Total Active Branches: ${sheet.totalBranchesCount}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1, color: PdfColors.blueGrey800),
            pw.SizedBox(height: 6),

            // Top Enterprise Net Worth KPI Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _metricCol('Total Group Sales',
                      'Rs. ${_currencyFmt.format(sheet.aggregateSalesPkr)}'),
                  _metricCol('Net Commission Earned',
                      'Rs. ${_currencyFmt.format(sheet.aggregateCommissionPkr)}'),
                  _metricCol('Operating Net Profit',
                      'Rs. ${_currencyFmt.format(sheet.aggregateNetProfitPkr)}'),
                  _metricCol('Market Receivables',
                      'Rs. ${_currencyFmt.format(sheet.aggregateReceivablesPkr)}'),
                  _metricCol('Farmer Payables',
                      'Rs. ${_currencyFmt.format(sheet.aggregatePayablesPkr)}'),
                  _metricCol('Consolidated Equity',
                      'Rs. ${_currencyFmt.format(sheet.aggregateEnterpriseEquityPkr)}'),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // Branch Breakdown Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.0), // Branch & Mandi City
                1: const pw.FlexColumnWidth(2.5), // Total Sales
                2: const pw.FlexColumnWidth(2.2), // Commission
                3: const pw.FlexColumnWidth(2.2), // Expenses
                4: const pw.FlexColumnWidth(2.2), // Net Profit
                5: const pw.FlexColumnWidth(2.5), // Receivables
                6: const pw.FlexColumnWidth(2.5), // Payables
                7: const pw.FlexColumnWidth(2.5), // Stock Value
                8: const pw.FlexColumnWidth(2.8), // Net Equity
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  children: [
                    _th('Branch / Mandi Market', isWhite: true),
                    _th('Gross Sales', isWhite: true),
                    _th('Commission', isWhite: true),
                    _th('Expenses', isWhite: true),
                    _th('Net Profit', isWhite: true),
                    _th('Receivables', isWhite: true),
                    _th('Payables', isWhite: true),
                    _th('Stock Assets', isWhite: true),
                    _th('Branch Equity', isWhite: true),
                  ],
                ),
                ...sheet.branches.map((b) {
                  return pw.TableRow(
                    children: [
                      _td('${b.shopName}\n(${b.city.isNotEmpty ? b.city : "Main Branch"})',
                          isBold: true),
                      _td('Rs. ${_currencyFmt.format(b.totalSalesPkr)}', alignRight: true),
                      _td('Rs. ${_currencyFmt.format(b.totalCommissionPkr)}', alignRight: true),
                      _td('Rs. ${_currencyFmt.format(b.totalExpensesPkr)}', alignRight: true),
                      _td('Rs. ${_currencyFmt.format(b.netProfitPkr)}',
                          alignRight: true, isBold: true),
                      _td('Rs. ${_currencyFmt.format(b.totalReceivablesPkr)}', alignRight: true),
                      _td('Rs. ${_currencyFmt.format(b.totalPayablesPkr)}', alignRight: true),
                      _td('Rs. ${_currencyFmt.format(b.stockValuePkr)}', alignRight: true),
                      _td('Rs. ${_currencyFmt.format(b.netBranchEquityPkr)}',
                          alignRight: true, isBold: true),
                    ],
                  );
                }),
                // Total Summary Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                  children: [
                    _td('GROUP TOTALS (${sheet.totalBranchesCount} Branches)', isBold: true),
                    _td('Rs. ${_currencyFmt.format(sheet.aggregateSalesPkr)}',
                        isBold: true, alignRight: true),
                    _td('Rs. ${_currencyFmt.format(sheet.aggregateCommissionPkr)}',
                        isBold: true, alignRight: true),
                    _td('Rs. ${_currencyFmt.format(sheet.aggregateExpensesPkr)}',
                        isBold: true, alignRight: true),
                    _td('Rs. ${_currencyFmt.format(sheet.aggregateNetProfitPkr)}',
                        isBold: true, alignRight: true),
                    _td('Rs. ${_currencyFmt.format(sheet.aggregateReceivablesPkr)}',
                        isBold: true, alignRight: true),
                    _td('Rs. ${_currencyFmt.format(sheet.aggregatePayablesPkr)}',
                        isBold: true, alignRight: true),
                    _td('Rs. ${_currencyFmt.format(sheet.aggregateStockValuePkr)}',
                        isBold: true, alignRight: true),
                    _td('Rs. ${_currencyFmt.format(sheet.aggregateEnterpriseEquityPkr)}',
                        isBold: true, alignRight: true),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _signCol('Chief Accountant / Head Munshi'),
                _signCol('Internal Auditor'),
                _signCol('Managing Partner / Proprietor Stamp'),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // =========================================================================
  // 2. INTER-SHOP STOCK TRANSFER GATE PASS & DELIVERY CHALLAN (A4 PORTRAIT)
  // =========================================================================

  static Future<Uint8List> generateTransferGatePassPdf({
    required InterShopTransfer transfer,
    required String sendingShopName,
    required String receivingShopName,
  }) async {
    final pdf = pw.Document();

    final dateStr =
        DateFormat('dd/MM/yyyy HH:mm').format(transfer.dispatchedAt);

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
                        sendingShopName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'INTER-SHOP STOCK TRANSFER CHALLAN & TRANSIT GATE PASS',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Challan #: ${transfer.transferNumber}',
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Dispatch Date: $dateStr',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1.5, color: PdfColors.blueGrey900),
              pw.SizedBox(height: 12),

              // Source & Destination Boxes
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DISPATCHING BRANCH (SOURCE):',
                              style: pw.TextStyle(
                                  fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(sendingShopName,
                              style: pw.TextStyle(
                                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Origin Mandi Facility',
                              style: const pw.TextStyle(
                                  fontSize: 8.5, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('RECEIVING BRANCH (DESTINATION):',
                              style: pw.TextStyle(
                                  fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(receivingShopName,
                              style: pw.TextStyle(
                                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Destination Mandi Facility',
                              style: const pw.TextStyle(
                                  fontSize: 8.5, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Vehicle & Freight Details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _metricCol('Vehicle Number',
                        transfer.vehicleNumber.isNotEmpty ? transfer.vehicleNumber : 'N/A'),
                    _metricCol('Driver Name',
                        transfer.driverName.isNotEmpty ? transfer.driverName : 'Official Driver'),
                    _metricCol('Driver Contact', transfer.driverPhone),
                    _metricCol('Transit Freight',
                        'Rs. ${_currencyFmt.format(transfer.transitFreightPkr)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Commodity Items Table
              pw.Text('CONSIGNMENT SPECIFICATIONS & INVENTORY DETAILS',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2.5),
                  3: const pw.FlexColumnWidth(2.5),
                  4: const pw.FlexColumnWidth(2.5),
                  5: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                    children: [
                      _th('Commodity Name'),
                      _th('Packaging'),
                      _th('Net Weight (KG)'),
                      _th('Mandi Maunds'),
                      _th('Rate / Maund'),
                      _th('Total Value (PKR)'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td(transfer.commodityName, isBold: true),
                      _td('${transfer.packageCount} ${transfer.packageType}s'),
                      _td('${_numberFmt.format(transfer.quantityKg)} KG', alignRight: true),
                      _td('${_numberFmt.format(transfer.quantityMaunds)} M', alignRight: true),
                      _td('Rs. ${_currencyFmt.format(transfer.unitCostPkr)}', alignRight: true),
                      _td('Rs. ${_currencyFmt.format(transfer.totalValuePkr)}',
                          alignRight: true, isBold: true),
                    ],
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _td('TOTAL DELIVERED VALUE (INCL. FREIGHT)', isBold: true),
                      _td('-'),
                      _td('${_numberFmt.format(transfer.quantityKg)} KG',
                          isBold: true, alignRight: true),
                      _td('${_numberFmt.format(transfer.quantityMaunds)} M',
                          isBold: true, alignRight: true),
                      _td('Rs. ${_currencyFmt.format(transfer.effectiveCostPerMaundPkr)}',
                          isBold: true, alignRight: true),
                      _td('Rs. ${_currencyFmt.format(transfer.totalDeliveredCostPkr)}',
                          isBold: true, alignRight: true),
                    ],
                  ),
                ],
              ),

              if (transfer.notes.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text('Notes / Special Handling Instructions:',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                pw.Text(transfer.notes, style: const pw.TextStyle(fontSize: 8.5)),
              ],

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _signCol('Dispatched By (Source Staff)'),
                  _signCol('Driver / Carrier Acknowledgement'),
                  _signCol('Received By (Destination Staff)'),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  '*** Official Inter-Shop Stock Transfer Gate Pass — Mandi Enterprise ERP ***',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- Helper Widgets ---

  static pw.Widget _metricCol(String title, String val) {
    return pw.Column(
      children: [
        pw.Text(title,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(val,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _signCol(String label) {
    return pw.Column(
      children: [
        pw.Container(width: 140, height: 1, color: PdfColors.grey600),
        pw.SizedBox(height: 4),
        pw.Text(label,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
      ],
    );
  }

  static pw.Widget _th(String text, {bool isWhite = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: isWhite ? PdfColors.white : PdfColors.blueGrey900,
        ),
      ),
    );
  }

  static pw.Widget _td(String text, {bool isBold = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  /// Direct print trigger for Consolidated Balance Sheet
  static Future<void> printConsolidatedPdf({
    required ConsolidatedBalanceSheet sheet,
    required String groupTitle,
    String? contactPhone,
  }) async {
    final bytes = await generateConsolidatedPdf(
      sheet: sheet,
      groupTitle: groupTitle,
      contactPhone: contactPhone,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Consolidated_Balance_Sheet_${DateFormat('yyyyMMdd').format(sheet.asOfDate)}.pdf',
    );
  }

  /// Direct print trigger for Transfer Gate Pass
  static Future<void> printTransferGatePassPdf({
    required InterShopTransfer transfer,
    required String sendingShopName,
    required String receivingShopName,
  }) async {
    final bytes = await generateTransferGatePassPdf(
      transfer: transfer,
      sendingShopName: sendingShopName,
      receivingShopName: receivingShopName,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Transfer_Gate_Pass_${transfer.transferNumber}.pdf',
    );
  }
}
