import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/excel_export_service.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/expense_model.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/expenses/providers/expense_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/reports/views/roznamcha_page.dart';
import 'package:mandi/modules/banking/views/bank_ledger_page.dart';
import 'package:mandi/modules/storage/views/storage_and_bardana_page.dart';
import 'package:mandi/modules/weighbridge/views/weighbridge_page.dart';
import 'package:mandi/modules/advances/views/farmer_advance_page.dart';
import 'package:mandi/modules/cross_border/views/cross_border_page.dart';
import 'package:mandi/modules/sms/views/sms_gateway_page.dart';
import 'package:mandi/modules/transfers/views/multi_shop_hub_page.dart';
import 'package:mandi/modules/voice_notes/views/voice_notes_hub_page.dart';
import 'package:mandi/modules/loyalty/views/customer_loyalty_page.dart';
import 'package:mandi/modules/rates/views/mandi_rate_board_page.dart';
import 'package:mandi/modules/payroll/views/staff_payroll_page.dart';
import 'package:mandi/modules/fleet/views/fleet_logistics_page.dart';
import 'package:mandi/modules/quality/views/quality_lab_page.dart';
import 'package:mandi/modules/inventory_labels/views/inventory_labels_page.dart';
import 'package:mandi/modules/offline_sync/views/offline_sync_page.dart';
import 'package:mandi/modules/broadcast/views/broadcast_hub_page.dart';

