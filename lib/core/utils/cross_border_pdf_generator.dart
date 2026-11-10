import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/cross_border_shipment_model.dart';

/// Professional A4 PDF Generator for Cross-Border Cargo Manifests and
/// Customs Clearance Statements (*سرحدی مال و کسٹم کلیئرنس پرچہ*).
class CrossBorderPdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');
  static final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  // =========================================================================
  // 1. SINGLE SHIPMENT CARGO MANIFEST & CUSTOMS CLEARANCE STATEMENT (A4)
  // =========================================================================

  static Future<Uint8List> generateCargoManifestPdf({
    required CrossBorderShipment shipment,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final pdf = pw.Document();

    final dateStr = shipment.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(shipment.createdAt!)
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    final clearanceDateStr = shipment.customsClearanceDate != null
        ? DateFormat('dd/MM/yyyy').format(shipment.customsClearanceDate!)
        : 'In Transit / Pending Clearance';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
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
                      if (shopCity != null && shopCity.isNotEmpty)
                        pw.Text(
                          'Mandi: $shopCity',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700),
                        ),
                      if (shopPhone != null && shopPhone.isNotEmpty)
                        pw.Text(
                          'Phone: $shopPhone',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blueGrey800,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'CROSS-BORDER CARGO MANIFEST',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Border Cargo & Customs Clearance Statement',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Manifest #: ${shipment.shipmentNumber}',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Date: $dateStr',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1.5, color: PdfColors.blueGrey900),
              pw.SizedBox(height: 8),

              // Section 1: Route & Clearance Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildInfoBox(
                      title: 'ORIGIN & BORDER ROUTE',
                      rows: [
                        ['Country:', shipment.originCountry.labelEnglish],
                        [
                          'Origin City:',
                          shipment.originCity.isNotEmpty
                              ? shipment.originCity
                              : 'Commercial Border Hub'
                        ],
                        [
                          'Border Checkpoint:',
                          shipment.borderCrossing.labelEnglish
                        ],
                        ['Clearance Date:', clearanceDateStr],
                        [
                          'Clearing Agent:',
                          shipment.clearingAgentName.isNotEmpty
                              ? shipment.clearingAgentName
                              : 'Direct Consignment'
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _buildInfoBox(
                      title: 'VEHICLE & CUSTOMS GD',
                      rows: [
                        [
                          'Vehicle Registration:',
                          shipment.vehicleNumber.isNotEmpty
                              ? shipment.vehicleNumber
                              : 'Not Specified'
                        ],
                        [
                          'Driver Name:',
                          shipment.driverName.isNotEmpty
                              ? shipment.driverName
                              : 'Official Freight Driver'
                        ],
                        ['Driver Phone:', shipment.driverPhone],
                        [
                          'Customs GD #:',
                          shipment.customsGdNumber.isNotEmpty
                              ? shipment.customsGdNumber
                              : 'Pending Customs GD'
                        ],
                        [
                          'Status:',
                          shipment.status.labelEnglish.toUpperCase()
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Section 2: Commodity & Weights
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.grey100,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _metricCol('Commodity', shipment.commodity),
                    _metricCol('Packaging',
                        '${shipment.packageCount} ${shipment.packageType}s'),
                    _metricCol('Gross Weight',
                        '${_numberFmt.format(shipment.grossWeightKg)} KG'),
                    _metricCol('Mandi Maunds',
                        '${_numberFmt.format(shipment.maunds)} Maunds'),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Section 3: Dual-Currency Financial Breakdown Table
              pw.Text(
                'DUAL-CURRENCY FINANCIAL & LANDED COST BREAKDOWN',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(4),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey100),
                    children: [
                      _th('Cost Component'),
                      _th('Foreign Value'),
                      _th('Pakistani Rupee (PKR)'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td('Foreign Supplier Contract Price'),
                      _td('${shipment.currency.code} ${_currencyFmt.format(shipment.foreignContractAmount)}'),
                      _td(
                          'Rs. ${_currencyFmt.format(shipment.computedBasePkr)} (@ Rs. ${_numberFmt.format(shipment.exchangeRateToPkr)})',
                          alignRight: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td('Customs Import Duty & Clearance Tariffs'),
                      _td('-'),
                      _td('Rs. ${_currencyFmt.format(shipment.customsDutyPkr)}',
                          alignRight: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td('Border Transport & Freight'),
                      _td('-'),
                      _td(
                          'Rs. ${_currencyFmt.format(shipment.borderFreightPkr)}',
                          alignRight: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td('Clearing Agent & Port Handling Fees'),
                      _td('-'),
                      _td(
                          'Rs. ${_currencyFmt.format(shipment.clearingChargesPkr)}',
                          alignRight: true),
                    ],
                  ),
                  if (shipment.otherExpensesPkr > 0)
                    pw.TableRow(
                      children: [
                        _td('Cold Chain, Tolls & Miscellaneous'),
                        _td('-'),
                        _td(
                            'Rs. ${_currencyFmt.format(shipment.otherExpensesPkr)}',
                            alignRight: true),
                      ],
                    ),
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _td('TOTAL BORDER SURCHARGES',
                          isBold: true),
                      _td('-'),
                      _td(
                          'Rs. ${_currencyFmt.format(shipment.totalBorderExpensesPkr)}',
                          isBold: true, alignRight: true),
                    ],
                  ),
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey200),
                    children: [
                      _td('FINAL MANDI LANDED COST',
                          isBold: true),
                      _td(
                          '${shipment.currency.code} ${_currencyFmt.format(shipment.foreignContractAmount)}',
                          isBold: true),
                      _td(
                          'Rs. ${_currencyFmt.format(shipment.computedTotalLandedCostPkr)}',
                          isBold: true, alignRight: true),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // Section 4: Unit Economics
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blueGrey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _metricCol('Cost / KG',
                        'Rs. ${_numberFmt.format(shipment.costPerKgPkr)}'),
                    _metricCol('Cost / Maund (40 KG)',
                        'Rs. ${_currencyFmt.format(shipment.costPerMaundPkr)}'),
                    _metricCol('Cost / ${shipment.packageType}',
                        'Rs. ${_currencyFmt.format(shipment.costPerPackagePkr)}'),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Section 5: Foreign Supplier Settlement Balance
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber700),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'FOREIGN SUPPLIER SETTLEMENT (${shipment.supplierName}):',
                      style: pw.TextStyle(
                          fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Paid: ${shipment.currency.code} ${_currencyFmt.format(shipment.paidToSupplierForeign)}  |  Remaining: ${shipment.currency.code} ${_currencyFmt.format(shipment.computedRemainingSupplierForeign)} (Rs. ${_currencyFmt.format(shipment.computedRemainingSupplierPkr)})',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: shipment.computedRemainingSupplierForeign > 0
                            ? PdfColors.red900
                            : PdfColors.green900,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _signCol('Driver / Transporter Signature'),
                  _signCol('Clearing Agent & Customs'),
                  _signCol('Mandi Commission Agent Stamp'),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  '*** Official Cross-Border Agricultural Transit Documentation - Mandi ERP ***',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey600),
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
  // 2. SHOP CROSS-BORDER REGISTER (LANDSCAPE A4)
  // =========================================================================

  static Future<Uint8List> generateBorderRegisterPdf({
    required List<CrossBorderShipment> shipments,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    DateTime? date,
  }) async {
    final pdf = pw.Document();
    final summary = CrossBorderSummary.fromShipments(shipments);
    final reportDate = date ?? DateTime.now();

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
                      shopName.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900),
                    ),
                    pw.Text('CROSS-BORDER IMPORT & TRANSIT REGISTER',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey700)),
                    pw.Text('Pak-Afghan & Pak-Iran International Transit Register',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        'Date: ${DateFormat('dd MMMM yyyy').format(reportDate)}',
                        style: const pw.TextStyle(fontSize: 9)),
                    if (shopCity != null && shopCity.isNotEmpty)
                      pw.Text('Mandi: $shopCity',
                          style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Total Shipments: ${shipments.length}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1, color: PdfColors.blueGrey800),
            pw.SizedBox(height: 6),

            // Summary KPI Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _metricCol('Total Cargo Maunds',
                      '${_numberFmt.format(summary.totalCargoMaunds)} M'),
                  _metricCol('Active Transit Shipments',
                      '${summary.activeShipments} Vehicles'),
                  _metricCol('Total Customs & Freight',
                      'Rs. ${_currencyFmt.format(summary.totalCustomsFreightPkr)}'),
                  _metricCol('Total Landed Value (PKR)',
                      'Rs. ${_currencyFmt.format(summary.totalLandedCostPkr)}'),
                  _metricCol('Foreign Debt (PKR Equiv)',
                      'Rs. ${_currencyFmt.format(summary.totalOutstandingSupplierPkr)}'),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // Shipments Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5), // Shipment #
                1: const pw.FlexColumnWidth(2.2), // Origin & Border
                2: const pw.FlexColumnWidth(2.0), // Vehicle #
                3: const pw.FlexColumnWidth(2.5), // Commodity
                4: const pw.FlexColumnWidth(2.0), // Weight (M)
                5: const pw.FlexColumnWidth(2.5), // Foreign Contract
                6: const pw.FlexColumnWidth(2.5), // Landed PKR
                7: const pw.FlexColumnWidth(2.2), // Cost / Maund
                8: const pw.FlexColumnWidth(2.0), // Status
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  children: [
                    _th('Shipment #', isWhite: true),
                    _th('Origin / Border', isWhite: true),
                    _th('Vehicle #', isWhite: true),
                    _th('Commodity', isWhite: true),
                    _th('Maunds', isWhite: true),
                    _th('Foreign Val', isWhite: true),
                    _th('Landed Cost', isWhite: true),
                    _th('Cost/Maund', isWhite: true),
                    _th('Status', isWhite: true),
                  ],
                ),
                ...shipments.map((s) {
                  return pw.TableRow(
                    children: [
                      _td(s.shipmentNumber, isBold: true),
                      _td('${s.originCountry.labelEnglish}\n(${s.borderCrossing.labelEnglish.split(" ").first})'),
                      _td(s.vehicleNumber),
                      _td('${s.commodity}\n(${s.packageCount} ${s.packageType})'),
                      _td('${_numberFmt.format(s.maunds)} M', alignRight: true),
                      _td(
                          '${s.currency.code} ${_currencyFmt.format(s.foreignContractAmount)}\n(@ ${_numberFmt.format(s.exchangeRateToPkr)})'),
                      _td('Rs. ${_currencyFmt.format(s.computedTotalLandedCostPkr)}',
                          alignRight: true),
                      _td('Rs. ${_currencyFmt.format(s.costPerMaundPkr)}',
                          alignRight: true),
                      _td(s.status.labelEnglish),
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

  // --- Helper Widgets ---

  static pw.Widget _buildInfoBox({
    required String title,
    required List<List<String>> rows,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800),
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey300),
          pw.SizedBox(height: 2),
          ...rows.map((r) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(r[0],
                        style: const pw.TextStyle(
                            fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text(r[1],
                        style: pw.TextStyle(
                            fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

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

  static pw.Widget _signCol(String title) {
    return pw.Column(
      children: [
        pw.Container(width: 110, height: 0.5, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(title,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7.5)),
      ],
    );
  }

  static pw.Widget _th(String text, {bool isWhite = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: isWhite ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _td(String text,
      {bool isBold = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Direct print trigger for Cargo Manifest
  static Future<void> printCargoManifest({
    required CrossBorderShipment shipment,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final pdfBytes = await generateCargoManifestPdf(
      shipment: shipment,
      shopName: shopName,
      shopPhone: shopPhone,
      shopCity: shopCity,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Manifest_${shipment.shipmentNumber}.pdf',
    );
  }

  /// Direct print trigger for Border Register
  static Future<void> printBorderRegister({
    required List<CrossBorderShipment> shipments,
    required String shopName,
    String? shopPhone,
    String? shopCity,
  }) async {
    final pdfBytes = await generateBorderRegisterPdf(
      shipments: shipments,
      shopName: shopName,
      shopPhone: shopPhone,
      shopCity: shopCity,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Cross_Border_Register_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
