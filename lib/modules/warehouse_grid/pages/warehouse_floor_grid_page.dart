// Visual 2D Godown & Cold Storage Floor Grid Page
// (*گودام اور کولڈ سٹوریج کا تصویری نقشہ*).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/theme/locale_provider.dart';
import 'package:mandi/core/widgets/liquid_crystal_background.dart';
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

  List<Map<String, String>> _chambers(bool isUrdu) => isUrdu
      ? const [
          {'code': 'CH-1', 'title': 'چیمبر 1 (گندم گودام)'},
          {'code': 'CH-2', 'title': 'چیمبر 2 (چاول گودام)'},
          {'code': 'Cold-A', 'title': 'کولڈ سٹور A (آلو اور بیج)'},
        ]
      : const [
          {'code': 'CH-1', 'title': 'Chamber 1 (Wheat & Grain)'},
          {'code': 'CH-2', 'title': 'Chamber 2 (Basmati Rice)'},
          {'code': 'Cold-A', 'title': 'Cold Store A (Potatoes & Seeds)'},
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

    return LiquidCrystalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppStrings.tr(context, 'warehouse_grid_title'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: MColors.textPrimary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: MColors.textPrimary),
          actions: [
            IconButton(
              icon: const Icon(Icons.print, color: MColors.textPrimary),
              tooltip: AppStrings.val(context, en: 'Print Floor Occupancy Report', ur: 'گودام رپورٹ پرنٹ کریں'),
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
                    Text(
                      '${AppStrings.tr(context, 'select_chamber')}:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: provider.selectedChamber,
                          items: _chambers(context.watch<LocaleProvider>().isUrdu).map((c) {
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
                    title: AppStrings.tr(context, 'total_capacity'),
                    value: '${_numberFmt.format(provider.totalCapacityBags)} ${AppStrings.val(context, en: 'Bags', ur: 'بوریاں')}',
                    subtitle: '${provider.bays.length} ${AppStrings.val(context, en: 'Total Bays', ur: 'کل خانے')}',
                    icon: Icons.grid_view,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: AppStrings.tr(context, 'stored_stock'),
                    value: '${_numberFmt.format(provider.totalStoredBags)} ${AppStrings.val(context, en: 'Bags', ur: 'بوریاں')}',
                    subtitle: '${provider.overallOccupancyPercent.toStringAsFixed(1)}% ${AppStrings.val(context, en: 'Full', ur: 'بھرپور')}',
                    icon: Icons.inventory_2,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: AppStrings.tr(context, 'active_bays'),
                    value: '${provider.occupiedBaysCount} / ${provider.bays.length}',
                    subtitle: '${provider.emptyBaysCount} ${AppStrings.val(context, en: 'Empty', ur: 'خالی')}',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: AppStrings.val(context, en: 'Overdue >90 Days', ur: 'میعاد 90 دن سے زائد'),
                    value: '${provider.overdueBaysCount} ${AppStrings.val(context, en: 'Bays', ur: 'خانے')}',
                    subtitle: AppStrings.val(context, en: 'Warning Alert', ur: 'انتباہ'),
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
                          '${AppStrings.tr(context, 'floor_plan')}: ${provider.selectedChamber}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        // Legend
                        Row(
                          children: [
                            _buildLegendItem(Colors.grey.shade300, AppStrings.val(context, en: 'Empty', ur: 'خالی')),
                            const SizedBox(width: 8),
                            _buildLegendItem(Colors.amber.shade300, AppStrings.val(context, en: 'Partial', ur: 'جزوی')),
                            const SizedBox(width: 8),
                            _buildLegendItem(Colors.teal.shade600, AppStrings.val(context, en: 'Full', ur: 'مکمل')),
                            const SizedBox(width: 8),
                            _buildLegendItem(Colors.red.shade600, AppStrings.val(context, en: '>90d Overdue', ur: '>90 دن زائد')),
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
              bay.currentBags > 0
                  ? '${bay.currentBags} ${AppStrings.val(context, en: 'Bags', ur: 'بوریاں')}'
                  : AppStrings.val(context, en: 'Empty', ur: 'خالی'),
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
                          bay.cropName ?? AppStrings.val(context, en: 'Empty Bay', ur: 'خالی خانہ'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (bay.farmerName != null)
                          Text('${AppStrings.val(context, en: 'Farmer', ur: 'زمیندار')}: ${bay.farmerName} • ${AppStrings.val(context, en: 'Lot', ur: 'لاٹ')}: ${bay.lotCode ?? '-'}',
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
                      AppStrings.val(
                        context,
                        en: 'OVERDUE >90 DAYS (${bay.daysInStorage}d)',
                        ur: 'میعاد 90 دن سے زائد (${bay.daysInStorage} دن)',
                      ),
                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  )
                else
                  Text(
                    bay.currentBags > 0
                        ? (AppStrings.isUrdu(context)
                            ? '${bay.daysInStorage} دن گودام میں'
                            : '${bay.daysInStorage} Days in Store')
                        : AppStrings.val(context, en: 'Ready to Store', ur: 'خالی اور تیار'),
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
                _buildBayDetailItem(AppStrings.val(context, en: 'Current Bags', ur: 'موجودہ بوریاں'), '${bay.currentBags} / ${bay.maxCapacityBags}'),
                _buildBayDetailItem(AppStrings.val(context, en: 'Occupancy', ur: 'گنجائش کا استعمال'), '${bay.occupancyPercent.toStringAsFixed(1)}%'),
                _buildBayDetailItem(AppStrings.val(context, en: 'Storage Date', ur: 'آمد تاریخ'), bay.formattedStartDate),
                _buildBayDetailItem(AppStrings.val(context, en: 'Chamber', ur: 'چیمبر'), bay.chamberCode),
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
                    bay.currentBags > 0 ? AppStrings.tr(context, 'edit_stock_btn') : AppStrings.tr(context, 'store_crop_btn'),
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
                    label: Text(AppStrings.tr(context, 'relocate_stock_btn'), style: const TextStyle(color: Colors.white, fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[900]),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(AppStrings.val(ctx, en: 'Clear Bay Stock?', ur: 'خانے کا اسٹاک خالی کریں؟')),
                          content: Text(AppStrings.val(
                            ctx,
                            en: 'Confirm checkout / dispatch of all ${bay.currentBags} bags from Bay ${bay.bayCode}?',
                            ur: 'کیا آپ خانہ ${bay.bayCode} سے تمام ${bay.currentBags} بوریاں نکالنے کی تصدیق کرتے ہیں؟',
                          )),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.tr(ctx, 'cancel'))),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: Text(AppStrings.tr(ctx, 'clear_bay_btn'), style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await provider.clearBay(bay.id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                    label: Text(AppStrings.tr(context, 'clear_bay_btn'), style: const TextStyle(color: Colors.red, fontSize: 13)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      constraints: const BoxConstraints(minHeight: AppDimensions.kpiCardMinHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 9.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Icon(icon, color: color.shade700, size: 15),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color.shade900),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black45, fontSize: 8.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
