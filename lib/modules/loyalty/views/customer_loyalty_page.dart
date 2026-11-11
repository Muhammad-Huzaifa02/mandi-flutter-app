import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/loyalty_rebate_pdf_generator.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/customer_loyalty_rebate_model.dart';
import 'package:mandi/modules/loyalty/providers/loyalty_rebate_provider.dart';
import 'package:mandi/modules/loyalty/views/new_loyalty_rebate_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Central Hub for Customer Loyalty, Volume Rebate & Seasonal Brokerage Incentives
/// (*گاہک رعایت، والیم بونس اور سالانہ انعامات*).
class CustomerLoyaltyPage extends StatefulWidget {
  const CustomerLoyaltyPage({super.key});

  @override
  State<CustomerLoyaltyPage> createState() => _CustomerLoyaltyPageState();
}

class _CustomerLoyaltyPageState extends State<CustomerLoyaltyPage> {
  final _searchCtrl = TextEditingController();
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoyaltyRebateProvider>().loadRebates();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openNewRebateDialog() {
    showDialog(
      context: context,
      builder: (_) => const NewLoyaltyRebateDialog(),
    );
  }

  void _printCreditNote(CustomerLoyaltyRebate rebate, String shopName,
      String? address, String? phone) {
    LoyaltyRebatePdfGenerator.printCreditNote(
      rebate: rebate,
      shopName: shopName,
      shopAddress: address,
      shopPhone: phone,
    );
  }

  Future<void> _confirmCreditToKhata(CustomerLoyaltyRebate rebate) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('کھاتہ میں کریڈٹ منتقل کریں؟'),
        content: Text(
          'کیا آپ تصدیق کرتے ہیں کہ ${rebate.customerName} کے کھاتے میں Rs. ${_currencyFmt.format(rebate.rebateAmountPkr)} کا کریڈٹ نوٹ (${rebate.creditNoteNumber}) لاگو کر کے بقایا کم کر دیا جائے؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('منسوخ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ہاں، کریڈٹ نوٹ جاری کریں'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final prov = context.read<LoyaltyRebateProvider>();
      final success = await prov.creditRebateToKhata(rebate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'کریڈٹ نوٹ کامیابی سے گاہک کھاتہ میں منتقل کر دیا گیا'
                : 'کھاتہ منتقلی میں خرابی پیش آگئی'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shop = shopCtx.currentShop;
    final shopName = shop?.name ?? 'Mandi Commission Shop';
    final prov = context.watch<LoyaltyRebateProvider>();
    final summary = prov.summary;
    final rebates = prov.filteredRebates;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Loyalty & Rebates'),
            Text(
              'گاہک رعایت، والیم بونس اور سالانہ انعامات',
              style: TextStyle(fontSize: 11, color: MColors.gold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ریفریش (Refresh)',
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.loadRebates(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
        onPressed: _openNewRebateDialog,
        icon: const Icon(Icons.stars_rounded),
        label: const Text('نیا رعایت واؤچر (Issue Rebate)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPI Headline Banner
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium,
                        color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'سیزنل خریدار ٹرن اوور و رعایت خلاصہ (Seasonal Incentives Summary)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildKpiBox(
                      title: 'اہل سیزن من (Maunds)',
                      value:
                          '${_numberFmt.format(summary.totalQualifyingMaunds)} M',
                      color: Colors.blue.shade700,
                      icon: Icons.scale,
                    ),
                    _buildKpiBox(
                      title: 'اہل تجارتی والیوم (Turnover)',
                      value:
                          'Rs. ${_currencyFmt.format(summary.totalQualifyingTurnoverPkr)}',
                      color: Colors.teal.shade700,
                      icon: Icons.point_of_sale,
                    ),
                    _buildKpiBox(
                      title: 'منظور شدہ بونس (Accrued)',
                      value:
                          'Rs. ${_currencyFmt.format(summary.totalRebatesAccruedPkr)}',
                      color: Colors.amber.shade800,
                      icon: Icons.hourglass_top,
                    ),
                    _buildKpiBox(
                      title: 'کھاتہ میں منتقل (Credited)',
                      value:
                          'Rs. ${_currencyFmt.format(summary.totalRebatesCreditedPkr)}',
                      color: Colors.green.shade700,
                      icon: Icons.check_circle_outline,
                      isHighlight: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search & Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'تلاش کریں (گاہک کا نام، فون، یا واؤچر نمبر)...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              prov.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => prov.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('تمام'),
                selected: prov.statusFilter == null,
                onSelected: (_) => prov.setStatusFilter(null),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('منظور شدہ'),
                selected: prov.statusFilter == RebateStatus.approved,
                onSelected: (_) => prov.setStatusFilter(RebateStatus.approved),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('منتقل شدہ'),
                selected: prov.statusFilter == RebateStatus.credited,
                onSelected: (_) => prov.setStatusFilter(RebateStatus.credited),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // List of Rebates
          if (prov.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (rebates.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'کوئی رعایت یا والیم بونس ریکارڈ نہیں ملا',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'نیا بونس واؤچر جاری کرنے کے لیے نیچے بٹن دبائیں',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...rebates.map((r) => _buildRebateCard(context, r, shopName, shop)),
        ],
      ),
    );
  }

  Widget _buildKpiBox({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? color.withValues(alpha: 0.1) : Colors.white,
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
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRebateCard(BuildContext context, CustomerLoyaltyRebate r,
      String shopName, dynamic shop) {
    Color statusColor;
    switch (r.status) {
      case RebateStatus.approved:
        statusColor = Colors.amber.shade900;
        break;
      case RebateStatus.credited:
        statusColor = Colors.green.shade700;
        break;
      case RebateStatus.accruing:
        statusColor = Colors.blue.shade700;
        break;
      case RebateStatus.cancelled:
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
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r.creditNoteNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${r.seasonYear} (${r.programName})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    r.status.labelUrdu,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Customer Name & Tier Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.customerName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (r.customerPhone.isNotEmpty)
                      Text(r.customerPhone,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.military_tech,
                          color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${r.tierLevel.labelEnglish} (${r.rebatePercentage}%)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Turnover & Rebate Metrics
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
                      const Text('سیزنل مال خریداری',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        '${_numberFmt.format(r.qualifyingMaunds)} من | Rs. ${_currencyFmt.format(r.qualifyingTurnoverPkr)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('رعایت کریڈٹ رقم (Rebate)',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        'Rs. ${_currencyFmt.format(r.rebateAmountPkr)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Print A4 Credit Note
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _printCreditNote(
                      r, shopName, shop?.address, shop?.phone),
                  icon: const Icon(Icons.receipt_outlined, size: 16),
                  label: const Text('کریڈٹ واؤچر پرنٹ (Credit Note)'),
                ),
                const SizedBox(width: 8),

                // Credit to Khata Button (if approved)
                if (r.status == RebateStatus.approved)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _confirmCreditToKhata(r),
                    icon: const Icon(Icons.account_balance_wallet_outlined,
                        size: 16),
                    label: const Text('کھاتہ میں کریڈٹ کریں (Apply to Khata)'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
