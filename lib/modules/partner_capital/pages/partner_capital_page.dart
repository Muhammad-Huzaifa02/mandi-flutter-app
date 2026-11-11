// Multi-Partner Mandi Shop Profit Sharing & Drawings Page
// (*شراکت داری اور منافع تقسیم کھاتہ*).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/partner_capital_model.dart';
import 'package:mandi/modules/partner_capital/providers/partner_capital_provider.dart';
import 'package:mandi/modules/partner_capital/dialogs/add_partner_dialog.dart';
import 'package:mandi/modules/partner_capital/dialogs/record_partner_drawing_dialog.dart';
import 'package:mandi/modules/partner_capital/dialogs/distribute_profit_wizard_dialog.dart';
import 'package:mandi/core/utils/partner_capital_pdf_generator.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class PartnerCapitalPage extends StatefulWidget {
  const PartnerCapitalPage({super.key});

  @override
  State<PartnerCapitalPage> createState() => _PartnerCapitalPageState();
}

class _PartnerCapitalPageState extends State<PartnerCapitalPage> {
  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  Future<void> _printReport(PartnerCapitalProvider provider, String shopName, String? shopPhone) async {
    final pdfBytes = await PartnerCapitalPdfGenerator.generatePartnerEquityReportPdf(
      partners: provider.partners,
      recentTransactions: provider.transactions,
      shopName: shopName,
      shopPhone: shopPhone,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Partner_Equity_Register.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shopName = shopCtx.currentShop?.name ?? 'Mandi Commission Shop';
    final shopPhone = shopCtx.currentShop?.phone;

    final provider = context.watch<PartnerCapitalProvider>();
    final partners = provider.partners;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Shop Partners & Profit Sharing (شراکت داری کھاتہ)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Print Equity Report (A4 PDF)',
            onPressed: partners.isEmpty ? null : () => _printReport(provider, shopName, shopPhone),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top KPI Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Partners / حصہ دار',
                    value: '${partners.length}',
                    subtitle: '${provider.totalProfitRatio.toStringAsFixed(1)}% Allocated',
                    icon: Icons.groups,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Firm Capital / کل سرمایہ',
                    value: 'Rs. ${_currencyFmt.format(provider.totalShopCapital)}',
                    subtitle: 'Current Partner Equity',
                    icon: Icons.account_balance,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Drawings / ذاتی خرچ',
                    value: 'Rs. ${_currencyFmt.format(provider.totalShopDrawings)}',
                    subtitle: 'Cumulative Drawings',
                    icon: Icons.money_off,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ratio Warning Banner if not 100%
            if (!provider.isRatioConfigValid && partners.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention: Total profit sharing ratio is ${provider.totalProfitRatio.toStringAsFixed(1)}% (must equal 100.0%).',
                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons Bar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const AddPartnerDialog(),
                  ),
                  icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                  label: const Text('نیا حصہ دار (Add Partner)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
                ),
                ElevatedButton.icon(
                  onPressed: partners.isEmpty
                      ? null
                      : () => showDialog(
                            context: context,
                            builder: (_) => const RecordPartnerDrawingDialog(isCapitalInjection: false),
                          ),
                  icon: const Icon(Icons.money_off, color: Colors.white, size: 18),
                  label: const Text('ذاتی خرچ (Record Drawing)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[900]),
                ),
                ElevatedButton.icon(
                  onPressed: partners.isEmpty
                      ? null
                      : () => showDialog(
                            context: context,
                            builder: (_) => const RecordPartnerDrawingDialog(isCapitalInjection: true),
                          ),
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                  label: const Text('سرمایہ اضافہ (Inject Capital)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                ),
                ElevatedButton.icon(
                  onPressed: partners.isEmpty
                      ? null
                      : () => showDialog(
                            context: context,
                            builder: (_) => const DistributeProfitWizardDialog(),
                          ),
                  icon: const Icon(Icons.pie_chart, color: Colors.white, size: 18),
                  label: const Text('منافع تقسیم (Distribute Profit)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[800]),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Partners Equity Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حصہ داران و سرمایہ بیلنس (Partner Capital Balances)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${partners.length} Partners',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (partners.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text('No partners registered yet. Click "Add Partner" to set up firm partners.'),
                ),
              )
            else
              ...partners.map((p) => _buildPartnerCard(context, p)),

            const SizedBox(height: 24),

            // Recent Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حالیہ ٹرانزیکشنز و منافع تفصیل (Recent Transactions)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${provider.transactions.length} Records',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: provider.transactions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No transactions recorded yet.')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.transactions.take(10).length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final txn = provider.transactions[idx];
                        final isDrawing = txn.type == PartnerTransactionType.drawing;
                        final isProfit = txn.type == PartnerTransactionType.profitDistribution;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDrawing
                                ? Colors.amber.shade100
                                : (isProfit ? Colors.teal.shade100 : Colors.green.shade100),
                            child: Icon(
                              isDrawing
                                  ? Icons.money_off
                                  : (isProfit ? Icons.pie_chart : Icons.arrow_downward),
                              color: isDrawing
                                  ? Colors.amber.shade900
                                  : (isProfit ? Colors.teal.shade900 : Colors.green.shade900),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            txn.type.labelEnglish,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            '${txn.formattedDate} • ${txn.paymentMethod.toUpperCase()} • ${txn.description ?? ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            '${isDrawing ? '-' : '+'} Rs. ${_currencyFmt.format(txn.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDrawing ? Colors.red.shade900 : Colors.green.shade900,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(BuildContext context, ShopPartnerModel partner) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal.shade800,
                      child: Text(
                        partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (partner.phone != null)
                          Text('Phone: ${partner.phone}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Text(
                    'Share: ${partner.profitRatioFormatted}',
                    style: TextStyle(
                      color: Colors.teal.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Opening Capital', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    Text('Rs. ${_currencyFmt.format(partner.openingCapital)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Drawings (نکلوانا)', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    Text('Rs. ${_currencyFmt.format(partner.totalDrawings)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Current Capital (موجودہ سرمایہ)',
                        style: TextStyle(color: Colors.teal.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(
                      'Rs. ${_currencyFmt.format(partner.currentCapital)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      constraints: const BoxConstraints(minHeight: AppDimensions.kpiCardMinHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
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
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color.shade700, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color.shade900),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black45, fontSize: 9.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
