// Mandi Gate Pass, Inward Token & Unloading Queue Page
// (*گیٹ پاس، ٹوکن اور ٹریکٹر لائن نمبر*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/widgets/liquid_crystal_background.dart';
import 'package:mandi/data/models/gate_pass_model.dart';
import 'package:mandi/modules/gate_pass/providers/gate_pass_provider.dart';
import 'package:mandi/modules/gate_pass/dialogs/issue_gate_pass_dialog.dart';
import 'package:mandi/modules/gate_pass/dialogs/callout_platform_dialog.dart';
import 'package:mandi/modules/gate_pass/dialogs/record_weighment_dialog.dart';
import 'package:mandi/core/utils/gate_pass_pdf_generator.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class GatePassPage extends StatefulWidget {
  const GatePassPage({super.key});

  @override
  State<GatePassPage> createState() => _GatePassPageState();
}

class _GatePassPageState extends State<GatePassPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _printToken(GatePassModel pass, String shopName) async {
    final pdfBytes = await GatePassPdfGenerator.generateTokenSlipPdf(
      gatePass: pass,
      shopName: shopName,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Token_${pass.tokenNumber}.pdf',
    );
  }

  Future<void> _printGateOutPass(GatePassModel pass, String shopName) async {
    final pdfBytes = await GatePassPdfGenerator.generateGateOutPassPdf(
      gatePass: pass,
      shopName: shopName,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'GateOut_${pass.tokenNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final shopName = shopCtx.currentShop?.name ?? 'Mandi Commission Shop';
    final gateProvider = context.watch<GatePassProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppStrings.tr(context, 'gate_pass_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: const Icon(Icons.tv), text: AppStrings.tr(context, 'unloading_board_tab')),
            Tab(icon: const Icon(Icons.confirmation_num), text: AppStrings.tr(context, 'inward_tokens_tab')),
            Tab(icon: const Icon(Icons.exit_to_app), text: AppStrings.tr(context, 'gate_out_tab')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.amberAccent, size: 28),
            tooltip: AppStrings.tr(context, 'issue_token_btn'),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const IssueGatePassDialog(),
            ),
          ),
        ],
      ),
      body: LiquidCrystalBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Live Unloading Board
            _buildUnloadingBoardTab(context, gateProvider, shopName),
            // Tab 2: Inward Tokens Register
            _buildInwardTokensTab(context, gateProvider, shopName),
            // Tab 3: Gate-Out Clearance Pass
            _buildGateOutTab(context, gateProvider, shopName),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const IssueGatePassDialog(),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          AppStrings.tr(context, 'issue_token_btn'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[800],
      ),
    );
  }

  Widget _buildUnloadingBoardTab(
      BuildContext context, GatePassProvider provider, String shopName) {
    final queued = provider.activeQueuePasses;
    final unloading = provider.unloadingPasses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flashing Public Callout Announcement Banner
          if (provider.lastAnnouncedCallout != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade900,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withAlpha(80), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.white, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📢 PUBLIC CALLOUT / اعلان برائے ان لوڈنگ',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.lastAnnouncedCallout!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Unloading at Platforms Section
          Row(
            children: [
              const Icon(Icons.storefront, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppStrings.tr(context, 'currently_unloading')} (${unloading.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (unloading.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('No vehicles currently unloading at platforms.'),
              ),
            )
          else
            ...unloading.map((pass) => _buildUnloadingCard(context, pass, provider, shopName)),

          const SizedBox(height: 24),

          // Waiting in Queue Section
          Row(
            children: [
              const Icon(Icons.hourglass_top, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppStrings.tr(context, 'waiting_queue')} (${queued.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (queued.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('No vehicles waiting in queue.'),
              ),
            )
          else
            ...queued.map((pass) => _buildQueueCard(context, pass, provider, shopName)),
        ],
      ),
    );
  }

  Widget _buildUnloadingCard(
      BuildContext context, GatePassModel pass, GatePassProvider provider, String shopName) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade700, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 420;
            final tokenBadge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pass.tokenNumber,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            );

            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pass.vehicleNumber} (${pass.driverName})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Farmer: ${pass.farmerName} | ${pass.commodityName} (${pass.estimatedBags} Bags)',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (pass.assignedPlatform != null)
                  Text(
                    'Platform: ${pass.assignedPlatform}',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            );

            final tareButton = ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => RecordWeighmentDialog(gatePass: pass),
              ),
              icon: const Icon(Icons.scale, size: 15, color: Colors.white),
              label: const Text('کنڈا وزن (Tare)', style: TextStyle(color: Colors.white, fontSize: 11.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[800],
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      tokenBadge,
                      const SizedBox(width: 8),
                      Expanded(child: details),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: tareButton),
                ],
              );
            }

            return Row(
              children: [
                tokenBadge,
                const SizedBox(width: 12),
                Expanded(child: details),
                const SizedBox(width: 8),
                tareButton,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQueueCard(
      BuildContext context, GatePassModel pass, GatePassProvider provider, String shopName) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey.shade800,
          child: Text(
            pass.tokenNumber.replaceAll('TKN-', ''),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text(
          '${pass.tokenNumber} - ${pass.vehicleNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${pass.farmerName} • ${pass.commodityName} • ${pass.estimatedBags} Bags • ${pass.inwardTimeFormatted}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.print, color: Colors.teal),
              tooltip: 'Print Token Slip',
              onPressed: () => _printToken(pass, shopName),
            ),
            ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => CalloutPlatformDialog(gatePass: pass),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
              child: const Text('کال آؤٹ (Call)', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInwardTokensTab(
      BuildContext context, GatePassProvider provider, String shopName) {
    final passes = provider.passes;

    if (passes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_num_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No Gate Inward Tokens issued yet.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const IssueGatePassDialog(),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('پہلا ٹوکن جاری کریں (Issue First Token)', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: passes.length,
      itemBuilder: (ctx, idx) {
        final pass = passes[idx];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.teal.shade300),
              ),
              child: Text(
                pass.tokenNumber,
                style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            title: Text('${pass.vehicleNumber} (${pass.driverName})', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${pass.farmerName} • ${pass.commodityName} • ${pass.estimatedBags} Bags\n${pass.inwardTimeFormatted}',
              style: const TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(pass.status),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.teal),
                  onPressed: () => _printToken(pass, shopName),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGateOutTab(
      BuildContext context, GatePassProvider provider, String shopName) {
    final weighedAndCleared = provider.passes.where(
      (p) => p.status == GatePassStatus.weighed || p.status == GatePassStatus.clearedGateOut,
    ).toList();

    if (weighedAndCleared.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.exit_to_app, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No vehicles ready for Gate-Out clearance.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: weighedAndCleared.length,
      itemBuilder: (ctx, idx) {
        final pass = weighedAndCleared[idx];
        final isCleared = pass.status == GatePassStatus.clearedGateOut;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(pass.tokenNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                          _buildStatusChip(pass.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Vehicle: ${pass.vehicleNumber} | Driver: ${pass.driverName}'),
                      Text('Farmer: ${pass.farmerName} | Crop: ${pass.commodityName}'),
                      if (pass.netWeightKg != null)
                        Text(
                          'Net Weight: ${pass.netWeightKg!.toStringAsFixed(1)} kg (${(pass.netMaunds ?? 0).toStringAsFixed(2)} Maunds)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (!isCleared)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await provider.clearGateOut(pass.id);
                          await _printGateOutPass(pass, shopName);
                        },
                        icon: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                        label: const Text('گیٹ آؤٹ کلیئر (Clear)', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => _printGateOutPass(pass, shopName),
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('پاس پرنٹ (Reprint)', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(GatePassStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case GatePassStatus.queued:
        bg = Colors.blueGrey.shade100;
        fg = Colors.blueGrey.shade900;
        break;
      case GatePassStatus.unloading:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case GatePassStatus.weighed:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      case GatePassStatus.clearedGateOut:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case GatePassStatus.cancelled:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.labelEnglish, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
