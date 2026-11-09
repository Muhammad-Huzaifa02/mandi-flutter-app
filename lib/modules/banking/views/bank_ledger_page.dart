import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/cheque_register_pdf_generator.dart';
import 'package:mandi/data/models/bank_account_model.dart';
import 'package:mandi/data/models/cheque_model.dart';
import 'package:mandi/modules/banking/providers/bank_provider.dart';
import 'package:mandi/modules/banking/views/add_edit_bank_account_dialog.dart';
import 'package:mandi/modules/banking/views/add_edit_cheque_dialog.dart';
import 'package:mandi/modules/banking/views/update_cheque_status_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Primary Mandi Banking Hub & Cheque Clearance Ledger (بینکاری و چیک رجسٹر).
class BankLedgerPage extends StatefulWidget {
  const BankLedgerPage({super.key});

  @override
  State<BankLedgerPage> createState() => _BankLedgerPageState();
}

class _BankLedgerPageState extends State<BankLedgerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  // Cheque filters
  String _selectedStatusFilter = 'all'; // 'all', 'in_hand', 'due_today', 'deposited', 'cleared', 'bounced'
  ChequeType? _selectedTypeFilter;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(
    String shopName,
    List<Cheque> cheques,
    List<BankAccount> bankAccounts,
  ) async {
    try {
      final pdfBytes = await ChequeRegisterPdfGenerator.generateRegisterPdf(
        shopName: shopName,
        cheques: cheques,
        bankAccounts: bankAccounts,
        filterTitle: _getFilterTitle(),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Cheque_Register_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: MColors.danger,
          ),
        );
      }
    }
  }

  String _getFilterTitle() {
    switch (_selectedStatusFilter) {
      case 'in_hand':
        return 'In-Hand PDCs (پاس موجود چیکس)';
      case 'due_today':
        return 'Due Today PDCs (آج کی تاریخ کے چیکس)';
      case 'deposited':
        return 'Under Bank Clearance (جمع شدہ)';
      case 'cleared':
        return 'Cleared Cheques (کلیئر شدہ)';
      case 'bounced':
        return 'Bounced / Dishonored (باؤنس شدہ)';
      default:
        return 'All Cheques & PDCs (تمام چیکس)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankProv = context.watch<BankProvider>();
    final shopCtx = context.watch<ShopContextProvider>();
    final shopName = shopCtx.currentShop?.name ?? 'Mandi Commission Shop';

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Accounts & Cheques',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'بینکاری اور چیک رجسٹر (PDC Ledger)',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF Report',
            onPressed: () => _exportPdf(
              shopName,
              bankProv.cheques,
              bankProv.bankAccounts,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MColors.primaryLight,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: const Icon(Icons.receipt_long),
              text: 'Cheque Register (${bankProv.cheques.length})',
            ),
            Tab(
              icon: const Icon(Icons.account_balance),
              text: 'Bank Accounts (${bankProv.bankAccounts.length})',
            ),
          ],
        ),
      ),
      body: bankProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChequesTab(bankProv),
                _buildBankAccountsTab(bankProv),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            showDialog(
              context: context,
              builder: (_) => const AddEditChequeDialog(),
            );
          } else {
            showDialog(
              context: context,
              builder: (_) => const AddEditBankAccountDialog(),
            );
          }
        },
        backgroundColor: MColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Record Cheque' : 'Add Bank Account',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Tab 1: Cheques & PDC Register ──────────────────────────────────────────

  Widget _buildChequesTab(BankProvider bankProv) {
    final summary = bankProv.summary;

    // Apply filters
    ChequeStatus? statusToFilter;
    bool onlyDueToday = false;

    switch (_selectedStatusFilter) {
      case 'in_hand':
        statusToFilter = ChequeStatus.inHand;
        break;
      case 'due_today':
        statusToFilter = ChequeStatus.inHand;
        onlyDueToday = true;
        break;
      case 'deposited':
        statusToFilter = ChequeStatus.deposited;
        break;
      case 'cleared':
        statusToFilter = ChequeStatus.cleared;
        break;
      case 'bounced':
        statusToFilter = ChequeStatus.bounced;
        break;
    }

    final filteredCheques = bankProv.filterCheques(
      status: statusToFilter,
      type: _selectedTypeFilter,
      onlyDueToday: onlyDueToday,
      query: _searchQuery,
    );

    return RefreshIndicator(
      onRefresh: () async {
        final shopId = context.read<ShopContextProvider>().currentShopId;
        bankProv.updateShop(shopId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── KPI Summary Cards ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'In-Hand PDCs',
                  subtitle: 'پاس موجود چیکس',
                  amount: summary.inHandAmount,
                  count: summary.inHandCount,
                  color: MColors.gold,
                  onTap: () => setState(() => _selectedStatusFilter = 'in_hand'),
                  isSelected: _selectedStatusFilter == 'in_hand',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Under Clearing',
                  subtitle: 'بینک میں جمع شدہ',
                  amount: summary.depositedAmount,
                  count: summary.depositedCount,
                  color: Colors.blueAccent,
                  onTap: () => setState(() => _selectedStatusFilter = 'deposited'),
                  isSelected: _selectedStatusFilter == 'deposited',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Cleared',
                  subtitle: 'کامیابی سے کلیئر',
                  amount: summary.clearedAmount,
                  count: summary.clearedCount,
                  color: MColors.primaryLight,
                  onTap: () => setState(() => _selectedStatusFilter = 'cleared'),
                  isSelected: _selectedStatusFilter == 'cleared',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Bounced / Alert',
                  subtitle: 'باؤنس شدہ چیکس',
                  amount: summary.bouncedAmount,
                  count: summary.bouncedCount,
                  color: MColors.danger,
                  onTap: () => setState(() => _selectedStatusFilter = 'bounced'),
                  isSelected: _selectedStatusFilter == 'bounced',
                ),
              ),
            ],
          ),

          if (summary.dueTodayCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: MRadius.md,
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm, color: Colors.amber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${summary.dueTodayCount} Cheques due today (Rs. ${_currencyFmt.format(summary.dueTodayAmount)}) - Ready for bank deposit!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedStatusFilter = 'due_today'),
                    child: const Text('View Due'),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Search & Filters Bar ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search Cheque #, Party, Bank...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<ChequeType?>(
                icon: Icon(
                  Icons.swap_horiz,
                  color: _selectedTypeFilter != null
                      ? MColors.primary
                      : null,
                ),
                tooltip: 'Filter Direction (Received/Issued)',
                initialValue: _selectedTypeFilter,
                onSelected: (v) => setState(() => _selectedTypeFilter = v),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('All Cheques (تمام)'),
                  ),
                  const PopupMenuItem(
                    value: ChequeType.received,
                    child: Text('Received (وصولی - خریدار)'),
                  ),
                  const PopupMenuItem(
                    value: ChequeType.issued,
                    child: Text('Issued (ادائیگی - زمیندار)'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All (${bankProv.cheques.length})', 'all'),
                const SizedBox(width: 6),
                _buildFilterChip('In-Hand (${summary.inHandCount})', 'in_hand'),
                const SizedBox(width: 6),
                _buildFilterChip('Due Today (${summary.dueTodayCount})', 'due_today'),
                const SizedBox(width: 6),
                _buildFilterChip('Deposited (${summary.depositedCount})', 'deposited'),
                const SizedBox(width: 6),
                _buildFilterChip('Cleared (${summary.clearedCount})', 'cleared'),
                const SizedBox(width: 6),
                _buildFilterChip('Bounced (${summary.bouncedCount})', 'bounced'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Cheques List ───────────────────────────────────────────────────
          if (filteredCheques.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No cheques found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "+ Record Cheque" below to record incoming or outgoing cheques.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...filteredCheques.map((cheque) => _buildChequeCard(cheque)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String subtitle,
    required double amount,
    required int count,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: MRadius.md,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: MRadius.md,
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Rs. ${_currencyFmt.format(amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: MColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? MColors.primary : null,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatusFilter = value);
        }
      },
    );
  }

  Widget _buildChequeCard(Cheque cheque) {
    Color statusColor;
    Color statusBg;

    switch (cheque.status) {
      case ChequeStatus.inHand:
        statusColor = MColors.gold;
        statusBg = MColors.gold.withValues(alpha: 0.12);
        break;
      case ChequeStatus.deposited:
        statusColor = Colors.blueAccent;
        statusBg = Colors.blueAccent.withValues(alpha: 0.12);
        break;
      case ChequeStatus.cleared:
        statusColor = MColors.primary;
        statusBg = MColors.primary.withValues(alpha: 0.12);
        break;
      case ChequeStatus.bounced:
        statusColor = MColors.danger;
        statusBg = MColors.danger.withValues(alpha: 0.12);
        break;
      case ChequeStatus.returned:
        statusColor = Colors.grey;
        statusBg = Colors.grey.withValues(alpha: 0.12);
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: MRadius.md),
      elevation: 0.5,
      child: InkWell(
        borderRadius: MRadius.md,
        onTap: () => showDialog(
          context: context,
          builder: (_) => UpdateChequeStatusDialog(cheque: cheque),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Type Tag, Cheque #, Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: cheque.type == ChequeType.received
                              ? MColors.primary.withValues(alpha: 0.15)
                              : MColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cheque.typeLabelEnglish,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: cheque.type == ChequeType.received
                                ? MColors.primary
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${cheque.chequeNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cheque.statusLabelEnglish,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Middle Row: Party Name & Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cheque.partyName.isEmpty ? '—' : cheque.partyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        if (cheque.bankName.isNotEmpty)
                          Text(
                            'Bank: ${cheque.bankName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${_currencyFmt.format(cheque.amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: MColors.primary,
                    ),
                  ),
                ],
              ),

              const Divider(height: 18),

              // Bottom Row: Dates & Quick Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_outlined,
                          size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_dateFmt.format(cheque.dueDate)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: cheque.isPdc
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: cheque.isOverdue
                              ? MColors.danger
                              : cheque.isDueToday
                                  ? Colors.amber.shade900
                                  : Colors.grey.shade700,
                        ),
                      ),
                      if (cheque.isPdc) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'PDC',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) =>
                              UpdateChequeStatusDialog(cheque: cheque),
                        ),
                        icon: const Icon(Icons.sync_alt, size: 15),
                        label: const Text(
                          'Update Status',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onSelected: (action) {
                          if (action == 'edit') {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  AddEditChequeDialog(existingCheque: cheque),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit Details'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              if (cheque.status == ChequeStatus.bounced &&
                  cheque.bounceReason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: MColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Reason: ${cheque.bounceReason}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 2: Bank Accounts ───────────────────────────────────────────────────

  Widget _buildBankAccountsTab(BankProvider bankProv) {
    final accounts = bankProv.bankAccounts;
    final totalBalance = bankProv.totalBankBalance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total Liquid Balance Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MColors.primary, MColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: MRadius.lg,
            boxShadow: [
              BoxShadow(
                color: MColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Liquid Bank Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.account_balance, color: Colors.white70, size: 22),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Rs. ${_currencyFmt.format(totalBalance)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'مجموعی بینکاری بیلنس (${accounts.where((a) => a.isActive).length} Active Accounts)',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Configured Bank Accounts (${accounts.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddEditBankAccountDialog(),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Account'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (accounts.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.account_balance_outlined,
                    size: 50, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                const Text(
                  'No bank accounts configured yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add your Mandi shop commercial accounts (Meezan, HBL, MCB, Raast, JazzCash).',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...accounts.map((acc) => _buildBankAccountCard(acc, bankProv)),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBankAccountCard(BankAccount acc, BankProvider bankProv) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: MRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Name & Default Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance,
                      color: MColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      acc.bankName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (acc.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: MColors.primary,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => AddEditBankAccountDialog(
                              existingAccount: acc,
                            ),
                          );
                        } else if (action == 'delete') {
                          _confirmDeleteAccount(acc, bankProv);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Account'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Account',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Account Title
            if (acc.accountTitle.isNotEmpty)
              Text(
                acc.accountTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),

            const SizedBox(height: 6),

            // Account Number & IBAN with Copy
            Row(
              children: [
                Text(
                  'A/C: ${acc.accountNumber}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
                if (acc.accountNumber.isNotEmpty)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: acc.accountNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account number copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.copy, size: 13, color: Colors.grey),
                    ),
                  ),
              ],
            ),

            if (acc.iban.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'IBAN: ${acc.iban}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: acc.iban));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('IBAN copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.copy, size: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 18),

            // Current Balance & Branch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  acc.branchName.isNotEmpty
                      ? 'Branch: ${acc.branchName}'
                      : 'Mandi Account',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                Text(
                  'Rs. ${_currencyFmt.format(acc.currentBalance)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: MColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BankAccount acc, BankProvider bankProv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Bank Account?'),
        content: Text('Are you sure you want to delete ${acc.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              await bankProv.deleteBankAccount(acc.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
