import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
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
  StreamSubscription<ScaleReading>? _scaleSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeScale();
  }

  void _subscribeScale() {
    _scaleSubscription = ScaleService().readingStream.listen((reading) {
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
    _scaleSubscription?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openRecordGrossDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NewWeighbridgeTicketDialog(),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openRecordTareDialog(WeighbridgeTicket ticket) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecordTareDialog(ticket: ticket),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _printTicketSlip(
    String shopName,
    WeighbridgeTicket ticket,
  ) async {
    try {
      final pdfBytes = await WeighbridgeSlipPdfGenerator.generateSlipPdf(
        shopName: shopName,
        ticket: ticket,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Weighbridge_Slip_${ticket.ticketNumber}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.val(context, en: "Print error", ur: "پرنٹنگ میں خرابی")}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportRegisterPdf(
    String shopName,
    WeighbridgeProvider wbProv,
  ) async {
    try {
      final pdfBytes = await WeighbridgeSlipPdfGenerator.generateRegisterPdf(
        shopName: shopName,
        tickets: wbProv.filteredTickets,
        summary: wbProv.summary,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Weighbridge_Daily_Register.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.val(context, en: "Register export error", ur: "رجسٹر ایکسپورٹ میں خرابی")}: $e'),
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
    final isUrdu = AppStrings.isUrdu(context);
    final shop = context.read<ShopContextProvider>().currentShop;
    final lines = [
      '*** ${shopName.toUpperCase()} ***',
      if (shop?.city != null && shop!.city.isNotEmpty)
        '${isUrdu ? "منڈی" : "Mandi"}: ${shop.city}',
      if (shop?.phone != null && shop!.phone.isNotEmpty)
        '${isUrdu ? "فون" : "Ph"}: ${shop.phone}',
      '--------------------------------',
      isUrdu ? '*** دھرم کنڈا وزن پرچی ***' : '*** DHARAM KANDA WEIGHMENT ***',
      '${isUrdu ? "پرچی نمبر" : "Ticket #"}: ${ticket.ticketNumber}',
      '${isUrdu ? "گاڑی" : "Vehicle"}: ${ticket.vehicleNumber} (${isUrdu ? ticket.vehicleType.labelUrdu : ticket.vehicleType.labelEnglish})',
      '${isUrdu ? "کھاتہ" : "Party"}: ${ticket.partyName.isNotEmpty ? ticket.partyName : (isUrdu ? "عام" : "Walk-in")}',
      '${isUrdu ? "جنس" : "Commodity"}: ${ticket.commodityName}',
      if (ticket.driverName.isNotEmpty)
        '${isUrdu ? "ڈرائیور" : "Driver"}: ${ticket.driverName}',
      if (ticket.bagCount > 0)
        '${isUrdu ? "بوریاں" : "Bags"}: ${ticket.bagCount}',
      '--------------------------------',
      '${isUrdu ? "پہلا بھرا وزن" : "1st Gross Wt"}: ${ticket.grossWeightKg.toStringAsFixed(0)} KG (${ticket.grossMaunds.toStringAsFixed(2)} M)',
      '${isUrdu ? "دوسرا خالی وزن" : "2nd Tare Wt"}:  ${ticket.tareWeightKg.toStringAsFixed(0)} KG (${ticket.tareMaunds.toStringAsFixed(2)} M)',
      '${isUrdu ? "صاف وزن" : "Net Weight"}:   ${ticket.computedNetWeightKg.toStringAsFixed(0)} KG (${ticket.netMaunds.toStringAsFixed(2)} M)',
      if (ticket.deductionKg > 0)
        '${isUrdu ? "کٹوتی" : "Katoti"}:       -${ticket.deductionKg.toStringAsFixed(0)} KG (${ticket.deductionReason})',
      '================================',
      '${isUrdu ? "خالص بل وزن" : "FINAL WEIGHT"}: ${ticket.computedFinalWeightKg.toStringAsFixed(0)} KG',
      '              (${ticket.maunds.toStringAsFixed(2)} ${isUrdu ? "من" : "Maunds"})',
      '${isUrdu ? "کنڈا فیس" : "Kanda Fee"}:    Rs. ${ticket.kandaFee.toStringAsFixed(0)}',
      '--------------------------------',
      '${isUrdu ? "دستخط ڈرائیور" : "Driver"}: ________  ${isUrdu ? "کنڈا انچارج" : "Incharge"}: ________',
      isUrdu ? '*** تصدیق شدہ منڈی کنڈا پرچی ***' : '*** Certified Mandi Weighment ***',
    ];

    ThermalPrintPreviewDialog.show(
      context: context,
      title: AppStrings.val(context, en: 'Kanda Thermal Slip', ur: 'تھرمل کنڈا پرچی'),
      subtitle: '${AppStrings.val(context, en: "Ticket", ur: "پرچی")} #${ticket.ticketNumber} • ${ticket.vehicleNumber}',
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

  void _createConsignmentLotFromTicket(WeighbridgeTicket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddConsignmentLotPage(
          initialVehicleNumber: ticket.vehicleNumber,
          initialWeightKg: ticket.computedFinalWeightKg,
          initialBags: ticket.bagCount,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.val(context, en: 'Mandi Weighbridge', ur: 'دھرم کنڈا'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              AppStrings.val(
                context,
                en: 'Electronic Scale & Vehicle Gross/Tare Weighment',
                ur: 'الیکٹرانک ترازو و گاڑی کا بھرا/خالی وزن',
              ),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: AppStrings.val(context, en: 'Export Register PDF', ur: 'کنڈا رجسٹر پی ڈی ایف'),
            onPressed: () => _exportRegisterPdf(shopName, wbProv),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.val(context, en: 'Refresh Tickets', ur: 'تازہ ترین کریں'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppStrings.val(
                      context,
                      en: 'Weighbridge data updated in real-time',
                      ur: 'کنڈا ریکارڈ کی تازہ ترین معلومات موصول ہو گئی ہیں',
                    ),
                  ),
                  duration: const Duration(seconds: 1),
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
        label: Text(
          AppStrings.val(context, en: 'Record 1st Weight', ur: 'پہلا وزن محفوظ کریں'),
        ),
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

                  // ── KPI Metrics Section ────────────────────────────────────────
                  _buildKpiSection(wbProv.summary),

                  const SizedBox(height: 20),

                  // ── Search & Filter Controls ───────────────────────────────────
                  _buildSearchAndFilters(wbProv),

                  const SizedBox(height: 16),

                  // ── Tickets List or Empty State ────────────────────────────────
                  if (wbProv.filteredTickets.isEmpty)
                    _buildEmptyState(wbProv)
                  else
                    ...wbProv.filteredTickets.map(
                      (ticket) => _buildTicketCard(ticket, shopName, wbProv),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // ── Live Digital Scale Banner ──────────────────────────────────────────────
  Widget _buildLiveScaleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            Colors.blueGrey.shade900,
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
                    AppStrings.val(
                      context,
                      en: 'DIGITAL WEIGHBRIDGE INDICATOR',
                      ur: 'الیکٹرانک کنڈا پیمانہ',
                    ),
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
                  _scaleIsStable
                      ? AppStrings.val(context, en: 'STABLE (ST)', ur: 'مستحکم (ST)')
                      : AppStrings.val(context, en: 'MOTION (US)', ur: 'متحرک (US)'),
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
                    '≈ ${_numberFmt.format(_liveScaleWeight / 40.0)} ${AppStrings.val(context, en: "Maunds", ur: "من")}',
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
                    label: Text(
                      AppStrings.val(context, en: 'Simulate Truck', ur: 'ٹرک نمونہ'),
                    ),
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
                    child: Text(
                      AppStrings.val(context, en: 'Zero (0.0)', ur: 'صفر کریں (0.0)'),
                    ),
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
          label: AppStrings.val(context, en: 'Awaiting Tare', ur: 'خالی گاڑی باقی'),
          value: '${s.awaitingTareCount}',
          subtitle: AppStrings.val(context, en: 'Pending 2nd weight', ur: 'دوسرا وزن باقی'),
          icon: Icons.rv_hookup,
          color: s.awaitingTareCount > 0 ? Colors.orange : Colors.grey,
          isAlert: s.awaitingTareCount > 0,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          label: AppStrings.val(context, en: 'Completed Slips', ur: 'مکمل پرچیاں'),
          value: '${s.completedCount}',
          subtitle: AppStrings.val(context, en: 'Certified slips', ur: 'تصدیق شدہ پرچیاں'),
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          label: AppStrings.val(context, en: 'Net Weighed', ur: 'صاف کل وزن'),
          value: '${_currencyFmt.format(s.totalFinalWeightKg)} KG',
          subtitle: '${_numberFmt.format(s.totalFinalMaunds)} ${AppStrings.val(context, en: "Maunds", ur: "من")}',
          icon: Icons.fitness_center,
          color: MColors.primary,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          label: AppStrings.val(context, en: 'Kanda Fee', ur: 'کنڈا فیس'),
          value: 'Rs. ${_currencyFmt.format(s.totalKandaFee)}',
          subtitle: AppStrings.val(context, en: 'Revenue collected', ur: 'حاصل شدہ آمدن'),
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
                  hintText: AppStrings.val(
                    context,
                    en: 'Search by vehicle plate, slip #, party, driver...',
                    ur: 'گاڑی نمبر، پرچی، کھاتہ، یا ڈرائیور سے تلاش کریں...',
                  ),
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
              label: AppStrings.val(
                context,
                en: 'All Tickets (${wbProv.tickets.length})',
                ur: 'تمام پرچیاں (${wbProv.tickets.length})',
              ),
              isSelected: wbProv.filter == 'all',
              onTap: () => wbProv.setFilter('all'),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: AppStrings.val(
                context,
                en: 'Awaiting Tare (${wbProv.tickets.where((t) => t.isAwaitingTare).length})',
                ur: 'خالی وزن باقی (${wbProv.tickets.where((t) => t.isAwaitingTare).length})',
              ),
              isSelected: wbProv.filter == 'awaitingTare',
              onTap: () => wbProv.setFilter('awaitingTare'),
              badgeColor: Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: AppStrings.val(
                context,
                en: 'Completed (${wbProv.tickets.where((t) => t.status == WeighbridgeStatus.completed).length})',
                ur: 'مکمل شدہ (${wbProv.tickets.where((t) => t.status == WeighbridgeStatus.completed).length})',
              ),
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
    final isUrdu = AppStrings.isUrdu(context);
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
                      '(${isUrdu ? ticket.vehicleType.labelUrdu : ticket.vehicleType.labelEnglish})',
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
                        ? AppStrings.val(context, en: 'Awaiting Tare', ur: 'خالی وزن باقی')
                        : AppStrings.val(context, en: 'Completed', ur: 'مکمل'),
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
                  ticket.partyName.isEmpty
                      ? AppStrings.val(context, en: 'Walk-in Party', ur: 'عام کھاتہ')
                      : ticket.partyName,
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
                      ? AppStrings.val(context, en: 'General Crop', ur: 'عام جنس')
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
                    '${ticket.bagCount} ${AppStrings.val(context, en: "Bags", ur: "بوریاں")}',
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
                  AppStrings.val(context, en: '1st Gross', ur: 'پہلا بھرا وزن'),
                  '${_numberFmt.format(ticket.grossWeightKg)} KG',
                  '${_numberFmt.format(ticket.grossMaunds)} ${AppStrings.val(context, en: "Maunds", ur: "من")}',
                  Colors.blueGrey.shade800,
                ),
                _buildWeightCell(
                  AppStrings.val(context, en: '2nd Tare', ur: 'دوسرا خالی وزن'),
                  ticket.tareWeightKg > 0
                      ? '${_numberFmt.format(ticket.tareWeightKg)} KG'
                      : AppStrings.val(context, en: 'Pending Tare...', ur: 'خالی وزن باقی...'),
                  ticket.tareWeightKg > 0
                      ? '${_numberFmt.format(ticket.tareMaunds)} ${AppStrings.val(context, en: "Maunds", ur: "من")}'
                      : AppStrings.val(context, en: 'Awaiting', ur: 'انتظار'),
                  ticket.tareWeightKg > 0 ? Colors.black87 : Colors.orange,
                ),
                _buildWeightCell(
                  AppStrings.val(context, en: 'Net Weight', ur: 'صاف وزن'),
                  '${_numberFmt.format(ticket.computedNetWeightKg)} KG',
                  '${_numberFmt.format(ticket.netMaunds)} ${AppStrings.val(context, en: "Maunds", ur: "من")}',
                  Colors.blue.shade800,
                ),
                _buildWeightCell(
                  AppStrings.val(context, en: 'Final Billable', ur: 'خالص وزن'),
                  '${_numberFmt.format(ticket.computedFinalWeightKg)} KG',
                  '${_numberFmt.format(ticket.maunds)} ${AppStrings.val(context, en: "Maunds", ur: "من")}',
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
                  '${AppStrings.val(context, en: "Kanda Fee", ur: "کنڈا فیس")}: Rs. ${_currencyFmt.format(ticket.kandaFee)} (${isUrdu ? ticket.feePaidBy.labelUrdu : ticket.feePaidBy.labelEnglish})',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Row(
                  children: [
                    if (isAwaiting)
                      ElevatedButton.icon(
                        onPressed: () => _openRecordTareDialog(ticket),
                        icon: const Icon(Icons.rv_hookup, size: 16),
                        label: Text(
                          AppStrings.val(context, en: 'Record Tare', ur: 'خالی وزن درج کریں'),
                        ),
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
                        label: Text(
                          AppStrings.val(context, en: 'Create Lot', ur: 'ڈھیری بنائیں'),
                        ),
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
                        tooltip: AppStrings.val(
                          context,
                          en: 'Print Thermal Slip',
                          ur: 'تھرمل پرچی پرنٹ کریں',
                        ),
                        color: Colors.blueGrey.shade800,
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: () => _printTicketSlip(shopName, ticket),
                        icon: const Icon(Icons.print, size: 14),
                        label: Text(
                          AppStrings.val(context, en: 'Print A4', ur: 'A4 پرچی'),
                        ),
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
            fontSize: 11,
            color: isHighlight ? color : Colors.grey,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valueKg,
          style: TextStyle(
            fontSize: 13,
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
          Text(
            AppStrings.val(
              context,
              en: 'No Weighbridge Tickets Found',
              ur: 'کوئی کنڈا پرچی نہیں ملی',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            wbProv.searchQuery.isNotEmpty
                ? '${AppStrings.val(context, en: "No tickets match", ur: "کوئی پرچی نہیں ملی برائے")} "${wbProv.searchQuery}".'
                : AppStrings.val(
                    context,
                    en: 'Click "Record 1st Weight" to record a new vehicle arriving at the weighbridge.',
                    ur: 'کنڈا پر آنے والی نئی گاڑی کا وزن درج کرنے کے لیے "پہلا وزن محفوظ کریں" دبائیں',
                  ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openRecordGrossDialog,
            icon: const Icon(Icons.add),
            label: Text(
              AppStrings.val(
                context,
                en: 'Record 1st Weight',
                ur: 'پہلا وزن محفوظ کریں',
              ),
            ),
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
