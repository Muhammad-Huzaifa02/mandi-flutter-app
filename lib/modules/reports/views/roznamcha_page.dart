import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/roznamcha_calculator.dart';
import 'package:mandi/core/utils/roznamcha_pdf_generator.dart';
import 'package:mandi/data/models/roznamcha_entry_model.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/payments/providers/payment_provider.dart';
import 'package:mandi/modules/purchase_orders/providers/purchase_order_provider.dart';
import 'package:mandi/modules/expenses/providers/expense_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Full interactive daily cash book register (روزنامچہ / Roznamcha).
/// Reconciles daily opening cash, sales cash inflows, khata recoveries,
/// supplier cash payouts, procurement payments, and operating expenses.
class RoznamchaPage extends StatefulWidget {
  const RoznamchaPage({super.key});

  @override
  State<RoznamchaPage> createState() => _RoznamchaPageState();
}

class _RoznamchaPageState extends State<RoznamchaPage> {
  DateTime _selectedDate = DateTime.now();
  double _openingCash = 0.0;
  bool _isLoadingOpening = true;
  int _selectedFilterIndex = 0; // 0: All, 1: Cash In, 2: Cash Out

  @override
  void initState() {
    super.initState();
    _loadOpeningBalance();
  }

  String get _prefsKey {
    final shopId = context.read<ShopContextProvider>().currentShopId ?? 'default';
    final dateStr =
        '${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}';
    return 'roznamcha_opening_${shopId}_$dateStr';
  }

