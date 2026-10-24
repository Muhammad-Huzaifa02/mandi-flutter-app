import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/excel_export_service.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/expense_model.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/expenses/providers/expense_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';

enum ReportPeriod { allTime, today, thisWeek, thisMonth, custom }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ReportPeriod _selectedPeriod = ReportPeriod.allTime;
  DateTimeRange? _customRange;

  String get _periodLabel {
    switch (_selectedPeriod) {
      case ReportPeriod.allTime:
        return 'All Time';
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.custom:
        if (_customRange != null) {
          return '${_customRange!.start.day}/${_customRange!.start.month} - ${_customRange!.end.day}/${_customRange!.end.month}';
        }
        return 'Custom';
    }
  }

  bool _isInPeriod(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case ReportPeriod.allTime:
        return true;
      case ReportPeriod.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case ReportPeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return date.isAfter(start.subtract(const Duration(seconds: 1)));
      case ReportPeriod.thisMonth:
        return date.year == now.year && date.month == now.month;
      case ReportPeriod.custom:
        if (_customRange == null) return true;
        final start = DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day);
        final end = DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(end.add(const Duration(seconds: 1)));
    }
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = ReportPeriod.custom;
        _customRange = picked;
      });
    }
  }

  Future<void> _exportPdfReport({
    required List<Invoice> filteredInvoices,
    required List<Expense> filteredExpenses,
    required double totalSalesSubtotal,
    required double totalCommission,
    required double expensesSum,
    required double netProfit,
    required double totalReceivables,
    required double totalPayables,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MANDI FINANCIAL REPORT',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Period: $_periodLabel',
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Executive Financial Summary',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Sales Volume: Rs. ${totalSalesSubtotal.toStringAsFixed(0)}'),
                      pw.Text('Commission Earned: Rs. ${totalCommission.toStringAsFixed(0)}'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Shop Expenses: Rs. ${expensesSum.toStringAsFixed(0)}'),
                      pw.Text('Net Mandi Profit: Rs. ${netProfit.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Customer Receivables: Rs. ${totalReceivables.toStringAsFixed(0)}'),
                      pw.Text('Supplier Payables: Rs. ${totalPayables.toStringAsFixed(0)}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Invoices Breakdown (${filteredInvoices.length} Invoices)',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Invoice #', 'Customer', 'Subtotal', 'Commission', 'Total', 'Status'],
              data: filteredInvoices
                  .map((inv) => [
                        inv.invoiceNumber,
                        inv.customerName.isNotEmpty ? inv.customerName : 'Walk-in',
                        'Rs. ${inv.subtotal.toStringAsFixed(0)}',
                        'Rs. ${inv.commission.toStringAsFixed(0)}',
                        'Rs. ${inv.total.toStringAsFixed(0)}',
                        inv.status.toUpperCase(),
                      ])
                  .toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Mandi_Report_$_periodLabel.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final allInvoices = context.watch<InvoiceProvider>().invoices;
    final allExpenses = context.watch<ExpenseProvider>().expenses;
    final customers = context.watch<CustomerProvider>().customers;
    final suppliers = context.watch<SupplierProvider>().suppliers;

    final filteredInvoices =
        allInvoices.where((i) => _isInPeriod(i.createdAt)).toList();
    final filteredExpenses =
        allExpenses.where((e) => _isInPeriod(e.createdAt)).toList();

    final totalSalesSubtotal =
        filteredInvoices.fold(0.0, (sum, i) => sum + i.subtotal);
    final totalCommission =
        filteredInvoices.fold(0.0, (sum, i) => sum + i.commission);
    final expensesSum =
        filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalRevenue = totalSalesSubtotal + totalCommission;
    final netProfit = totalCommission - expensesSum;

    final totalReceivables = customers.fold(
        0.0, (sum, c) => sum + (c.runningBalance > 0 ? c.runningBalance : 0));
    final totalPayables = suppliers.fold(
        0.0, (sum, s) => sum + (s.runningBalance > 0 ? s.runningBalance : 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Report',
            onSelected: (val) {
              if (val == 'excel') {
                ExcelExportService.exportFinancialSummary(
                  periodName: _periodLabel,
                  totalSalesSubtotal: totalSalesSubtotal,
                  totalCommission: totalCommission,
                  totalExpenses: expensesSum,
                  netProfit: netProfit,
                  totalReceivables: totalReceivables,
                  totalPayables: totalPayables,
                  invoices: filteredInvoices,
                  expenses: filteredExpenses,
                );
              } else if (val == 'pdf') {
                _exportPdfReport(
                  filteredInvoices: filteredInvoices,
                  filteredExpenses: filteredExpenses,
                  totalSalesSubtotal: totalSalesSubtotal,
                  totalCommission: totalCommission,
                  expensesSum: expensesSum,
                  netProfit: netProfit,
                  totalReceivables: totalReceivables,
                  totalPayables: totalPayables,
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, color: Colors.green),
                    SizedBox(width: MSpacing.xs),
                    Text('Export to Excel (.xlsx)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent),
                    SizedBox(width: MSpacing.xs),
                    Text('Export to PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Filter Choice Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Time'),
                    selected: _selectedPeriod == ReportPeriod.allTime,
                    onSelected: (s) {
                      if (s) setState(() => _selectedPeriod = ReportPeriod.allTime);
                    },
                  ),
                  const SizedBox(width: MSpacing.xs),
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: _selectedPeriod == ReportPeriod.today,
                    onSelected: (s) {
                      if (s) setState(() => _selectedPeriod = ReportPeriod.today);
                    },
                  ),
                  const SizedBox(width: MSpacing.xs),
                  ChoiceChip(
                    label: const Text('This Week'),
                    selected: _selectedPeriod == ReportPeriod.thisWeek,
                    onSelected: (s) {
                      if (s) setState(() => _selectedPeriod = ReportPeriod.thisWeek);
                    },
                  ),
                  const SizedBox(width: MSpacing.xs),
                  ChoiceChip(
                    label: const Text('This Month'),
                    selected: _selectedPeriod == ReportPeriod.thisMonth,
                    onSelected: (s) {
                      if (s) setState(() => _selectedPeriod = ReportPeriod.thisMonth);
                    },
                  ),
                  const SizedBox(width: MSpacing.xs),
                  ChoiceChip(
                    label: Text(_selectedPeriod == ReportPeriod.custom
                        ? _periodLabel
                        : 'Custom Range'),
                    selected: _selectedPeriod == ReportPeriod.custom,
                    onSelected: (s) => _pickCustomDateRange(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Net Mandi Profit & Loss Summary GlassCard
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(MSpacing.lg),
              backgroundColor: MColors.primary.withValues(alpha: 0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Mandi Profit (Commission - Expenses)',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: MColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _periodLabel,
                          style: const TextStyle(
                              color: MColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${netProfit.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: MSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatColumn(
                        label: 'Commission Earned',
                        value: 'Rs. ${totalCommission.toStringAsFixed(0)}',
                      ),
                      _StatColumn(
                        label: 'Shop Expenses',
                        value: 'Rs. ${expensesSum.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Financial Analytics Interactive Line Chart
            Text('Financial Trends',
                style: MText.titleLg.copyWith(color: Colors.white)),
            const SizedBox(height: MSpacing.sm),
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sales vs Commission Trend',
                          style: MText.labelMd.copyWith(color: Colors.white)),
                      Row(
                        children: [
                          Container(width: 8, height: 8, color: MColors.gold),
                          const SizedBox(width: 4),
                          const Text('Sales',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(width: 10),
                          Container(width: 8, height: 8, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          const Text('Commission',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: MSpacing.lg),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: filteredInvoices.isEmpty
                                ? const [FlSpot(0, 0), FlSpot(1, 0)]
                                : List.generate(
                                    filteredInvoices.length > 6
                                        ? 6
                                        : filteredInvoices.length,
                                    (i) => FlSpot(i.toDouble(),
                                        filteredInvoices[i].subtotal / 1000),
                                  ),
                            isCurved: true,
                            color: MColors.gold,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                          LineChartBarData(
                            spots: filteredInvoices.isEmpty
                                ? const [FlSpot(0, 0), FlSpot(1, 0)]
                                : List.generate(
                                    filteredInvoices.length > 6
                                        ? 6
                                        : filteredInvoices.length,
                                    (i) => FlSpot(i.toDouble(),
                                        filteredInvoices[i].commission / 1000),
                                  ),
                            isCurved: true,
                            color: Colors.greenAccent,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Mandi Sales & Volume Overview GlassCard
            Text('Sales & Volume Overview',
                style: MText.titleLg.copyWith(color: Colors.white)),
            const SizedBox(height: MSpacing.sm),
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                children: [
                  _ReportRow(
                    label: 'Sales Invoices Count',
                    value: '${filteredInvoices.length}',
                  ),
                  _ReportRow(
                    label: 'Total Products Volume Sold',
                    value: 'Rs. ${totalSalesSubtotal.toStringAsFixed(0)}',
                  ),
                  _ReportRow(
                    label: 'Total Mandi Commission',
                    value: 'Rs. ${totalCommission.toStringAsFixed(0)}',
                  ),
                  _ReportRow(
                    label: 'Total Gross Revenue',
                    value: 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Receivables & Payables Ledger Summary
            Text('Ledger Balance Summary',
                style: MText.titleLg.copyWith(color: Colors.white)),
            const SizedBox(height: MSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(MSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer Receivables',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: MSpacing.xs),
                        Text(
                          'Rs. ${totalReceivables.toStringAsFixed(0)}',
                          style: MText.titleLg.copyWith(color: MColors.danger),
                        ),
                        const SizedBox(height: 2),
                        const Text('Money owed to shop',
                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: MSpacing.md),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(MSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Supplier Payables',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: MSpacing.xs),
                        Text(
                          'Rs. ${totalPayables.toStringAsFixed(0)}',
                          style: MText.titleLg.copyWith(color: Colors.greenAccent),
                        ),
                        const SizedBox(height: 2),
                        const Text('Money owed by shop',
                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(value,
              style: MText.titleLg.copyWith(fontSize: 15, color: MColors.gold)),
        ],
      ),
    );
  }
}
