import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/farmer_advance_pdf_generator.dart';
import 'package:mandi/data/models/farmer_advance_model.dart';
import 'package:mandi/modules/advances/providers/farmer_advance_provider.dart';
import 'package:mandi/modules/advances/views/new_farmer_advance_dialog.dart';
import 'package:mandi/modules/advances/views/record_advance_recovery_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Primary Mandi Pre-Harvest Financing & Input Financed Khata Hub.
class FarmerAdvancePage extends StatefulWidget {
  const FarmerAdvancePage({super.key});

  @override
  State<FarmerAdvancePage> createState() => _FarmerAdvancePageState();
}

class _FarmerAdvancePageState extends State<FarmerAdvancePage> {
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportRegisterPdf(
    String shopName,
    FarmerAdvanceProvider advProv,
  ) async {
    try {
      final Uint8List pdfBytes =
          await FarmerAdvancePdfGenerator.generateAdvancesRegisterPdf(
        shopName: shopName,
        advances: advProv.filteredAdvances,
        summary: advProv.summary,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            'Farmer_Advances_Register_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate register PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printFarmerStatement(
    String shopName,
    FarmerAdvance advance,
  ) async {
    try {
      final Uint8List pdfBytes =
          await FarmerAdvancePdfGenerator.generateFarmerStatementPdf(
        shopName: shopName,
        farmerName: advance.farmerName,
        farmerPhone: advance.farmerPhone,
        advances: [advance],
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Advance_Statement_${advance.farmerName}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print statement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openNewAdvanceDialog() {
    showDialog(
      context: context,
      builder: (_) => const NewFarmerAdvanceDialog(),
    );
  }

  void _openRecoveryDialog(FarmerAdvance advance) {
    showDialog(
      context: context,
      builder: (_) => RecordAdvanceRecoveryDialog(advance: advance),
    );
  }

  @override
  Widget build(BuildContext context) {
    final advProv = context.watch<FarmerAdvanceProvider>();
    final shopContext = context.watch<ShopContextProvider>();
    final shopName = shopContext.currentShop?.name ?? 'Mandi Commission Shop';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.val(
                context,
                en: 'Farmer Advances',
                ur: 'زمیندار پیشگی ایڈوانس',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              AppStrings.val(
                context,
                en: 'Pre-harvest financing & input ledger',
                ur: 'پیشگی قرضہ و زرعی کھاتہ',
              ),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: AppStrings.val(context, en: 'Export Register', ur: 'رجسٹر پرنٹ کریں'),
            onPressed: () => _exportRegisterPdf(shopName, advProv),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.val(context, en: 'Refresh', ur: 'ریفریش کریں'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppStrings.val(
                      context,
                      en: 'Advances data synced in real-time',
                      ur: 'ایڈوانس ڈیٹا سنک ہو گیا',
                    ),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewAdvanceDialog,
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: Text(
          AppStrings.val(
            context,
            en: 'Disburse Advance',
            ur: 'نیا ایڈوانس دیں',
          ),
        ),
      ),
      body: advProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── KPI Summary Cards ──────────────────────────────────────────
                  _buildKpiSection(advProv.summary),

                  const SizedBox(height: 16),

                  // ── Search & Filter Chips ──────────────────────────────────────
                  _buildSearchAndFilters(advProv),

                  const SizedBox(height: 14),

                  // ── Advances List ──────────────────────────────────────────────
                  if (advProv.filteredAdvances.isEmpty)
                    _buildEmptyState(advProv)
                  else
                    ...advProv.filteredAdvances.map(
                      (a) => _buildAdvanceCard(a, shopName),
                    ),

                  const SizedBox(height: 80), // Fab space
                ],
              ),
            ),
    );
  }

  // ── KPI Summary ────────────────────────────────────────────────────────────
  Widget _buildKpiSection(FarmerAdvanceSummary s) {
    return Row(
      children: [
        _buildStatCard(
          label: AppStrings.val(context, en: 'Active Loans', ur: 'فعال قرضہ جات'),
          value: '${s.activeCount}',
          subtitle: AppStrings.val(context, en: 'Farmers financing', ur: 'کسان فنانسنگ'),
          icon: Icons.people_outline,
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          label: AppStrings.val(context, en: 'Disbursed', ur: 'کل ایڈوانس'),
          value: 'Rs. ${_currencyFmt.format(s.totalPrincipalDisbursed)}',
          subtitle: AppStrings.val(context, en: 'Cash + Inputs', ur: 'نقد و کھاد بیج'),
          icon: Icons.outbox_rounded,
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          label: AppStrings.val(context, en: 'Recovered', ur: 'وصول شدہ'),
          value: 'Rs. ${_currencyFmt.format(s.totalRecovered)}',
          subtitle: AppStrings.val(context, en: 'From crop auctions', ur: 'فصل نیلامی سے'),
          icon: Icons.move_to_inbox_rounded,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          label: AppStrings.val(context, en: 'Net Balance', ur: 'بقایا قرضہ'),
          value: 'Rs. ${_currencyFmt.format(s.netOutstandingBalance)}',
          subtitle: s.overdueCount > 0
              ? '${s.overdueCount} ${AppStrings.val(context, en: "Overdue!", ur: "تاخیر شدہ")}'
              : AppStrings.val(context, en: 'Healthy', ur: 'درست'),
          icon: Icons.account_balance_wallet_outlined,
          color: s.overdueCount > 0 ? Colors.red : Colors.purple,
          isAlert: s.overdueCount > 0,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isAlert = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: MRadius.md,
          border: Border.all(
            color: isAlert ? color : color.withValues(alpha: 0.25),
            width: isAlert ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isAlert ? Colors.red.shade800 : Colors.grey,
                fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search & Filters ───────────────────────────────────────────────────────
  Widget _buildSearchAndFilters(FarmerAdvanceProvider advProv) {
    return Column(
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search by farmer name, phone, crop, description...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      advProv.setSearchQuery('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: MRadius.md,
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onChanged: (val) => advProv.setSearchQuery(val),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildFilterChip(
              label: 'All Advances (${advProv.advances.length})',
              isSelected: advProv.filter == 'all',
              onTap: () => advProv.setFilter('all'),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label:
                  'Active (${advProv.advances.where((a) => a.status != FarmerAdvanceStatus.fullyRecovered).length})',
              isSelected: advProv.filter == 'active',
              onTap: () => advProv.setFilter('active'),
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label:
                  'Overdue (${advProv.advances.where((a) => a.isOverdue).length})',
              isSelected: advProv.filter == 'overdue',
              onTap: () => advProv.setFilter('overdue'),
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label:
                  'Cleared (${advProv.advances.where((a) => a.status == FarmerAdvanceStatus.fullyRecovered).length})',
              isSelected: advProv.filter == 'recovered',
              onTap: () => advProv.setFilter('recovered'),
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: MRadius.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? MColors.primary).withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: MRadius.sm,
          border: Border.all(
            color: isSelected
                ? (color ?? MColors.primary)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (color ?? MColors.primary)
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ── Advance Card Widget ────────────────────────────────────────────────────
  Widget _buildAdvanceCard(FarmerAdvance advance, String shopName) {
    final isCleared = advance.status == FarmerAdvanceStatus.fullyRecovered;
    final isOverdue = advance.isOverdue;
    final progress = advance.recoveryRatio;

    final borderColor = isOverdue
        ? Colors.red
        : (isCleared ? Colors.green.shade300 : Colors.grey.shade300);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: MRadius.md,
        side: BorderSide(color: borderColor, width: isOverdue ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Farmer Name, Type Badge, Overdue Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: MRadius.sm,
                      ),
                      child: Icon(
                        advance.advanceType == FarmerAdvanceType.cash
                            ? Icons.payments_outlined
                            : Icons.agriculture_outlined,
                        color: Colors.green.shade800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          advance.farmerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (advance.farmerPhone.isNotEmpty)
                          Text(
                            advance.farmerPhone,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isOverdue) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppStrings.val(context, en: 'OVERDUE', ur: 'تاخیر شدہ'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCleared
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppStrings.val(
                          context,
                          en: advance.advanceType.labelEnglish,
                          ur: advance.advanceType.labelUrdu,
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCleared
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (advance.description.isNotEmpty ||
                advance.targetCrop.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (advance.targetCrop.isNotEmpty) ...[
                    const Icon(
                      Icons.grass_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${AppStrings.val(context, en: "Crop", ur: "فصل")}: ${advance.targetCrop}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (advance.description.isNotEmpty) ...[
                    const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        advance.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 10),

            // Recovery Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppStrings.val(context, en: "Recovery Progress", ur: "وصولی پیش رفت")}: ${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '${AppStrings.val(context, en: "Disbursed", ur: "ادائیگی")}: ${_dateFmt.format(advance.disbursementDate)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCleared
                          ? Colors.green
                          : (isOverdue ? Colors.red : Colors.orange),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Financial Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountCell(
                  AppStrings.val(context, en: 'Principal', ur: 'اصل رقم'),
                  'Rs. ${_currencyFmt.format(advance.principalAmount)}',
                  Colors.blueGrey.shade800,
                ),
                _buildAmountCell(
                  AppStrings.val(context, en: 'Markup', ur: 'منافع'),
                  advance.computedMarkupAmount > 0
                      ? '+Rs. ${_currencyFmt.format(advance.computedMarkupAmount)}'
                      : '0',
                  Colors.purple.shade700,
                ),
                _buildAmountCell(
                  AppStrings.val(context, en: 'Total Recovered', ur: 'کل وصولی'),
                  'Rs. ${_currencyFmt.format(advance.recoveredAmount)}',
                  Colors.green.shade800,
                ),
                _buildAmountCell(
                  AppStrings.val(context, en: 'Remaining Balance', ur: 'بقایا رقم'),
                  'Rs. ${_currencyFmt.format(advance.computedRemainingBalance)}',
                  advance.computedRemainingBalance > 0
                      ? Colors.red.shade800
                      : Colors.green.shade800,
                  isBold: true,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (advance.expectedHarvestDate != null)
                  Text(
                    '${AppStrings.val(context, en: "Harvest", ur: "کٹائی")}: ${_dateFmt.format(advance.expectedHarvestDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue ? Colors.red.shade800 : Colors.grey,
                      fontWeight:
                          isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    if (!isCleared)
                      ElevatedButton.icon(
                        onPressed: () => _openRecoveryDialog(advance),
                        icon: const Icon(Icons.price_check, size: 16),
                        label: Text(
                          AppStrings.val(context, en: 'Deduct Recovery', ur: 'کٹوتی درج کریں'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _printFarmerStatement(shopName, advance),
                      icon: const Icon(Icons.print, size: 14),
                      label: Text(
                        AppStrings.val(context, en: 'Print Slip', ur: 'پرچہ پرنٹ کریں'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCell(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(FarmerAdvanceProvider advProv) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.agriculture_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.val(
              context,
              en: 'No Farmer Advances Recorded',
              ur: 'کوئی پیشگی ایڈوانس ریکارڈ نہیں ملا',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            advProv.searchQuery.isNotEmpty
                ? AppStrings.val(
                    context,
                    en: 'No loans match "${advProv.searchQuery}".',
                    ur: 'تلاش سے مطابقت رکھنے والا کوئی قرضہ نہیں ملا۔',
                  )
                : AppStrings.val(
                    context,
                    en: 'Click "Disburse Advance" to record pre-harvest cash or fertilizer/seed credit provided to farmers.',
                    ur: 'کسانوں کو پیشگی نقد یا کھاد بیج دینے کے لیے "نیا ایڈوانس دیں" پر کلک کریں۔',
                  ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openNewAdvanceDialog,
            icon: const Icon(Icons.add),
            label: Text(
              AppStrings.val(
                context,
                en: 'Disburse Advance',
                ur: 'نیا ایڈوانس دیں',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
