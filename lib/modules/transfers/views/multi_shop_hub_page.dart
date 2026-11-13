import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
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
        title: Text(
          AppStrings.val(
            ctx,
            en: 'Acknowledge Stock Receipt',
            ur: 'اسٹاک وصولی کی تصدیق',
          ),
        ),
        content: Text(
          AppStrings.val(
            ctx,
            en: 'Do you confirm that transfer #${transfer.transferNumber} of ${transfer.commodityName} (${_numberFmt.format(transfer.quantityMaunds)} Maunds) has arrived safely and is added to stock?',
            ur: 'کیا آپ تصدیق کرتے ہیں کہ چالان نمبر ${transfer.transferNumber} کا مال (${transfer.commodityName} - ${_numberFmt.format(transfer.quantityMaunds)} من) بحفاظت پہنچ گیا ہے اور اسٹاک میں جمع کر لیا گیا ہے؟',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.val(ctx, en: 'Cancel', ur: 'منسوخ کریں')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.val(ctx, en: 'Confirm Received', ur: 'ہاں، وصول پایا')),
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
                ? AppStrings.val(context,
                    en: 'Stock receipt acknowledged successfully.',
                    ur: 'چالان کی وصولی کامیابی سے درج کر لی گئی ہے')
                : AppStrings.val(context,
                    en: 'Failed to record receipt.',
                    ur: 'وصولی کے اندراج میں خرابی پیش آگئی')),
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
        title: Text(
          AppStrings.val(
            ctx,
            en: 'Cancel Transfer Consignment',
            ur: 'چالان کی منسوخی',
          ),
        ),
        content: Text(
          AppStrings.val(
            ctx,
            en: 'Are you sure you want to cancel consignment #${transfer.transferNumber}?',
            ur: 'کیا آپ واقعی چالان نمبر ${transfer.transferNumber} کو منسوخ کرنا چاہتے ہیں؟',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.val(ctx, en: 'Back', ur: 'واپس')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.val(ctx, en: 'Cancel Consignment', ur: 'چالان منسوخ کریں')),
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
                ? AppStrings.val(context,
                    en: 'Consignment cancelled successfully.',
                    ur: 'چالان کامیابی سے منسوخ کر دیا گیا')
                : AppStrings.val(context,
                    en: 'Failed to cancel consignment.',
                    ur: 'منسوخی میں خرابی پیش آگئی')),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.val(
                context,
                en: 'Multi-Shop & Stock Transfers',
                ur: 'بین المانڈی مشترکہ گوشوارہ',
              ),
            ),
            Text(
              AppStrings.val(
                context,
                en: 'Consolidated Sheet & Inter-Shop Transfers',
                ur: 'مشترکہ گوشوارہ و اسٹاک منتقلی',
              ),
              style: const TextStyle(fontSize: 11, color: MColors.gold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.val(context, en: 'Refresh', ur: 'ریفریش کریں'),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              multiShopProv.loadTransfers();
              multiShopProv.loadConsolidatedBalanceSheet();
            },
          ),
          if (balanceSheet != null)
            IconButton(
              tooltip: AppStrings.val(
                context,
                en: 'Print Consolidated Sheet',
                ur: 'مشترکہ گوشوارہ پرنٹ کریں',
              ),
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
          tabs: [
            Tab(
              icon: const Icon(Icons.analytics_outlined),
              text: AppStrings.val(
                context,
                en: 'Consolidated Sheet',
                ur: 'مشترکہ گوشوارہ',
              ),
            ),
            Tab(
              icon: const Icon(Icons.local_shipping_outlined),
              text: AppStrings.val(
                context,
                en: 'Inter-Shop Transfers',
                ur: 'اسٹاک منتقلی',
              ),
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
              label: Text(
                AppStrings.val(
                  context,
                  en: 'Dispatch Stock',
                  ur: 'نیا اسٹاک چالان',
                ),
              ),
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
              Text(
                AppStrings.val(
                  context,
                  en: 'Consolidated balance sheet data not available',
                  ur: 'مشترکہ گوشوارہ کا ڈیٹا دستیاب نہیں ہے',
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.val(
                  context,
                  en: 'Please tap refresh or register more branch shops',
                  ur: 'برائے مہربانی ریفریش کا بٹن دبائیں یا مزید برانچز کو رجسٹر کریں',
                ),
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
                label: Text(
                  AppStrings.val(context, en: 'Load Data', ur: 'لوڈ کریں'),
                ),
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
                        '${AppStrings.val(context, en: 'Enterprise Assets & Branch Financial Sheet', ur: 'مجموعی اثاثہ جات اور برانچز کا مالیاتی گوشوارہ')} — ${DateFormat('dd MMMM yyyy').format(sheet.asOfDate)}',
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
                    label: Text(
                      AppStrings.val(context, en: 'Export PDF', ur: 'A4 پرنٹ کریں'),
                    ),
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
                    title: AppStrings.val(
                      context,
                      en: 'Enterprise Equity',
                      ur: 'مجموعی برانچ ایکویٹی',
                    ),
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalNetEnterpriseEquityPkr)}',
                    color: Colors.teal.shade700,
                    icon: Icons.account_balance,
                    isHighlight: true,
                  ),
                  _buildKpiCard(
                    title: AppStrings.val(
                      context,
                      en: 'Total Turnover',
                      ur: 'مجموعی مال بکری',
                    ),
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalEnterpriseSalesPkr)}',
                    color: Colors.blue.shade700,
                    icon: Icons.point_of_sale,
                  ),
                  _buildKpiCard(
                    title: AppStrings.val(
                      context,
                      en: 'Net Commission',
                      ur: 'خالص کمیشن آمدن',
                    ),
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalEnterpriseCommissionPkr)}',
                    color: Colors.green.shade700,
                    icon: Icons.monetization_on_outlined,
                  ),
                  _buildKpiCard(
                    title: AppStrings.val(
                      context,
                      en: 'Receivables',
                      ur: 'واجب الوصول گاہک',
                    ),
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalEnterpriseReceivablesPkr)}',
                    color: Colors.orange.shade800,
                    icon: Icons.call_received,
                  ),
                  _buildKpiCard(
                    title: AppStrings.val(
                      context,
                      en: 'Payables',
                      ur: 'واجب الادا زمیندار',
                    ),
                    value:
                        'Rs. ${_currencyFmt.format(sheet.totalEnterprisePayablesPkr)}',
                    color: Colors.red.shade700,
                    icon: Icons.call_made,
                  ),
                  _buildKpiCard(
                    title: AppStrings.val(
                      context,
                      en: 'Stock Assets',
                      ur: 'موجود گودام مالیت',
                    ),
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
                  Text(
                    AppStrings.val(
                      context,
                      en: 'Branch Financial Breakdown',
                      ur: 'برانچ وار مالیاتی موازنہ و تفصیلات',
                    ),
                    style: const TextStyle(
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
                      AppStrings.val(
                        context,
                        en: '${sheet.branches.length} Branches',
                        ur: '${sheet.branches.length} برانچز',
                      ),
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
                  columns: [
                    DataColumn(
                        label: Text(
                            AppStrings.val(context, en: 'Branch / City', ur: 'برانچ یا شہر'),
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text(
                            AppStrings.val(context, en: 'Sales', ur: 'سیلز'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text(
                            AppStrings.val(context, en: 'Commission', ur: 'کمیشن'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text(
                            AppStrings.val(context, en: 'Expenses', ur: 'اخراجات'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text(
                            AppStrings.val(context, en: 'Profit', ur: 'خالص منافع'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text(
                            AppStrings.val(context, en: 'Receivables', ur: 'بقایا گاہک'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text(
                            AppStrings.val(context, en: 'Payables', ur: 'بقایا زمیندار'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text(
                            AppStrings.val(context, en: 'Stock', ur: 'اسٹاک مالیت'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        numeric: true),
                    DataColumn(
                        label: Text(
                            AppStrings.val(context, en: 'Equity', ur: 'خالص ایکویٹی'),
                            style: const TextStyle(
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
                        DataCell(Text(
                            AppStrings.val(context, en: 'Enterprise Total', ur: 'مجموعہ'),
                            style: const TextStyle(fontWeight: FontWeight.bold))),
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
                    hintText: AppStrings.val(
                      context,
                      en: 'Search (transfer #, commodity, vehicle, or shop)...',
                      ur: 'تلاش کریں (چالان نمبر، جنس، گاڑی، یا دکان)...',
                    ),
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
                    label: Text(AppStrings.val(context, en: 'All', ur: 'تمام')),
                    selected: multiShopProv.statusFilter == null,
                    onSelected: (_) => multiShopProv.setStatusFilter(null),
                  ),
                  ChoiceChip(
                    label: Text(AppStrings.val(context, en: 'In Transit', ur: 'راستے میں')),
                    selected: multiShopProv.statusFilter ==
                        StockTransferStatus.inTransit,
                    onSelected: (_) => multiShopProv
                        .setStatusFilter(StockTransferStatus.inTransit),
                  ),
                  ChoiceChip(
                    label: Text(AppStrings.val(context, en: 'Received', ur: 'موصول شدہ')),
                    selected: multiShopProv.statusFilter ==
                        StockTransferStatus.received,
                    onSelected: (_) => multiShopProv
                        .setStatusFilter(StockTransferStatus.received),
                  ),
                  ChoiceChip(
                    label: Text(AppStrings.val(context, en: 'Cancelled', ur: 'منسوخ')),
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'No stock transfer consignments found.',
                              ur: 'کوئی اسٹاک منتقلی چالان نہیں ملا',
                            ),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Tap the button below to issue a new stock dispatch challan.',
                              ur: 'نیا چالان جاری کرنے کے لیے نیچے دیے گئے بٹن پر کلک کریں',
                            ),
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
                    AppStrings.val(
                      context,
                      en: t.status.labelEnglish,
                      ur: t.status.labelUrdu,
                    ),
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
                      Text(
                        AppStrings.val(context, en: 'Source Shop', ur: 'روانہ کنندہ دکان'),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
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
                      Text(
                        AppStrings.val(context, en: 'Destination Branch', ur: 'منزل برانچ'),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
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
                        '${_numberFmt.format(t.quantityMaunds)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: MColors.primary,
                        ),
                      ),
                      Text(
                        'Rs. ${_currencyFmt.format(t.totalDeliveredCostPkr)} ${AppStrings.val(context, en: 'Total Cost', ur: 'کل لاگت')}',
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
                    '${AppStrings.val(context, en: 'Vehicle', ur: 'گاڑی')}: ${t.vehicleNumber.isNotEmpty ? t.vehicleNumber : "-"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${AppStrings.val(context, en: 'Driver', ur: 'ڈرائیور')}: ${t.driverName.isNotEmpty ? t.driverName : "-"} ${t.driverPhone.isNotEmpty ? "(${t.driverPhone})" : ""}',
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
                  label: Text(AppStrings.val(context, en: 'Gate Pass', ur: 'گیٹ پاس')),
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
                    label: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں')),
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
                    label: Text(AppStrings.val(context, en: 'Receive', ur: 'وصول پایا')),
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
