import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mandi/core/utils/esc_pos_command_builder.dart';
import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/data/models/consignment_lot_model.dart';
import 'package:mandi/data/models/farmer_advance_model.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/weighbridge_ticket_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Universal Thermal Receipt & Slip Printing Engine for 58mm and 80mm POS Printers.
///
/// Supports multi-document Mandi operational printing:
/// 1. Sales Invoices (*سیلز بل*)
/// 2. Auction Winning Bids / Dheri Slips (*بولی پرچہ*)
/// 3. Electronic Weighbridge / Kanda Weight Certificates (*دھرم کنڈا وزن رسید*)
/// 4. Cash Receipts & Khata Recovery Slips (*نقدی وصولی پرچہ*)
/// 5. Farmer Advance Crop Loan Deductions (*ایڈوانس کٹوتی پرچہ*)
/// 6. Printer Hardware Alignment & Feed Test Slips (*ٹیسٹ پرنٹ*)
class ThermalReceiptService {
  // =========================================================================
  // 1. SALES INVOICE THERMAL SLIP
  // =========================================================================

  /// Generates a roll paper ESC/POS PDF layout (e.g. 58mm / 80mm width) for Invoices.
  static Future<Uint8List> generateThermalReceiptPdf({
    required Invoice invoice,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double rollWidthMm = 80,
  }) async {
    final pdf = pw.Document();

    final dateStr = invoice.createdAt != null
        ? '${invoice.createdAt!.day}/${invoice.createdAt!.month}/${invoice.createdAt!.year}'
        : '';

    final rollFormat = PdfPageFormat(
      rollWidthMm * PdfPageFormat.mm,
      double.infinity,
      marginAll: 8,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (shopCity != null && shopCity.isNotEmpty)
                pw.Center(
                  child: pw.Text('Mandi: $shopCity',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              if (shopPhone != null && shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text('Ph: $shopPhone',
                      style: const pw.TextStyle(fontSize: 8)),
                ),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),

              pw.Text('Invoice #: ${invoice.invoiceNumber}',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              if (dateStr.isNotEmpty)
                pw.Text('Date: $dateStr',
                    style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                  'Party: ${invoice.customerName.isNotEmpty ? invoice.customerName : (invoice.supplierName.isNotEmpty ? invoice.supplierName : "Walk-in")}',
                  style: const pw.TextStyle(fontSize: 8)),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              // Items
              pw.Text('ITEMS',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),

              ...invoice.items.map((item) {
                final manns = MandiCalculator.kgToMann(item.weightKg);
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(item.productName,
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Rs. ${item.lineTotal.toStringAsFixed(0)}',
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Text(
                        '${item.quantity.toStringAsFixed(0)} Bags • ${item.weightKg.toStringAsFixed(0)}KG (${manns.toStringAsFixed(2)} Mann) @ Rs. ${item.unitPrice.toStringAsFixed(0)}',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              // Summary
              _row('Subtotal:', 'Rs. ${invoice.subtotal.toStringAsFixed(0)}'),
              if (invoice.commission > 0)
                _row('Commission:',
                    '+Rs. ${invoice.commission.toStringAsFixed(0)}'),
              if (invoice.expenses > 0)
                _row('Expenses:',
                    '+Rs. ${invoice.expenses.toStringAsFixed(0)}'),
              if (invoice.discount > 0)
                _row('Discount:',
                    '-Rs. ${invoice.discount.toStringAsFixed(0)}'),
              pw.Divider(thickness: 0.5),
              _row('TOTAL:', 'Rs. ${invoice.total.toStringAsFixed(0)}',
                  isBold: true),
              _row('Received:',
                  'Rs. ${invoice.receivedAmount.toStringAsFixed(0)}'),
              if (invoice.pendingAmount > 0)
                _row('Pending:',
                    'Rs. ${invoice.pendingAmount.toStringAsFixed(0)}',
                    isBold: true),

              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('*** Thank You! ***',
                    style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct layout print trigger for 58mm / 80mm Invoice thermal printer
  static Future<void> printThermalSlip({
    required Invoice invoice,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double? rollWidthMm,
  }) async {
    var fullInvoice = invoice;
    if (fullInvoice.items.isEmpty && fullInvoice.id.isNotEmpty) {
      final fetchedItems =
          await SupabaseService.getInvoiceItems(fullInvoice.id);
      fullInvoice = fullInvoice.copyWith(items: fetchedItems);
    }

    final width = rollWidthMm ?? await _getStoredRollWidth();

    await Printing.layoutPdf(
      onLayout: (_) => generateThermalReceiptPdf(
        invoice: fullInvoice,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        rollWidthMm: width,
      ),
    );
  }

  // =========================================================================
  // 2. AUCTION BOLI & DHERI SLIP (*بولی و ڈھیری پرچہ*)
  // =========================================================================

  /// Generates a roll paper ESC/POS PDF layout for Auction Winning Bids.
  static Future<Uint8List> generateBoliSlipPdf({
    required ConsignmentLot lot,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double rollWidthMm = 80,
  }) async {
    final pdf = pw.Document();
    final rollFormat = PdfPageFormat(
      rollWidthMm * PdfPageFormat.mm,
      double.infinity,
      marginAll: 8,
    );

    final lotDate = lot.createdAt ?? DateTime.now();
    final dateStr = '${lotDate.day}/${lotDate.month}/${lotDate.year}';
    final weightMaunds = lot.maunds;
    final winningRate = lot.ratePerMaund;
    final grossTotal = lot.estimatedTotal;

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (shopCity != null && shopCity.isNotEmpty)
                pw.Center(
                  child: pw.Text('Mandi: $shopCity',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              if (shopPhone != null && shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text('Ph: $shopPhone',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text('*** AUCTION BOLI SLIP / بولی پرچہ ***',
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(thickness: 0.5),

              _row('Lot Number:', lot.lotNumber, isBold: true),
              _row('Date:', dateStr),
              _row('Farmer (زمیندار):',
                  lot.supplierName.isNotEmpty ? lot.supplierName : 'Local Farmer'),
              if (lot.vehicleNumber.isNotEmpty)
                _row('Vehicle #:', lot.vehicleNumber),
              _row('Crop (جنس):',
                  lot.productName.isNotEmpty ? lot.productName : 'Standard Lot'),
              _row('Bags (بوریاں):', '${lot.bagCount} Bags'),
              _row('Weight (وزن):',
                  '${lot.weightKg.toStringAsFixed(0)} KG (${weightMaunds.toStringAsFixed(2)} Mann)'),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              _row('Winning Bidder:',
                  lot.winningBuyerName.isNotEmpty ? lot.winningBuyerName : 'Open / In Auction',
                  isBold: true),
              _row('Winning Rate (ریٹ):',
                  'Rs. ${winningRate.toStringAsFixed(0)} / Mann',
                  isBold: true),
              pw.Divider(thickness: 0.5),

              _row('Gross Boli Total:', 'Rs. ${grossTotal.toStringAsFixed(0)}',
                  isBold: true),

              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 45, height: 0.5, color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text('Buyer Sign', style: const pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 45, height: 0.5, color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text('Munshi Sign', style: const pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('* Mandi Commission Agent Boli Slip *',
                    style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct layout print trigger for Boli Slip
  static Future<void> printBoliSlip({
    required ConsignmentLot lot,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double? rollWidthMm,
  }) async {
    final width = rollWidthMm ?? await _getStoredRollWidth();
    await Printing.layoutPdf(
      onLayout: (_) => generateBoliSlipPdf(
        lot: lot,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        rollWidthMm: width,
      ),
    );
  }

  // =========================================================================
  // 3. WEIGHBRIDGE KANDA CERTIFICATE SLIP (*دھرم کنڈا رسید*)
  // =========================================================================

  /// Generates a roll paper ESC/POS PDF layout for Dharam Kanda weighments.
  static Future<Uint8List> generateWeighbridgeSlipPdf({
    required WeighbridgeTicket ticket,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double rollWidthMm = 80,
  }) async {
    final pdf = pw.Document();
    final rollFormat = PdfPageFormat(
      rollWidthMm * PdfPageFormat.mm,
      double.infinity,
      marginAll: 8,
    );

    final grossDate =
        '${ticket.grossWeighedAt.day}/${ticket.grossWeighedAt.month} ${ticket.grossWeighedAt.hour.toString().padLeft(2, '0')}:${ticket.grossWeighedAt.minute.toString().padLeft(2, '0')}';
    final tareDate = ticket.tareWeighedAt != null
        ? '${ticket.tareWeighedAt!.day}/${ticket.tareWeighedAt!.month} ${ticket.tareWeighedAt!.hour.toString().padLeft(2, '0')}:${ticket.tareWeighedAt!.minute.toString().padLeft(2, '0')}'
        : 'Pending';

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (shopCity != null && shopCity.isNotEmpty)
                pw.Center(
                  child: pw.Text('Mandi: $shopCity',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              if (shopPhone != null && shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text('Ph: $shopPhone',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text('*** COMPUTERIZED DHARAM KANDA / دھرم کنڈا ***',
                    style: pw.TextStyle(
                        fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(thickness: 0.5),

              _row('Ticket #:', ticket.ticketNumber, isBold: true),
              _row('Vehicle #:', '${ticket.vehicleNumber} (${ticket.vehicleType.labelEnglish})'),
              _row('Party (پارٹی):', ticket.partyName),
              _row('Commodity (جنس):', ticket.commodityName),
              if (ticket.driverName.isNotEmpty)
                _row('Driver:', ticket.driverName),
              if (ticket.bagCount > 0)
                _row('Bags:', '${ticket.bagCount} Bags'),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              _row('1st Gross Wt (بھرا):',
                  '${ticket.grossWeightKg.toStringAsFixed(0)} KG (${ticket.grossMaunds.toStringAsFixed(2)} Mann)'),
              _row('Gross Time:', grossDate),
              _row('2nd Tare Wt (خالی):',
                  '${ticket.tareWeightKg.toStringAsFixed(0)} KG (${ticket.tareMaunds.toStringAsFixed(2)} Mann)'),
              _row('Tare Time:', tareDate),
              pw.Divider(thickness: 0.5),

              _row('Net Weight (صافی):',
                  '${ticket.computedNetWeightKg.toStringAsFixed(0)} KG (${ticket.netMaunds.toStringAsFixed(2)} Mann)',
                  isBold: true),

              if (ticket.deductionKg > 0) ...[
                pw.SizedBox(height: 2),
                _row('Katoti Deductions:',
                    '-${ticket.deductionKg.toStringAsFixed(0)} KG (${ticket.deductionReason})'),
              ],

              pw.Divider(thickness: 0.5),
              _row('FINAL BILLABLE:',
                  '${ticket.computedFinalWeightKg.toStringAsFixed(0)} KG (${ticket.maunds.toStringAsFixed(2)} Mann)',
                  isBold: true),
              _row('Kanda Fee:', 'Rs. ${ticket.kandaFee.toStringAsFixed(0)}'),

              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 45, height: 0.5, color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text('Driver Sign', style: const pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 45, height: 0.5, color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text('Kanda Incharge',
                          style: const pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('* Certified Mandi Weighbridge Slip *',
                    style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct layout print trigger for Weighbridge Slip
  static Future<void> printWeighbridgeSlip({
    required WeighbridgeTicket ticket,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double? rollWidthMm,
  }) async {
    final width = rollWidthMm ?? await _getStoredRollWidth();
    await Printing.layoutPdf(
      onLayout: (_) => generateWeighbridgeSlipPdf(
        ticket: ticket,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        rollWidthMm: width,
      ),
    );
  }

  // =========================================================================
  // 4. CASH PAYMENT & KHATA RECOVERY SLIP (*نقدی وصولی پرچہ*)
  // =========================================================================

  /// Generates a roll paper ESC/POS PDF layout for Cash Khata Receipts.
  static Future<Uint8List> generatePaymentReceiptPdf({
    required String receiptNumber,
    required String partyName,
    required String partyType,
    required double amount,
    required double previousBalance,
    required double remainingBalance,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    DateTime? date,
    double rollWidthMm = 80,
  }) async {
    final pdf = pw.Document();
    final rollFormat = PdfPageFormat(
      rollWidthMm * PdfPageFormat.mm,
      double.infinity,
      marginAll: 8,
    );

    final paymentDate = date ?? DateTime.now();
    final dateStr =
        '${paymentDate.day}/${paymentDate.month}/${paymentDate.year} ${paymentDate.hour.toString().padLeft(2, '0')}:${paymentDate.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (shopCity != null && shopCity.isNotEmpty)
                pw.Center(
                  child: pw.Text('Mandi: $shopCity',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              if (shopPhone != null && shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text('Ph: $shopPhone',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text('*** CASH RECEIPT / وصولی پرچہ ***',
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(thickness: 0.5),

              _row('Receipt #:', receiptNumber, isBold: true),
              _row('Date & Time:', dateStr),
              _row('Party ($partyType):', partyName, isBold: true),
              _row('Payment Mode:', paymentMethod.toUpperCase()),
              if (referenceNumber != null && referenceNumber.isNotEmpty)
                _row('Ref / Cheque #:', referenceNumber),
              if (notes != null && notes.isNotEmpty) _row('Notes:', notes),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              _row('Previous Balance:',
                  'Rs. ${previousBalance.toStringAsFixed(0)}'),
              _row('AMOUNT RECEIVED (وصول):',
                  'Rs. ${amount.toStringAsFixed(0)}',
                  isBold: true),
              pw.Divider(thickness: 0.5),
              _row('NEW REMAINING BALANCE:',
                  'Rs. ${remainingBalance.toStringAsFixed(0)}',
                  isBold: true),

              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 45, height: 0.5, color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text('Party Sign', style: const pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 45, height: 0.5, color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text('Cashier / Munshi',
                          style: const pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('* JazakAllah Khair / شکریہ *',
                    style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct layout print trigger for Payment Receipt
  static Future<void> printPaymentReceipt({
    required String receiptNumber,
    required String partyName,
    required String partyType,
    required double amount,
    required double previousBalance,
    required double remainingBalance,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    DateTime? date,
    double? rollWidthMm,
  }) async {
    final width = rollWidthMm ?? await _getStoredRollWidth();
    await Printing.layoutPdf(
      onLayout: (_) => generatePaymentReceiptPdf(
        receiptNumber: receiptNumber,
        partyName: partyName,
        partyType: partyType,
        amount: amount,
        previousBalance: previousBalance,
        remainingBalance: remainingBalance,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        notes: notes,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        date: date,
        rollWidthMm: width,
      ),
    );
  }

  // =========================================================================
  // 5. FARMER ADVANCE LOAN RECOVERY SLIP (*ایڈوانس کٹوتی پرچہ*)
  // =========================================================================

  /// Generates a roll paper ESC/POS PDF layout for Farmer Advance Loan Deductions.
  static Future<Uint8List> generateAdvanceRecoverySlipPdf({
    required FarmerAdvance advance,
    required FarmerAdvanceRecovery recovery,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double rollWidthMm = 80,
  }) async {
    final pdf = pw.Document();
    final rollFormat = PdfPageFormat(
      rollWidthMm * PdfPageFormat.mm,
      double.infinity,
      marginAll: 8,
    );

    final recDate =
        '${recovery.recoveryDate.day}/${recovery.recoveryDate.month}/${recovery.recoveryDate.year}';
    final balanceBefore =
        advance.computedRemainingBalance + recovery.recoveredAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (shopCity != null && shopCity.isNotEmpty)
                pw.Center(
                  child: pw.Text('Mandi: $shopCity',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              if (shopPhone != null && shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text('Ph: $shopPhone',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text('*** ADVANCE RECOVERY / کٹوتی رسید ***',
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(thickness: 0.5),

              _row(
                  'Voucher #:',
                  recovery.id.length > 8
                      ? recovery.id.substring(0, 8)
                      : recovery.id,
                  isBold: true),
              _row('Date:', recDate),
              _row('Farmer (زمیندار):', advance.farmerName, isBold: true),
              _row('Category:', advance.advanceType.labelEnglish),
              if (advance.description.isNotEmpty)
                _row('Description:', advance.description),
              if (advance.targetCrop.isNotEmpty)
                _row('Target Crop:', advance.targetCrop),
              _row('Recovery Mode:', recovery.recoveryMethod.toUpperCase()),
              if (recovery.notes.isNotEmpty)
                _row('Remarks:', recovery.notes),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              _row('Loan Debt Before:',
                  'Rs. ${balanceBefore.toStringAsFixed(0)}'),
              _row('RECOVERY DEDUCTION (کٹوتی):',
                  'Rs. ${recovery.recoveredAmount.toStringAsFixed(0)}',
                  isBold: true),
              pw.Divider(thickness: 0.5),
              _row('REMAINING ADVANCE LOAN:',
                  'Rs. ${advance.computedRemainingBalance.toStringAsFixed(0)}',
                  isBold: true),

              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 45, height: 0.5, color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text('Farmer Sign', style: const pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 45, height: 0.5, color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text('Munshi Sign', style: const pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('* Mandi Pre-Harvest Financing System *',
                    style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct layout print trigger for Advance Recovery Slip
  static Future<void> printAdvanceRecoverySlip({
    required FarmerAdvance advance,
    required FarmerAdvanceRecovery recovery,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double? rollWidthMm,
  }) async {
    final width = rollWidthMm ?? await _getStoredRollWidth();
    await Printing.layoutPdf(
      onLayout: (_) => generateAdvanceRecoverySlipPdf(
        advance: advance,
        recovery: recovery,
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        rollWidthMm: width,
      ),
    );
  }

  // =========================================================================
  // 6. HARDWARE TEST SLIP (*پرنٹر ٹیسٹ پرچہ*)
  // =========================================================================

  /// Generates a roll paper ESC/POS PDF layout for testing printer alignment and feeds.
  static Future<Uint8List> generateTestSlipPdf({
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double rollWidthMm = 80,
  }) async {
    final pdf = pw.Document();
    final rollFormat = PdfPageFormat(
      rollWidthMm * PdfPageFormat.mm,
      double.infinity,
      marginAll: 8,
    );

    final now = DateTime.now();
    final dateStr =
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (shopCity != null && shopCity.isNotEmpty)
                pw.Center(
                  child: pw.Text('Mandi: $shopCity',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              if (shopPhone != null && shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text('Ph: $shopPhone',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('*** PRINTER TEST SLIP / ٹیسٹ پرنٹ ***',
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(thickness: 0.5),

              _row('Roll Width:',
                  '${rollWidthMm.toStringAsFixed(0)}mm (${rollWidthMm == 58 ? "32 Columns" : "48 Columns"})'),
              _row('Test Date:', dateStr),
              _row('Protocol:', 'ESC/POS Emulation'),
              _row('Encoding:', 'UTF-8 / Latin-1 Monospace'),
              _row('Status:', 'ONLINE & READY', isBold: true),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              pw.Text('COLUMN ALIGNMENT TEST:',
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('123456789012345678901234567890123456789012345678',
                  style: const pw.TextStyle(fontSize: 6)),
              pw.SizedBox(height: 2),
              _row('Left Item', 'Right Value'),
              _row('Bold Left Key', 'Bold Right Val', isBold: true),

              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Text('*** Printer Ready For Mandi Operations ***',
                    style: const pw.TextStyle(fontSize: 7.5)),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct layout print trigger for Test Slip
  static Future<void> printTestSlip({
    required String shopName,
    String? shopPhone,
    String? shopCity,
    double? rollWidthMm,
  }) async {
    final width = rollWidthMm ?? await _getStoredRollWidth();
    await Printing.layoutPdf(
      onLayout: (_) => generateTestSlipPdf(
        shopName: shopName,
        shopPhone: shopPhone,
        shopCity: shopCity,
        rollWidthMm: width,
      ),
    );
  }

  // =========================================================================
  // 7. RAW ESC/POS BYTE BUILDERS (BLUETOOTH / SERIAL SOCKETS)
  // =========================================================================

  /// Builds raw ESC/POS byte commands for an Invoice
  static Uint8List buildInvoiceEscPosBytes({
    required Invoice invoice,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    ThermalRollWidth rollWidth = ThermalRollWidth.mm80,
  }) {
    final builder = EscPosCommandBuilder(rollWidth: rollWidth);
    builder.header(shopName, subtitle: shopCity, phone: shopPhone);
    builder.text('*** SALES INVOICE ***', align: PosAlign.center, bold: true);
    builder.divider();

    builder.row2(left: 'Invoice #:', right: invoice.invoiceNumber, bold: true);
    if (invoice.createdAt != null) {
      builder.row2(
          left: 'Date:',
          right:
              '${invoice.createdAt!.day}/${invoice.createdAt!.month}/${invoice.createdAt!.year}');
    }
    final partyName = invoice.customerName.isNotEmpty
        ? invoice.customerName
        : (invoice.supplierName.isNotEmpty ? invoice.supplierName : 'Walk-in');
    builder.row2(left: 'Party:', right: partyName);
    builder.divider();

    builder.row3(col1: 'Item', col2: 'Qty', col3: 'Total', bold: true);
    builder.divider();

    for (final item in invoice.items) {
      builder.row3(
        col1: item.productName,
        col2: '${item.quantity.toStringAsFixed(0)}B',
        col3: 'Rs.${item.lineTotal.toStringAsFixed(0)}',
      );
    }
    builder.divider();

    builder.row2(
        left: 'Subtotal:', right: 'Rs. ${invoice.subtotal.toStringAsFixed(0)}');
    if (invoice.commission > 0) {
      builder.row2(
          left: 'Commission:',
          right: '+Rs. ${invoice.commission.toStringAsFixed(0)}');
    }
    if (invoice.discount > 0) {
      builder.row2(
          left: 'Discount:',
          right: '-Rs. ${invoice.discount.toStringAsFixed(0)}');
    }
    builder.doubleDivider();
    builder.row2(
        left: 'TOTAL:',
        right: 'Rs. ${invoice.total.toStringAsFixed(0)}',
        bold: true);
    builder.row2(
        left: 'Received:',
        right: 'Rs. ${invoice.receivedAmount.toStringAsFixed(0)}');
    if (invoice.pendingAmount > 0) {
      builder.row2(
          left: 'Pending Balance:',
          right: 'Rs. ${invoice.pendingAmount.toStringAsFixed(0)}',
          bold: true);
    }
    builder.divider();
    builder.text('*** Thank You! ***', align: PosAlign.center);
    builder.cut();

    return builder.toBytes();
  }

  /// Builds raw ESC/POS byte commands for an Auction Boli Slip
  static Uint8List buildBoliEscPosBytes({
    required ConsignmentLot lot,
    required String shopName,
    String? shopPhone,
    String? shopCity,
    ThermalRollWidth rollWidth = ThermalRollWidth.mm80,
  }) {
    final builder = EscPosCommandBuilder(rollWidth: rollWidth);
    builder.header(shopName, subtitle: shopCity, phone: shopPhone);
    builder.text('*** AUCTION BOLI SLIP ***', align: PosAlign.center, bold: true);
    builder.divider();

    builder.row2(left: 'Lot #:', right: lot.lotNumber, bold: true);
    final lotDate = lot.createdAt ?? DateTime.now();
    builder.row2(
        left: 'Date:',
        right: '${lotDate.day}/${lotDate.month}/${lotDate.year}');
    builder.row2(
        left: 'Farmer:',
        right:
            lot.supplierName.isNotEmpty ? lot.supplierName : 'Local Farmer');
    builder.row2(
        left: 'Crop:',
        right: lot.productName.isNotEmpty ? lot.productName : 'Lot');
    builder.row2(left: 'Bags:', right: '${lot.bagCount} Bags');
    builder.row2(
        left: 'Weight:',
        right:
            '${lot.weightKg.toStringAsFixed(0)}KG (${lot.maunds.toStringAsFixed(2)}M)');
    builder.divider();

    builder.row2(
        left: 'Winner:',
        right:
            lot.winningBuyerName.isNotEmpty ? lot.winningBuyerName : 'Open',
        bold: true);
    builder.row2(
        left: 'Bid Rate:',
        right: 'Rs.${lot.ratePerMaund.toStringAsFixed(0)}/Mann',
        bold: true);
    builder.doubleDivider();
    builder.row2(
        left: 'Gross Boli Total:',
        right: 'Rs. ${lot.estimatedTotal.toStringAsFixed(0)}',
        bold: true);
    builder.divider();
    builder.text('Munshi: ________  Buyer: ________', align: PosAlign.center);
    builder.cut();

    return builder.toBytes();
  }

  // =========================================================================
  // INTERNAL HELPERS
  // =========================================================================

  static pw.Widget _row(String label, String value, {bool isBold = false}) {
    final style = pw.TextStyle(
      fontSize: 8,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static Future<double> _getStoredRollWidth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('printer_roll_width') ?? 80.0;
    } catch (_) {
      return 80.0;
    }
  }
}
