// Visual 2D Godown & Cold Storage Floor Grid Page
// (*گودام اور کولڈ سٹوریج کا تصویری نقشہ*).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import 'package:mandi/data/models/warehouse_grid_model.dart';
import 'package:mandi/modules/warehouse_grid/providers/warehouse_grid_provider.dart';
import 'package:mandi/modules/warehouse_grid/dialogs/store_crop_in_bay_dialog.dart';
import 'package:mandi/modules/warehouse_grid/dialogs/relocate_bay_stock_dialog.dart';
import 'package:mandi/core/utils/warehouse_grid_pdf_generator.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class WarehouseFloorGridPage extends StatefulWidget {
  const WarehouseFloorGridPage({super.key});

  @override
  State<WarehouseFloorGridPage> createState() => _WarehouseFloorGridPageState();
}

class _WarehouseFloorGridPageState extends State<WarehouseFloorGridPage> {
  final _numberFmt = NumberFormat('#,##0', 'en_US');

  final List<Map<String, String>> _chambers = [
    {'code': 'CH-1', 'title': 'Chamber 1 (Wheat & Grain / گندم گودام)'},
    {'code': 'CH-2', 'title': 'Chamber 2 (Basmati Rice / چاول گودام)'},
    {'code': 'Cold-A', 'title': 'Cold Store A (Potatoes & Seeds / کولڈ سٹوریج)'},
  ];

