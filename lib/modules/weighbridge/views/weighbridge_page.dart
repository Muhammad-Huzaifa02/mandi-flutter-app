import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/scale_service.dart';
import 'package:mandi/core/utils/thermal_receipt_service.dart';
import 'package:mandi/core/utils/weighbridge_slip_pdf_generator.dart';
import 'package:mandi/core/widgets/thermal_print_preview_dialog.dart';
import 'package:mandi/data/models/weighbridge_ticket_model.dart';
import 'package:mandi/modules/consignment/views/add_consignment_lot_page.dart';
import 'package:mandi/modules/weighbridge/providers/weighbridge_provider.dart';
import 'package:mandi/modules/weighbridge/views/new_weighbridge_ticket_dialog.dart';
import 'package:mandi/modules/weighbridge/views/record_tare_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Primary Mandi Weighbridge & Dharam Kanda Operations Hub.
class WeighbridgePage extends StatefulWidget {
  const WeighbridgePage({super.key});

  @override
  State<WeighbridgePage> createState() => _WeighbridgePageState();
}

class _WeighbridgePageState extends State<WeighbridgePage> {
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _numberFmt = NumberFormat('#,##0.00', 'en_US');
  final _searchCtrl = TextEditingController();

  double _liveScaleWeight = 0.0;
  bool _scaleIsStable = true;
  StreamSubscription<ScaleReading>? _scaleSub;

