// Professional A4 PDF Generator for Fleet Logistics, Trip Bilty & Vehicle Ledgers
// (*ٹرانسپورٹ بلٹی، ڈیزل خرچ اور گاڑی نفع نقصان رجسٹر*).

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/fleet_model.dart';

class FleetLogisticsPdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');

  // =========================================================================
  // 1. OFFICIAL TRIP BILTY / DELIVERY CHALLAN (A4 PORTRAIT)
  // =========================================================================

  static Future<Uint8List> generateTripChallanPdf({
    required FleetTrip trip,
    required FleetVehicle vehicle,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy').format(trip.tripDate);

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
                      pw.Text('GRAIN & AGRI-COMMODITY CARGO LOGISTICS',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
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
                        pw.Text('TRIP BILTY / CHALLAN',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.Text('گاڑی بلٹی و کرایہ پرچہ',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.teal700)),
                        pw.SizedBox(height: 4),
                        pw.Text('Bilty #: ${trip.tripNumber}',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal900)),
                        pw.Text('Date: $dateStr',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey800)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // Route & Vehicle Info Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Vehicle Reg / نمبر گاڑی:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(vehicle.registrationNumber,
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blueGrey900)),
                        pw.Text(vehicle.vehicleType.labelEnglish,
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Driver / ڈرائیور:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                            vehicle.driverName.isNotEmpty
                                ? vehicle.driverName
                                : 'Assigned Driver',
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blueGrey900)),
                        if (vehicle.driverPhone.isNotEmpty)
                          pw.Text(vehicle.driverPhone,
                              style: const pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Route / راستہ:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text('${trip.origin}  ->  ${trip.destination}',
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.indigo900)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Trip Status:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: trip.status == TripStatus.completed
                                ? PdfColors.green100
                                : trip.status == TripStatus.cancelled
                                    ? PdfColors.red100
                                    : PdfColors.blue100,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            trip.status.labelEnglish.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: trip.status == TripStatus.completed
                                  ? PdfColors.green900
                                  : trip.status == TripStatus.cancelled
                                      ? PdfColors.red900
                                      : PdfColors.blue900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Cargo Consignment Details Table
              pw.Text('CARGO & COMMODITY MANIFEST (مال و جنس کی تفصیل)',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _thCell('Party / فارمر'),
                      _thCell('Commodity / جنس'),
                      _thCell('Bags / بوریاں'),
                      _thCell('Weight (KG)'),
                      _thCell('Weight (Maunds / من)'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tbCellCenter(trip.partyName.isNotEmpty
                          ? trip.partyName
                          : 'General Mandi Consignment'),
                      _tbCellCenter(trip.commodityName.isNotEmpty
                          ? trip.commodityName
                          : 'Agricultural Goods'),
                      _tbCellCenter('${trip.bagCount} Bags'),
                      _tbCellRight('${trip.loadedWeightKg.toStringAsFixed(0)} KG'),
                      _tbCellRightBold('${trip.loadedWeightMaunds.toStringAsFixed(2)} Maunds'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Freight & Financial Settlement Summary
              pw.Text('FREIGHT CHARGES & EXPENSE SETTLEMENT (کرایہ و اخراجات حساب)',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Agreed Freight (طے شدہ کرایہ):',
                        'PKR ${_currencyFmt.format(trip.agreedFreightPkr)}',
                        isBold: true),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    _buildRow('Driver Advance Cash (ڈرائیور پیشگی):',
                        '- PKR ${_currencyFmt.format(trip.driverAdvancePkr)}'),
                    _buildRow('Diesel Fuel Expense (ڈیزل خرچ):',
                        '- PKR ${_currencyFmt.format(trip.dieselExpensePkr)}'),
                    _buildRow('Toll Tax & Gate Fees (ٹول پلازہ / پرچی):',
                        '- PKR ${_currencyFmt.format(trip.tollAndTaxPkr)}'),
                    if (trip.otherExpensePkr > 0)
                      _buildRow('Other Incidental Expenses (دیگر خرچ):',
                          '- PKR ${_currencyFmt.format(trip.otherExpensePkr)}'),
                    pw.Divider(thickness: 1, color: PdfColors.grey400),
                    _buildRow(
                      'Balance Freight Payable to Driver (بقایا کرایہ):',
                      'PKR ${_currencyFmt.format(trip.balanceFreightPayablePkr)}',
                      isBold: true,
                      color: PdfColors.red800,
                    ),
                    _buildRow(
                      'Net Trip Profit to Shop (گاڑی خالص منافع):',
                      'PKR ${_currencyFmt.format(trip.netTripProfitPkr)}',
                      isBold: true,
                      color: PdfColors.green800,
                    ),
                  ],
                ),
              ),

              if (trip.notes.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.amber200),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('Special Instructions: ',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.amber900)),
                      pw.Expanded(
                        child: pw.Text(trip.notes,
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.amber900)),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Consignor / Farmer',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('دستخط بھیجنے والا',
                          style: const pw.TextStyle(
                              fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Driver Signature',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('دستخط ڈرائیور وصول کنندہ',
                          style: const pw.TextStyle(
                              fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Mandi Commission Agent',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('مہر و دستخط منڈی آڑھتی',
                          style: const pw.TextStyle(
                              fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                    'Official Fleet Logistics Bilty • Mandi Cloud ERP',
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey500)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // =========================================================================
  // 2. VEHICLE PROFIT & LOSS LEDGER REGISTER (A4 LANDSCAPE)
  // =========================================================================

  static Future<Uint8List> generateVehicleLedgerPdf({
    required FleetVehicle vehicle,
    required List<FleetTrip> trips,
    required List<FleetFuelLog> fuelLogs,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();

    final totalFreight = trips.fold(0.0, (sum, t) => sum + t.agreedFreightPkr);
    final totalAdvances = trips.fold(0.0, (sum, t) => sum + t.driverAdvancePkr);
    final totalTripExpenses = trips.fold(
        0.0, (sum, t) => sum + t.dieselExpensePkr + t.tollAndTaxPkr + t.otherExpensePkr);
    final totalTripProfit = trips.fold(0.0, (sum, t) => sum + t.netTripProfitPkr);
    final totalFuelCost = fuelLogs.fold(0.0, (sum, f) => sum + f.totalCostPkr);
    final totalFuelLiters = fuelLogs.fold(0.0, (sum, f) => sum + f.liters);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
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
                        'VEHICLE FREIGHT, FUEL & P&L LEDGER (گاڑی کرایہ، ڈیزل و منافع کھاتہ)',
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
                        'Vehicle: ${vehicle.registrationNumber} (${vehicle.vehicleType.labelEnglish})',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900,
                        ),
                      ),
                      pw.Text(
                        'Driver: ${vehicle.driverName.isNotEmpty ? vehicle.driverName : "N/A"}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // KPI Row
              pw.Row(
                children: [
                  _kpiBox('Total Trips', '${trips.length}'),
                  _kpiBox('Gross Freight Earned', 'PKR ${_currencyFmt.format(totalFreight)}', color: PdfColors.green800),
                  _kpiBox('Total Fuel Consumed', '${totalFuelLiters.toStringAsFixed(1)} L (PKR ${_currencyFmt.format(totalFuelCost)})', color: PdfColors.red800),
                  _kpiBox('Driver Advances', 'PKR ${_currencyFmt.format(totalAdvances)}'),
                  _kpiBox('Net Vehicle Profit', 'PKR ${_currencyFmt.format(totalTripProfit)}', color: PdfColors.teal900, isBold: true),
                ],
              ),
              pw.SizedBox(height: 12),

              // Trips Table
              pw.Text('TRIP LOGS & FREIGHT EARNINGS',
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.6), // #
                  1: const pw.FlexColumnWidth(1.2), // Trip #
                  2: const pw.FlexColumnWidth(1.2), // Date
                  3: const pw.FlexColumnWidth(2.2), // Route
                  4: const pw.FlexColumnWidth(1.4), // Cargo
                  5: const pw.FlexColumnWidth(1.2), // Weight
                  6: const pw.FlexColumnWidth(1.4), // Agreed Freight
                  7: const pw.FlexColumnWidth(1.2), // Advance
                  8: const pw.FlexColumnWidth(1.2), // Expenses
                  9: const pw.FlexColumnWidth(1.4), // Net Profit
                  10: const pw.FlexColumnWidth(1.0), // Status
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _thCell('#'),
                      _thCell('Trip #'),
                      _thCell('Date'),
                      _thCell('Route (From -> To)'),
                      _thCell('Cargo / Party'),
                      _thCell('Maunds'),
                      _thCell('Freight (PKR)'),
                      _thCell('Advance'),
                      _thCell('Expenses'),
                      _thCell('Net Profit'),
                      _thCell('Status'),
                    ],
                  ),
                  ...trips.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final t = entry.value;
                    final exp = t.dieselExpensePkr + t.tollAndTaxPkr + t.otherExpensePkr;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _tbCellCenter('$idx'),
                        _tbCellCenter(t.tripNumber),
                        _tbCellCenter(DateFormat('dd-MMM').format(t.tripDate)),
                        _tbCell('${t.origin} -> ${t.destination}'),
                        _tbCell('${t.commodityName} (${t.partyName})'),
                        _tbCellRight(t.loadedWeightMaunds.toStringAsFixed(1)),
                        _tbCellRight(_currencyFmt.format(t.agreedFreightPkr)),
                        _tbCellRight(_currencyFmt.format(t.driverAdvancePkr)),
                        _tbCellRight(_currencyFmt.format(exp)),
                        _tbCellRightBold(_currencyFmt.format(t.netTripProfitPkr)),
                        _tbCellCenter(t.status.name.toUpperCase()),
                      ],
                    );
                  }),
                  // Totals
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _tbCellCenter(''),
                      _tbCellBold('TOTALS'),
                      _tbCellCenter(''),
                      _tbCell(''),
                      _tbCell(''),
                      _tbCell(''),
                      _tbCellRightBold(_currencyFmt.format(totalFreight)),
                      _tbCellRightBold(_currencyFmt.format(totalAdvances)),
                      _tbCellRightBold(_currencyFmt.format(totalTripExpenses)),
                      _tbCellRightBold(_currencyFmt.format(totalTripProfit)),
                      _tbCellCenter(''),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Transport Munshi: _________________________',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('Authorized Auditor: _________________________',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Helper Table Cell Widgets ─────────────────────────────────────────────

  static pw.Widget _kpiBox(String title, String value,
      {PdfColor? color, bool isBold = false}) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? PdfColors.blueGrey900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _thCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900),
        ),
      );

  static pw.Widget _tbCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
      );

  static pw.Widget _tbCellBold(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900)),
      );

  static pw.Widget _tbCellCenter(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(text,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
      );

  static pw.Widget _tbCellRight(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(text,
            textAlign: pw.TextAlign.right,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
      );

  static pw.Widget _tbCellRightBold(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(text,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900)),
      );

  static pw.Widget _buildRow(String label, String value,
      {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color ?? PdfColors.grey800)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color ?? PdfColors.grey900)),
        ],
      ),
    );
  }

  /// Direct print trigger for Trip Bilty
  static Future<void> printTripChallan({
    required FleetTrip trip,
    required FleetVehicle vehicle,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdfBytes = await generateTripChallanPdf(
      trip: trip,
      vehicle: vehicle,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Bilty_${trip.tripNumber}_${vehicle.registrationNumber}.pdf',
    );
  }

  /// Direct print trigger for Vehicle Ledger
  static Future<void> printVehicleLedger({
    required FleetVehicle vehicle,
    required List<FleetTrip> trips,
    required List<FleetFuelLog> fuelLogs,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdfBytes = await generateVehicleLedgerPdf(
      vehicle: vehicle,
      trips: trips,
      fuelLogs: fuelLogs,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Vehicle_Ledger_${vehicle.registrationNumber}.pdf',
    );
  }
}
