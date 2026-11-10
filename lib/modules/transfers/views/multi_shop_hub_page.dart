import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/consolidated_balance_sheet_pdf_generator.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/multi_shop_transfer_model.dart';
import 'package:mandi/modules/transfers/providers/multi_shop_provider.dart';
import 'package:mandi/modules/transfers/views/new_stock_transfer_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Central Hub for Multi-Shop Consolidated Balance Sheet & Inter-Shop Stock Transfers.
class MultiShopHubPage extends StatefulWidget {
  const MultiShopHubPage({super.key});

  @override
  State<MultiShopHubPage> createState() => _MultiShopHubPageState();
}

class _MultiShopHubPageState extends State<MultiShopHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _numberFmt = NumberFormat('#,##0.00', 'en_US');
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final multiShopProv = context.read<MultiShopProvider>();
      multiShopProv.loadTransfers();
      multiShopProv.loadConsolidatedBalanceSheet();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openNewTransferDialog() {
    showDialog(
      context: context,
      builder: (_) => const NewStockTransferDialog(),
    );
  }

  void _printConsolidatedSheet(
      ConsolidatedBalanceSheet sheet, String groupName, String? phone) {
    ConsolidatedBalanceSheetPdfGenerator.printConsolidatedPdf(
      sheet: sheet,
      groupTitle: groupName,
      contactPhone: phone,
    );
  }

  void _printGatePass(InterShopTransfer transfer) {
    ConsolidatedBalanceSheetPdfGenerator.printTransferGatePassPdf(
      transfer: transfer,
      sendingShopName: transfer.sourceShopName,
      receivingShopName: transfer.destinationShopName,
    );
  }

  Future<void> _confirmAcknowledgeReceipt(InterShopTransfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اسٹاک وصولی کی تصدیق (Acknowledge Receipt)'),
        content: Text(
          'کیا آپ تصدیق کرتے ہیں کہ چالان نمبر ${transfer.transferNumber} کا مال (${transfer.commodityName} - ${_numberFmt.format(transfer.quantityMaunds)} من) بحفاظت پہنچ گیا ہے اور اسٹاک میں جمع کر لیا گیا ہے؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('منسوخ کریں (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ہاں، وصول پایا (Confirm Received)'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prov = context.read<MultiShopProvider>();
      final ok = await prov.acknowledgeReceipt(transfer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'چالان کی وصولی کامیابی سے درج کر لی گئی ہے'
                : 'وصولی کے اندراج میں خرابی پیش آگئی'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmCancelTransfer(InterShopTransfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('چالان کی منسوخی (Cancel Transfer)'),
        content: Text(
          'کیا آپ واقعی چالان نمبر ${transfer.transferNumber} کو منسوخ کرنا چاہتے ہیں؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('واپس (Back)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('منسوخ کریں (Cancel Consignment)'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prov = context.read<MultiShopProvider>();
      final ok = await prov.cancelTransfer(transfer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'چالان کامیابی سے منسوخ کر دیا گیا'
                : 'منسوخی میں خرابی پیش آگئی'),
            backgroundColor: ok ? Colors.grey.shade800 : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shop = shopCtx.currentShop;
    final enterpriseTitle =
        shop != null ? '${shop.name} Group of Shops' : 'Mandi Enterprise';
    final multiShopProv = context.watch<MultiShopProvider>();
    final balanceSheet = multiShopProv.balanceSheet;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Multi-Shop & Stock Transfers'),
            Text(
              'بین المانڈی مشترکہ گوشوارہ و اسٹاک منتقلی',
              style: TextStyle(fontSize: 11, color: MColors.gold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ریفریش (Refresh)',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              multiShopProv.loadTransfers();
              multiShopProv.loadConsolidatedBalanceSheet();
            },
          ),
          if (balanceSheet != null)
            IconButton(
              tooltip: 'مشترکہ گوشوارہ پرنٹ کریں (Print Consolidated Sheet)',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _printConsolidatedSheet(
                balanceSheet,
                enterpriseTitle,
                shop?.phone,
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MColors.primary,
          labelColor: MColors.primary,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics_outlined),
              text: 'مشترکہ گوشوارہ (Consolidated Sheet)',
            ),
            Tab(
              icon: Icon(Icons.local_shipping_outlined),
              text: 'اسٹاک منتقلی (Inter-Shop Transfers)',
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
              onPressed: _openNewTransferDialog,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('نیا اسٹاک چالان (Dispatch Stock)'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Consolidated Balance Sheet
          _buildConsolidatedSheetTab(context, balanceSheet, enterpriseTitle),

          // Tab 2: Inter-Shop Transfers
          _buildTransfersTab(context, multiShopProv),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: CONSOLIDATED BALANCE SHEET
  // =========================================================================

  Widget _buildConsolidatedSheetTab(BuildContext context,
      ConsolidatedBalanceSheet? sheet, String enterpriseTitle) {
    final multiShopProv = context.watch<MultiShopProvider>();
    final shopCtx = context.watch<ShopContextProvider>();

    if (multiShopProv.isLoadingBalanceSheet) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sheet == null || sheet.branches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_outlined,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'مشترکہ گوشوارہ کا ڈیٹا دستیاب نہیں ہے',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'برائے مہربانی ریفریش کا بٹن دبائیں یا مزید برانچز کو رجسٹر کریں',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => multiShopProv.loadConsolidatedBalanceSheet(),
                icon: const Icon(Icons.refresh),
                label: const Text('لوڈ کریں (Load)'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Enterprise Headline Card
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enterpriseTitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MColors.primary,
                        ),
                      ),
                      Text(
                        'مجموعی اثاثہ جات اور برانچز کا مالیاتی گوشوارہ — ${DateFormat('dd MMMM yyyy').format(sheet.asOfDate)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _printConsolidatedSheet(
                      sheet,
                      enterpriseTitle,
                      shopCtx.currentShop?.phone,
                    ),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('A4 پرنٹ کریں (Export PDF)'),
                  ),
                ],
              ),
              const Divider(height: 24),

              // KPI Row
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildKpiCard(
                    title: 'مجموعی برانچ ایکویٹی (Enterprise Equity)',
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalNetEnterpriseEquityPkr)}',
                    color: Colors.teal.shade700,
                    icon: Icons.account_balance,
                    isHighlight: true,
                  ),
                  _buildKpiCard(
                    title: 'مجموعی مال بکری (Total Turnover)',
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalEnterpriseSalesPkr)}',
                    color: Colors.blue.shade700,
                    icon: Icons.point_of_sale,
                  ),
                  _buildKpiCard(
                    title: 'خالص کمیشن آمدن (Net Commission)',
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalEnterpriseCommissionPkr)}',
                    color: Colors.green.shade700,
                    icon: Icons.monetization_on_outlined,
                  ),
                  _buildKpiCard(
                    title: 'واجب الوصول گاہک (Receivables)',
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalEnterpriseReceivablesPkr)}',
                    color: Colors.orange.shade800,
                    icon: Icons.call_received,
                  ),
                  _buildKpiCard(
                    title: 'واجب الادا زمیندار (Payables)',
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalEnterprisePayablesPkr)}',
                    color: Colors.red.shade700,
                    icon: Icons.call_made,
                  ),
                  _buildKpiCard(
                    title: 'موجود گودام مالیت (Stock Assets)',
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalEnterpriseStockValuePkr)}',
                    color: Colors.purple.shade700,
                    icon: Icons.warehouse_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Branch Breakdown Table
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      color: MColors.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'برانچ وار مالیاتی موازنہ و تفصیلات (Branch Breakdown)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sheet.branches.length} برانچز',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: MColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                      MColors.primary.withValues(alpha: 0.08)),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  columns: const [
                    DataColumn(
                        label: Text('برانچ / شہر',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('سیلز (Sales)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text('کمیشن (Commission)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text('اخراجات (Expenses)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text('خالص منافع (Profit)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text('بقایا گاہک (Receivables)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text('بقایا زمیندار (Payables)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text('اسٹاک مالیت (Stock)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text('خالص ایکویٹی (Equity)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: MColors.primary)),
                        numeric: true),
                  ],
                  rows: [
                    ...sheet.branches.map((b) {
                      final isCurrent = b.shopId == shopCtx.currentShopId;
                      return DataRow(
                        color: isCurrent
                            ? WidgetStateProperty.all(
                                Colors.amber.withValues(alpha: 0.08))
                            : null,
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                if (isCurrent)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.star,
                                        size: 14, color: Colors.amber),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(b.shopName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(b.city,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text('Rs. ${_currencyFmt.format(b.totalSalesPkr)}')),
                          DataCell(Text('Rs. ${_currencyFmt.format(b.totalCommissionPkr)}',
                              style: const TextStyle(color: Colors.green))),
                          DataCell(Text('Rs. ${_currencyFmt.format(b.totalExpensesPkr)}',
                              style: const TextStyle(color: Colors.red))),
                          DataCell(Text(
                            'Rs. ${_currencyFmt.format(b.netOperatingProfitPkr)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: b.netOperatingProfitPkr >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          )),
                          DataCell(Text(
                              'Rs. ${_currencyFmt.format(b.totalReceivablesPkr)}')),
                          DataCell(Text(
                              'Rs. ${_currencyFmt.format(b.totalPayablesPkr)}')),
                          DataCell(Text(
                              'Rs. ${_currencyFmt.format(b.stockValuePkr)}')),
                          DataCell(
                            Text(
                              'Rs. ${_currencyFmt.format(b.netBranchEquityPkr)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: b.netBranchEquityPkr >= 0
                                    ? Colors.teal.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    // Totals Row
                    DataRow(
                      color: WidgetStateProperty.all(
                          MColors.primary.withValues(alpha: 0.12)),
                      cells: [
                        const DataCell(Text('مجموعہ (Enterprise Total)',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(
                          'Rs. ${_currencyFmt.format(sheet.totalEnterpriseSalesPkr)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          'Rs. ${_currencyFmt.format(sheet.totalEnterpriseCommissionPkr)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        )),
                        DataCell(Text(
                          'Rs. ${_currencyFmt.format(sheet.totalEnterpriseExpensesPkr)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red),
                        )),
                        DataCell(Text(
                          'Rs. ${_currencyFmt.format(sheet.totalEnterpriseOperatingProfitPkr)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sheet.totalEnterpriseOperatingProfitPkr >= 0
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        )),
                        DataCell(Text(
                          'Rs. ${_currencyFmt.format(sheet.totalEnterpriseReceivablesPkr)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          'Rs. ${_currencyFmt.format(sheet.totalEnterprisePayablesPkr)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          'Rs. ${_currencyFmt.format(sheet.totalEnterpriseStockValuePkr)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          'Rs. ${_currencyFmt.format(sheet.totalNetEnterpriseEquityPkr)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MColors.primary,
                            fontSize: 14,
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? color.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight ? color : Colors.grey.shade200,
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: INTER-SHOP TRANSFERS
  // =========================================================================

  Widget _buildTransfersTab(
      BuildContext context, MultiShopProvider multiShopProv) {
    final shopCtx = context.watch<ShopContextProvider>();
    final transfers = multiShopProv.filteredTransfers;

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'تلاش کریں (چالان نمبر، جنس، گاڑی، یا دکان)...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              multiShopProv.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => multiShopProv.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('تمام (All)'),
                    selected: multiShopProv.statusFilter == null,
                    onSelected: (_) => multiShopProv.setStatusFilter(null),
                  ),
                  ChoiceChip(
                    label: const Text('راستے میں (In Transit)'),
                    selected: multiShopProv.statusFilter ==
                        StockTransferStatus.inTransit,
                    onSelected: (_) => multiShopProv
                        .setStatusFilter(StockTransferStatus.inTransit),
                  ),
                  ChoiceChip(
                    label: const Text('موصول شدہ (Received)'),
                    selected: multiShopProv.statusFilter ==
                        StockTransferStatus.received,
                    onSelected: (_) => multiShopProv
                        .setStatusFilter(StockTransferStatus.received),
                  ),
                  ChoiceChip(
                    label: const Text('منسوخ (Cancelled)'),
                    selected: multiShopProv.statusFilter ==
                        StockTransferStatus.cancelled,
                    onSelected: (_) => multiShopProv
                        .setStatusFilter(StockTransferStatus.cancelled),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: multiShopProv.isLoadingTransfers
              ? const Center(child: CircularProgressIndicator())
              : transfers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'کوئی اسٹاک منتقلی چالان نہیں ملا',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'نیا چالان جاری کرنے کے لیے نیچے دیے گئے بٹن پر کلک کریں',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: transfers.length,
                      itemBuilder: (context, index) {
                        final t = transfers[index];
                        return _buildTransferCard(context, t, shopCtx);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTransferCard(
      BuildContext context, InterShopTransfer t, ShopContextProvider shopCtx) {
    final isSource = t.sourceShopId == shopCtx.currentShopId;
    final isDest = t.destinationShopId == shopCtx.currentShopId;

    Color statusColor;
    switch (t.status) {
      case StockTransferStatus.inTransit:
        statusColor = Colors.orange.shade800;
        break;
      case StockTransferStatus.received:
        statusColor = Colors.green.shade700;
        break;
      case StockTransferStatus.cancelled:
        statusColor = Colors.red.shade700;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.transferNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: MColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(t.dispatchedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${t.status.labelUrdu} (${t.status.labelEnglish})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Route: Source -> Destination
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('روانہ کنندہ دکان (Source)',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                      Text(
                        t.sourceShopName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSource ? MColors.primary : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('منزل برانچ (Destination)',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                      Text(
                        t.destinationShopName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDest ? MColors.primary : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Commodity & Weights
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.commodityName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${t.packageCount} ${t.packageType} | ${_numberFmt.format(t.quantityKg)} KG',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_numberFmt.format(t.quantityMaunds)} من (Maunds)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: MColors.primary,
                        ),
                      ),
                      Text(
                        'Rs. ${_currencyFmt.format(t.totalDeliveredCostPkr)} کل لاگت',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Vehicle & Driver Details
            if (t.vehicleNumber.isNotEmpty || t.driverName.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.local_shipping,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'گاڑی: ${t.vehicleNumber.isNotEmpty ? t.vehicleNumber : "-"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'ڈرائیور: ${t.driverName.isNotEmpty ? t.driverName : "-"} ${t.driverPhone.isNotEmpty ? "(${t.driverPhone})" : ""}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Print Gate Pass
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _printGatePass(t),
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: const Text('گیٹ پاس (Gate Pass)'),
                ),
                const SizedBox(width: 8),

                // Cancel button (only if in-transit and isSource or admin)
                if (t.status == StockTransferStatus.inTransit) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    onPressed: () => _confirmCancelTransfer(t),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('منسوخ (Cancel)'),
                  ),
                  const SizedBox(width: 8),

                  // Acknowledge Receipt
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _confirmAcknowledgeReceipt(t),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('وصول پایا (Receive)'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
