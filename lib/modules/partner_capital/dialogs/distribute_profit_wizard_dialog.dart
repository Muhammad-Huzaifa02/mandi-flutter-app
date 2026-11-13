// Wizard Dialog to Distribute Net Commission Profit among Partners.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/modules/partner_capital/providers/partner_capital_provider.dart';

class DistributeProfitWizardDialog extends StatefulWidget {
  const DistributeProfitWizardDialog({super.key});

  @override
  State<DistributeProfitWizardDialog> createState() => _DistributeProfitWizardDialogState();
}

class _DistributeProfitWizardDialogState extends State<DistributeProfitWizardDialog> {
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _profitCtrl = TextEditingController(text: '1000000');
  final _periodCtrl = TextEditingController();
  bool _isDistributing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_periodCtrl.text.isEmpty) {
      _periodCtrl.text = AppStrings.val(
        context,
        en: 'Season Net Commission Profit',
        ur: 'سیزن خالص کمیشن منافع',
      );
    }
  }

  @override
  void dispose() {
    _profitCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final profit = double.tryParse(_profitCtrl.text.trim()) ?? 0.0;
    if (profit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Please enter a valid profit amount.',
              ur: 'براہ کرم درست منافع رقم درج کریں۔',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isDistributing = true);
    final provider = context.read<PartnerCapitalProvider>();
    final success = await provider.distributeNetProfit(
      totalNetProfit: profit,
      periodDescription: _periodCtrl.text.trim(),
      distributionDate: DateTime.now(),
    );

    setState(() => _isDistributing = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.val(
                context,
                en: 'Profit distributed to partner capitals successfully!',
                ur: 'شراکت داروں میں منافع کامیابی سے تقسیم ہو گیا!',
              ),
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error distributing profit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartnerCapitalProvider>();
    final activePartners = provider.partners.where((p) => p.isActive).toList();
    final profit = double.tryParse(_profitCtrl.text.trim()) ?? 0.0;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.pie_chart, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.val(
                context,
                en: 'Net Profit Distribution Wizard',
                ur: 'خالص منافع تقسیم وزرڈ',
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.val(
                context,
                en: 'Enter total shop net commission profit to automatically allocate to partners according to their agreed ratios.',
                ur: 'دکان کا کل خالص کمیشن منافع درج کریں تاکہ طے شدہ تناسب کے مطابق تمام شراکت داروں میں تقسیم کیا جا سکے۔',
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _profitCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppStrings.val(
                  context,
                  en: 'Total Net Profit *',
                  ur: 'کل خالص منافع *',
                ),
                prefixText: 'Rs. ',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.monetization_on),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _periodCtrl,
              decoration: InputDecoration(
                labelText: AppStrings.val(
                  context,
                  en: 'Period / Description',
                  ur: 'سیزن و تفصیل',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.val(
                context,
                en: 'LIVE DISTRIBUTION PREVIEW:',
                ur: 'متوقع منافع تقسیم تفصیل:',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: activePartners.isEmpty
                  ? Text(
                      AppStrings.val(
                        context,
                        en: 'No active partners configured.',
                        ur: 'کوئی فعال شراکت دار موجود نہیں۔',
                      ),
                    )
                  : Column(
                      children: activePartners.map((p) {
                        final share = profit * (p.profitSharingRatio / 100.0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${p.name} (${p.profitRatioFormatted})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Rs. ${_currencyFmt.format(share)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDistributing ? null : () => Navigator.pop(context),
          child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں')),
        ),
        ElevatedButton(
          onPressed: _isDistributing ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
          child: _isDistributing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  AppStrings.val(
                    context,
                    en: 'Distribute Profit',
                    ur: 'منافع تقسیم کریں',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
