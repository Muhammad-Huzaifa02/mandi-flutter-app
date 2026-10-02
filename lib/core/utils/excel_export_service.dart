import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/models/expense_model.dart';
import 'package:mandi/data/models/invoice_model.dart';

/// Excel Report Export service using the `excel` package.
class ExcelExportService {
  /// Exports Sales Invoices list to an Excel (.xlsx) file and triggers native share.
  static Future<void> exportInvoices(List<Invoice> invoices) async {
    final excel = Excel.createExcel();
    final sheet = excel['Invoices Report'];

    sheet.appendRow([
      TextCellValue('Invoice #'),
      TextCellValue('Customer'),
      TextCellValue('Date'),
      TextCellValue('Subtotal (PKR)'),
      TextCellValue('Commission (PKR)'),
      TextCellValue('Total (PKR)'),
      TextCellValue('Received (PKR)'),
      TextCellValue('Pending (PKR)'),
      TextCellValue('Status'),
    ]);

    for (final inv in invoices) {
      final dateStr = inv.createdAt != null
          ? '${inv.createdAt!.day}/${inv.createdAt!.month}/${inv.createdAt!.year}'
          : '';
      sheet.appendRow([
        TextCellValue(inv.invoiceNumber),
        TextCellValue(inv.customerName.isNotEmpty ? inv.customerName : 'Walk-in Customer'),
        TextCellValue(dateStr),
        DoubleCellValue(inv.subtotal),
        DoubleCellValue(inv.commission),
        DoubleCellValue(inv.total),
        DoubleCellValue(inv.receivedAmount),
        DoubleCellValue(inv.pendingAmount),
        TextCellValue(inv.status.toUpperCase()),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await _saveAndShareExcel(bytes, 'Invoices_Report.xlsx');
    }
  }

  /// Exports Expenses list to an Excel (.xlsx) file.
  static Future<void> exportExpenses(List<Expense> expenses) async {
    final excel = Excel.createExcel();
    final sheet = excel['Expenses Report'];

    sheet.appendRow([
      TextCellValue('Category'),
      TextCellValue('Amount (PKR)'),
      TextCellValue('Reference'),
      TextCellValue('Date'),
      TextCellValue('Notes'),
    ]);

    for (final e in expenses) {
      final dateStr = e.createdAt != null
          ? '${e.createdAt!.day}/${e.createdAt!.month}/${e.createdAt!.year}'
          : '';
      sheet.appendRow([
        TextCellValue(e.category.displayName),
        DoubleCellValue(e.amount),
        TextCellValue(e.reference),
        TextCellValue(dateStr),
        TextCellValue(e.note),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await _saveAndShareExcel(bytes, 'Expenses_Report.xlsx');
    }
  }

  /// Exports Customer Ledgers to an Excel (.xlsx) file.
  static Future<void> exportCustomers(List<Customer> customers) async {
    final excel = Excel.createExcel();
    final sheet = excel['Customer Ledgers'];

    sheet.appendRow([
      TextCellValue('Customer Name'),
      TextCellValue('Phone'),
      TextCellValue('City'),
      TextCellValue('Opening Balance (PKR)'),
      TextCellValue('Running Balance (PKR)'),
    ]);

    for (final c in customers) {
      sheet.appendRow([
        TextCellValue(c.name),
        TextCellValue(c.phone),
        TextCellValue(c.city),
        DoubleCellValue(c.openingBalance),
        DoubleCellValue(c.runningBalance),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await _saveAndShareExcel(bytes, 'Customers_Ledger_Report.xlsx');
    }
  }

  static Future<void> _saveAndShareExcel(
      List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Mandi Excel Report - $fileName',
    );
  }
}
