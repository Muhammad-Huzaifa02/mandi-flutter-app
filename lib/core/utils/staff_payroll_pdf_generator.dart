// Professional A4 PDF Generator for Munshi Staff Pay Slips & Monthly Wage Registers
// (*تنخواہ پرچہ، اوورٹائم اور ماہانہ عملہ کیش ڈسبرسمنٹ رجسٹر*).

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mandi/data/models/staff_payroll_model.dart';

class StaffPayrollPdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');

  // =========================================================================
  // 1. INDIVIDUAL STAFF SALARY SLIP (A4 PORTRAIT)
  // =========================================================================

  static Future<Uint8List> generatePaySlipPdf({
    required StaffPayrollVoucher voucher,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();
    final issueDate = voucher.paidAt != null
        ? DateFormat('dd MMMM yyyy').format(voucher.paidAt!)
        : DateFormat('dd MMMM yyyy').format(DateTime.now());

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
                      pw.Text('GRAIN & VEGETABLE COMMISSION AGENTS',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo50,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.indigo300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('STAFF SALARY SLIP',
                            style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.indigo900)),
                        pw.Text('تنخواہ پرچہ و ڈسبرسمنٹ واؤچر',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.indigo700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                            'Voucher #: ${voucher.voucherNumber.isNotEmpty ? voucher.voucherNumber : "DRAFT"}',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.indigo900)),
                        pw.Text('Month: ${voucher.monthYear}',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey800)),
                        pw.Text('Date: $issueDate',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Staff Details Box
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
                        pw.Text('Employee Name / عملہ کا نام:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(voucher.staffName,
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blueGrey900)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Pay Period / مہینہ:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(voucher.monthYear,
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blueGrey900)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Payment Status / کیفیت:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: voucher.status == PayrollStatus.paid
                                ? PdfColors.green100
                                : voucher.status == PayrollStatus.approved
                                    ? PdfColors.blue100
                                    : PdfColors.orange100,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            voucher.status.labelEnglish.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: voucher.status == PayrollStatus.paid
                                  ? PdfColors.green900
                                  : voucher.status == PayrollStatus.approved
                                      ? PdfColors.blue900
                                      : PdfColors.orange900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Attendance Summary
              pw.Text('ATTENDANCE & WORK DAYS SUMMARY (حاضری و کام کے ایام)',
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
                      _thCell('Days Present (حاضر)'),
                      _thCell('Days Absent (غیر حاضر)'),
                      _thCell('Half Days (نصف دن)'),
                      _thCell('Overtime (اوور ٹائم)'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tbCellCenter('${voucher.daysPresent} Days'),
                      _tbCellCenter('${voucher.daysAbsent} Days'),
                      _tbCellCenter('${voucher.daysHalfDay} Days'),
                      _tbCellCenter('${voucher.overtimeHours.toStringAsFixed(1)} Hours'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Earnings & Deductions Two-Column Comparison
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Earnings Column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          color: PdfColors.green50,
                          child: pw.Text('EARNINGS & ALLOWANCES (آمدن و مراعات)',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green900)),
                        ),
                        pw.SizedBox(height: 4),
                        _buildPayRow(
                            'Base Salary (بنیادی تنخواہ):',
                            'PKR ${_currencyFmt.format(voucher.baseMonthlySalary)}'),
                        _buildPayRow(
                            'Overtime Allowance (اوورٹائم الاؤنس):',
                            '+ PKR ${_currencyFmt.format(voucher.overtimeAllowancePkr)}'),
                        _buildPayRow(
                            'Bonus & Incentives (انعامی بونس):',
                            '+ PKR ${_currencyFmt.format(voucher.bonusIncentivePkr)}'),
                        pw.Divider(thickness: 0.8, color: PdfColors.grey300),
                        _buildPayRow(
                          'Gross Pay (کل آمدن):',
                          'PKR ${_currencyFmt.format(voucher.baseMonthlySalary + voucher.overtimeAllowancePkr + voucher.bonusIncentivePkr)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Deductions Column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          color: PdfColors.red50,
                          child: pw.Text('DEDUCTIONS & RECOVERIES (کٹوتیاں)',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red900)),
                        ),
                        pw.SizedBox(height: 4),
                        _buildPayRow(
                            'Absentee Deduction (غیر حاضری کٹوتی):',
                            '- PKR ${_currencyFmt.format(voucher.absenteeDeductionPkr)}'),
                        _buildPayRow(
                            'Advance Salary (پیشگی تنخواہ کٹوتی):',
                            '- PKR ${_currencyFmt.format(voucher.advanceSalaryDeductionPkr)}'),
                        pw.SizedBox(height: 18),
                        pw.Divider(thickness: 0.8, color: PdfColors.grey300),
                        _buildPayRow(
                          'Total Deductions (کل کٹوتی):',
                          '- PKR ${_currencyFmt.format(voucher.absenteeDeductionPkr + voucher.advanceSalaryDeductionPkr)}',
                          isBold: true,
                          color: PdfColors.red800,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Net Payable Banner
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.indigo900,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NET DISBURSABLE SALARY / خالص واجب الادا رقم:',
                            style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey300,
                                letterSpacing: 0.5)),
                        pw.SizedBox(height: 2),
                        pw.Text('بذریعہ: ${voucher.paymentMethod.toUpperCase()}',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey400)),
                      ],
                    ),
                    pw.Text(
                      'PKR ${_currencyFmt.format(voucher.netPayableSalaryPkr)}',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              if (voucher.notes.isNotEmpty) ...[
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
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Note: ',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.amber900)),
                      pw.Expanded(
                        child: pw.Text(voucher.notes,
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.amber900)),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // Signatures Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                          width: 140,
                          height: 1,
                          color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Munshi / Cashier',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('دستخط منشی / کیشئر',
                          style: const pw.TextStyle(
                              fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                          width: 140,
                          height: 1,
                          color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Employee Signature',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('دستخط وصول کنندہ عملہ',
                          style: const pw.TextStyle(
                              fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                          width: 140,
                          height: 1,
                          color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text('Managing Partner / Proprietor',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('تصدیق و مہر آڑھتی مالک',
                          style: const pw.TextStyle(
                              fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                    'Computer-generated staff salary voucher • Mandi Cloud ERP',
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
  // 2. MONTHLY STAFF WAGE DISBURSEMENT REGISTER (A4 LANDSCAPE)
  // =========================================================================

  static Future<Uint8List> generateDisbursementRegisterPdf({
    required List<StaffPayrollVoucher> vouchers,
    required String shopName,
    required String monthYear,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdf = pw.Document();

    double totalBase = 0;
    double totalOvertime = 0;
    double totalBonus = 0;
    double totalAbsenteeDed = 0;
    double totalAdvanceDed = 0;
    double totalNet = 0;

    for (final v in vouchers) {
      totalBase += v.baseMonthlySalary;
      totalOvertime += v.overtimeAllowancePkr;
      totalBonus += v.bonusIncentivePkr;
      totalAbsenteeDed += v.absenteeDeductionPkr;
      totalAdvanceDed += v.advanceSalaryDeductionPkr;
      totalNet += v.netPayableSalaryPkr;
    }

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
                        'STAFF PAYROLL & WAGE DISBURSEMENT REGISTER (ماہانہ تنخواہ و کیش رجسٹر)',
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
                        'Period: $monthYear',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.Text(
                        'Printed on: ${DateFormat("dd-MMM-yyyy").format(DateTime.now())}',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // Table
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.6), // #
                    1: const pw.FlexColumnWidth(2.2), // Name
                    2: const pw.FlexColumnWidth(1.4), // Base Salary
                    3: const pw.FlexColumnWidth(1.2), // Present/Absent
                    4: const pw.FlexColumnWidth(1.2), // Overtime PKR
                    5: const pw.FlexColumnWidth(1.1), // Bonus
                    6: const pw.FlexColumnWidth(1.3), // Absent Ded
                    7: const pw.FlexColumnWidth(1.3), // Adv Ded
                    8: const pw.FlexColumnWidth(1.6), // Net Wage
                    9: const pw.FlexColumnWidth(1.0), // Status
                    10: const pw.FlexColumnWidth(1.5), // Sign
                  },
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _thCell('#'),
                        _thCell('Staff Name'),
                        _thCell('Base (PKR)'),
                        _thCell('Att (P/A/H)'),
                        _thCell('OT (PKR)'),
                        _thCell('Bonus'),
                        _thCell('Abs. Ded'),
                        _thCell('Adv. Ded'),
                        _thCell('Net Payable'),
                        _thCell('Status'),
                        _thCell('Signature'),
                      ],
                    ),
                    ...vouchers.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final v = entry.value;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: idx % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                        ),
                        children: [
                          _tbCellCenter('$idx'),
                          _tbCell(v.staffName),
                          _tbCellRight(_currencyFmt.format(v.baseMonthlySalary)),
                          _tbCellCenter('${v.daysPresent}/${v.daysAbsent}/${v.daysHalfDay}'),
                          _tbCellRight(_currencyFmt.format(v.overtimeAllowancePkr)),
                          _tbCellRight(_currencyFmt.format(v.bonusIncentivePkr)),
                          _tbCellRight(_currencyFmt.format(v.absenteeDeductionPkr)),
                          _tbCellRight(_currencyFmt.format(v.advanceSalaryDeductionPkr)),
                          _tbCellRightBold(_currencyFmt.format(v.netPayableSalaryPkr)),
                          _tbCellCenter(v.status.name.toUpperCase()),
                          _tbCell(''),
                        ],
                      );
                    }),
                    // Summary Totals Row
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _tbCellCenter(''),
                        _tbCellBold('TOTALS'),
                        _tbCellRightBold(_currencyFmt.format(totalBase)),
                        _tbCellCenter(''),
                        _tbCellRightBold(_currencyFmt.format(totalOvertime)),
                        _tbCellRightBold(_currencyFmt.format(totalBonus)),
                        _tbCellRightBold(_currencyFmt.format(totalAbsenteeDed)),
                        _tbCellRightBold(_currencyFmt.format(totalAdvanceDed)),
                        _tbCellRightBold(_currencyFmt.format(totalNet)),
                        _tbCellCenter(''),
                        _tbCell(''),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),
              // Footer Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      'Total Staff Count: ${vouchers.length} | Net Cash Required: PKR ${_currencyFmt.format(totalNet)}',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900)),
                  pw.Text('Munshi / Cashier Signature: _______________________',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('Authorized Signature: _______________________',
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

  static pw.Widget _buildPayRow(String label, String value,
      {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color ?? PdfColors.grey800)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color ?? PdfColors.grey900)),
        ],
      ),
    );
  }

  /// Direct print trigger for individual salary slip
  static Future<void> printPaySlip({
    required StaffPayrollVoucher voucher,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdfBytes = await generatePaySlipPdf(
      voucher: voucher,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Salary_Slip_${voucher.staffName.replaceAll(" ", "_")}_${voucher.monthYear.replaceAll(" ", "_")}.pdf',
    );
  }

  /// Direct print trigger for monthly disbursement register
  static Future<void> printDisbursementRegister({
    required List<StaffPayrollVoucher> vouchers,
    required String shopName,
    required String monthYear,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final pdfBytes = await generateDisbursementRegisterPdf(
      vouchers: vouchers,
      shopName: shopName,
      monthYear: monthYear,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Staff_Payroll_Register_${monthYear.replaceAll(" ", "_")}.pdf',
    );
  }
}
