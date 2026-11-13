import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/roznamcha_calculator.dart';
import 'package:mandi/core/utils/roznamcha_pdf_generator.dart';
import 'package:mandi/data/models/roznamcha_entry_model.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/payments/providers/payment_provider.dart';
import 'package:mandi/modules/purchase_orders/providers/purchase_order_provider.dart';
import 'package:mandi/modules/expenses/providers/expense_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Full interactive daily cash book register (Roznamcha).
/// Reconciles daily opening cash, sales cash inflows, khata recoveries,
/// farmer cash payouts, procurement payments, and operating expenses.
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
    final isUrdu = AppStrings.isUrdu(context);
    final controller =
        TextEditingController(text: _openingCash.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, color: MColors.gold),
            const SizedBox(width: MSpacing.xs),
            Text(isUrdu ? 'ابتدائی نقد رقم' : 'Opening Cash in Hand'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu
                  ? 'اس دن کے آغاز پر گلہ میں موجود نقد رقم درج کریں:'
                  : 'Enter the physical cash available in the cash drawer at the start of this day:',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: MSpacing.md),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: isUrdu ? 'ابتدائی نقد رقم (روپے) *' : 'Opening Cash (Rs.) *',
                prefixText: 'Rs. ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim()) ?? 0.0;
              _updateOpeningBalance(val);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isUrdu
                        ? 'ابتدائی نقد رقم روپے ${val.toStringAsFixed(0)} پر اپ ڈیٹ ہو گئی۔'
                        : 'Opening cash updated to Rs. ${val.toStringAsFixed(0)}',
                  ),
                ),
              );
            },
            child: Text(isUrdu ? 'محفوظ کریں' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _changeDateByDays(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _loadOpeningBalance();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadOpeningBalance();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppStrings.isUrdu(context);
    final shop = context.watch<ShopContextProvider>().currentShop;
    final invoices = context.watch<InvoiceProvider>().invoices;
    final payments = context.watch<PaymentProvider>().payments;
    final purchaseOrders =
        context.watch<PurchaseOrderProvider>().purchaseOrders;
    final expenses = context.watch<ExpenseProvider>().expenses;

    final report = RoznamchaCalculator.computeDailyRoznamcha(
      targetDate: _selectedDate,
      openingBalance: _openingCash,
      invoices: invoices,
      payments: payments,
      purchaseOrders: purchaseOrders,
      expenses: expenses,
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
        title: Text(isUrdu ? 'روزنامچہ کیش بک' : 'Daily Cash Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: isUrdu ? 'روزنامچہ پی ڈی ایف پرنٹ کریں' : 'Print Daily Roznamcha (PDF)',
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: isUrdu ? 'پچھلا دن' : 'Previous Day',
                  onPressed: () => _changeDateByDays(-1),
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: MRadius.sm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MSpacing.sm,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: MColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateDisplayStr,
                          style: MText.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: isUrdu ? 'اگلا دن' : 'Next Day',
                  onPressed: _selectedDate.isBefore(
                    DateTime.now().subtract(const Duration(hours: 1)),
                  )
                      ? () => _changeDateByDays(1)
                      : null,
                ),
              ],
            ),
          ),

          // Daily Financial Balance KPI Cards
          Padding(
            padding: const EdgeInsets.all(MSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    // Opening Cash
                    Expanded(
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: MRadius.sm,
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: InkWell(
                          onTap: _showEditOpeningDialog,
                          borderRadius: MRadius.sm,
                          child: Padding(
                            padding: const EdgeInsets.all(MSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isUrdu ? 'ابتدائی نقد' : 'Opening Cash',
                                      style: MText.caption.copyWith(
                                        color: MColors.textSecondary,
                                        fontWeight: FontWeight.bold,
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
                                      : (isUrdu
                                          ? 'روپے ${report.openingBalance.toStringAsFixed(0)}'
                                          : 'Rs. ${report.openingBalance.toStringAsFixed(0)}'),
                                  style: MText.titleMd.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: MColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: MSpacing.sm),
                    // Closing Cash
                    Expanded(
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: MRadius.sm,
                          side: BorderSide(color: MColors.gold.withValues(alpha: 0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(MSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isUrdu ? 'اختتامی کیش' : 'Closing Cash',
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
                                isUrdu
                                    ? 'روپے ${report.closingBalance.toStringAsFixed(0)}'
                                    : 'Rs. ${report.closingBalance.toStringAsFixed(0)}',
                                style: MText.titleMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: MColors.gold,
                                ),
                              ),
                            ],
                          ),
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
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: MRadius.sm,
                          side: BorderSide(color: Colors.green.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(MSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isUrdu ? 'کیش آمد (+)' : 'Cash In (+)',
                                    style: MText.caption.copyWith(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isUrdu
                                    ? 'روپے ${report.totalCashIn.toStringAsFixed(0)}'
                                    : 'Rs. ${report.totalCashIn.toStringAsFixed(0)}',
                                style: MText.titleMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                isUrdu
                                    ? '${report.cashInEntries.length} وصولیاں'
                                    : '${report.cashInEntries.length} receipts',
                                style: MText.caption.copyWith(
                                  fontSize: 10,
                                  color: MColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: MSpacing.sm),
                    // Total Cash Out
                    Expanded(
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: MRadius.sm,
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(MSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 14,
                                    color: MColors.danger,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isUrdu ? 'کیش اخراج (-)' : 'Cash Out (-)',
                                    style: MText.caption.copyWith(
                                      color: MColors.danger,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isUrdu
                                    ? 'روپے ${report.totalCashOut.toStringAsFixed(0)}'
                                    : 'Rs. ${report.totalCashOut.toStringAsFixed(0)}',
                                style: MText.titleMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: MColors.danger,
                                ),
                              ),
                              Text(
                                isUrdu
                                    ? '${report.cashOutEntries.length} ادائیگیاں'
                                    : '${report.cashOutEntries.length} disbursements',
                                style: MText.caption.copyWith(
                                  fontSize: 10,
                                  color: MColors.textSecondary,
                                ),
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

          // Filter Segment Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MSpacing.md),
            child: Row(
              children: [
                _buildFilterChip(
                  0,
                  isUrdu ? 'تمام (${report.entries.length})' : 'All (${report.entries.length})',
                ),
                const SizedBox(width: MSpacing.xs),
                _buildFilterChip(
                  1,
                  isUrdu ? 'آمد (${report.cashInEntries.length})' : 'Cash In (${report.cashInEntries.length})',
                  activeColor: Colors.green,
                ),
                const SizedBox(width: MSpacing.xs),
                _buildFilterChip(
                  2,
                  isUrdu ? 'اخراج (${report.cashOutEntries.length})' : 'Cash Out (${report.cashOutEntries.length})',
                  activeColor: MColors.danger,
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
                          isUrdu
                              ? '$dateDisplayStr پر کوئی لین دین نہیں'
                              : 'No cash transactions on $dateDisplayStr',
                          style: MText.bodyMd.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUrdu
                              ? 'انوائس، ادائیگیوں یا اخراجات سے درج کیے گئے لین دین یہاں ظاہر ہوں گے۔'
                              : 'Transactions recorded via Invoices, Payments, or Expenses appear here.',
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

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: MRadius.md,
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
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
                                      ? Colors.green
                                      : MColors.danger,
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
                                              color: MColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isUrdu
                                              ? '${entry.isCashIn ? '+' : '-'} روپے ${entry.amount.toStringAsFixed(0)}'
                                              : '${entry.isCashIn ? '+' : '-'} Rs. ${entry.amount.toStringAsFixed(0)}',
                                          style: MText.bodyMd.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: entry.isCashIn
                                                ? Colors.green
                                                : MColors.danger,
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
                                              color: MColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          isUrdu
                                              ? 'میزان: روپے ${entry.runningBalance.toStringAsFixed(0)}'
                                              : 'Bal: Rs. ${entry.runningBalance.toStringAsFixed(0)}',
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
                ? color.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            borderRadius: MRadius.sm,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: MText.caption.copyWith(
              color: isSelected ? color : MColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
