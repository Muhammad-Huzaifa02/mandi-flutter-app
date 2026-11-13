import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/customer_loyalty_rebate_model.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/loyalty/providers/loyalty_rebate_provider.dart';

/// Modal dialog to record and issue a customer volume rebate incentive.
class NewLoyaltyRebateDialog extends StatefulWidget {
  final Customer? preselectedCustomer;

  const NewLoyaltyRebateDialog({super.key, this.preselectedCustomer});

  @override
  State<NewLoyaltyRebateDialog> createState() => _NewLoyaltyRebateDialogState();
}

class _NewLoyaltyRebateDialogState extends State<NewLoyaltyRebateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  Customer? _selectedCustomer;
  final _seasonCtrl = TextEditingController();
  final _programCtrl = TextEditingController();
  final _maundsCtrl = TextEditingController(text: '1200'); // >1000 Silver tier
  final _turnoverCtrl = TextEditingController(text: '4800000'); // Rs. 4.8M
  final _percentageCtrl = TextEditingController(text: '1.0'); // 1%
  final _notesCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
    _recalcTier();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seasonCtrl.text.isEmpty) {
      _seasonCtrl.text = AppStrings.val(
        context,
        en: 'Rabi 2026 Season',
        ur: 'ربیع 2026 سیزن',
      );
    }
    if (_programCtrl.text.isEmpty) {
      _programCtrl.text = AppStrings.val(
        context,
        en: 'Seasonal Grain Volume Rebate',
        ur: 'سیزنل والیم رعایت پروگرام',
      );
    }
  }

  @override
  void dispose() {
    _seasonCtrl.dispose();
    _programCtrl.dispose();
    _maundsCtrl.dispose();
    _turnoverCtrl.dispose();
    _percentageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _maunds => double.tryParse(_maundsCtrl.text.trim()) ?? 0.0;
  double get _turnover => double.tryParse(_turnoverCtrl.text.trim()) ?? 0.0;
  double get _percent => double.tryParse(_percentageCtrl.text.trim()) ?? 1.0;
  double get _rebateAmount => _turnover * (_percent / 100.0);
  RebateTierLevel get _tier => RebateTierLevel.fromMaunds(_maunds);

  void _recalcTier() {
    final t = RebateTierLevel.fromMaunds(_maunds);
    _percentageCtrl.text = t.defaultPercentage.toString();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final cust = _selectedCustomer;
    if (cust == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Please select a customer.',
              ur: 'برائے مہربانی گاہک منتخب کریں',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final prov = context.read<LoyaltyRebateProvider>();

    final ok = await prov.createRebateProgram(
      customerId: cust.id,
      customerName: cust.name,
      customerPhone: cust.phone,
      programName: _programCtrl.text.trim(),
      seasonYear: _seasonCtrl.text.trim(),
      qualifyingMaunds: _maunds,
      qualifyingTurnoverPkr: _turnover,
      customRebatePercentage: _percent,
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Rebate voucher approved successfully (${cust.name})',
              ur: 'رعایت واؤچر کامیابی سے منظور کر لیا گیا (${cust.name})',
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Failed to record rebate.',
              ur: 'رعایت اندراج میں خرابی پیش آگئی',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final custProv = context.watch<CustomerProvider>();
    final customers = custProv.customers;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Customer Volume Rebate',
                              ur: 'گاہک والیم رعایت واؤچر',
                            ),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Issue trading bonus & credit voucher for seasonal buyers',
                              ur: 'سیزنل خریداروں کے لیے ٹریڈنگ بونس اور کریڈٹ واؤچر جاری کریں',
                            ),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Form Fields
                Expanded(
                  child: ListView(
                    children: [
                      // Customer Dropdown
                      DropdownButtonFormField<Customer>(
                        initialValue: _selectedCustomer,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(
                            context,
                            en: 'Buyer / Customer *',
                            ur: 'خریدار یا گاہک *',
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: customers.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.name} (${c.phone.isNotEmpty ? c.phone : AppStrings.val(context, en: "Mandi Buyer", ur: "منڈی خریدار")})',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCustomer = val),
                        validator: (val) => val == null
                            ? AppStrings.val(context, en: 'Customer is required', ur: 'گاہک لازمی منتخب کریں')
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Season & Program Name
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _seasonCtrl,
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Season / Year',
                                  ur: 'سیزن یا سال',
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _programCtrl,
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Program Name',
                                  ur: 'پروگرام کا نام',
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Qualifying Maunds & Turnover
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _maundsCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Season Purchases (Maunds) *',
                                  ur: 'سیزن خریداری من *',
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixText: AppStrings.val(context, en: 'Maunds', ur: 'من'),
                              ),
                              onChanged: (_) {
                                _recalcTier();
                                setState(() {});
                              },
                              validator: (val) {
                                final v = double.tryParse(val ?? '');
                                if (v == null || v <= 0) {
                                  return AppStrings.val(context, en: 'Enter a valid weight', ur: 'درست وزن درج کریں');
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _turnoverCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Total Turnover (Rs.) *',
                                  ur: 'کل ٹرن اوور مالیت روپے *',
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixText: 'Rs. ',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                final v = double.tryParse(val ?? '');
                                if (v == null || v <= 0) {
                                  return AppStrings.val(context, en: 'Enter a valid amount', ur: 'درست رقم درج کریں');
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Rebate Percentage & Tier Indicator
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _percentageCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: AppStrings.val(
                                  context,
                                  en: 'Rebate %',
                                  ur: 'رعایت شرح فیصد',
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixText: '%',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.military_tech, color: Colors.amber, size: 24),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.val(context, en: 'Achieved Tier', ur: 'حاصل کردہ درجہ'),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                      Text(
                                        AppStrings.val(context, en: _tier.labelEnglish, ur: _tier.labelUrdu),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(
                            context,
                            en: 'Additional Terms or Notes',
                            ur: 'اضافی شرائط یا نوٹ',
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Incentive Payout Preview
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderColor: Colors.teal.withValues(alpha: 0.4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Rebate Credit Amount',
                                    ur: 'منظور شدہ رعایت رقم',
                                  ),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. ${_currencyFmt.format(_rebateAmount)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_percent% of ${_currencyFmt.format(_turnover)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSaving
                            ? AppStrings.val(context, en: 'Approving...', ur: 'منظور ہو رہا ہے...')
                            : AppStrings.val(context, en: 'Approve Rebate', ur: 'رعایت منظور کریں'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
