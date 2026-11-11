// Live Auction (Boli) Digital Floor Terminal
// (*لائیو نیلامی بولی اسکرین و پھڑ ٹرمینل*).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mandi/modules/auction_boli/providers/auction_boli_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class LiveAuctionTerminalPage extends StatefulWidget {
  const LiveAuctionTerminalPage({super.key});

  @override
  State<LiveAuctionTerminalPage> createState() => _LiveAuctionTerminalPageState();
}

class _LiveAuctionTerminalPageState extends State<LiveAuctionTerminalPage> {
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _customBidCtrl = TextEditingController();

  final List<Map<String, dynamic>> _quickBuyers = [
    {'paddle': 12, 'name': 'Haji Mukhtar Traders (پڈل 12)'},
    {'paddle': 15, 'name': 'Al-Madina Rice Mills (پڈل 15)'},
    {'paddle': 24, 'name': 'Chaudhry Akram Commission (پڈل 24)'},
    {'paddle': 37, 'name': 'Bismillah Grain Traders (پڈل 37)'},
    {'paddle': 48, 'name': 'Malik & Sons Brokerage (پڈل 48)'},
    {'paddle': 55, 'name': 'Kashmir Flour Mills (پڈل 55)'},
  ];

  @override
  void dispose() {
    _customBidCtrl.dispose();
    super.dispose();
  }

