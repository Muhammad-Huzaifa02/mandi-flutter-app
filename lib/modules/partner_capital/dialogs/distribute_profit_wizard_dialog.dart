// Wizard Dialog to Distribute Net Commission Profit among Partners
// (*شراکت داروں میں خالص منافع کی تقسیم وزرڈ*).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mandi/modules/partner_capital/providers/partner_capital_provider.dart';

class DistributeProfitWizardDialog extends StatefulWidget {
  const DistributeProfitWizardDialog({super.key});

  @override
  State<DistributeProfitWizardDialog> createState() => _DistributeProfitWizardDialogState();
}

class _DistributeProfitWizardDialogState extends State<DistributeProfitWizardDialog> {
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _profitCtrl = TextEditingController(text: '1000000');
  final _periodCtrl = TextEditingController(text: 'Season Net Commission Profit (سیزن خالص کمیشن منافع)');
  bool _isDistributing = false;

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
        const SnackBar(content: Text('Please enter a valid profit amount.')),
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
          const SnackBar(
            content: Text('Profit Distributed to Partner Capitals Successfully! (منافع تقسیم ہو گیا)'),
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
      title: const Row(
        children: [
          Icon(Icons.pie_chart, color: Colors.teal),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Net Profit Distribution Wizard\n(خالص منافع تقسیم وزرڈ)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter total shop net commission profit to automatically allocate to partners according to their agreed ratios.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _profitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Net Profit / کل خالص منافع *',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _periodCtrl,
              decoration: const InputDecoration(
                labelText: 'Period / سیزن و تفصیل',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'LIVE DISTRIBUTION PREVIEW / متوقع تقسیم تفصیل:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal),
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
                  ? const Text('No active partners configured.')
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
          child: const Text('منسوخ (Cancel)'),
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
              : const Text('منافع تقسیم کریں (Distribute Profit)', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
