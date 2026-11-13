import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/cross_border_pdf_generator.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/cross_border_shipment_model.dart';
import 'package:mandi/modules/consignment/views/add_consignment_lot_page.dart';
import 'package:mandi/modules/cross_border/providers/cross_border_provider.dart';
import 'package:mandi/modules/cross_border/views/new_cross_border_shipment_dialog.dart';
import 'package:mandi/modules/cross_border/views/update_cross_border_status_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Primary Mandi Operations Hub for Cross-Border Fruit & Vegetable Shipments,
/// Customs Clearance, and Dual-Currency Foreign Exporter Ledgers.
class CrossBorderPage extends StatefulWidget {
  const CrossBorderPage({super.key});

  @override
  State<CrossBorderPage> createState() => _CrossBorderPageState();
}

class _CrossBorderPageState extends State<CrossBorderPage> {
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _numberFmt = NumberFormat('#,##0.00', 'en_US');
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openNewShipmentDialog() {
    showDialog(
      context: context,
      builder: (_) => const NewCrossBorderShipmentDialog(),
    );
  }

  void _openUpdateStatusDialog(CrossBorderShipment shipment) {
    showDialog(
      context: context,
      builder: (_) => UpdateCrossBorderStatusDialog(shipment: shipment),
    );
  }

  void _printAllRegister(
      List<CrossBorderShipment> shipments, String shopName, String? shopCity, String? shopPhone) {
    CrossBorderPdfGenerator.printBorderRegister(
      shipments: shipments,
      shopName: shopName,
      shopCity: shopCity,
      shopPhone: shopPhone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shop = shopCtx.currentShop;
    final shopName = shop?.name ??
        AppStrings.val(
          context,
          en: 'Mandi Commission Shop',
          ur: 'منڈی کمیشن شاپ',
        );
    final cbProv = context.watch<CrossBorderProvider>();
    final summary = cbProv.summary;
    final shipments = cbProv.filteredShipments;
    final isUrdu = AppStrings.isUrdu(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppStrings.val(
          context,
          en: 'Cross-Border Trade',
          ur: 'بین الاقوامی سرحد تجارت',
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: AppStrings.val(
              context,
              en: 'Print Cross-Border Register',
              ur: 'سرحدی رجسٹر پرنٹ کریں',
            ),
            onPressed: shipments.isEmpty
                ? null
                : () => _printAllRegister(
                      shipments,
                      shopName,
                      shop?.city,
                      shop?.phone,
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: AppStrings.val(
              context,
              en: 'Record Border Cargo',
              ur: 'سرحدی مال درج کریں',
            ),
            onPressed: _openNewShipmentDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewShipmentDialog,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.val(
          context,
          en: 'New Cargo',
          ur: 'نیا مال',
        )),
        backgroundColor: MColors.gold,
        foregroundColor: Colors.black,
      ),
      body: cbProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                cbProv.setSearchQuery(_searchCtrl.text);
              },
              child: ListView(
                padding: const EdgeInsets.all(MSpacing.md),
                children: [
                  // KPI Cards
                  _buildKpiSection(summary),
                  const SizedBox(height: MSpacing.md),

                  // Search and Filters
                  _buildSearchAndFilters(cbProv, isUrdu),
                  const SizedBox(height: MSpacing.md),

                  // Shipment List or Empty State
                  if (shipments.isEmpty)
                    _buildEmptyState(cbProv)
                  else
                    ...shipments.map((s) => _buildShipmentCard(s, shopName, isUrdu)),
                  const SizedBox(height: 70),
                ],
              ),
            ),
    );
  }

  // ── KPI Summary Cards ───────────────────────────────────────────────────────
  Widget _buildKpiSection(CrossBorderSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: AppStrings.val(
                  context,
                  en: 'Total Border Cargo',
                  ur: 'کل بین الاقوامی مال',
                ),
                value: '${_numberFmt.format(summary.totalCargoMaunds)} ${AppStrings.val(context, en: "M", ur: "من")}',
                subtitle: '${summary.totalShipments} ${AppStrings.val(context, en: "Vehicles Imported", ur: "درآمدی گاڑیاں")}',
                icon: Icons.local_shipping_outlined,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: MSpacing.sm),
            Expanded(
              child: _buildMetricCard(
                title: AppStrings.val(
                  context,
                  en: 'Foreign Debt (PKR Equiv)',
                  ur: 'غیر ملکی قرضہ واجب الادا',
                ),
                value: 'Rs. ${_currencyFmt.format(summary.totalOutstandingSupplierPkr)}',
                subtitle: '${summary.activeShipments} ${AppStrings.val(context, en: "Active Shipments", ur: "زیر التواء مال")}',
                icon: Icons.public_outlined,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: MSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: AppStrings.val(
                  context,
                  en: 'Total Landed Value',
                  ur: 'کل لاگت منڈی پہنچ',
                ),
                value: 'Rs. ${_currencyFmt.format(summary.totalLandedCostPkr)}',
                subtitle: AppStrings.val(
                  context,
                  en: 'Cargo + Tariffs + Freight',
                  ur: 'مال + ڈیوٹی + کرایہ',
                ),
                icon: Icons.warehouse_outlined,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: MSpacing.sm),
            Expanded(
              child: _buildMetricCard(
                title: AppStrings.val(
                  context,
                  en: 'Customs & Border Freight',
                  ur: 'کسٹم ڈیوٹی و گاڑی کرایہ',
                ),
                value: 'Rs. ${_currencyFmt.format(summary.totalCustomsFreightPkr)}',
                subtitle: AppStrings.val(
                  context,
                  en: 'Border Logistics Paid',
                  ur: 'ادا شدہ اخراجات',
                ),
                icon: Icons.verified_outlined,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(MSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 8.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Search & Filter Tabs ───────────────────────────────────────────────────
  Widget _buildSearchAndFilters(CrossBorderProvider cbProv, bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: AppStrings.val(
              context,
              en: 'Search by GD #, vehicle plate, driver, commodity...',
              ur: 'جی ڈی نمبر، گاڑی نمبر، ڈرائیور یا جنس سے تلاش کریں...',
            ),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      cbProv.setSearchQuery('');
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
          onChanged: (val) => cbProv.setSearchQuery(val),
        ),
        const SizedBox(height: 8),

        // Country Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: AppStrings.val(
                  context,
                  en: 'All Origins (${cbProv.shipments.length})',
                  ur: 'تمام ممالک (${cbProv.shipments.length})',
                ),
                isSelected: cbProv.countryFilter == 'all',
                onTap: () => cbProv.setCountryFilter('all'),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: AppStrings.val(
                  context,
                  en: '🇦🇫 Afghanistan',
                  ur: '🇦🇫 افغانستان',
                ),
                isSelected: cbProv.countryFilter == 'afghanistan',
                onTap: () => cbProv.setCountryFilter('afghanistan'),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: AppStrings.val(
                  context,
                  en: '🇮🇷 Iran',
                  ur: '🇮🇷 ایران',
                ),
                isSelected: cbProv.countryFilter == 'iran',
                onTap: () => cbProv.setCountryFilter('iran'),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: AppStrings.val(
                  context,
                  en: '🇺🇿 Central Asia',
                  ur: '🇺🇿 وسطی ایشیا',
                ),
                isSelected: cbProv.countryFilter == 'centralAsia',
                onTap: () => cbProv.setCountryFilter('centralAsia'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Status Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: AppStrings.val(
                  context,
                  en: 'All Status',
                  ur: 'تمام کیفیت',
                ),
                isSelected: cbProv.statusFilter == 'all',
                onTap: () => cbProv.setStatusFilter('all'),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: AppStrings.val(
                  context,
                  en: 'In Transit',
                  ur: 'راستے میں',
                ),
                isSelected: cbProv.statusFilter == 'inTransit',
                onTap: () => cbProv.setStatusFilter('inTransit'),
                badgeColor: Colors.orange,
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: AppStrings.val(
                  context,
                  en: 'Customs Cleared',
                  ur: 'کسٹم کلیئرڈ',
                ),
                isSelected: cbProv.statusFilter == 'clearedAtBorder',
                onTap: () => cbProv.setStatusFilter('clearedAtBorder'),
                badgeColor: Colors.blue,
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: AppStrings.val(
                  context,
                  en: 'Mandi Arrived',
                  ur: 'منڈی آمد',
                ),
                isSelected: cbProv.statusFilter == 'arrivedInMandi',
                onTap: () => cbProv.setStatusFilter('arrivedInMandi'),
                badgeColor: Colors.teal,
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: AppStrings.val(
                  context,
                  en: 'Settled',
                  ur: 'بیباق',
                ),
                isSelected: cbProv.statusFilter == 'settled',
                onTap: () => cbProv.setStatusFilter('settled'),
                badgeColor: const Color(0xFF2E7D32),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (badgeColor ?? MColors.primary).withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (badgeColor ?? MColors.primary)
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (badgeColor ?? MColors.primary)
                    : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shipment Card Widget ────────────────────────────────────────────────────
  Widget _buildShipmentCard(CrossBorderShipment s, String shopName, bool isUrdu) {
    final shop = context.read<ShopContextProvider>().currentShop;

    return GlassCard(
      padding: const EdgeInsets.all(MSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Origin Flag, Route Badge, Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(s.originCountry.flagEmoji,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    s.shipmentNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: MColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isUrdu ? s.originCountry.labelUrdu : s.originCountry.labelEnglish} • ${isUrdu ? s.borderCrossing.labelUrdu.split(" ").first : s.borderCrossing.labelEnglish.split(" ").first}',
                      style: const TextStyle(
                          fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isUrdu ? s.status.labelUrdu : s.status.labelEnglish,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: s.status.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Vehicle & Commodity Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.vehicleNumber}  •  ${s.commodity}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${s.packageCount} ${s.packageType}s (${_numberFmt.format(s.maunds)} ${AppStrings.val(context, en: "M", ur: "من")})',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          if (s.customsGdNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${AppStrings.val(context, en: "Customs GD #:", ur: "کسٹم جی ڈی #:")} ${s.customsGdNumber}  |  ${AppStrings.val(context, en: "Agent:", ur: "ایجنٹ:")} ${s.clearingAgentName.isNotEmpty ? s.clearingAgentName : (isUrdu ? "براہ راست" : "Direct")}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Economics Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cell(
                AppStrings.val(context, en: 'Contract Price', ur: 'معاہدہ قیمت'),
                '${s.currency.symbol} ${_currencyFmt.format(s.foreignContractAmount)}',
                '@ Rs. ${_numberFmt.format(s.exchangeRateToPkr)}',
              ),
              _cell(
                AppStrings.val(context, en: 'Border Surcharges', ur: 'سرحدی اخراجات'),
                'Rs. ${_currencyFmt.format(s.totalBorderExpensesPkr)}',
                AppStrings.val(context, en: 'Duty + Freight', ur: 'ڈیوٹی + کرایہ'),
              ),
              _cell(
                AppStrings.val(context, en: 'Landed Cost', ur: 'منڈی لاگت'),
                'Rs. ${_currencyFmt.format(s.computedTotalLandedCostPkr)}',
                'Rs. ${_currencyFmt.format(s.costPerMaundPkr)} / ${AppStrings.val(context, en: "Maund", ur: "من")}',
                isBold: true,
                color: const Color(0xFF2E7D32),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Supplier Settlement Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.val(context, en: "Farmer:", ur: "زمیندار:")} ${s.supplierName}',
                    style: const TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${AppStrings.val(context, en: "Debt:", ur: "قرضہ:")} ${s.currency.symbol} ${_currencyFmt.format(s.computedRemainingSupplierForeign)} (Rs. ${_currencyFmt.format(s.computedRemainingSupplierPkr)})',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: s.computedRemainingSupplierForeign > 0
                          ? Colors.red.shade800
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: s.settlementRatio,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    s.computedRemainingSupplierForeign <= 0
                        ? const Color(0xFF2E7D32)
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddConsignmentLotPage(
                        initialVehicleNumber: s.vehicleNumber,
                        initialBags: s.packageCount,
                        initialWeightKg: s.grossWeightKg,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.inventory_2_outlined, size: 14),
                label: Text(AppStrings.val(context, en: 'Bridge Lot', ur: 'ڈھیری لاٹ')),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 10.5),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _openUpdateStatusDialog(s),
                icon: const Icon(Icons.sync, size: 14),
                label: Text(AppStrings.val(context, en: 'Update / Pay', ur: 'اپ ڈیٹ / ادائیگی')),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 10.5),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () {
                  CrossBorderPdfGenerator.printCargoManifest(
                    shipment: s,
                    shopName: shopName,
                    shopCity: shop?.city,
                    shopPhone: shop?.phone,
                  );
                },
                icon: const Icon(Icons.print, size: 14),
                label: Text(AppStrings.val(context, en: 'Manifest', ur: 'پرچہ مال')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 10.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(String title, String val, String sub,
      {bool isBold = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
        Text(
          val,
          style: TextStyle(
            fontSize: isBold ? 12 : 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
        Text(sub,
            style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
      ],
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(CrossBorderProvider cbProv) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.public_off_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            AppStrings.val(
              context,
              en: 'No Cross-Border Shipments Found',
              ur: 'کوئی سرحدی مال نہیں ملا',
            ),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            cbProv.searchQuery.isNotEmpty
                ? AppStrings.val(
                    context,
                    en: 'No shipments match "${cbProv.searchQuery}".',
                    ur: 'کوئی مال تلاش سے مطابقت نہیں رکھتا۔',
                  )
                : AppStrings.val(
                    context,
                    en: 'Tap "New Cargo" to log imported fruits & vegetables from Afghanistan or Iran.',
                    ur: 'افغانستان یا ایران سے درآمدی پھل و سبزی کے اندراج کے لیے "نیا مال" پر کلک کریں۔',
                  ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openNewShipmentDialog,
            icon: const Icon(Icons.add),
            label: Text(AppStrings.val(
              context,
              en: 'Record 1st Border Cargo',
              ur: 'پہلا سرحدی مال درج کریں',
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