enum ReportPeriod { allTime, today, thisWeek, thisMonth, custom }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ReportPeriod _selectedPeriod = ReportPeriod.allTime;
  DateTimeRange? _customRange;

  String _getPeriodLabel(bool isUrdu) {
    switch (_selectedPeriod) {
      case ReportPeriod.allTime:
        return isUrdu ? 'مکمل مدت' : 'All Time';
      case ReportPeriod.today:
        return isUrdu ? 'آج' : 'Today';
      case ReportPeriod.thisWeek:
        return isUrdu ? 'اس ہفتے' : 'This Week';
      case ReportPeriod.thisMonth:
        return isUrdu ? 'اس مہینے' : 'This Month';
      case ReportPeriod.custom:
        if (_customRange != null) {
          return '${_customRange!.start.day}/${_customRange!.start.month} - ${_customRange!.end.day}/${_customRange!.end.month}';
        }
        return isUrdu ? 'مخصوص مدت' : 'Custom Range';
    }
  }

  bool _isWithinRange(DateTime date) {
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
        final startZero =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return date.isAfter(startZero);
      case ReportPeriod.thisMonth:
        return date.year == now.year && date.month == now.month;
      case ReportPeriod.custom:
        if (_customRange == null) return true;
        final startZero = DateTime(_customRange!.start.year,
            _customRange!.start.month, _customRange!.start.day);
        final endZero = DateTime(_customRange!.end.year,
            _customRange!.end.month, _customRange!.end.day, 23, 59, 59);
        return date.isAfter(startZero) && date.isBefore(endZero);
    }
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriod = ReportPeriod.custom;
      });
    }
  }

  Future<void> _exportPdfReport({
    required List<Invoice> invoices,
    required List<Expense> expenses,
    required double totalRevenue,
    required double totalSalesSubtotal,
    required double totalCommission,
    required double expensesSum,
    required double netProfit,
    required double totalReceivables,
    required double totalPayables,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Mandi Financial Analytics & Profit/Loss',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Period: ${_getPeriodLabel(false)}',
                    style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('EXECUTIVE SUMMARY',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Products Volume Sold:'),
                    pw.Text('Rs. ${totalSalesSubtotal.toStringAsFixed(0)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Mandi Commission:'),
                    pw.Text('+ Rs. ${totalCommission.toStringAsFixed(0)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Shop Operating Expenses:'),
                    pw.Text('- Rs. ${expensesSum.toStringAsFixed(0)}'),
                  ],
                ),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET MANDI PROFIT:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs. ${netProfit.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Ledger Balance Summary',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Ledger Type', 'Total Balance (PKR)'],
            data: [
              ['Customer Receivables', 'Rs. ${totalReceivables.toStringAsFixed(0)}'],
              ['Farmer Payables', 'Rs. ${totalPayables.toStringAsFixed(0)}'],
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppStrings.isUrdu(context);
    final allInvoices = context.watch<InvoiceProvider>().invoices;
    final allExpenses = context.watch<ExpenseProvider>().expenses;
    final customers = context.watch<CustomerProvider>().customers;
    final suppliers = context.watch<SupplierProvider>().suppliers;

    final filteredInvoices = allInvoices
        .where((inv) =>
            inv.createdAt == null ? true : _isWithinRange(inv.createdAt!))
        .toList();

    final filteredExpenses = allExpenses
        .where((exp) =>
            exp.createdAt == null ? true : _isWithinRange(exp.createdAt!))
        .toList();

    final totalSalesSubtotal =
        filteredInvoices.fold(0.0, (sum, inv) => sum + inv.subtotal);
    final totalCommission =
        filteredInvoices.fold(0.0, (sum, inv) => sum + inv.commission);
    final totalRevenue =
        filteredInvoices.fold(0.0, (sum, inv) => sum + inv.total);
    final expensesSum =
        filteredExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final netProfit = totalCommission - expensesSum;

    final totalReceivables =
        customers.fold(0.0, (sum, c) => sum + (c.runningBalance > 0 ? c.runningBalance : 0));
    final totalPayables =
        suppliers.fold(0.0, (sum, s) => sum + (s.runningBalance > 0 ? s.runningBalance : 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'رپورٹس اور مالیاتی جائزے' : 'Reports & Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share_outlined),
            tooltip: isUrdu ? 'رپورٹ برآمد کریں' : 'Export Report',
            onSelected: (val) {
              if (val == 'excel') {
                ExcelExportService.exportFinancialSummary(
                  periodName: _getPeriodLabel(isUrdu),
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
                  invoices: filteredInvoices,
                  expenses: filteredExpenses,
                  totalRevenue: totalRevenue,
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
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, color: Colors.green),
                    const SizedBox(width: MSpacing.xs),
                    Text(isUrdu ? 'ایکسل رپورٹ ڈاؤنلوڈ کریں' : 'Export to Excel (.xlsx)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent),
                    const SizedBox(width: MSpacing.xs),
                    Text(isUrdu ? 'پی ڈی ایف رپورٹ پرنٹ کریں' : 'Export to PDF'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined, color: MColors.gold),
            tooltip: isUrdu ? 'روزنامچہ کیش بک' : 'Daily Cash Book',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoznamchaPage()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 18 Quick Operational Tiles
            _QuickActionTile(
              icon: Icons.menu_book_outlined,
              accentColor: MColors.gold,
              title: isUrdu ? 'روزنامچہ کیش بک' : 'Daily Cash Book',
              description: isUrdu
                  ? 'صبح کا گلہ، وصولیاں، ادائیگیاں اور اختتامی کیش کا حساب'
                  : 'Reconcile morning cash drawer, receipts, payments & closing balance',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoznamchaPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.account_balance_outlined,
              accentColor: MColors.primary,
              title: isUrdu ? 'بینکاری کھاتے اور چیک' : 'Bank Accounts & Cheques',
              description: isUrdu
                  ? 'پی ڈی سی چیک، کلیئرنس حالت اور بینک بیلنس کا ریکارڈ'
                  : 'Track Post-Dated Cheques (PDC), clearance statuses & bank balances',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BankLedgerPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.warehouse_outlined,
              accentColor: Colors.teal,
              title: isUrdu ? 'گودام اور باردانہ' : 'Godowns & Bardana',
              description: isUrdu
                  ? 'کولڈ اسٹورز، گودام بیجز اور بوریوں کا انتظام'
                  : 'Monitor Cold Stores, warehouse batches & gunny sacks circulation',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StorageAndBardanaPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.scale_rounded,
              accentColor: Colors.amber.shade800,
              title: isUrdu ? 'دھرم کنڈا' : 'Mandi Weighbridge',
              description: isUrdu
                  ? 'گاڑی بھرا و خالی وزن، کٹوتی اور تصدیق شدہ پرچی'
                  : 'Vehicle gross/tare weighment, deductions & certified kanda slips',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeighbridgePage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.agriculture_rounded,
              accentColor: Colors.green.shade700,
              title: isUrdu ? 'زمیندار پیشگی قرض و کھاد بیج' : 'Farmer Advances & Inputs',
              description: isUrdu
                  ? 'پیشگی نقد، کھاد بیج فنانسنگ اور نیلامی سے کٹوتی'
                  : 'Pre-harvest cash, fertilizer/seed financing & auction recovery deductions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FarmerAdvancePage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.public_rounded,
              accentColor: Colors.teal.shade700,
              title: isUrdu ? 'سرحدی تجارت و کسٹم' : 'Cross-Border Mandi Trade',
              description: isUrdu
                  ? 'افغان و ایران مال، غیر ملکی کرنسی کھاتہ اور کسٹم کلیئرنس'
                  : 'Afghan/Iran import cargo, USD/AFN/IRR currency ledger & customs clearance',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrossBorderPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.sms_rounded,
              accentColor: Colors.blue.shade700,
              title: isUrdu ? 'خودکار ایس ایم ایس الرٹس' : 'SMS Gateway & Alerts',
              description: isUrdu
                  ? 'بل، کیش وصولی اور بولی پر خودکار ایس ایم ایس'
                  : 'Automated SMS dispatch on bills, cash receipts & dheri bids',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmsGatewayPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.hub_outlined,
              accentColor: Colors.purple.shade700,
              title: isUrdu ? 'مشترکہ گوشوارہ و اسٹاک منتقلی' : 'Multi-Shop Consolidated Balance Sheet',
              description: isUrdu
                  ? 'تمام برانچز کا مجموعی کھاتہ اور اسٹاک ٹرانسفر چالان'
                  : 'Multi-branch enterprise balance sheet, branch equity & inter-shop stock transfers',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MultiShopHubPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.mic_rounded,
              accentColor: Colors.red.shade700,
              title: isUrdu ? 'منشی صوتی نوٹس اور ڈکٹیشن' : 'Munshi Voice Notes',
              description: isUrdu
                  ? 'آواز کی ریکارڈنگ اور منڈی کھاتہ ڈکٹیشن'
                  : 'Verbal voice recording, Mandi keyword parser & quick khata dictation memos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceNotesHubPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.stars_rounded,
              accentColor: Colors.amber.shade900,
              title: isUrdu ? 'گاہک رعایت اور والیم بونس' : 'Customer Loyalty & Volume Rebates',
              description: isUrdu
                  ? 'سیزنل خرید پر رعایت اور خودکار کریڈٹ واؤچر'
                  : 'Seasonal trading volume targets, rebate tiers, automated credit notes & A4 vouchers',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerLoyaltyPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.trending_up,
              accentColor: Colors.teal.shade800,
              title: isUrdu ? 'روزانہ منڈی ریٹ بورڈ' : 'Daily Mandi Rate Board',
              description: isUrdu
                  ? 'مارکیٹ ریٹس، آمد کی تفصیل اور واٹس ایپ براڈکاسٹ'
                  : 'Market price trends, arrivals volume, WhatsApp broadcast & morning notice prints',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MandiRateBoardPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.badge_outlined,
              accentColor: Colors.indigo.shade700,
              title: isUrdu ? 'عملہ حاضری اور تنخواہ' : 'Staff Attendance & Payroll',
              description: isUrdu
                  ? 'روزانہ حاضری، اوور ٹائم اور تنخواہ سلپ'
                  : 'Daily biometric attendance, overtime hours, advance recoveries & salary slips',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffPayrollPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.local_shipping_rounded,
              accentColor: Colors.teal.shade900,
              title: isUrdu ? 'ٹرانسپورٹ اور گاڑی بلٹی' : 'Fleet Logistics & Bilty',
              description: isUrdu
                  ? 'گاڑی کرایہ کھاتہ، بلٹی اور ڈیزل اخراجات'
                  : 'Vehicle freight ledger, trip bilty printing, diesel expense logs & carrier registers',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FleetLogisticsPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.biotech_rounded,
              accentColor: Colors.green.shade800,
              title: isUrdu ? 'جنس کوالٹی لیب اور کولڈ چین' : 'Quality Lab & Cold Chain',
              description: isUrdu
                  ? 'نمی ٹیسٹ، کٹوتی پرچہ اور درجہ حرارت لاگ'
                  : 'Moisture refraction katoti slips, grain grading certificates & temperature logs',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QualityLabPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.qr_code_2_rounded,
              accentColor: Colors.blue.shade800,
              title: isUrdu ? 'بارکوڈ اور کیو آر لیبلز' : 'Barcode & QR Pallet Tracking',
              description: isUrdu
                  ? 'ڈھیری و اسٹاک بارکوڈ اور گودام روسٹر'
                  : 'Pallet stack placards, Code128 1D barcodes, 2D QR tags & warehouse rosters',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryLabelsPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.sync_problem_rounded,
              accentColor: Colors.orange.shade800,
              title: isUrdu ? 'آف لائن سنک اور آڈٹ' : 'Offline Sync Engine & Audit',
              description: isUrdu
                  ? 'بغیر انٹرنیٹ ڈیٹا محفوظ اور خودکار سنک'
                  : 'Local mutation queues, automatic conflict resolution & offline sync logs',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfflineSyncPage()),
              ),
            ),
            const SizedBox(height: MSpacing.sm),

            _QuickActionTile(
              icon: Icons.campaign_rounded,
              accentColor: Colors.teal.shade600,
              title: isUrdu ? 'ریٹ براڈکاسٹ اور ٹیلی گرام بوٹ' : 'Rate Broadcast & Telegram Bot',
              description: isUrdu
                  ? 'واٹس ایپ اور ٹیلی گرام پر خودکار منڈی ریٹ لسٹ'
                  : 'Automated WhatsApp rate bulletins & Telegram channel broadcaster',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BroadcastHubPage()),
              ),
            ),
            const SizedBox(height: MSpacing.md),

            // Period Filter Choice Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(isUrdu ? 'مکمل مدت' : 'All Time'),
                    selected: _selectedPeriod == ReportPeriod.allTime,
                    onSelected: (s) {
                      if (s) setState(() => _selectedPeriod = ReportPeriod.allTime);
                    },
                  ),
                  const SizedBox(width: MSpacing.xs),
                  ChoiceChip(
                    label: Text(isUrdu ? 'آج' : 'Today'),
                    selected: _selectedPeriod == ReportPeriod.today,
                    onSelected: (s) {
                      if (s) setState(() => _selectedPeriod = ReportPeriod.today);
                    },
                  ),
                  const SizedBox(width: MSpacing.xs),
                  ChoiceChip(
                    label: Text(isUrdu ? 'اس ہفتے' : 'This Week'),
                    selected: _selectedPeriod == ReportPeriod.thisWeek,
                    onSelected: (s) {
                      if (s) setState(() => _selectedPeriod = ReportPeriod.thisWeek);
                    },
                  ),
                  const SizedBox(width: MSpacing.xs),
                  ChoiceChip(
                    label: Text(isUrdu ? 'اس مہینے' : 'This Month'),
                    selected: _selectedPeriod == ReportPeriod.thisMonth,
                    onSelected: (s) {
                      if (s) setState(() => _selectedPeriod = ReportPeriod.thisMonth);
                    },
                  ),
                  const SizedBox(width: MSpacing.xs),
                  ChoiceChip(
                    label: Text(_getPeriodLabel(isUrdu)),
                    selected: _selectedPeriod == ReportPeriod.custom,
                    onSelected: (s) => _pickCustomDateRange(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Net Mandi Profit & Loss Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.primary.withValues(alpha: 0.08),
                borderRadius: MRadius.lg,
                border: Border.all(color: MColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUrdu
                            ? 'خالص منڈی منافع (کمیشن منہا اخراجات)'
                            : 'Net Mandi Profit (Commission - Expenses)',
                        style: MText.bodySm.copyWith(color: MColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: MColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPeriodLabel(isUrdu),
                          style: const TextStyle(
                            color: MColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    isUrdu
                        ? 'روپے ${netProfit.toStringAsFixed(0)}'
                        : 'Rs. ${netProfit.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: netProfit >= 0 ? Colors.green.shade800 : MColors.danger,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: MSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatColumn(
                        label: isUrdu ? 'کل کمیشن آمدن' : 'Commission Earned',
                        value: isUrdu
                            ? 'روپے ${totalCommission.toStringAsFixed(0)}'
                            : 'Rs. ${totalCommission.toStringAsFixed(0)}',
                      ),
                      _StatColumn(
                        label: isUrdu ? 'دکان کے اخراجات' : 'Shop Expenses',
                        value: isUrdu
                            ? 'روپے ${expensesSum.toStringAsFixed(0)}'
                            : 'Rs. ${expensesSum.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Financial Analytics Interactive Line Chart
            Text(
              isUrdu ? 'مالیاتی رجحانات' : 'Financial Trends',
              style: MText.titleLg,
            ),
            const SizedBox(height: MSpacing.sm),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: MRadius.md,
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(MSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isUrdu ? 'فروخت بمقابلہ کمیشن' : 'Sales vs Commission Trend',
                          style: MText.labelMd,
                        ),
                        Row(
                          children: [
                            Container(width: 8, height: 8, color: MColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              isUrdu ? 'سیلز' : 'Sales',
                              style: const TextStyle(color: MColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(width: 10),
                            Container(width: 8, height: 8, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              isUrdu ? 'کمیشن' : 'Commission',
                              style: const TextStyle(color: MColors.textSecondary, fontSize: 11),
                            ),
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
                              color: Colors.green,
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
            ),

            const SizedBox(height: MSpacing.lg),

            // Mandi Sales & Volume Overview Card
            Text(
              isUrdu ? 'فروخت اور والیوم کا جائزہ' : 'Sales & Volume Overview',
              style: MText.titleLg,
            ),
            const SizedBox(height: MSpacing.sm),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: MRadius.md,
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(MSpacing.lg),
                child: Column(
                  children: [
                    _ReportRow(
                      label: isUrdu ? 'سیلز انوائسز کی تعداد' : 'Sales Invoices Count',
                      value: '${filteredInvoices.length}',
                    ),
                    _ReportRow(
                      label: isUrdu ? 'فروخت شدہ مال کا حجم' : 'Total Products Volume Sold',
                      value: isUrdu
                          ? 'روپے ${totalSalesSubtotal.toStringAsFixed(0)}'
                          : 'Rs. ${totalSalesSubtotal.toStringAsFixed(0)}',
                    ),
                    _ReportRow(
                      label: isUrdu ? 'کل منڈی کمیشن' : 'Total Mandi Commission',
                      value: isUrdu
                          ? 'روپے ${totalCommission.toStringAsFixed(0)}'
                          : 'Rs. ${totalCommission.toStringAsFixed(0)}',
                    ),
                    _ReportRow(
                      label: isUrdu ? 'کل مجموعی ریونیو' : 'Total Gross Revenue',
                      value: isUrdu
                          ? 'روپے ${totalRevenue.toStringAsFixed(0)}'
                          : 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Receivables & Payables Ledger Summary
            Text(
              isUrdu ? 'کھاتہ جات کے بقایا جات' : 'Ledger Balance Summary',
              style: MText.titleLg,
            ),
            const SizedBox(height: MSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: MRadius.md,
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(MSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu ? 'گاہکوں سے وصولی' : 'Customer Receivables',
                            style: MText.caption.copyWith(color: MColors.textSecondary),
                          ),
                          const SizedBox(height: MSpacing.xs),
                          Text(
                            isUrdu
                                ? 'روپے ${totalReceivables.toStringAsFixed(0)}'
                                : 'Rs. ${totalReceivables.toStringAsFixed(0)}',
                            style: MText.titleLg.copyWith(color: MColors.danger),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUrdu ? 'دکان کا واجب الوصول' : 'Money owed to shop',
                            style: MText.caption.copyWith(color: MColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MSpacing.md),
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: MRadius.md,
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(MSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu ? 'زمینداروں کی ادائیگی' : 'Farmer Payables',
                            style: MText.caption.copyWith(color: MColors.textSecondary),
                          ),
                          const SizedBox(height: MSpacing.xs),
                          Text(
                            isUrdu
                                ? 'روپے ${totalPayables.toStringAsFixed(0)}'
                                : 'Rs. ${totalPayables.toStringAsFixed(0)}',
                            style: MText.titleLg.copyWith(color: Colors.green.shade700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUrdu ? 'دکان پر واجب الادا' : 'Money owed by shop',
                            style: MText.caption.copyWith(color: MColors.textSecondary),
                          ),
                        ],
                      ),
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

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(MSpacing.md),
      borderColor: accentColor.withValues(alpha: 0.35),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: MSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: MText.bodyMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: MText.caption.copyWith(
                    color: MColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey,
          ),
        ],
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
        Text(label, style: MText.caption.copyWith(color: MColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: MText.titleLg.copyWith(color: MColors.textPrimary)),
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
          Text(label, style: MText.bodyMd.copyWith(color: MColors.textPrimary)),
          Text(value, style: MText.titleLg.copyWith(fontSize: 15, color: MColors.primary)),
        ],
      ),
    );
  }
}
