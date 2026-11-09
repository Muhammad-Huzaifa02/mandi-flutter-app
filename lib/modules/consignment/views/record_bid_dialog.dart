import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/consignment_lot_model.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/consignment/providers/consignment_provider.dart';

/// Modal dialog to record the winning bid and auction details for a consignment lot.
class RecordBidDialog extends StatefulWidget {
  final ConsignmentLot lot;

  const RecordBidDialog({super.key, required this.lot});

  @override
  State<RecordBidDialog> createState() => _RecordBidDialogState();
}

class _RecordBidDialogState extends State<RecordBidDialog> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  late TextEditingController _rateCtrl;
  late TextEditingController _weightCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rateCtrl = TextEditingController(
      text: widget.lot.ratePerMaund > 0
          ? widget.lot.ratePerMaund.toStringAsFixed(0)
          : '',
    );
    _weightCtrl = TextEditingController(
      text: widget.lot.weightKg > 0
          ? widget.lot.weightKg.toStringAsFixed(1)
          : '',
    );

    final customers = context.read<CustomerProvider>().customers;
    if (widget.lot.winningBuyerId != null) {
      final match = customers.where((c) => c.id == widget.lot.winningBuyerId);
      if (match.isNotEmpty) _selectedCustomer = match.first;
    }
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double get _currentWeight =>
      double.tryParse(_weightCtrl.text.trim()) ?? widget.lot.weightKg;
  double get _currentRate => double.tryParse(_rateCtrl.text.trim()) ?? 0.0;
  double get _currentMaunds => _currentWeight > 0 ? (_currentWeight / 40.0) : 0.0;
  double get _totalAuctionValue => _currentMaunds * _currentRate;

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: MColors.gold),
          const SizedBox(width: MSpacing.xs),
          Expanded(
            child: Text(
              'Record Auction Bid: ${widget.lot.lotNumber}',
              style: MText.titleMd.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farmer: ${widget.lot.supplierName} • ${widget.lot.productName}',
                style: MText.bodySm.copyWith(color: MColors.textOnDarkSub),
              ),
              const SizedBox(height: MSpacing.md),

              // Winning Buyer (Customer) Selector
              DropdownButtonFormField<Customer>(
                initialValue: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'Winning Buyer / Customer (خریدار) *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} (${c.phone})'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCustomer = val),
                validator: (val) =>
                    val == null ? 'Please select a winning buyer' : null,
              ),
              const SizedBox(height: MSpacing.sm),

              // Final Weighed Weight (KG)
              TextFormField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Final Weight in KG (حتمی وزن) *',
                  prefixIcon: const Icon(Icons.scale_outlined),
                  suffixText: '${_currentMaunds.toStringAsFixed(2)} Manns',
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  final n = double.tryParse(val?.trim() ?? '');
                  if (n == null || n <= 0) return 'Enter valid weight';
                  return null;
                },
              ),
              const SizedBox(height: MSpacing.sm),

              // Winning Rate per Maund (40 KG)
              TextFormField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Bid Rate per Maund (ریٹ فی من 40 کلو) *',
                  prefixIcon: Icon(Icons.price_change_outlined),
                  prefixText: 'Rs. ',
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  final n = double.tryParse(val?.trim() ?? '');
                  if (n == null || n <= 0) return 'Enter valid rate';
                  return null;
                },
              ),
              const SizedBox(height: MSpacing.md),

              // Calculation Summary Box
              Container(
                padding: const EdgeInsets.all(MSpacing.sm),
                decoration: BoxDecoration(
                  color: MColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MColors.gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Manns (من):',
                            style: MText.caption.copyWith(color: Colors.white)),
                        Text('${_currentMaunds.toStringAsFixed(2)} Manns',
                            style: MText.bodySm.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Auction Value (کل نیلامی):',
                            style: MText.bodySm.copyWith(
                                fontWeight: FontWeight.bold,
                                color: MColors.gold)),
                        Text(
                          'Rs. ${_totalAuctionValue.toStringAsFixed(0)}',
                          style: MText.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MColors.gold,
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
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (_selectedCustomer == null) return;

                  setState(() => _isSaving = true);
                  final prov = context.read<ConsignmentProvider>();
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    await prov.recordBid(
                      lotId: widget.lot.id,
                      winningBuyerId: _selectedCustomer!.id,
                      winningBuyerName: _selectedCustomer!.name,
                      ratePerMaund: _currentRate,
                      finalWeightKg: _currentWeight,
                    );
                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                              'Winning bid recorded for ${widget.lot.lotNumber}: Rs. ${_currentRate.toStringAsFixed(0)}/Mann'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to record bid: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Winning Bid'),
        ),
      ],
    );
  }
}
