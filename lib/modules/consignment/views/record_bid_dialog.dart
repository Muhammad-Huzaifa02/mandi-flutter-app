import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
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
              '${AppStrings.val(context, en: 'Record Auction Bid', ur: 'بولی ریکارڈ کریں')}: ${widget.lot.lotNumber}',
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
                '${AppStrings.val(context, en: 'Farmer', ur: 'زمیندار')}: ${widget.lot.supplierName} • ${widget.lot.productName}',
                style: MText.bodySm.copyWith(color: MColors.textOnDarkSub),
              ),
              const SizedBox(height: MSpacing.md),

              // Winning Buyer (Customer) Selector
              DropdownButtonFormField<Customer>(
                initialValue: _selectedCustomer,
                decoration: InputDecoration(
                  labelText: AppStrings.val(context, en: 'Winning Buyer / Customer *', ur: 'خریدار / گاہک *'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} (${c.phone})'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCustomer = val),
                validator: (val) => val == null
                    ? AppStrings.val(context, en: 'Please select a winning buyer', ur: 'خریدار منتخب کریں')
                    : null,
              ),
              const SizedBox(height: MSpacing.sm),

              // Final Weighed Weight (KG)
              TextFormField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppStrings.val(context, en: 'Final Weight in KG *', ur: 'حتمی وزن (کلوگرام) *'),
                  prefixIcon: const Icon(Icons.scale_outlined),
                  suffixText: '${_currentMaunds.toStringAsFixed(2)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  final n = double.tryParse(val?.trim() ?? '');
                  if (n == null || n <= 0) {
                    return AppStrings.val(context, en: 'Enter valid weight', ur: 'درست وزن درج کریں');
                  }
                  return null;
                },
              ),
              const SizedBox(height: MSpacing.sm),

              // Winning Rate per Maund (40 KG)
              TextFormField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppStrings.val(context, en: 'Bid Rate per Maund (40 KG) *', ur: 'بولی ریٹ فی من (40 کلو) *'),
                  prefixIcon: const Icon(Icons.price_change_outlined),
                  prefixText: 'Rs. ',
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  final n = double.tryParse(val?.trim() ?? '');
                  if (n == null || n <= 0) {
                    return AppStrings.val(context, en: 'Enter valid rate', ur: 'درست ریٹ درج کریں');
                  }
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
                        Text(
                          AppStrings.val(context, en: 'Total Maunds:', ur: 'کل من:'),
                          style: MText.caption.copyWith(color: Colors.white),
                        ),
                        Text(
                          '${_currentMaunds.toStringAsFixed(2)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
                          style: MText.bodySm.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.val(context, en: 'Auction Value:', ur: 'کل نیلامی رقم:'),
                          style: MText.bodySm.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MColors.gold,
                          ),
                        ),
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
          child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں')),
        ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (_selectedCustomer == null) return;

                  setState(() => _isSaving = true);
                  final prov = context.read<ConsignmentProvider>();
                  final isUrdu = AppStrings.isUrdu(context);
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
                            isUrdu
                                ? '${widget.lot.lotNumber} کے لیے کامیاب بولی درج: Rs. ${_currentRate.toStringAsFixed(0)} فی من'
                                : 'Winning bid recorded for ${widget.lot.lotNumber}: Rs. ${_currentRate.toStringAsFixed(0)}/Mann',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isUrdu
                                ? 'بولی محفوظ کرنے میں ناکامی: $e'
                                : 'Failed to record bid: $e',
                          ),
                        ),
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
              : Text(AppStrings.val(context, en: 'Save Winning Bid', ur: 'بولی محفوظ کریں')),
        ),
      ],
    );
  }
}