  void _showNewLotDialog(BuildContext context, AuctionBoliProvider provider) {
    final lotCodeCtrl = TextEditingController(text: 'HEAP-${DateTime.now().minute}');
    final cropCtrl = TextEditingController(text: 'Wheat Super (گندم)');
    final farmerCtrl = TextEditingController(text: 'Chaudhry Riaz (چوہدری ریاض)');
    final maundsCtrl = TextEditingController(text: '50.0');
    final bagsCtrl = TextEditingController(text: '50');
    final basePriceCtrl = TextEditingController(text: '3800');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('پھڑ ڈھیری تفصیل درج کریں (New Auction Heap)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: lotCodeCtrl,
                  decoration: const InputDecoration(labelText: 'Heap / Lot Code'),
                ),
                TextField(
                  controller: cropCtrl,
                  decoration: const InputDecoration(labelText: 'Commodity / جنس'),
                ),
                TextField(
                  controller: farmerCtrl,
                  decoration: const InputDecoration(labelText: 'Farmer / زمیندار کا نام'),
                ),
                TextField(
                  controller: maundsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight in Maunds (من)'),
                ),
                TextField(
                  controller: bagsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Estimated Bags (بوریاں)'),
                ),
                TextField(
                  controller: basePriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Base Price per Maund (ابتدائی بولی)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('منسوخ (Cancel)'),
            ),
            ElevatedButton(
              onPressed: () {
                final maunds = double.tryParse(maundsCtrl.text) ?? 50.0;
                final bags = int.tryParse(bagsCtrl.text) ?? 50;
                final basePrice = double.tryParse(basePriceCtrl.text) ?? 3800.0;

                provider.initializeLot(
                  lotCode: lotCodeCtrl.text.trim(),
                  cropCommodity: cropCtrl.text.trim(),
                  farmerName: farmerCtrl.text.trim(),
                  heapMaunds: maunds,
                  estimatedBags: bags,
                  basePricePerMaund: basePrice,
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
              child: const Text('شروع کریں (Start Boli)', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printThermalBoliSlip(AuctionBoliProvider provider, String shopName) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          130 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                shopName.toUpperCase(),
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('LIVE AUCTION BOLI SLIP / نیلامی بولی پرچی',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.teal900)),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Lot / ڈھیری:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(provider.lotCode, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Crop / جنس:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(provider.cropCommodity, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Farmer / زمیندار:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(provider.farmerName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Weight / وزن:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('${provider.heapMaunds.toStringAsFixed(1)} Maunds (${provider.estimatedBags} Bags)',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('WINNING BUYER / خریدار',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text(
                      'Paddle #${provider.selectedPaddleNumber} - ${provider.selectedBuyerName}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Final Rate: Rs. ${_currencyFmt.format(provider.currentBidPerMaund)} / Maund',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    ),
                    pw.Text(
                      'Total Value: Rs. ${_currencyFmt.format(provider.currentTotalGrossValue)}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.BarcodeWidget(
                data: 'BOLI-${provider.lotCode}-${provider.selectedPaddleNumber}',
                barcode: pw.Barcode.code128(),
                width: 140,
                height: 24,
                drawText: false,
              ),
              pw.SizedBox(height: 4),
              pw.Text('ایک، دو، تین — ہو گیا! (Auction Closed)',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Boli_Slip_${provider.lotCode}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shopName = shopCtx.currentShop?.name ?? 'Mandi Commission Shop';
    final boliProvider = context.watch<AuctionBoliProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate Navy TV Theme
      appBar: AppBar(
        title: const Text(
          'Live Auction Floor Terminal (لائیو نیلامی بولی اسکرین)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.amberAccent),
            tooltip: 'نئی ڈھیری شروع کریں (New Heap)',
            onPressed: () => _showNewLotDialog(context, boliProvider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'ری سیٹ (Reset)',
            onPressed: () => boliProvider.resetAuction(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 850;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left 60%: Current Heap & Big Bidding Numbers
                      Expanded(
                        flex: 6,
                        child: _buildMainBiddingFloor(context, boliProvider, shopName),
                      ),
                      const SizedBox(width: 16),
                      // Right 40%: Buyer Paddle Grid & Bid Log
                      Expanded(
                        flex: 4,
                        child: _buildBuyerPaddleGrid(context, boliProvider),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMainBiddingFloor(context, boliProvider, shopName),
                        const SizedBox(height: 16),
                        _buildBuyerPaddleGrid(context, boliProvider),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildMainBiddingFloor(
      BuildContext context, AuctionBoliProvider provider, String shopName) {
    final isLocked = provider.isAuctionLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lot Info Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          provider.lotCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.cropCommodity,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Farmer: ${provider.farmerName}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${provider.heapMaunds.toStringAsFixed(1)} Maunds (من)',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${provider.estimatedBags} Bags (بوریاں)',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Big Bid Terminal Display Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isLocked ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked ? Colors.greenAccent : Colors.teal.shade400,
              width: isLocked ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isLocked
                    ? Colors.greenAccent.withAlpha(50)
                    : Colors.teal.withAlpha(30),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                isLocked ? '🎉 SOLD! بولی مکمل ہو گئی' : 'CURRENT HIGHEST BID / موجودہ بلند ترین بولی',
                style: TextStyle(
                  color: isLocked ? Colors.greenAccent : Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Rs. ',
                    style: TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _currencyFmt.format(provider.currentBidPerMaund),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    ' / Maund (من)',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total Gross: Rs. ${_currencyFmt.format(provider.currentTotalGrossValue)}',
                style: TextStyle(
                  color: Colors.amber.shade300,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Winning Buyer Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, color: Colors.tealAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Paddle #${provider.selectedPaddleNumber} - ${provider.selectedBuyerName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.gavelMessage.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    provider.gavelMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Increment Buttons (+10, +25, +50, +100)
        Row(
          children: [
            _buildIncrementButton(provider, 10, '+ Rs. 10'),
            const SizedBox(width: 8),
            _buildIncrementButton(provider, 25, '+ Rs. 25'),
            const SizedBox(width: 8),
            _buildIncrementButton(provider, 50, '+ Rs. 50'),
            const SizedBox(width: 8),
            _buildIncrementButton(provider, 100, '+ Rs. 100'),
          ],
        ),
        const SizedBox(height: 16),

        // Gavel Strike Action Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: isLocked ? null : () => provider.strikeGavel(),
                icon: const Icon(Icons.gavel, color: Colors.white, size: 28),
                label: Text(
                  provider.gavelCount == 0
                      ? 'ایک! First Call (Strike 1)'
                      : provider.gavelCount == 1
                          ? 'دو! Second Call (Strike 2)'
                          : 'تین — ہو گیا! Final Sold (Strike 3)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.gavelCount == 2
                      ? Colors.red.shade700
                      : Colors.amber.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _printThermalBoliSlip(provider, shopName),
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text('پرچی پرنٹ (Boli Slip)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildIncrementButton(AuctionBoliProvider provider, double delta, String label) {
    final isLocked = provider.isAuctionLocked;

    return Expanded(
      child: ElevatedButton(
        onPressed: isLocked ? null : () => provider.incrementBid(delta),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF334155),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBuyerPaddleGrid(BuildContext context, AuctionBoliProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BUYER PADDLES / خریدار پڈل نمبر',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          // Paddle Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickBuyers.map((b) {
              final isSelected = provider.selectedPaddleNumber == b['paddle'];
              return ChoiceChip(
                label: Text(
                  '#${b['paddle']} ${b['name'].toString().split(' ')[0]}',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.tealAccent,
                backgroundColor: const Color(0xFF334155),
                onSelected: provider.isAuctionLocked
                    ? null
                    : (selected) {
                        if (selected) {
                          provider.selectBuyer(
                            paddleNumber: b['paddle'] as int,
                            buyerName: b['name'] as String,
                          );
                        }
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),

          // Bid History
          const Text(
            'BID LOG / بولی کی تاریخ',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: provider.bidHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No bids recorded yet. Press +Rs buttons to bid.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.bidHistory.length,
                    itemBuilder: (ctx, idx) {
                      final item = provider.bidHistory[idx];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: idx == 0 ? Colors.teal.shade900.withAlpha(80) : Colors.black26,
                          borderRadius: BorderRadius.circular(6),
                          border: idx == 0 ? Border.all(color: Colors.tealAccent, width: 0.8) : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${item.paddleNumber} ${item.buyerName.split(' ')[0]}',
                              style: TextStyle(
                                color: idx == 0 ? Colors.tealAccent : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Rs. ${_currencyFmt.format(item.bidPerMaund)} / Md',
                              style: TextStyle(
                                color: idx == 0 ? Colors.amberAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