  Future<void> _loadOpeningBalance() async {
    setState(() => _isLoadingOpening = true);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefsKey) ?? 0.0;
    if (mounted) {
      setState(() {
        _openingCash = saved;
        _isLoadingOpening = false;
      });
    }
  }

  Future<void> _updateOpeningBalance(double newBalance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, newBalance);
    if (mounted) {
      setState(() => _openingCash = newBalance);
    }
  }

  void _showEditOpeningDialog() {
    final controller =
        TextEditingController(text: _openingCash.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: MColors.gold),
            SizedBox(width: MSpacing.xs),
            Text('Opening Cash in Hand'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the physical cash available in the cash drawer (گلہ) at the start of this day:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: MSpacing.md),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Opening Cash (Rs.) *',
                prefixText: 'Rs. ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim()) ?? 0.0;
              _updateOpeningBalance(val);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Opening cash updated to Rs. ${val.toStringAsFixed(0)}'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadOpeningBalance();
    }
  }

  void _changeDateByDays(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
    _loadOpeningBalance();
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shop = shopCtx.currentShop;
    final invoiceProv = context.watch<InvoiceProvider>();
    final paymentProv = context.watch<PaymentProvider>();
    final poProv = context.watch<PurchaseOrderProvider>();
    final expenseProv = context.watch<ExpenseProvider>();

    final report = RoznamchaCalculator.computeDailyRoznamcha(
      targetDate: _selectedDate,
      openingBalance: _openingCash,
      invoices: invoiceProv.invoices,
      payments: paymentProv.payments,
      purchaseOrders: poProv.purchaseOrders,
      expenses: expenseProv.expenses,
    );

    List<RoznamchaEntry> filteredEntries;
    if (_selectedFilterIndex == 1) {
      filteredEntries = report.cashInEntries;
    } else if (_selectedFilterIndex == 2) {
      filteredEntries = report.cashOutEntries;
    } else {
      filteredEntries = report.entries;
    }

    final dateDisplayStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Cash Book'),
            Text(
              'روزنامچہ نقد و گلہ',
              style: TextStyle(fontSize: 11, color: MColors.gold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Daily Roznamcha (PDF)',
            onPressed: () {
              RoznamchaPdfGenerator.printOrShareRoznamcha(
                report: report,
                shopName: shop?.name ?? 'Mandi Commission Shop',
                shopPhone: shop?.phone,
                shopCity: shop?.city,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Navigator Banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MSpacing.md,
              vertical: MSpacing.xs,
            ),
            color: MColors.surfaceDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Day',
                  onPressed: () => _changeDateByDays(-1),
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: MRadius.sm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MSpacing.sm,
                      vertical: MSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: MColors.gold),
                        const SizedBox(width: MSpacing.xs),
                        Text(
                          dateDisplayStr,
                          style: MText.titleMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_isToday(_selectedDate)) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: MColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: MColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'TODAY',
                              style: MText.caption.copyWith(
                                color: MColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Day',
                  onPressed: () => _changeDateByDays(1),
                ),
              ],
            ),
          ),

          // KPI Cards Carousel
          Padding(
            padding: const EdgeInsets.all(MSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    // Opening Cash
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(MSpacing.sm),
                        onTap: _showEditOpeningDialog,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Opening Cash',
                                  style: MText.caption.copyWith(
                                    color: MColors.textOnDarkSub,
                                  ),
                                ),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: MColors.gold,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isLoadingOpening
                                  ? '...'
                                  : 'Rs. ${report.openingBalance.toStringAsFixed(0)}',
                              style: MText.titleMd.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'ابتدائی نقد رقم',
                              style: MText.caption.copyWith(
                                fontSize: 9,
                                color: MColors.textOnDarkSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: MSpacing.sm),
                    // Closing Cash
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(MSpacing.sm),
                        borderColor: MColors.gold.withValues(alpha: 0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Closing Cash',
                                  style: MText.caption.copyWith(
                                    color: MColors.gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.lock_clock_outlined,
                                  size: 14,
                                  color: MColors.gold,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${report.closingBalance.toStringAsFixed(0)}',
                              style: MText.titleMd.copyWith(
                                fontWeight: FontWeight.bold,
                                color: MColors.gold,
                              ),
                            ),
                            Text(
                              'میزان موجود در گلہ',
                              style: MText.caption.copyWith(
                                fontSize: 9,
                                color: MColors.textOnDarkSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MSpacing.sm),
                Row(
                  children: [
                    // Total Cash In
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(MSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 14,
                                  color: Colors.greenAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cash In (+)',
                                  style: MText.caption.copyWith(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${report.totalCashIn.toStringAsFixed(0)}',
                              style: MText.titleMd.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                            Text(
                              '${report.cashInEntries.length} receipts',
                              style: MText.caption.copyWith(
                                fontSize: 9,
                                color: MColors.textOnDarkSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: MSpacing.sm),
                    // Total Cash Out
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(MSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 14,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cash Out (-)',
                                  style: MText.caption.copyWith(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${report.totalCashOut.toStringAsFixed(0)}',
                              style: MText.titleMd.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            Text(
                              '${report.cashOutEntries.length} disbursements',
                              style: MText.caption.copyWith(
                                fontSize: 9,
                                color: MColors.textOnDarkSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Segment Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MSpacing.md),
            child: Row(
              children: [
                _buildFilterChip(0, 'All (${report.entries.length})'),
                const SizedBox(width: MSpacing.xs),
                _buildFilterChip(
                  1,
                  'Cash In (${report.cashInEntries.length})',
                  activeColor: Colors.greenAccent,
                ),
                const SizedBox(width: MSpacing.xs),
                _buildFilterChip(
                  2,
                  'Cash Out (${report.cashOutEntries.length})',
                  activeColor: Colors.redAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: MSpacing.xs),

          // Itemized Entries List
          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 56,
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: MSpacing.sm),
                        Text(
                          'No cash transactions on $dateDisplayStr',
                          style: MText.bodyMd.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transactions recorded via Invoices, Payments, or Expenses appear here.',
                          style: MText.caption.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(MSpacing.md),
                    itemCount: filteredEntries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: MSpacing.xs),
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      final timeStr =
                          '${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}';

                      return GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MSpacing.md,
                          vertical: MSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  entry.color.withValues(alpha: 0.15),
                              child: Icon(
                                entry.icon,
                                size: 18,
                                color: entry.isCashIn
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: MSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.partyName,
                                          style: MText.bodyMd.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${entry.isCashIn ? '+' : '-'} Rs. ${entry.amount.toStringAsFixed(0)}',
                                        style: MText.bodyMd.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: entry.isCashIn
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${entry.reference} • ${entry.description} • $timeStr',
                                          style: MText.caption.copyWith(
                                            color: MColors.textOnDarkSub,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'Bal: Rs. ${entry.runningBalance.toStringAsFixed(0)}',
                                        style: MText.caption.copyWith(
                                          color: MColors.gold,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, {Color? activeColor}) {
    final isSelected = _selectedFilterIndex == index;
    final color = activeColor ?? MColors.gold;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilterIndex = index),
        borderRadius: MRadius.sm,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : MColors.surfaceDark.withValues(alpha: 0.5),
            borderRadius: MRadius.sm,
            border: Border.all(
              color: isSelected ? color : Colors.white10,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: MText.caption.copyWith(
              color: isSelected ? color : MColors.textOnDarkSub,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
