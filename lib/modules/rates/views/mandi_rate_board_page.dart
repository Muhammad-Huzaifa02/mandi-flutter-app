import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/theme/locale_provider.dart';
import 'package:mandi/core/utils/mandi_rate_board_pdf_generator.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/widgets/liquid_crystal_background.dart';
import 'package:mandi/data/models/mandi_rate_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/modules/rates/providers/mandi_rate_provider.dart';
import 'package:mandi/modules/rates/views/record_commodity_rate_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Live Mandi Price Intelligence & Daily Rate Board Broadcast Hub
/// (*منڈی روزانہ ریٹ بورڈ اور براڈکاسٹ سسٹم*).
class MandiRateBoardPage extends StatefulWidget {
  const MandiRateBoardPage({super.key});

  @override
  State<MandiRateBoardPage> createState() => _MandiRateBoardPageState();
}

class _MandiRateBoardPageState extends State<MandiRateBoardPage> {
  final _searchCtrl = TextEditingController();
  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MandiRateProvider>().loadRates();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openRecordRateDialog() {
    showDialog(
      context: context,
      builder: (_) => const RecordCommodityRateDialog(),
    );
  }

  void _printRateBoard(List<MandiCommodityRate> rates, String shopName,
      String? address, String? phone, DateTime date) {
    if (rates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No rates recorded for this date to print.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    MandiRateBoardPdfGenerator.printRateBoard(
      rates: rates,
      shopName: shopName,
      shopAddress: address,
      shopPhone: phone,
      date: date,
    );
  }

  void _showBroadcastModal(
      String shopName, String city, String shopId, DateTime date) {
    final provider = context.read<MandiRateProvider>();
    final isUrdu = context.read<LocaleProvider>().isUrdu;
    final broadcastMsg = provider.generateBroadcastMessage(
      shopName: shopName,
      city: city,
      date: date,
      isUrdu: isUrdu,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: MColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr(ctx, 'broadcast_rate_board'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This formatted message will be shared with farmers, commission buyers, and transport brokers:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      broadcastMsg,
                      style: const TextStyle(
                          fontSize: 12, height: 1.5, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Text'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: broadcastMsg));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rate list copied to clipboard!')),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), // WhatsApp green
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share WhatsApp'),
            onPressed: () async {
              Clipboard.setData(ClipboardData(text: broadcastMsg));
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              await SupabaseService.markMandiRatesBroadcastSent(
                shopId: shopId,
                rateDate: dateStr,
              );
              final encoded = Uri.encodeComponent(broadcastMsg);
              final whatsappUrl = Uri.parse('whatsapp://send?text=$encoded');
              final webWhatsappUrl =
                  Uri.parse('https://api.whatsapp.com/send?text=$encoded');

              if (await canLaunchUrl(whatsappUrl)) {
                await launchUrl(whatsappUrl);
              } else if (await canLaunchUrl(webWhatsappUrl)) {
                await launchUrl(webWhatsappUrl,
                    mode: LaunchMode.externalApplication);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rateProv = context.watch<MandiRateProvider>();
    final shopContext = context.watch<ShopContextProvider>();
    final activeShop = shopContext.currentShop;
    final shopName = activeShop?.name ?? 'Mandi Commission Shop';
    final shopCity = activeShop?.city ?? 'Ghalla Mandi';
    final shopAddress = activeShop?.address ?? '';
    final shopPhone = activeShop?.phone ?? '';
    final shopId = activeShop?.id ?? '';

    final rates = rateProv.filteredRates;
    final totalCommodities = rates.length;
    final bullishCount =
        rates.where((r) => r.marketTrend == MarketTrend.bullish).length;
    final bearishCount =
        rates.where((r) => r.marketTrend == MarketTrend.bearish).length;
    final totalArrivals =
        rates.fold(0.0, (sum, r) => sum + r.arrivalsMaunds);

    return LiquidCrystalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppStrings.tr(context, 'rate_board')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: MColors.textPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print Rate Board A4',
              onPressed: () => _printRateBoard(
                rates,
                shopName,
                shopAddress,
                shopPhone,
                rateProv.selectedDate,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.campaign),
              tooltip: 'Broadcast via WhatsApp/SMS',
              onPressed: () => _showBroadcastModal(
                shopName,
                shopCity,
                shopId,
                rateProv.selectedDate,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => rateProv.loadRates(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Top Controls Bar (Date Picker, Search, Trend Filter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Date Selector
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: MColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: MColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMMM yyyy')
                                      .format(rateProv.selectedDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: MColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: rateProv.selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                rateProv.setSelectedDate(picked);
                              }
                            },
                            child: const Text('Change Date'),
                          ),
                        ],
                      ),

                      // Search box
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search commodity...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (val) => rateProv.setSearchQuery(val),
                        ),
                      ),

                      // Trend Filter Chips
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChoiceChip(
                            label: Text(AppStrings.tr(context, 'all')),
                            selected: rateProv.trendFilter == null,
                            onSelected: (_) => rateProv.setTrendFilter(null),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: Text('▲ ${AppStrings.tr(context, 'bullish')}'),
                            selected:
                                rateProv.trendFilter == MarketTrend.bullish,
                            selectedColor: Colors.green.shade100,
                            onSelected: (sel) => rateProv.setTrendFilter(
                                sel ? MarketTrend.bullish : null),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: Text('▼ ${AppStrings.tr(context, 'bearish')}'),
                            selected:
                                rateProv.trendFilter == MarketTrend.bearish,
                            selectedColor: Colors.red.shade100,
                            onSelected: (sel) => rateProv.setTrendFilter(
                                sel ? MarketTrend.bearish : null),
                          ),
                        ],
                      ),

                      // New Rate Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _openRecordRateDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(AppStrings.tr(context, 'record_rate_btn')),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Metrics Cards Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: AppStrings.tr(context, 'commodities'),
                      value: '$totalCommodities',
                      icon: Icons.list_alt,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: AppStrings.tr(context, 'bullish'),
                      value: '$bullishCount',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: AppStrings.tr(context, 'bearish'),
                      value: '$bearishCount',
                      icon: Icons.trending_down,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: AppStrings.tr(context, 'total_arrivals'),
                      value: '${_currencyFmt.format(totalArrivals)} ${AppStrings.tr(context, 'maunds')}',
                      icon: Icons.local_shipping_outlined,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),

            // Commodity Rates List / Empty View
            Expanded(
              child: rateProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : rates.isEmpty
                      ? _buildEmptyRatesView()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: rates.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final rate = rates[idx];
                            return _buildRateCard(rate);
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openRecordRateDialog,
          backgroundColor: MColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Daily Rate'),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCard(MandiCommodityRate rate) {
    final trendColor = rate.marketTrend == MarketTrend.bullish
        ? Colors.green
        : rate.marketTrend == MarketTrend.bearish
            ? Colors.red
            : Colors.grey.shade700;

    final trendIcon = rate.marketTrend == MarketTrend.bullish
        ? Icons.arrow_upward
        : rate.marketTrend == MarketTrend.bearish
            ? Icons.arrow_downward
            : Icons.remove;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Commodity Icon & Name
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: MColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rate.commodityName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MColors.textPrimary,
                        ),
                      ),
                      if (rate.variety.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rate.variety,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Grade: ${rate.qualityGrade}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (rate.arrivalsMaunds > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          AppStrings.val(
                            context,
                            en: 'Arrivals: ${_currencyFmt.format(rate.arrivalsMaunds)} Maunds',
                            ur: 'آمد: ${_currencyFmt.format(rate.arrivalsMaunds)} من',
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (rate.notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      rate.notes,
                      style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),

            // Modal Rate & Rate per KG
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${_currencyFmt.format(rate.modalRatePerMaund)} / ${AppStrings.tr(context, 'maunds')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MColors.primary,
                    ),
                  ),
                  Text(
                    'Rs. ${rate.pricePerKgPkr.toStringAsFixed(1)} / ${AppStrings.val(context, en: 'KG', ur: 'کلو')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Range: ${_currencyFmt.format(rate.minRatePerMaund)} - ${_currencyFmt.format(rate.maxRatePerMaund)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Trend Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: trendColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trendIcon, size: 16, color: trendColor),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rate.marketTrend.labelEnglish,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: trendColor,
                        ),
                      ),
                      if (rate.previousModalRate > 0)
                        Text(
                          '${rate.priceChangePkr >= 0 ? "+" : ""}${rate.priceChangePkr.toStringAsFixed(0)} (${rate.priceChangePercent.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: trendColor,
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
  }

  Widget _buildEmptyRatesView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No Mandi Rates Recorded For This Date',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Click "+ Record Daily Rate" to publish morning commodity prices.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _openRecordRateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Record First Commodity Rate'),
          ),
        ],
      ),
    );
  }
}
