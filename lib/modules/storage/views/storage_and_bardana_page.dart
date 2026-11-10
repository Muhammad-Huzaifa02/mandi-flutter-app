import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/storage_and_bardana_pdf_generator.dart';
import 'package:mandi/data/models/bardana_model.dart';
import 'package:mandi/data/models/storage_allocation_model.dart';
import 'package:mandi/data/models/storage_location_model.dart';
import 'package:mandi/modules/storage/providers/storage_provider.dart';
import 'package:mandi/modules/storage/views/add_edit_storage_location_dialog.dart';
import 'package:mandi/modules/storage/views/allocate_stock_dialog.dart';
import 'package:mandi/modules/storage/views/record_bardana_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Primary Mandi Storage Hub: Godowns, Cold Stores, and Bardana Sacks Ledger.
class StorageAndBardanaPage extends StatefulWidget {
  const StorageAndBardanaPage({super.key});

  @override
  State<StorageAndBardanaPage> createState() => _StorageAndBardanaPageState();
}

class _StorageAndBardanaPageState extends State<StorageAndBardanaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _numberFmt = NumberFormat('#,##0', 'en_US');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  // Bardana filter
  String _bardanaFilter = 'all'; // 'all', 'pending', 'overdue', 'returned'
  String _bardanaSearch = '';
  final _bardanaSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bardanaSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(
    String shopName,
    StorageProvider storageProv,
  ) async {
    try {
      final Uint8List pdfBytes;
      final String docName;

      if (_tabController.index == 0) {
        pdfBytes =
            await StorageAndBardanaPdfGenerator.generateStorageReportPdf(
          shopName: shopName,
          locations: storageProv.locations,
          allocations: storageProv.allocations,
        );
        docName =
            'Storage_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      } else {
        pdfBytes =
            await StorageAndBardanaPdfGenerator.generateBardanaReportPdf(
          shopName: shopName,
          transactions: storageProv.bardanaTransactions,
        );
        docName =
            'Bardana_Ledger_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      }

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: docName,
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

  @override
  Widget build(BuildContext context) {
    final storageProv = context.watch<StorageProvider>();
    final shopCtx = context.watch<ShopContextProvider>();
    final shopName = shopCtx.currentShop?.name ?? 'Mandi Commission Shop';

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Godowns, Cold Storage & Bardana',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'گودام، کولڈ سٹوریج اور باردانہ کھاتہ',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF Report',
            onPressed: () => _exportPdf(shopName, storageProv),
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
              icon: const Icon(Icons.warehouse),
              text: 'Godowns & Stores (${storageProv.locations.length})',
            ),
            Tab(
              icon: const Icon(Icons.shopping_bag_outlined),
              text:
                  'Bardana Sacks (${storageProv.bardanaSummary.netPendingWithParties} Out)',
            ),
          ],
        ),
      ),
      body: storageProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStorageTab(storageProv),
                _buildBardanaTab(storageProv),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            showDialog(
              context: context,
              builder: (_) => const AllocateStockDialog(),
            );
          } else {
            showDialog(
              context: context,
              builder: (_) => const RecordBardanaDialog(
                defaultDirection: BardanaDirection.issued,
              ),
            );
          }
        },
        backgroundColor: MColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0
              ? 'Store Crop Batch'
              : 'Issue / Return Bardana',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Tab 0: Godowns & Cold Storage ──────────────────────────────────────────

  Widget _buildStorageTab(StorageProvider storageProv) {
    final locations = storageProv.locations;
    final allocations = storageProv.allocations;

    return RefreshIndicator(
      onRefresh: () async {
        final shopId = context.read<ShopContextProvider>().currentShopId;
        storageProv.updateShop(shopId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── KPI Summary Ribbon ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Bags in Storage',
                  subtitle: 'کل موجود بوریاں',
                  value:
                      '${_numberFmt.format(storageProv.totalBagsInStorage)} Bags',
                  color: MColors.primaryLight,
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Storage Utilization',
                  subtitle:
                      'Total: ${_numberFmt.format(storageProv.totalStorageCapacity)} Bags',
                  value:
                      '${(storageProv.overallUtilization * 100).toStringAsFixed(1)}%',
                  color: Colors.blueAccent,
                  icon: Icons.pie_chart_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Cold Storage Stock',
                  subtitle: 'پھل اور آلو کولڈ سٹور',
                  value:
                      '${_numberFmt.format(storageProv.totalColdStorageBags)} Bags',
                  color: Colors.teal,
                  icon: Icons.ac_unit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Est. Accrued Rent',
                  subtitle: 'گودام و سٹور کرایہ',
                  value:
                      'Rs. ${_currencyFmt.format(storageProv.totalEstimatedAccruedRent)}',
                  color: MColors.gold,
                  icon: Icons.monetization_on_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Facilities Header & Action ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storage Facilities & Godowns (${locations.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const AddEditStorageLocationDialog(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Facility'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (locations.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.warehouse_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'No storage facilities configured',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add your Mandi Godown, Cold Store, or Shop Pharr to track bags.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...locations.map((loc) => _buildLocationCard(loc, storageProv)),

          const SizedBox(height: 24),

          // ── Active Crop Batches in Storage ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Crop Batches in Storage (${storageProv.activeAllocations.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const AllocateStockDialog(),
                ),
                icon: const Icon(Icons.move_to_inbox_outlined, size: 18),
                label: const Text('Store Batch'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (allocations.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'No crop batches currently stored.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else
            ...allocations.map((alloc) => _buildAllocationCard(alloc, storageProv)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    StorageLocation loc,
    StorageProvider storageProv,
  ) {
    Color typeColor;
    switch (loc.type) {
      case StorageLocationType.coldStorage:
        typeColor = Colors.teal;
        break;
      case StorageLocationType.shopPharr:
        typeColor = MColors.gold;
        break;
      case StorageLocationType.godown:
        typeColor = MColors.primaryLight;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: MRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.warehouse_outlined,
                        color: typeColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      loc.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        loc.typeLabelEnglish,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => AddEditStorageLocationDialog(
                              existingLocation: loc,
                            ),
                          );
                        } else if (action == 'store') {
                          showDialog(
                            context: context,
                            builder: (_) => AllocateStockDialog(
                              preselectedLocationId: loc.id,
                            ),
                          );
                        } else if (action == 'delete') {
                          _confirmDeleteLocation(loc, storageProv);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'store',
                          child: Row(
                            children: [
                              Icon(Icons.move_to_inbox, size: 16),
                              SizedBox(width: 8),
                              Text('Store Crops Here'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Facility'),
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
                              Text('Delete',
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
            const SizedBox(height: 10),

            // Progress bar for capacity
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: loc.utilizationRatio,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  loc.utilizationRatio > 0.9 ? MColors.danger : typeColor,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_numberFmt.format(loc.currentBags)} / ${_numberFmt.format(loc.capacityBags)} Bags (${(loc.utilizationRatio * 100).toStringAsFixed(0)}% full)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_numberFmt.format(loc.availableCapacityBags)} Bags Available',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),

            if (loc.monthlyRentPerBag > 0 || loc.contactPerson.isNotEmpty) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.contactPerson.isNotEmpty
                        ? 'Manager: ${loc.contactPerson} (${loc.phone})'
                        : loc.address,
                    style:
                        TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                  if (loc.monthlyRentPerBag > 0)
                    Text(
                      'Rent: Rs. ${_currencyFmt.format(loc.monthlyRentPerBag)} / bag / month',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: MColors.primary,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationCard(
    StorageAllocation alloc,
    StorageProvider storageProv,
  ) {
    final isInStore = alloc.status == AllocationStatus.inStore;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: MRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: MColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alloc.productName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: MColors.primary,
                        ),
                      ),
                    ),
                    if (alloc.lotNumber.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '#${alloc.lotNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isInStore
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alloc.statusLabelEnglish,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isInStore
                          ? Colors.green.shade900
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alloc.partyName.isNotEmpty
                          ? alloc.partyName
                          : 'General Mandi Stock',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      'Store: ${alloc.storageLocationName ?? 'Facility'}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${alloc.bagCount} Bags',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: MColors.primary,
                      ),
                    ),
                    if (alloc.weightKg > 0)
                      Text(
                        '${alloc.maunds.toStringAsFixed(1)} Maunds (${_numberFmt.format(alloc.weightKg)} KG)',
                        style: TextStyle(
                            fontSize: 10.5, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ],
            ),

            const Divider(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inward: ${_dateFmt.format(alloc.inwardDate)} (${alloc.daysInStorage} days)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                if (isInStore)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _confirmDispatchStock(alloc, storageProv),
                    icon: const Icon(Icons.outbox_outlined, size: 14),
                    label: const Text('Dispatch / Release',
                        style: TextStyle(fontSize: 11.5)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDispatchStock(
    StorageAllocation alloc,
    StorageProvider storageProv,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dispatch / Release Batch?'),
        content: Text(
          'Mark ${alloc.bagCount} bags of ${alloc.productName} as dispatched from storage? This will free up facility capacity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await storageProv.dispatchOrReleaseStock(
                allocationId: alloc.id,
                locationId: alloc.storageLocationId,
                bagsDispatched: alloc.bagCount,
                newStatus: 'dispatched',
                totalRentCharged: alloc.estimatedAccruedRent,
              );
            },
            child: const Text('Confirm Dispatch'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLocation(
    StorageLocation loc,
    StorageProvider storageProv,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Storage Facility?'),
        content: Text(
          'Are you sure you want to delete ${loc.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              await storageProv.deleteLocation(loc.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Bardana Sacks & Crates Ledger ───────────────────────────────────

  Widget _buildBardanaTab(StorageProvider storageProv) {
    final summary = storageProv.bardanaSummary;
    final txs = storageProv.bardanaTransactions.where((t) {
      if (_bardanaFilter == 'pending' && t.status != BardanaStatus.pending) {
        return false;
      }
      if (_bardanaFilter == 'overdue' && !t.isOverdue) {
        return false;
      }
      if (_bardanaFilter == 'returned' && t.status != BardanaStatus.returned) {
        return false;
      }
      if (_bardanaSearch.trim().isNotEmpty) {
        final q = _bardanaSearch.toLowerCase();
        final matchesParty = t.partyName.toLowerCase().contains(q);
        final matchesType = t.bardanaType.name.toLowerCase().contains(q);
        if (!matchesParty && !matchesType) return false;
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        final shopId = context.read<ShopContextProvider>().currentShopId;
        storageProv.updateShop(shopId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── KPI Summary Ribbon ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Net Out in Market',
                  subtitle: 'واپسی باقی بوریاں',
                  value:
                      '${_numberFmt.format(summary.netPendingWithParties)} Bags',
                  color: summary.netPendingWithParties > 0
                      ? Colors.orange.shade800
                      : MColors.primaryLight,
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Returned',
                  subtitle: 'واپس موصول شدہ',
                  value:
                      '${_numberFmt.format(summary.totalReturnedCount)} Bags',
                  color: MColors.primaryLight,
                  icon: Icons.assignment_turned_in_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Deposit at Risk',
                  subtitle: 'سیکیورٹی رقم',
                  value:
                      'Rs. ${_currencyFmt.format(summary.totalDepositReceivable)}',
                  color: Colors.blueGrey.shade800,
                  icon: Icons.monetization_on_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Overdue Returns',
                  subtitle: 'تاخیر شدہ باردانہ',
                  value: '${_numberFmt.format(summary.totalOverdueCount)} Bags',
                  color: summary.totalOverdueCount > 0
                      ? MColors.danger
                      : Colors.grey,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search & Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bardanaSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search Party Name...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _bardanaSearch.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _bardanaSearchCtrl.clear();
                              setState(() => _bardanaSearch = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (v) => setState(() => _bardanaSearch = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBardanaFilterChip(
                  'All (${storageProv.bardanaTransactions.length})',
                  'all',
                ),
                const SizedBox(width: 6),
                _buildBardanaFilterChip(
                  'Pending (${summary.netPendingWithParties})',
                  'pending',
                ),
                const SizedBox(width: 6),
                _buildBardanaFilterChip(
                  'Overdue (${summary.totalOverdueCount})',
                  'overdue',
                ),
                const SizedBox(width: 6),
                _buildBardanaFilterChip(
                  'Returned (${summary.totalReturnedCount})',
                  'returned',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (txs.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'No Bardana records found',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap "+ Issue / Return Bardana" below to record sacks and crates.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...txs.map((tx) => _buildBardanaCard(tx, storageProv)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBardanaFilterChip(String label, String value) {
    final isSelected = _bardanaFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: MColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? MColors.primary : null,
      ),
      onSelected: (v) {
        if (v) setState(() => _bardanaFilter = value);
      },
    );
  }

  Widget _buildBardanaCard(BardanaTransaction tx, StorageProvider storageProv) {
    final isIssue = tx.direction == BardanaDirection.issued;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: MRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isIssue
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tx.directionLabelEnglish,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isIssue
                              ? Colors.orange.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tx.bardanaTypeLabelEnglish,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: tx.isOverdue
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.statusLabelUrdu,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: tx.isOverdue ? MColors.danger : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tx.partyName.isNotEmpty ? tx.partyName : 'Party',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${tx.bagCount} Bags',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIssue ? Colors.orange.shade900 : MColors.primary,
                  ),
                ),
              ],
            ),

            if (tx.unitDepositRate > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Security: Rs. ${_currencyFmt.format(tx.unitDepositRate)}/bag (Total: Rs. ${_currencyFmt.format(tx.totalDepositAmount)})',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],

            const Divider(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${_dateFmt.format(tx.transactionDate)}${tx.dueReturnDate != null ? ' | Due: ${_dateFmt.format(tx.dueReturnDate!)}' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: tx.isOverdue ? MColors.danger : Colors.grey.shade600,
                    fontWeight:
                        tx.isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isIssue && tx.status == BardanaStatus.pending)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      await storageProv.updateBardanaStatus(
                        id: tx.id,
                        status: 'returned',
                      );
                    },
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Mark Returned',
                        style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: MRadius.md,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
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
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
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
    );
  }
}
