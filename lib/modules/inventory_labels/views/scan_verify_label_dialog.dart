// Scan & Verification Terminal Modal for Mandi Barcode & QR Labels
// (*بارکوڈ اور کیو آر اسکیننگ اور تصدیقی ٹرمینل*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/inventory_label_pdf_generator.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/inventory_label_model.dart';
import 'package:mandi/modules/inventory_labels/providers/inventory_label_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class ScanVerifyLabelDialog extends StatefulWidget {
  final String? prefillScanQuery;

  const ScanVerifyLabelDialog({super.key, this.prefillScanQuery});

  @override
  State<ScanVerifyLabelDialog> createState() => _ScanVerifyLabelDialogState();
}

class _ScanVerifyLabelDialogState extends State<ScanVerifyLabelDialog> {
  final _inputCtrl = TextEditingController();
  InventoryLabel? _matchedLabel;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillScanQuery != null &&
        widget.prefillScanQuery!.trim().isNotEmpty) {
      _inputCtrl.text = widget.prefillScanQuery!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performLookup();
      });
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _performLookup() {
    final query = _inputCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _matchedLabel = null;
        _hasSearched = false;
      });
      return;
    }

    final provider = context.read<InventoryLabelProvider>();
    final result = provider.findLabelByScan(query);

    setState(() {
      _matchedLabel = result;
      _hasSearched = true;
    });
  }

  Future<void> _toggleDispatchStatus() async {
    if (_matchedLabel == null) return;
    final provider = context.read<InventoryLabelProvider>();

    final newStatus = _matchedLabel!.isActive
        ? LabelStatus.dispatched
        : LabelStatus.active;

    try {
      await provider.updateLabelStatus(_matchedLabel!.id, newStatus);
      if (!mounted) return;
      setState(() {
        _matchedLabel = provider.findLabelByScan(_matchedLabel!.labelCode);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == LabelStatus.dispatched
                ? 'Pallet ${_matchedLabel!.labelCode} marked as DISPATCHED / SOLD!'
                : 'Pallet ${_matchedLabel!.labelCode} restored to ACTIVE STOCK!',
          ),
          backgroundColor: newStatus == LabelStatus.dispatched
              ? Colors.amber[800]
              : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _printPlacard() async {
    if (_matchedLabel == null) return;
    final shopCtx = context.read<ShopContextProvider>();
    final shop = shopCtx.currentShop;

    await InventoryLabelPdfGenerator.printSinglePalletPlacard(
      label: _matchedLabel!,
      shopName: shop?.name ?? 'Mandi Enterprise',
      shopAddress: shop?.address,
      shopPhone: shop?.phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryLabelProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            Colors.blueAccent.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.lightBlueAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan & Verify Pallet Label',
                            style: MText.bodyMd.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'بارکوڈ اسکینر و تصدیق گودام',
                            style: MText.caption.copyWith(
                              color: Colors.lightBlueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),

              // Barcode / QR Scanner Input Box
              Text(
                'Scan Barcode or Enter Label Code / درج کریں',
                style: MText.caption.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. LBL-2611-0001 or Code128',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.barcode_reader,
                            color: Colors.lightBlueAccent),
                        suffixIcon: _inputCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _inputCtrl.clear();
                                  _performLookup();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Colors.lightBlueAccent.withValues(alpha: 0.5)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) => _performLookup(),
                      onSubmitted: (_) => _performLookup(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _performLookup,
                    child: const Text('Lookup'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick simulated test buttons if any active labels exist
              if (provider.allLabels.isNotEmpty) ...[
                Text(
                  'Quick Test Scanner Pick:',
                  style: MText.caption.copyWith(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: provider.allLabels.take(4).map((lbl) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          label: Text(
                            lbl.labelCode,
                            style: const TextStyle(
                                color: Colors.lightBlueAccent, fontSize: 11),
                          ),
                          onPressed: () {
                            _inputCtrl.text = lbl.labelCode;
                            _performLookup();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Result View
              if (_matchedLabel != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _matchedLabel!.isActive
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.orange.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Code Banner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _matchedLabel!.isActive
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _matchedLabel!.isActive
                                      ? Icons.check_circle_outline
                                      : Icons.local_shipping_outlined,
                                  size: 14,
                                  color: _matchedLabel!.isActive
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _matchedLabel!.status.labelEnglish.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _matchedLabel!.isActive
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _matchedLabel!.labelCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Commodity Title
                      Text(
                        _matchedLabel!.displayCommodity,
                        style: MText.bodyMd.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Location & Party
                      Text(
                        'Location: ${_matchedLabel!.displayLocation.isNotEmpty ? _matchedLabel!.displayLocation : "Unassigned Bay"}',
                        style: const TextStyle(
                            color: Colors.lightBlueAccent, fontSize: 13),
                      ),
                      if (_matchedLabel!.partyName.isNotEmpty)
                        Text(
                          'Party / Grower: ${_matchedLabel!.partyName}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      const SizedBox(height: 10),

                      // Bags & Maund KPI Banner
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Total Bags',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_matchedLabel!.bagCount}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Net Weight',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_matchedLabel!.netWeightKg.toStringAsFixed(0)} KG',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Mandi Maunds',
                                    style: TextStyle(
                                        color: Colors.tealAccent, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_matchedLabel!.netWeightMaunds.toStringAsFixed(2)} Mnds',
                                  style: const TextStyle(
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Barcode & QR Code Graphic
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 40,
                                    child: BarcodeWidget(
                                      barcode: Barcode.code128(),
                                      data: _matchedLabel!.barcodeValue.isNotEmpty
                                          ? _matchedLabel!.barcodeValue
                                          : _matchedLabel!.labelCode,
                                      drawText: true,
                                      style: const TextStyle(fontSize: 8, color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: BarcodeWidget(
                                barcode: Barcode.qrCode(),
                                data: _matchedLabel!.qrPayload.isNotEmpty
                                    ? _matchedLabel!.qrPayload
                                    : _matchedLabel!.labelCode,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _printPlacard,
                              icon: const Icon(Icons.print_outlined, size: 16),
                              label: const Text('Print A4 Placard'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _matchedLabel!.isActive
                                    ? Colors.amber[800]
                                    : Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _toggleDispatchStatus,
                              icon: Icon(
                                _matchedLabel!.isActive
                                    ? Icons.local_shipping
                                    : Icons.restore,
                                size: 16,
                              ),
                              label: Text(
                                _matchedLabel!.isActive
                                    ? 'Mark Dispatched'
                                    : 'Restore to Stock',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (_hasSearched) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No active pallet found matching "${_inputCtrl.text}". Verify the barcode tag or check dispatched records.',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
