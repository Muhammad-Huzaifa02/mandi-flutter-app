// Printable PDF Generator for Farmer QR Identity Card & Simplified Urdu Passbook
// (*زمیندار کیو آر شناختی کارڈ اور تصویری کھاتہ پاس بک*).

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FarmerIdCardPdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');
  static final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  // =========================================================================
  // 1. STANDARD CREDIT-CARD SIZE (CR80) FARMER IDENTITY CARD (85.6mm x 54mm)
  // =========================================================================

  static Future<Uint8List> generateFarmerIdCardPdf({
    required String farmerId,
    required String farmerName,
    String? cnic,
    String? phone,
    String? villageOrCity,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();

    // Standard CR80 Card Size: 85.6mm x 54mm
    const cardFormat = PdfPageFormat(
      85.6 * PdfPageFormat.mm,
      54.0 * PdfPageFormat.mm,
      marginAll: 3 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: cardFormat,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.teal900, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              color: PdfColors.white,
            ),
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Shop Ribbon
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.teal900,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        shopName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'FARMER PASS CARD / زمیندار کارڈ',
                        style: const pw.TextStyle(
                          color: PdfColors.amber300,
                          fontSize: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // Card Body: Photo/Icon + Info + QR Code
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Avatar / Farmer Symbol
                      pw.Container(
                        width: 38,
                        height: 42,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            farmerName.isNotEmpty ? farmerName[0].toUpperCase() : 'Z',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 6),

                      // Details
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              farmerName,
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                              maxLines: 1,
                            ),
                            if (phone != null && phone.isNotEmpty) ...[
                              pw.SizedBox(height: 1),
                              pw.Text('Phone: $phone',
                                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800)),
                            ],
                            if (cnic != null && cnic.isNotEmpty) ...[
                              pw.SizedBox(height: 1),
                              pw.Text('CNIC: $cnic',
                                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800)),
                            ],
                            if (villageOrCity != null && villageOrCity.isNotEmpty) ...[
                              pw.SizedBox(height: 1),
                              pw.Text('Village: $villageOrCity',
                                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800),
                                  maxLines: 1),
                            ],
                            pw.SizedBox(height: 1),
                            pw.Text('ID: ${farmerId.length > 8 ? farmerId.substring(0, 8) : farmerId}',
                                style: pw.TextStyle(fontSize: 5.5, color: PdfColors.teal800, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),

                      // QR Code for Instant Scanner Verification
                      pw.BarcodeWidget(
                        data: 'MANDI:FARMER:$farmerId',
                        barcode: pw.Barcode.qrCode(),
                        width: 38,
                        height: 38,
                      ),
                    ],
                  ),
                ),

                // Card Footer
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.only(top: 2),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Direct Scan for Fast Inward & Khata',
                        style: const pw.TextStyle(fontSize: 4.8, color: PdfColors.grey600),
                      ),
                      if (shopPhone != null && shopPhone.isNotEmpty)
                        pw.Text('Helpline: $shopPhone',
                            style: const pw.TextStyle(fontSize: 4.8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // =========================================================================
  // 2. SIMPLIFIED HIGH-CONTRAST URDU PASSBOOK SUMMARY SLIP (80mm Thermal)
  // =========================================================================

  static Future<Uint8List> generateFarmerPassbookSlipPdf({
    required String farmerName,
    String? phone,
    required double totalDeliveredMaunds,
    required double totalGrossEarnings,
    required double totalDeductions,
    required double totalPaymentsReceived,
    required double runningBalance, // Positive = Payable to farmer, Negative = Advance owed
    required String shopName,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          160 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          final isBalancePayable = runningBalance >= 0;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                shopName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'FARMER PASSBOOK / زمیندار تصویری کھاتہ',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.teal800),
              pw.SizedBox(height: 4),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Farmer: $farmerName',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    if (phone != null && phone.isNotEmpty)
                      pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 7.5)),
                    pw.Text('Date: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Metric 1: Total Maunds Delivered
              _buildPassbookRow(
                'Total Crop Delivered (کل مال)',
                '${_numberFmt.format(totalDeliveredMaunds)} Maunds (من)',
                isBold: true,
              ),
              _buildPassbookRow(
                'Gross Auction Value (کل بولی رقم)',
                'Rs. ${_currencyFmt.format(totalGrossEarnings)}',
              ),
              _buildPassbookRow(
                'Mandi Deductions (کمیشن و منہائی)',
                '- Rs. ${_currencyFmt.format(totalDeductions)}',
                color: PdfColors.red900,
              ),
              _buildPassbookRow(
                'Net Crop Earnings (خالص رقم)',
                'Rs. ${_currencyFmt.format(totalGrossEarnings - totalDeductions)}',
                isBold: true,
              ),
              _buildPassbookRow(
                'Cash / Paid Advances (ادا شدہ رقم)',
                'Rs. ${_currencyFmt.format(totalPaymentsReceived)}',
              ),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1.5, color: PdfColors.teal800),
              pw.SizedBox(height: 6),

              // Final Balance Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: pw.BoxDecoration(
                  color: isBalancePayable ? PdfColors.green50 : PdfColors.amber50,
                  border: pw.Border.all(
                    color: isBalancePayable ? PdfColors.green800 : PdfColors.amber800,
                    width: 1.5,
                  ),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      isBalancePayable
                          ? 'باقی رقم واجب الادا (Payable to Farmer)'
                          : 'پیشگی ادھار واجب الوصول (Advance Owed)',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: isBalancePayable ? PdfColors.green900 : PdfColors.amber900,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Rs. ${_currencyFmt.format(runningBalance.abs())}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: isBalancePayable ? PdfColors.green900 : PdfColors.amber900,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Text(
                'کسی بھی غلطی یا تصدیق کی صورت میں منشی سے فوری رابطہ کریں۔',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
              if (shopPhone != null) ...[
                pw.SizedBox(height: 2),
                pw.Text('Shop Contact: $shopPhone',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800)),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPassbookRow(String title, String val,
      {bool isBold = false, PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
          pw.Text(val,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color,
              )),
        ],
      ),
    );
  }
}
