import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/boli_sheet_pdf_generator.dart';
import 'package:mandi/data/models/consignment_lot_model.dart';
import 'package:mandi/modules/consignment/providers/consignment_provider.dart';
import 'package:mandi/modules/consignment/views/add_consignment_lot_page.dart';
import 'package:mandi/modules/consignment/views/record_bid_dialog.dart';
import 'package:mandi/modules/invoices/views/create_invoice_page.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Full management screen for crop consignment arrivals (آمد) and Mandi auction bidding (بولی).
class ConsignmentListPage extends StatefulWidget {
  const ConsignmentListPage({super.key});

  @override
  State<ConsignmentListPage> createState() => _ConsignmentListPageState();
}

class _ConsignmentListPageState extends State<ConsignmentListPage> {
  final _searchCtrl = TextEditingController();
  int _selectedFilterIndex = 0; // 0: All, 1: Arrived/Auction, 2: Sold

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shop = shopCtx.currentShop;
    final prov = context.watch<ConsignmentProvider>();

    final query = _searchCtrl.text.trim();
    List<ConsignmentLot> sourceLots =
        query.isEmpty ? prov.lots : prov.search(query);

    List<ConsignmentLot> filtered;
    if (_selectedFilterIndex == 1) {
      filtered = sourceLots
          .where((l) =>
              l.status == ConsignmentLotStatus.arrived ||
              l.status == ConsignmentLotStatus.auctioning)
          .toList();
    } else if (_selectedFilterIndex == 2) {
      filtered = sourceLots
          .where((l) =>
              l.status == ConsignmentLotStatus.sold ||
              l.status == ConsignmentLotStatus.settled)
          .toList();
    } else {
      filtered = sourceLots;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consignments & Auction'),
            Text(
              'آمد مال و نیلامی بولی',
              style: TextStyle(fontSize: 11, color: MColors.gold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Daily Boli Sheet (بولی شیٹ پرنٹ)',
            onPressed: () {
              BoliSheetPdfGenerator.printOrShareBoliSheet(
                lots: prov.todayLots.isNotEmpty ? prov.todayLots : prov.lots,
                date: DateTime.now(),
                shopName: shop?.name ?? 'Mandi Commission Shop',
                shopPhone: shop?.phone,
                shopCity: shop?.city,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Arrival (نئی آمد)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddConsignmentLotPage(),
            ),
          );
        },
      ),
      body: Column(
        children: [
          // KPI Metric Banner
          Padding(
            padding: const EdgeInsets.all(MSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(MSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today Bags',
                            style: MText.caption
                                .copyWith(color: MColors.textOnDarkSub)),
                        const SizedBox(height: 2),
                        Text(
                          '${prov.totalBagsToday}',
                          style: MText.titleMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text('کل بوریاں',
                            style: MText.caption.copyWith(
                                color: MColors.textOnDarkSub, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: MSpacing.xs),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(MSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Manns',
                            style: MText.caption
                                .copyWith(color: MColors.textOnDarkSub)),
                        const SizedBox(height: 2),
                        Text(
                          '${prov.totalMaundsToday.toStringAsFixed(1)} من',
                          style: MText.titleMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text('کل وزن (من)',
                            style: MText.caption.copyWith(
                                color: MColors.textOnDarkSub, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: MSpacing.xs),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(MSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auction Sales',
                            style: MText.caption
                                .copyWith(color: MColors.gold)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${prov.totalSoldAmountToday.toStringAsFixed(0)}',
                          style: MText.titleMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MColors.gold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('کل نیلامی رقم',
                            style: MText.caption.copyWith(
                                color: MColors.textOnDarkSub, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MSpacing.md),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by Lot #, Farmer, Commodity, Vehicle...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: MSpacing.sm),

          // Filter Segment Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MSpacing.md),
            child: Row(
              children: [
                _buildFilterChip(0, 'All (${prov.lots.length})'),
                const SizedBox(width: MSpacing.xs),
                _buildFilterChip(
                  1,
                  'Active Boli (${prov.arrivedLots.length + prov.auctioningLots.length})',
                  activeColor: Colors.orangeAccent,
                ),
                const SizedBox(width: MSpacing.xs),
                _buildFilterChip(
                  2,
                  'Sold (${prov.soldLots.length})',
                  activeColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: MSpacing.sm),

          // Lots List View
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.grass_outlined,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: MSpacing.sm),
                            Text(
                              query.isEmpty
                                  ? 'No consignment lots recorded yet.'
                                  : 'No lots matching "$query"',
                              style: MText.bodyMd.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "New Arrival" below to record a farmer consignment.',
                              style: MText.caption.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          MSpacing.md,
                          MSpacing.xs,
                          MSpacing.md,
                          80, // Space for FAB
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: MSpacing.sm),
                        itemBuilder: (context, index) {
                          final lot = filtered[index];
                          return _ConsignmentLotCard(
                            lot: lot,
                            shopName: shop?.name ?? 'Mandi Commission Shop',
                            shopPhone: shop?.phone,
                            shopCity: shop?.city,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _ConsignmentLotCard extends StatelessWidget {
  final ConsignmentLot lot;
  final String shopName;
  final String? shopPhone;
  final String? shopCity;

  const _ConsignmentLotCard({
    required this.lot,
    required this.shopName,
    this.shopPhone,
    this.shopCity,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(MSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Lot #, Status Chip, Print Slip Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: MColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: MColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      lot.lotNumber,
                      style: MText.caption.copyWith(
                        color: MColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.xs),
                  Text(
                    lot.productName.isNotEmpty ? lot.productName : 'Produce',
                    style: MText.titleMd.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: lot.status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: lot.status.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${lot.status.englishName} (${lot.status.urduName})',
                      style: MText.caption.copyWith(
                        color: lot.status.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_outlined, size: 18),
                    tooltip: 'Print Lot Slip (پرچہ پرنٹ)',
                    onPressed: () {
                      BoliSheetPdfGenerator.printLotSlip(
                        lot: lot,
                        shopName: shopName,
                        shopPhone: shopPhone,
                        shopCity: shopCity,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: MSpacing.xs),

          // Farmer and Vehicle info
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Farmer: ${lot.supplierName.isNotEmpty ? lot.supplierName : 'Direct Farmer'}',
                style: MText.bodySm.copyWith(color: Colors.white70),
              ),
              if (lot.vehicleNumber.isNotEmpty) ...[
                const SizedBox(width: MSpacing.sm),
                const Icon(Icons.local_shipping_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  lot.vehicleNumber,
                  style: MText.bodySm.copyWith(color: Colors.white70),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Bags & Weight metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${lot.bagCount} Bags • ${lot.weightKg.toStringAsFixed(1)} KG (${lot.maunds.toStringAsFixed(1)} من)',
                style: MText.caption.copyWith(color: MColors.textOnDarkSub),
              ),
              if (lot.ratePerMaund > 0)
                Text(
                  'Rs. ${lot.ratePerMaund.toStringAsFixed(0)} / Mann',
                  style: MText.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MColors.gold,
                  ),
                ),
            ],
          ),

          // If Sold, show winning buyer and total
          if (lot.isSold) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Buyer: ${lot.winningBuyerName.isNotEmpty ? lot.winningBuyerName : 'Buyer'}',
                    style: MText.caption.copyWith(color: Colors.greenAccent),
                  ),
                  Text(
                    'Total: Rs. ${lot.estimatedTotal.toStringAsFixed(0)}',
                    style: MText.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: MSpacing.sm),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!lot.isSold) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.gavel_rounded, size: 14),
                  label: const Text('Record Bid (بولی درج کریں)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MColors.gold,
                    side: const BorderSide(color: MColors.gold),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => RecordBidDialog(lot: lot),
                    );
                  },
                ),
              ] else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long, size: 14),
                  label: const Text('Create Invoice (بل بنائیں)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateInvoicePage(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