  @override
  void initState() {
    super.initState();
    _scaleSub = ScaleService().readingStream.listen((reading) {
      if (mounted) {
        setState(() {
          _liveScaleWeight = reading.weightKg;
          _scaleIsStable = reading.stability == ScaleStability.stable;
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportRegisterPdf(
    String shopName,
    WeighbridgeProvider wbProv,
  ) async {
    try {
      final Uint8List pdfBytes =
          await WeighbridgeSlipPdfGenerator.generateRegisterPdf(
        shopName: shopName,
        tickets: wbProv.filteredTickets,
        summary: wbProv.summary,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            'Weighbridge_Register_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate register PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printTicketSlip(
    String shopName,
    WeighbridgeTicket ticket,
  ) async {
    try {
      final Uint8List pdfBytes =
          await WeighbridgeSlipPdfGenerator.generateSlipPdf(
        shopName: shopName,
        ticket: ticket,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Kanda_Slip_${ticket.ticketNumber}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print slip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _printThermalTicketSlip(
    String shopName,
    WeighbridgeTicket ticket,
  ) {
    final shop = context.read<ShopContextProvider>().currentShop;
    final lines = [
      '*** ${shopName.toUpperCase()} ***',
      if (shop?.city != null && shop!.city.isNotEmpty) 'Mandi: ${shop.city}',
      if (shop?.phone != null && shop!.phone.isNotEmpty) 'Ph: ${shop.phone}',
      '--------------------------------',
      '*** DHARAM KANDA / دھرم کنڈا ***',
      'Ticket #: ${ticket.ticketNumber}',
      'Vehicle: ${ticket.vehicleNumber} (${ticket.vehicleType.labelEnglish})',
      'Party: ${ticket.partyName.isNotEmpty ? ticket.partyName : "Walk-in"}',
      'Commodity: ${ticket.commodityName}',
      if (ticket.driverName.isNotEmpty) 'Driver: ${ticket.driverName}',
      if (ticket.bagCount > 0) 'Bags: ${ticket.bagCount} Bags',
      '--------------------------------',
      '1st Gross Wt: ${ticket.grossWeightKg.toStringAsFixed(0)} KG (${ticket.grossMaunds.toStringAsFixed(2)}M)',
      '2nd Tare Wt:  ${ticket.tareWeightKg.toStringAsFixed(0)} KG (${ticket.tareMaunds.toStringAsFixed(2)}M)',
      'Net Weight:   ${ticket.computedNetWeightKg.toStringAsFixed(0)} KG (${ticket.netMaunds.toStringAsFixed(2)}M)',
      if (ticket.deductionKg > 0)
        'Katoti:       -${ticket.deductionKg.toStringAsFixed(0)} KG (${ticket.deductionReason})',
      '================================',
      'FINAL WEIGHT: ${ticket.computedFinalWeightKg.toStringAsFixed(0)} KG',
      '              (${ticket.maunds.toStringAsFixed(2)} Maunds)',
      'Kanda Fee:    Rs. ${ticket.kandaFee.toStringAsFixed(0)}',
      '--------------------------------',
      'Driver: ________  Incharge: ________',
      '*** Certified Mandi Weighment ***',
    ];

    ThermalPrintPreviewDialog.show(
      context: context,
      title: 'Kanda Thermal Slip',
      subtitle: 'Ticket #${ticket.ticketNumber} • ${ticket.vehicleNumber}',
      previewLines: lines,
      onPrint: (rollWidth, copies) async {
        for (int i = 0; i < copies; i++) {
          await ThermalReceiptService.printWeighbridgeSlip(
            ticket: ticket,
            shopName: shopName,
            shopPhone: shop?.phone,
            shopCity: shop?.city,
            rollWidthMm: rollWidth,
          );
        }
      },
    );
  }

  void _openRecordGrossDialog() {
    showDialog(
      context: context,
      builder: (_) => const NewWeighbridgeTicketDialog(),
    );
  }

  void _openRecordTareDialog(WeighbridgeTicket ticket) {
    showDialog(
      context: context,
      builder: (_) => RecordTareDialog(ticket: ticket),
    );
  }

  void _createConsignmentLotFromTicket(WeighbridgeTicket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddConsignmentLotPage(
          initialVehicleNumber: ticket.vehicleNumber,
          initialBags: ticket.bagCount,
          initialWeightKg: ticket.computedFinalWeightKg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wbProv = context.watch<WeighbridgeProvider>();
    final shopContext = context.watch<ShopContextProvider>();
    final shopName = shopContext.currentShop?.name ?? 'Mandi Commission Shop';

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mandi Weighbridge (دھرم کنڈا)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Electronic Scale & Vehicle Gross/Tare Weighment',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export Register PDF',
            onPressed: () => _exportRegisterPdf(shopName, wbProv),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Tickets',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Weighbridge data updated in real-time'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordGrossDialog,
        backgroundColor: MColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.scale_rounded),
        label: const Text('Record 1st Weight (بھرا گاڑی)'),
      ),
      body: wbProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Live Digital Scale Banner ──────────────────────────────────
                  _buildLiveScaleBanner(),

                  const SizedBox(height: 16),

                  // ── KPI Summary Cards ──────────────────────────────────────────
                  _buildKpiSection(wbProv.summary),

                  const SizedBox(height: 16),

                  // ── Search & Filter Tabs ───────────────────────────────────────
                  _buildSearchAndFilters(wbProv),

                  const SizedBox(height: 14),

                  // ── Tickets List ───────────────────────────────────────────────
                  if (wbProv.filteredTickets.isEmpty)
                    _buildEmptyState(wbProv)
                  else
                    ...wbProv.filteredTickets.map(
                      (t) => _buildTicketCard(t, shopName, wbProv),
                    ),

                  const SizedBox(height: 80), // Fab padding
                ],
              ),
            ),
    );
  }

  // ── Digital Scale Live Indicator Banner ────────────────────────────────────
  Widget _buildLiveScaleBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.shade900,
            Colors.black87,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: MRadius.lg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _scaleIsStable ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DIGITAL WEIGHBRIDGE INDICATOR (الیکٹرانک ترازو)',
                    style: TextStyle(
                      color: Colors.blueGrey.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _scaleIsStable
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _scaleIsStable
                        ? Colors.greenAccent.withValues(alpha: 0.5)
                        : Colors.orangeAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _scaleIsStable ? 'STABLE (ST)' : 'MOTION (US)',
                  style: TextStyle(
                    color: _scaleIsStable ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _numberFmt.format(_liveScaleWeight),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'KG',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '≈ ${_numberFmt.format(_liveScaleWeight / 40.0)} Maunds (من)',
                    style: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaleService().startSimulation(targetWeightKg: 8520.0);
                    },
                    icon: const Icon(Icons.play_arrow, size: 14),
                    label: const Text('Simulate Truck'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.blueGrey.shade600),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () {
                      ScaleService().zeroScale();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                      side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    child: const Text('Zero (0.0)'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary KPI Cards ──────────────────────────────────────────────────────
  Widget _buildKpiSection(WeighbridgeSummary s) {
    return Row(
      children: [
        _buildStatCard(
          label: 'Awaiting Tare (خالی گاڑی باقی)',
          value: '${s.awaitingTareCount}',
          subtitle: 'Pending 2nd weight',
          icon: Icons.rv_hookup,
          color: s.awaitingTareCount > 0 ? Colors.orange : Colors.grey,
          isAlert: s.awaitingTareCount > 0,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          label: 'Completed Slips (مکمل)',
          value: '${s.completedCount}',
          subtitle: 'Certified slips',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          label: 'Net Weighed (کل وزن)',
          value: '${_currencyFmt.format(s.totalFinalWeightKg)} KG',
          subtitle: '${_numberFmt.format(s.totalFinalMaunds)} Maunds',
          icon: Icons.fitness_center,
          color: MColors.primary,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          label: 'Kanda Fee (کنڈا فیس)',
          value: 'Rs. ${_currencyFmt.format(s.totalKandaFee)}',
          subtitle: 'Revenue collected',
          icon: Icons.receipt_long_outlined,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isAlert = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: MRadius.md,
          border: Border.all(
            color: isAlert ? color : color.withValues(alpha: 0.25),
            width: isAlert ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search & Filter Tabs ───────────────────────────────────────────────────
  Widget _buildSearchAndFilters(WeighbridgeProvider wbProv) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by vehicle plate, slip #, party, driver...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            wbProv.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: MRadius.md,
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: (val) => wbProv.setSearchQuery(val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildFilterChip(
              label: 'All Tickets (${wbProv.tickets.length})',
              isSelected: wbProv.filter == 'all',
              onTap: () => wbProv.setFilter('all'),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label:
                  'Awaiting Tare (${wbProv.tickets.where((t) => t.isAwaitingTare).length})',
              isSelected: wbProv.filter == 'awaitingTare',
              onTap: () => wbProv.setFilter('awaitingTare'),
              badgeColor: Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label:
                  'Completed (${wbProv.tickets.where((t) => t.status == WeighbridgeStatus.completed).length})',
              isSelected: wbProv.filter == 'completed',
              onTap: () => wbProv.setFilter('completed'),
              badgeColor: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: MRadius.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (badgeColor ?? MColors.primary).withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: MRadius.sm,
          border: Border.all(
            color: isSelected
                ? (badgeColor ?? MColors.primary)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (badgeColor ?? MColors.primary)
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ── Ticket Card Widget ─────────────────────────────────────────────────────
  Widget _buildTicketCard(
    WeighbridgeTicket ticket,
    String shopName,
    WeighbridgeProvider wbProv,
  ) {
    final isAwaiting = ticket.isAwaitingTare;
    final cardBorderColor = isAwaiting ? Colors.orange : Colors.grey.shade300;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: MRadius.md,
        side: BorderSide(
          color: cardBorderColor,
          width: isAwaiting ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Slip #, Vehicle, Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MColors.primary.withValues(alpha: 0.1),
                        borderRadius: MRadius.sm,
                      ),
                      child: Text(
                        ticket.ticketNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: MColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ticket.vehicleNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${ticket.vehicleType.labelEnglish})',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isAwaiting
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isAwaiting
                        ? 'Awaiting Tare (خالی وزن باقی)'
                        : 'Completed (مکمل)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAwaiting ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Party & Commodity Info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  ticket.partyName.isEmpty ? 'Walk-in Party' : ticket.partyName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.grass_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  ticket.commodityName.isEmpty
                      ? 'General Crop'
                      : ticket.commodityName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (ticket.bagCount > 0) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.bagCount} Bags',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Weight Metrics Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWeightCell(
                  '1st Gross (بھرا)',
                  '${_numberFmt.format(ticket.grossWeightKg)} KG',
                  '${_numberFmt.format(ticket.grossMaunds)} Maunds',
                  Colors.blueGrey.shade800,
                ),
                _buildWeightCell(
                  '2nd Tare (خالی)',
                  ticket.tareWeightKg > 0
                      ? '${_numberFmt.format(ticket.tareWeightKg)} KG'
                      : 'Pending Tare...',
                  ticket.tareWeightKg > 0
                      ? '${_numberFmt.format(ticket.tareMaunds)} Maunds'
                      : 'Awaiting',
                  ticket.tareWeightKg > 0 ? Colors.black87 : Colors.orange,
                ),
                _buildWeightCell(
                  'Net Weight (صاف)',
                  '${_numberFmt.format(ticket.computedNetWeightKg)} KG',
                  '${_numberFmt.format(ticket.netMaunds)} Maunds',
                  Colors.blue.shade800,
                ),
                _buildWeightCell(
                  'Final Billable (خالص)',
                  '${_numberFmt.format(ticket.computedFinalWeightKg)} KG',
                  '${_numberFmt.format(ticket.maunds)} Maunds',
                  MColors.primary,
                  isHighlight: true,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kanda Fee: Rs. ${_currencyFmt.format(ticket.kandaFee)} (${ticket.feePaidBy.labelEnglish})',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Row(
                  children: [
                    if (isAwaiting)
                      ElevatedButton.icon(
                        onPressed: () => _openRecordTareDialog(ticket),
                        icon: const Icon(Icons.rv_hookup, size: 16),
                        label: const Text('Record Tare (خالی وزن)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      )
                    else ...[
                      OutlinedButton.icon(
                        onPressed: () =>
                            _createConsignmentLotFromTicket(ticket),
                        icon: const Icon(Icons.inventory, size: 14),
                        label: const Text('Create Lot (ڈھیری)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _printThermalTicketSlip(shopName, ticket),
                        icon: const Icon(Icons.receipt_long, size: 18),
                        tooltip: 'Print 58mm/80mm Thermal Slip (تھرمل پرچی)',
                        color: Colors.blueGrey.shade800,
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: () => _printTicketSlip(shopName, ticket),
                        icon: const Icon(Icons.print, size: 14),
                        label: const Text('Print A4 (پرچی)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCell(
    String title,
    String valueKg,
    String valueMaunds,
    Color color, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isHighlight ? color : Colors.grey,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valueKg,
          style: TextStyle(
            fontSize: isHighlight ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          valueMaunds,
          style: TextStyle(
            fontSize: 9,
            color: isHighlight ? Colors.green.shade800 : Colors.grey,
          ),
        ),
      ],
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(WeighbridgeProvider wbProv) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.scale_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No Weighbridge Tickets Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            wbProv.searchQuery.isNotEmpty
                ? 'No tickets match "${wbProv.searchQuery}".'
                : 'Click "Record 1st Weight" to record a new vehicle arriving at the weighbridge.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openRecordGrossDialog,
            icon: const Icon(Icons.add),
            label: const Text('Record 1st Weight (بھرا گاڑی)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
