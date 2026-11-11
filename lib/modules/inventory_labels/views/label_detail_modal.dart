// Modal Bottom Sheet for Viewing, Zooming & Printing an Inventory Label
// (*لیبل تفصیل، بڑا بارکوڈ اور پرنٹ شیٹ*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/inventory_label_pdf_generator.dart';
import 'package:mandi/data/models/inventory_label_model.dart';
import 'package:mandi/modules/inventory_labels/providers/inventory_label_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class LabelDetailModal extends StatelessWidget {
  final InventoryLabel label;

  const LabelDetailModal({super.key, required this.label});

  static void show(BuildContext context, InventoryLabel label) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LabelDetailModal(label: label),
    );
  }

  Future<void> _printPlacard(BuildContext context) async {
    final shopCtx = context.read<ShopContextProvider>();
    final shop = shopCtx.currentShop;

    await InventoryLabelPdfGenerator.printSinglePalletPlacard(
      label: label,
      shopName: shop?.name ?? 'Mandi Enterprise',
      shopAddress: shop?.address,
      shopPhone: shop?.phone,
    );
  }

  Future<void> _toggleStatus(BuildContext context) async {
    final provider = context.read<InventoryLabelProvider>();
    final newStatus =
        label.isActive ? LabelStatus.dispatched : LabelStatus.active;

    try {
      await provider.updateLabelStatus(label.id, newStatus);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == LabelStatus.dispatched
                  ? 'Label ${label.labelCode} marked as Dispatched!'
                  : 'Label ${label.labelCode} marked as Active Stock!',
            ),
            backgroundColor: newStatus == LabelStatus.dispatched
                ? Colors.amber[800]
                : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MColors.surfaceDark,
        title: const Text('Delete Label?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to permanently delete label ${label.labelCode}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<InventoryLabelProvider>();
      await provider.deleteLabel(label.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Label ${label.labelCode} deleted.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag indicator handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: label.isActive
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label.status.labelEnglish.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: label.isActive
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label.labelType.labelEnglish,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  label.labelCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Big Barcode & QR Display Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Code128 Barcode
                  SizedBox(
                    height: 60,
                    child: BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: label.barcodeValue.isNotEmpty
                          ? label.barcodeValue
                          : label.labelCode,
                      drawText: true,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.black26, height: 1),
                  const SizedBox(height: 12),

                  // 2D QR Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: BarcodeWidget(
                          barcode: Barcode.qrCode(),
                          data: label.qrPayload.isNotEmpty
                              ? label.qrPayload
                              : label.labelCode,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.displayCommodity,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${label.bagCount} Bags (${label.packageType.labelEnglish})',
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${label.netWeightMaunds.toStringAsFixed(2)} Maunds (${label.netWeightKg.toStringAsFixed(0)} KG)',
                            style: TextStyle(
                              color: Colors.teal[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Detail Cards
            _detailRow('Commodity / جنس:', label.displayCommodity),
            _detailRow('Quality Grade:', label.qualityGrade.toUpperCase().replaceAll('_', ' ')),
            _detailRow('Packaging Type:', label.packageType.labelEnglish),
            _detailRow('Location / گودام:', label.displayLocation.isNotEmpty ? label.displayLocation : 'General Yard'),
            if (label.partyName.isNotEmpty)
              _detailRow('Party / Grower:', label.partyName),
            if (label.vehicleNumber.isNotEmpty)
              _detailRow('Vehicle #:', label.vehicleNumber),
            _detailRow('Gross Weight:', '${label.grossWeightKg.toStringAsFixed(0)} KG'),
            _detailRow('Net Certified Weight:', '${label.netWeightKg.toStringAsFixed(0)} KG (${label.netWeightMaunds.toStringAsFixed(2)} Maunds)'),
            if (label.notes.isNotEmpty)
              _detailRow('Notes:', label.notes),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _printPlacard(context),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Print A4 Placard'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: label.isActive
                          ? Colors.amber[800]
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _toggleStatus(context),
                    icon: Icon(
                      label.isActive ? Icons.local_shipping : Icons.restore,
                      size: 18,
                    ),
                    label: Text(label.isActive ? 'Mark Dispatched' : 'Restore Stock'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
