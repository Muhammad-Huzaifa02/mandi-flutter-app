// Main Management Hub for Mandi Barcode, QR Code & Pallet Inventory Labels
// (*بارکوڈ و کیو آر انوینٹری لیبلز اور گودام پیلیٹ ٹریکنگ ہب*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/inventory_label_pdf_generator.dart';
import 'package:mandi/data/models/inventory_label_model.dart';
import 'package:mandi/modules/inventory_labels/providers/inventory_label_provider.dart';
import 'package:mandi/modules/inventory_labels/views/create_inventory_label_dialog.dart';
import 'package:mandi/modules/inventory_labels/views/label_detail_modal.dart';
import 'package:mandi/modules/inventory_labels/views/scan_verify_label_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class InventoryLabelsPage extends StatefulWidget {
  const InventoryLabelsPage({super.key});

  @override
  State<InventoryLabelsPage> createState() => _InventoryLabelsPageState();
}

class _InventoryLabelsPageState extends State<InventoryLabelsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final _numberFmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => const CreateInventoryLabelDialog(),
    );
  }

  void _openScanDialog() {
    showDialog(
      context: context,
      builder: (_) => const ScanVerifyLabelDialog(),
    );
  }

  Future<void> _print4UpStickers() async {
    final provider = context.read<InventoryLabelProvider>();
    final labels = provider.filteredLabels.where((e) => e.isActive).toList();

    if (labels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active labels to print stickers for.')),
      );
      return;
    }

    final shopCtx = context.read<ShopContextProvider>();
    final shop = shopCtx.currentShop;

    await InventoryLabelPdfGenerator.print4UpStickers(
      labels: labels,
      shopName: shop?.name ?? 'Mandi Enterprise',
    );
  }

  Future<void> _printRoster() async {
    final provider = context.read<InventoryLabelProvider>();
    final labels = provider.filteredLabels;

    if (labels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No inventory labels to print in roster.')),
      );
      return;
    }

    final shopCtx = context.read<ShopContextProvider>();
    final shop = shopCtx.currentShop;

    await InventoryLabelPdfGenerator.printInventoryRoster(
      labels: labels,
      shopName: shop?.name ?? 'Mandi Enterprise',
      shopAddress: shop?.address,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryLabelProvider>();

    return Scaffold(
      backgroundColor: MColors.backgroundDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barcode & QR Labels',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'بارکوڈ و کیو آر انوینٹری لیبلز',
              style: MText.caption.copyWith(color: MColors.primaryLight),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.lightBlueAccent),
            tooltip: 'Scan & Verify Label',
            onPressed: _openScanDialog,
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.amberAccent),
            tooltip: 'Print 4-Up Adhesive Stickers',
            onPressed: _print4UpStickers,
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.tealAccent),
            tooltip: 'Print Warehouse Inventory Roster',
            onPressed: _printRoster,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MColors.primaryLight,
          labelColor: MColors.primaryLight,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_outlined, size: 20),
              text: 'Active (${provider.totalActiveLabels})',
            ),
            Tab(
              icon: const Icon(Icons.local_shipping_outlined, size: 20),
              text: 'Dispatched (${provider.totalDispatchedLabels})',
            ),
            const Tab(
              icon: Icon(Icons.qr_code_2_rounded, size: 20),
              text: 'Scan Terminal',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Label / نیا لیبل'),
        onPressed: _openCreateDialog,
      ),
      body: Column(
        children: [
          // KPI Metrics Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MColors.surfaceDark,
                    MColors.primary.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricTile(
                    'Active Pallets',
                    '${provider.totalActiveLabels}',
                    Icons.layers_outlined,
                    Colors.lightBlueAccent,
                  ),
                  _metricTile(
                    'Total Bags',
                    _numberFmt.format(provider.totalActiveBags),
                    Icons.shopping_bag_outlined,
                    Colors.orangeAccent,
                  ),
                  _metricTile(
                    'Net Maunds (من)',
                    '${provider.totalActiveNetMaunds.toStringAsFixed(1)} M',
                    Icons.scale_rounded,
                    MColors.primaryLight,
                    isBig: true,
                  ),
                  _metricTile(
                    'Total Net KG',
                    _numberFmt.format(provider.totalActiveNetKg),
                    Icons.fitness_center_rounded,
                    Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          // Search Bar & Filter Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search label code, crop, vehicle, bay...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchCtrl.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => provider.setSearchQuery(v),
                  ),
                ),
                const SizedBox(width: 8),
                if (provider.filterType != null ||
                    provider.filterCommodity != null ||
                    provider.searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off, color: Colors.amber),
                    tooltip: 'Clear Filters',
                    onPressed: () {
                      _searchCtrl.clear();
                      provider.clearFilters();
                    },
                  ),
              ],
            ),
          ),

          // Filter Type Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Types'),
                  selected: provider.filterType == null,
                  onSelected: (_) => provider.setFilterType(null),
                ),
                const SizedBox(width: 6),
                ...InventoryLabelType.values.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(t.labelEnglish),
                      selected: provider.filterType == t,
                      onSelected: (s) => provider.setFilterType(s ? t : null),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Active Labels
                _buildLabelList(
                  provider.filteredLabels.where((e) => e.isActive).toList(),
                  provider.isLoading,
                  isDispatchedView: false,
                ),

                // Tab 2: Dispatched Labels
                _buildLabelList(
                  provider.filteredLabels
                      .where((e) => e.status == LabelStatus.dispatched)
                      .toList(),
                  provider.isLoading,
                  isDispatchedView: true,
                ),

                // Tab 3: Embedded Scanner Terminal
                const ScanVerifyLabelDialog(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelList(List<InventoryLabel> labels, bool isLoading,
      {required bool isDispatchedView}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (labels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDispatchedView
                  ? Icons.local_shipping_outlined
                  : Icons.inventory_2_outlined,
              size: 56,
              color: Colors.white24,
            ),
            const SizedBox(height: 12),
            Text(
              isDispatchedView
                  ? 'No dispatched inventory labels found'
                  : 'No active pallet or lot labels created yet',
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 8),
            if (!isDispatchedView)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Generate First Label'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: labels.length,
      itemBuilder: (context, idx) {
        final lbl = labels[idx];
        return _buildLabelCard(lbl);
      },
    );
  }

  Widget _buildLabelCard(InventoryLabel lbl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lbl.isActive ? Colors.white12 : Colors.orangeAccent.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => LabelDetailModal.show(context, lbl),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Type badge, Label Code, and Print Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          lbl.labelType.labelEnglish,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lbl.labelCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print_outlined,
                            size: 18, color: Colors.tealAccent),
                        tooltip: 'Print A4 Placard',
                        onPressed: () async {
                          final shopCtx = context.read<ShopContextProvider>();
                          final shop = shopCtx.currentShop;
                          await InventoryLabelPdfGenerator.printSinglePalletPlacard(
                            label: lbl,
                            shopName: shop?.name ?? 'Mandi Enterprise',
                            shopAddress: shop?.address,
                            shopPhone: shop?.phone,
                          );
                        },
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: Colors.grey),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Commodity & Location
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lbl.displayCommodity,
                          style: MText.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.warehouse_outlined,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lbl.displayLocation.isNotEmpty
                                    ? lbl.displayLocation
                                    : 'General Yard',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Mini QR Code preview thumbnail
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: lbl.qrPayload.isNotEmpty ? lbl.qrPayload : lbl.labelCode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Badges: Bags, KG, Maunds
              Row(
                children: [
                  _chipBadge('${lbl.bagCount} Bags', Colors.amberAccent),
                  const SizedBox(width: 6),
                  _chipBadge(
                      '${_numberFmt.format(lbl.netWeightKg)} KG', Colors.white70),
                  const SizedBox(width: 6),
                  _chipBadge(
                    '${lbl.netWeightMaunds.toStringAsFixed(2)} Maunds',
                    MColors.primaryLight,
                    isHighlight: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipBadge(String text, Color color, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isHighlight ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _metricTile(
      String label, String value, IconData icon, Color color,
      {bool isBig = false}) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isBig ? 16 : 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }
}
