// Farmer Simplified Digital Passbook & QR Card Page
// (*زمیندار پاس بک اور تصویری کھاتہ*).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/widgets/liquid_crystal_background.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/modules/farmer_passbook/providers/farmer_passbook_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/core/utils/farmer_id_card_pdf_generator.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class FarmerPassbookPage extends StatefulWidget {
  const FarmerPassbookPage({super.key});

  @override
  State<FarmerPassbookPage> createState() => _FarmerPassbookPageState();
}

class _FarmerPassbookPageState extends State<FarmerPassbookPage> {
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final passbookProv = context.read<FarmerPassbookProvider>();
      final supplierProv = context.read<SupplierProvider>();
      if (passbookProv.selectedFarmer == null && supplierProv.suppliers.isNotEmpty) {
        passbookProv.selectFarmer(supplierProv.suppliers.first);
      } else if (passbookProv.selectedFarmer == null) {
        // Fallback default sample farmer for immediate testability
        final defaultFarmer = Supplier(
          id: 'farm_001',
          shopId: passbookProv.shopId ?? '',
          name: 'Chaudhry Riaz (چوہدری ریاض)',
          phone: '0300-1234567',
          runningBalance: 425000.0,
        );
        passbookProv.selectFarmer(defaultFarmer);
      }
    });
  }

  Future<void> _printIdCard(
      FarmerPassbookProvider provider, String shopName, String? shopPhone) async {
    final f = provider.selectedFarmer;
    if (f == null) return;

    final pdfBytes = await FarmerIdCardPdfGenerator.generateFarmerIdCardPdf(
      farmerId: f.id,
      farmerName: f.name,
      phone: f.phone,
      shopName: shopName,
      shopPhone: shopPhone,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Farmer_Card_${f.name.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> _printPassbookSlip(
      FarmerPassbookProvider provider, String shopName, String? shopPhone) async {
    final f = provider.selectedFarmer;
    if (f == null) return;

    final pdfBytes = await FarmerIdCardPdfGenerator.generateFarmerPassbookSlipPdf(
      farmerName: f.name,
      phone: f.phone,
      totalDeliveredMaunds: provider.totalDeliveredMaunds,
      totalGrossEarnings: provider.totalGrossEarnings,
      totalDeductions: provider.totalDeductions,
      totalPaymentsReceived: provider.totalPaymentsReceived,
      runningBalance: provider.runningBalance,
      shopName: shopName,
      shopPhone: shopPhone,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Farmer_Passbook_${f.name.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shopName = shopCtx.currentShop?.name ?? 'Mandi Commission Shop';
    final shopPhone = shopCtx.currentShop?.phone;

    final passbookProvider = context.watch<FarmerPassbookProvider>();
    final supplierProvider = context.watch<SupplierProvider>();

    final farmer = passbookProvider.selectedFarmer;
    final isPayable = passbookProvider.runningBalance >= 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppStrings.tr(context, 'farmer_passbook_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.amberAccent),
            tooltip: AppStrings.tr(context, 'print_qr_card'),
            onPressed: farmer == null ? null : () => _printIdCard(passbookProvider, shopName, shopPhone),
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: AppStrings.tr(context, 'print_passbook_slip'),
            onPressed: farmer == null ? null : () => _printPassbookSlip(passbookProvider, shopName, shopPhone),
          ),
        ],
      ),
      body: LiquidCrystalBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Farmer Selector Row
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_search, color: Colors.teal),
                    const SizedBox(width: 10),
                    Text(
                      '${AppStrings.tr(context, 'select_farmer')}:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Supplier>(
                          isExpanded: true,
                          hint: const Text('Choose Zamindar'),
                          value: supplierProvider.suppliers.contains(farmer) ? farmer : null,
                          items: supplierProvider.suppliers.map((s) {
                            return DropdownMenuItem<Supplier>(
                              value: s,
                              child: Text(
                                '${s.name} (${s.phone})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (newFarmer) {
                            if (newFarmer != null) {
                              passbookProvider.selectFarmer(newFarmer);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // High-Contrast Main Balance Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPayable
                      ? [const Color(0xFF065F46), const Color(0xFF047857)]
                      : [const Color(0xFF9A3412), const Color(0xFFC2410C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isPayable ? Colors.green : Colors.deepOrange).withAlpha(60),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farmer?.name ?? 'Farmer Passbook',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (farmer?.phone.isNotEmpty == true)
                            Text(
                              'Phone: ${farmer!.phone}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPayable
                              ? AppStrings.tr(context, 'payable_to_farmer')
                              : AppStrings.tr(context, 'advance_receivable'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.tr(context, 'current_khata_balance'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Rs. ',
                          style: TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _currencyFmt.format(passbookProvider.runningBalance.abs()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPayable
                        ? 'یہ رقم آڑھت کی طرف کسان کو واجب الادا ہے۔'
                        : 'یہ پیشگی رقم کسان کی طرف واجب الوصول ہے۔',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Audio Summary (صوتی خلاصہ) Button & Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.amber.shade800,
                        child: Icon(
                          passbookProvider.isPlayingAudioSummary
                              ? Icons.volume_up
                              : Icons.record_voice_over,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'کھاتے کا صوتی خلاصہ (Urdu Audio Summary)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'زمیندار کو بول کر کھاتہ بیلنس سنائیں',
                              style: TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => passbookProvider.toggleAudioSummary(),
                        icon: Icon(
                          passbookProvider.isPlayingAudioSummary ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        label: Text(
                          passbookProvider.isPlayingAudioSummary ? 'روکیں (Stop)' : 'سنیں (Play)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: passbookProvider.isPlayingAudioSummary
                              ? Colors.red.shade700
                              : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  if (passbookProvider.isPlayingAudioSummary ||
                      passbookProvider.audioNarrationScript.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        passbookProvider.audioNarrationScript,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4 Key Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Delivered / کل مال',
                    value: '${_numberFmt.format(passbookProvider.totalDeliveredMaunds)} من',
                    subtitle: '(${_numberFmt.format(passbookProvider.totalDeliveredKg)} KG)',
                    icon: Icons.grain,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Gross Auction / کل بولی',
                    value: 'Rs. ${_currencyFmt.format(passbookProvider.totalGrossEarnings)}',
                    subtitle: 'نیلامی کل آمدن',
                    icon: Icons.monetization_on,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Deductions / منہائی',
                    value: 'Rs. ${_currencyFmt.format(passbookProvider.totalDeductions)}',
                    subtitle: 'کمیشن، پلے داری و اخراجات',
                    icon: Icons.remove_circle_outline,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Cash Paid / ادا شدہ',
                    value: 'Rs. ${_currencyFmt.format(passbookProvider.totalPaymentsReceived)}',
                    subtitle: 'وصول شدہ رقم و پیشگی',
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Delivered Crop Lots Table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'فصل ترسیل و نیلامی تفصیل (Delivered Lots)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${passbookProvider.deliveries.length} Entries',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: passbookProvider.deliveries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final item = passbookProvider.deliveries[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.commodity,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Date: ${item.dateStr} • Rate: Rs. ${_currencyFmt.format(item.ratePerMaund)} / Md',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.maunds.toStringAsFixed(1)} Maunds',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                            ),
                            Text(
                              'Net: Rs. ${_currencyFmt.format(item.netPayable)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.shade50,
            child: Icon(icon, color: color.shade800, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color.shade900),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.black38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