  Future<void> _printReport(WarehouseGridProvider provider, String shopName, String? shopPhone) async {
    final pdfBytes = await WarehouseGridPdfGenerator.generateWarehouseOccupancyReportPdf(
      bays: provider.bays,
      chamberCode: provider.selectedChamber,
      shopName: shopName,
      shopPhone: shopPhone,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Warehouse_Grid_${provider.selectedChamber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shopName = shopCtx.currentShop?.name ?? 'Mandi Commission Shop';
    final shopPhone = shopCtx.currentShop?.phone;

    final provider = context.watch<WarehouseGridProvider>();
    final selectedBay = provider.selectedBay;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Visual 2D Godown Grid (گودام تصویری نقشہ)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Print Floor Occupancy Report',
            onPressed: provider.bays.isEmpty ? null : () => _printReport(provider, shopName, shopPhone),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chamber Selector Row
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.warehouse, color: Colors.teal),
                    const SizedBox(width: 10),
                    const Text(
                      'Chamber / سیکشن:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: provider.selectedChamber,
                          items: _chambers.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['code'],
                              child: Text(
                                c['title']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (newChamber) {
                            if (newChamber != null) {
                              provider.switchChamber(newChamber);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Top KPI Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Capacity / گنجائش',
                    value: '${_numberFmt.format(provider.totalCapacityBags)} Bags',
                    subtitle: '${provider.bays.length} Total Bays',
                    icon: Icons.grid_view,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Stored Stock / موجودہ مال',
                    value: '${_numberFmt.format(provider.totalStoredBags)} Bags',
                    subtitle: '${provider.overallOccupancyPercent.toStringAsFixed(1)}% Full',
                    icon: Icons.inventory_2,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Active Bays / زیر استعمال',
                    value: '${provider.occupiedBaysCount} / ${provider.bays.length}',
                    subtitle: '${provider.emptyBaysCount} Empty',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Overdue >90 Days',
                    value: '${provider.overdueBaysCount} Bays',
                    subtitle: 'Warning Alert',
                    icon: Icons.warning_amber,
                    color: provider.overdueBaysCount > 0 ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2D Visual Grid Matrix
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '2D FLOOR PLAN: ${provider.selectedChamber} (گودام لے آؤٹ)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        // Legend
                        Row(
                          children: [
                            _buildLegendItem(Colors.grey.shade300, 'Empty'),
                            const SizedBox(width: 8),
                            _buildLegendItem(Colors.amber.shade300, 'Partial'),
                            const SizedBox(width: 8),
                            _buildLegendItem(Colors.teal.shade600, 'Full'),
                            const SizedBox(width: 8),
                            _buildLegendItem(Colors.red.shade600, '>90d Overdue'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Grid View
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        childAspectRatio: 1.15,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: provider.bays.length,
                      itemBuilder: (ctx, idx) {
                        final bay = provider.bays[idx];
                        final isSelected = selectedBay?.id == bay.id;
                        return _buildBayCell(context, bay, isSelected, provider);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bay Inspector Card (When Bay is tapped)
            if (selectedBay != null)
              _buildBayInspectorCard(context, selectedBay, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildBayCell(BuildContext context, WarehouseGridBayModel bay,
      bool isSelected, WarehouseGridProvider provider) {
    Color bgColor;
    Color borderColor;

    if (bay.isOverdue) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade700;
    } else if (bay.isFull) {
      bgColor = Colors.teal.shade50;
      borderColor = Colors.teal.shade800;
    } else if (bay.currentBags > 0) {
      bgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade700;
    } else {
      bgColor = Colors.white;
      borderColor = Colors.grey.shade300;
    }

    return InkWell(
      onTap: () => provider.selectBay(bay),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade100 : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.teal.shade900 : borderColor,
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.teal.withAlpha(80), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bay.bayCode,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isSelected ? Colors.teal.shade900 : Colors.black87,
                  ),
                ),
                if (bay.isOverdue)
                  const Icon(Icons.warning, color: Colors.red, size: 14)
                else if (bay.currentBags > 0)
                  Icon(Icons.inventory, color: Colors.teal.shade800, size: 14),
              ],
            ),
            const Spacer(),
            Text(
              bay.currentBags > 0 ? '${bay.currentBags} Bags' : 'Empty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: bay.currentBags > 0 ? Colors.black87 : Colors.grey,
              ),
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: bay.occupancyRatio,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  bay.isOverdue
                      ? Colors.red
                      : (bay.isFull ? Colors.teal : Colors.amber.shade700),
                ),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBayInspectorCard(
      BuildContext context, WarehouseGridBayModel bay, WarehouseGridProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.teal.shade700, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bay ${bay.bayCode}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bay.cropName ?? 'Empty Bay / کوئی مال نہیں',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (bay.farmerName != null)
                          Text('Farmer: ${bay.farmerName} • Lot: ${bay.lotCode ?? '-'}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                if (bay.isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      'OVERDUE >90 DAYS (${bay.daysInStorage}d)',
                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  )
                else
                  Text(
                    bay.currentBags > 0 ? '${bay.daysInStorage} Days in Store' : 'Ready to Store',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBayDetailItem('Current Bags', '${bay.currentBags} / ${bay.maxCapacityBags}'),
                _buildBayDetailItem('Occupancy', '${bay.occupancyPercent.toStringAsFixed(1)}%'),
                _buildBayDetailItem('Storage Date', bay.formattedStartDate),
                _buildBayDetailItem('Chamber', bay.chamberCode),
              ],
            ),
            const SizedBox(height: 14),

            // Actions for the Bay
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => StoreCropInBayDialog(bay: bay),
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                  label: Text(
                    bay.currentBags > 0 ? 'Edit Stock (تبدیل)' : 'Store Crop (مال رکھیں)',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
                ),
                if (bay.currentBags > 0) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => RelocateBayStockDialog(sourceBay: bay),
                    ),
                    icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 16),
                    label: const Text('منتقل کریں (Relocate)', style: TextStyle(color: Colors.white, fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[900]),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear Bay Stock?'),
                          content: Text('Confirm checkout / dispatch of all ${bay.currentBags} bags from Bay ${bay.bayCode}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Clear Bay', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await provider.clearBay(bay.id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                    label: const Text('خالی کریں (Clear)', style: TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBayDetailItem(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 10), maxLines: 1),
              ),
              Icon(icon, color: color.shade700, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color.shade900),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.black38, fontSize: 9)),
        ],
      ),
    );
  }
}
