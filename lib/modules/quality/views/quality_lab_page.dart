import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/quality_inspection_pdf_generator.dart';
import 'package:mandi/data/models/quality_inspection_model.dart';
import 'package:mandi/modules/quality/providers/quality_provider.dart';
import 'package:mandi/modules/quality/views/log_cold_chain_temp_dialog.dart';
import 'package:mandi/modules/quality/views/new_quality_inspection_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Central Quality Control Lab, Moisture Testing, Katoti Deductions,
/// and Cold Chain Storage Monitoring Page
/// (*جنس لیب کوالٹی گریڈنگ، نمی کٹوتی، اور کولڈ روم ٹمپریچر لاگ*).
class QualityLabPage extends StatefulWidget {
  const QualityLabPage({super.key});

  @override
  State<QualityLabPage> createState() => _QualityLabPageState();
}

class _QualityLabPageState extends State<QualityLabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QualityProvider>().loadQualityData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openNewInspectionDialog() {
    showDialog(
      context: context,
      builder: (_) => const NewQualityInspectionDialog(),
    );
  }

  void _openLogTempDialog([String? chamber]) {
    showDialog(
      context: context,
      builder: (_) => LogColdChainTempDialog(preselectedChamber: chamber),
    );
  }

  void _printCertificate(QualityInspection inspection) {
    final shop = context.read<ShopContextProvider>().currentShop;
    QualityInspectionPdfGenerator.printQualityCertificate(
      inspection: inspection,
      shopName: shop?.name ?? 'Mandi Trading Co.',
      shopAddress: shop?.address,
      shopPhone: shop?.phone,
    );
  }

  void _printColdChainAudit(List<ColdChainLog> logs) {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No cold chain logs to export.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final shop = context.read<ShopContextProvider>().currentShop;
    QualityInspectionPdfGenerator.printColdChainLogSheet(
      logs: logs,
      shopName: shop?.name ?? 'Mandi Trading Co.',
      shopAddress: shop?.address,
      shopPhone: shop?.phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QualityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Lab & Moisture (جنس کوالٹی لیب)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Lab Data',
            onPressed: () => provider.loadQualityData(),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.ac_unit, size: 18),
            label: const Text('Log Temp'),
            onPressed: () => _openLogTempDialog(),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New Lab Test (ٹیسٹ)'),
            onPressed: _openNewInspectionDialog,
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.teal,
          indicatorWeight: 3,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              icon: Icon(Icons.biotech_outlined),
              text: 'Quality & Moisture (کوالٹی سرٹیفکیٹ)',
            ),
            Tab(
              icon: Icon(Icons.ac_unit_outlined),
              text: 'Cold Chain Temp (کولڈ روم لاگ)',
            ),
            Tab(
              icon: Icon(Icons.menu_book_outlined),
              text: 'Deductions Matrix (کٹوتی رولز)',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // KPI Metric Banner
          _buildKpiMetricsBanner(provider),

          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQualityTestsTab(provider),
                _buildColdChainTab(provider),
                _buildDeductionsMatrixTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Lab Inspection'),
        onPressed: _openNewInspectionDialog,
      ),
    );
  }

  // ===========================================================================
  // KPI METRICS BANNER
  // ===========================================================================

  Widget _buildKpiMetricsBanner(QualityProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiTile(
              label: 'Total Inspected / ٹیسٹ شدہ',
              value: '${provider.totalInspectionsCount} Samples',
              subtitle: '${provider.certifiedCount} Certified',
              color: Colors.teal,
              icon: Icons.biotech,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'Avg Moisture / اوسط نمی',
              value: '${provider.averageMoisture.toStringAsFixed(1)} %',
              subtitle: 'Base Standard: 14%',
              color: Colors.blue,
              icon: Icons.water_drop,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'Gross Tested / وزن بھرا',
              value:
                  '${_currencyFmt.format(provider.totalGrossWeightKg)} KG',
              subtitle:
                  '(${((provider.totalGrossWeightKg) / 40.0).toStringAsFixed(0)} Maunds)',
              color: Colors.indigo,
              icon: Icons.scale,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'Total Katoti / کٹوتی وزن',
              value:
                  '- ${_currencyFmt.format(provider.totalDeductionWeightKg)} KG',
              subtitle: 'Moisture + Refraction',
              color: Colors.red,
              icon: Icons.remove_circle_outline,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'Net Certified / صاف وزن',
              value:
                  '${provider.totalNetWeightMaunds.toStringAsFixed(0)} Maunds',
              subtitle:
                  '${_currencyFmt.format(provider.totalNetWeightKg)} KG',
              color: Colors.green,
              icon: Icons.verified_outlined,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'Cold Chain Alerts / خطرہ',
              value: '${provider.activeColdChainAlerts} Warnings',
              subtitle: 'Temperature Excursions',
              color: provider.activeColdChainAlerts > 0
                  ? Colors.redAccent
                  : Colors.blueGrey,
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              Text(
                value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
              Text(subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: COMMODITY QUALITY & MOISTURE TESTS
  // ===========================================================================

  Widget _buildQualityTestsTab(QualityProvider provider) {
    final inspections = provider.filteredInspections;

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText:
                        'Search certificate #, commodity, party, or vehicle...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => provider.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 12),
              // Grade Filter
              DropdownButton<QualityGrade?>(
                value: provider.selectedGrade,
                hint: const Text('All Grades'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All Grades (تمام گریڈز)')),
                  DropdownMenuItem(
                      value: QualityGrade.gradeASuper,
                      child: Text(QualityGrade.gradeASuper.labelEnglish)),
                  DropdownMenuItem(
                      value: QualityGrade.gradeBFaq,
                      child: Text(QualityGrade.gradeBFaq.labelEnglish)),
                  DropdownMenuItem(
                      value: QualityGrade.gradeCSubstandard,
                      child: Text(QualityGrade.gradeCSubstandard.labelEnglish)),
                  DropdownMenuItem(
                      value: QualityGrade.rejected,
                      child: Text(QualityGrade.rejected.labelEnglish)),
                ],
                onChanged: (val) => provider.setGradeFilter(val),
              ),
              const SizedBox(width: 12),
              // Commodity Filter
              if (provider.availableCommodities.isNotEmpty)
                DropdownButton<String?>(
                  value: provider.selectedCommodity,
                  hint: const Text('All Crops'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Crops (تمام اجناس)')),
                    ...provider.availableCommodities.map((c) {
                      return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 12)));
                    }),
                  ],
                  onChanged: (val) => provider.setCommodityFilter(val),
                ),
            ],
          ),
        ),

        // Inspection Cards List
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : inspections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.biotech_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No Quality Inspections Found / کوئی لیب ٹیسٹ نہیں',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Perform grain moisture tests and calculate certified weight katoti.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('New Lab Test (نیا ٹیسٹ)'),
                            onPressed: _openNewInspectionDialog,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: inspections.length,
                      itemBuilder: (context, index) {
                        final item = inspections[index];
                        return _buildInspectionCard(item);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildInspectionCard(QualityInspection item) {
    Color gradeColor;
    switch (item.qualityGrade) {
      case QualityGrade.gradeASuper:
        gradeColor = Colors.green;
        break;
      case QualityGrade.gradeBFaq:
        gradeColor = Colors.blue;
        break;
      case QualityGrade.gradeCSubstandard:
        gradeColor = Colors.orange;
        break;
      case QualityGrade.rejected:
        gradeColor = Colors.red;
        break;
    }

    final excessMoisture =
        (item.moisturePercentage - item.baseMoisturePercentage)
            .clamp(0.0, 50.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Cert #, Date, Grade Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.verified,
                          color: Colors.teal, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.certificateNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: MColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: gradeColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        item.qualityGrade.labelEnglish,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: gradeColor),
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a')
                      .format(item.inspectionDate),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Commodity, Variety, Vehicle, Party
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.commodityName} ${item.variety.isNotEmpty ? '(${item.variety})' : ''} • ${item.partyName.isNotEmpty ? 'Party: ${item.partyName}' : 'General Lot'}${item.vehicleNumber.isNotEmpty ? ' • Vehicle: ${item.vehicleNumber}' : ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lab Metrics Breakdown
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _metricItem('Moisture',
                      '${item.moisturePercentage.toStringAsFixed(1)} % (Base ${item.baseMoisturePercentage.toStringAsFixed(0)}%)'),
                  _metricItem('Excess Moist.',
                      '+ ${excessMoisture.toStringAsFixed(1)} %',
                      color: excessMoisture > 0 ? Colors.blue : null),
                  _metricItem('Trash / Foreign',
                      '${item.foreignMatterPercentage.toStringAsFixed(1)} %'),
                  _metricItem('Broken Grain',
                      '${item.brokenGrainPercentage.toStringAsFixed(1)} %'),
                  _metricItem('Damaged',
                      '${item.damagedGrainPercentage.toStringAsFixed(1)} %'),
                  _metricItem('Total Katoti',
                      '- ${item.totalDeductionPercentage.toStringAsFixed(2)} %',
                      color: Colors.red, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Weight Deduction & Net Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gross Weight (بھرا)',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text('${_currencyFmt.format(item.grossWeightKg)} KG',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Katoti Weight (کٹوتی)',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                        '- ${_currencyFmt.format(item.deductionWeightKg)} KG',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.red)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Net Certified (صاف وزن)',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                      '${_currencyFmt.format(item.netWeightKg)} KG (${item.netWeightMaunds.toStringAsFixed(1)} Maunds)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print Cert A4',
                      style: TextStyle(fontSize: 12)),
                  onPressed: () => _printCertificate(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String title, String val,
      {Color? color, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: COLD CHAIN TEMPERATURE MONITORING
  // ===========================================================================

  Widget _buildColdChainTab(QualityProvider provider) {
    final logs = provider.filteredColdChainLogs;

    return Column(
      children: [
        // Filter bar & Print Audit Sheet action
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Filter by Chamber: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  DropdownButton<String?>(
                    value: provider.selectedChamber,
                    hint: const Text('All Chambers'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Chambers (تمام رومز)')),
                      ...provider.availableChambers.map((c) {
                        return DropdownMenuItem(
                            value: c,
                            child:
                                Text(c, style: const TextStyle(fontSize: 12)));
                      }),
                    ],
                    onChanged: (val) => provider.setChamberFilter(val),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print Audit Sheet'),
                    onPressed: () => _printColdChainAudit(logs),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Log Temp Reading'),
                    onPressed: () =>
                        _openLogTempDialog(provider.selectedChamber),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cold Chain Logs List
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ac_unit_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No Cold Chain Temperature Logs Found',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Record daily cold room core temperatures and humidity readings.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final statusColor = log.status == ColdChainStatus.optimal
                        ? Colors.green
                        : (log.status == ColdChainStatus.warning
                            ? Colors.orange
                            : Colors.red);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.thermostat, color: statusColor),
                        ),
                        title: Row(
                          children: [
                            Text(
                              log.chamberName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                log.status.labelEnglish.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${log.temperatureCelsius.toStringAsFixed(1)} °C',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Humidity: ${log.humidityPercentage.toStringAsFixed(0)} % RH • Safe: ${log.minTempThreshold.toStringAsFixed(0)}-${log.maxTempThreshold.toStringAsFixed(0)} °C • Sensor: ${log.sensorDeviceId.isEmpty ? 'Probe' : log.sensorDeviceId}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                DateFormat('dd MMM, hh:mm a')
                                    .format(log.recordedAt),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: DEDUCTIONS MATRIX & QUALITY STANDARDS
  // ===========================================================================

  Widget _buildDeductionsMatrixTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mandi Standard Moisture & Katoti Matrix (کٹوتی رولز و شیڈول)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Official reference standards for moisture baselines and laboratory dockage multipliers.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Standard Grain Moisture Baselines
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.grass, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'Standard Crop Moisture Limits (معیاری نمی کی حد)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildMatrixRow('Wheat (گندم)', '12.0 %',
                      'Above 12% : 1:1 weight shrinkage deduction'),
                  _buildMatrixRow('Paddy / Rice (دھان / چاول)', '14.0 %',
                      'Above 14% : 1:1 deduction; above 22% rejected'),
                  _buildMatrixRow('Corn / Maize (مکئی)', '14.0 %',
                      'Above 14% : 1:1 drying katoti; mold risk above 18%'),
                  _buildMatrixRow('Cotton / Phutti (پھٹی)', '8.0 %',
                      'Moisture above 8% causes lint discoloration'),
                  _buildMatrixRow('Canola & Oilseeds (کینولا و سرسوں)', '9.0 %',
                      'High moisture causes rancidity & acidity spike'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Refraction & Dockage Multipliers
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Refraction Dockage Rules (کچرا و ٹوٹا دانہ رولز)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildMatrixRow('Foreign Matter (کچرا و ریت)', '1:1 Katoti',
                      'Every 1% trash deducts 1% gross payload directly'),
                  _buildMatrixRow('Broken Grain (ٹوٹا دانہ)', '0.5:1 Katoti',
                      'Deduction factor of 50% applied to broken kernels'),
                  _buildMatrixRow('Damaged / Weeviled (داغی و کیڑا)',
                      '0.75:1 Katoti',
                      'Deduction factor of 75% applied to insect-bored kernels'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cold Storage Optimal Conditions
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.ac_unit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Cold Storage HACCP Climatic Bands (کولڈ روم حالات)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildMatrixRow('Potatoes (آلو برائے بیج و خوراک)',
                      '2.0 °C to 4.0 °C', 'Relative Humidity: 85 - 90 % RH'),
                  _buildMatrixRow('Apples (سیب)', '-1.0 °C to 2.0 °C',
                      'Relative Humidity: 90 - 95 % RH'),
                  _buildMatrixRow('Dry Onions (پیاز)', '0.0 °C to 2.0 °C',
                      'Relative Humidity: 65 - 70 % RH (Dry Air Circulation)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(String item, String target, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(item,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(target,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.teal)),
          ),
          Expanded(
            flex: 3,
            child: Text(note,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}
