// Dialog to Relocate Bay Stock to Another Bay

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/data/models/warehouse_grid_model.dart';
import 'package:mandi/modules/warehouse_grid/providers/warehouse_grid_provider.dart';

class RelocateBayStockDialog extends StatefulWidget {
  final WarehouseGridBayModel sourceBay;

  const RelocateBayStockDialog({super.key, required this.sourceBay});

  @override
  State<RelocateBayStockDialog> createState() => _RelocateBayStockDialogState();
}

class _RelocateBayStockDialogState extends State<RelocateBayStockDialog> {
  String? _targetBayId;
  bool _isRelocating = false;

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppStrings.isUrdu(context);
    final provider = context.watch<WarehouseGridProvider>();
    final targetBays = provider.bays
        .where((b) => b.id != widget.sourceBay.id && b.currentBags == 0)
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isUrdu
                  ? 'خانہ ${widget.sourceBay.bayCode} سے مال کی منتقلی'
                  : 'Relocate Stock from Bay ${widget.sourceBay.bayCode}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUrdu
                ? '${widget.sourceBay.currentBags} بوریاں ${widget.sourceBay.cropName ?? 'مال'} (کسان: ${widget.sourceBay.farmerName ?? 'نامعلوم'})'
                : 'Moving ${widget.sourceBay.currentBags} Bags of ${widget.sourceBay.cropName ?? 'Commodity'} (Farmer: ${widget.sourceBay.farmerName ?? 'N/A'})',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            isUrdu ? 'نیا خالی خانہ منتخب کریں:' : 'Select Destination Empty Bay:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (targetBays.isEmpty)
            Text(
              isUrdu
                  ? 'منتقلی کے لیے اس چیمبر میں کوئی خالی خانہ دستیاب نہیں۔'
                  : 'No empty bays available in this chamber for relocation.',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _targetBayId ?? targetBays.first.id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grid_view),
              ),
              items: targetBays.map((b) {
                return DropdownMenuItem<String>(
                  value: b.id,
                  child: Text(
                    isUrdu
                        ? 'خانہ ${b.bayCode} (گنجائش: ${b.maxCapacityBags} بوریاں)'
                        : 'Bay ${b.bayCode} (Capacity: ${b.maxCapacityBags} Bags)',
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _targetBayId = val);
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isRelocating ? null : () => Navigator.pop(context),
          child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isRelocating || targetBays.isEmpty)
              ? null
              : () async {
                  final target = _targetBayId ?? targetBays.first.id;
                  setState(() => _isRelocating = true);

                  final success = await provider.relocateStock(
                    sourceBayId: widget.sourceBay.id,
                    targetBayId: target,
                  );

                  setState(() => _isRelocating = false);

                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isUrdu
                              ? 'مال کامیابی کے ساتھ دوسرے خانے میں منتقل ہو گیا!'
                              : 'Stock Relocated Successfully!',
                        ),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage ?? (isUrdu ? 'منتقلی میں خرابی' : 'Relocation failed')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[900]),
          child: _isRelocating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  isUrdu ? 'منتقل کریں' : 'Confirm Relocate',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
