import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
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
    final isUrdu = AppStrings.isUrdu(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.val(context, en: 'Quality Lab & Moisture', ur: 'کوالٹی و نمی ٹیسٹ لیب')),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.val(context, en: 'Refresh Lab Data', ur: 'تازہ کریں'),
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
            label: Text(AppStrings.val(context, en: 'Log Temp', ur: 'ٹمپریچر لاگ')),
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
            label: Text(AppStrings.val(context, en: 'New Lab Test', ur: 'نیا ٹیسٹ')),
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
          tabs: [
            Tab(
              icon: const Icon(Icons.biotech_outlined),
              text: AppStrings.val(context, en: 'Quality & Moisture', ur: 'کوالٹی و نمی سرٹیفکیٹ'),
            ),
            Tab(
              icon: const Icon(Icons.ac_unit_outlined),
              text: AppStrings.val(context, en: 'Cold Chain Temp', ur: 'کولڈ روم لاگ'),
            ),
            Tab(
              icon: const Icon(Icons.menu_book_outlined),
              text: AppStrings.val(context, en: 'Deductions Matrix', ur: 'کٹوتی کے اصول'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // KPI Metric Banner
          _buildKpiMetricsBanner(context, provider, isUrdu),

          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQualityTestsTab(context, provider, isUrdu),
                _buildColdChainTab(context, provider, isUrdu),
                _buildDeductionsMatrixTab(context, isUrdu),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.val(context, en: 'New Lab Inspection', ur: 'نیا کوالٹی معائنہ')),
        onPressed: _openNewInspectionDialog,
      ),
    );
  }

  // ===========================================================================
  // KPI METRICS BANNER
  // ===========================================================================

  Widget _buildKpiMetricsBanner(BuildContext context, QualityProvider provider, bool isUrdu) {
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
              label: AppStrings.val(context, en: 'Total Inspected', ur: 'کل ٹیسٹ شدہ'),
              value: '${provider.totalInspectionsCount} ${AppStrings.val(context, en: 'Samples', ur: 'نمونے')}',
              subtitle: '${provider.certifiedCount} ${AppStrings.val(context, en: 'Certified', ur: 'منظور شدہ')}',
              color: Colors.teal,
              icon: Icons.biotech,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: AppStrings.val(context, en: 'Avg Moisture', ur: 'اوسط نمی'),
              value: '${provider.averageMoisture.toStringAsFixed(1)} %',
              subtitle: '${AppStrings.val(context, en: 'Base Standard', ur: 'معیاری حد')}: 14%',
              color: Colors.blue,
              icon: Icons.water_drop,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: AppStrings.val(context, en: 'Gross Tested', ur: 'بھرا وزن'),
              value: '${_currencyFmt.format(provider.totalGrossWeightKg)} KG',
              subtitle:
                  '(${((provider.totalGrossWeightKg) / 40.0).toStringAsFixed(0)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')})',
              color: Colors.indigo,
              icon: Icons.scale,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: AppStrings.val(context, en: 'Total Katoti', ur: 'کل کٹوتی وزن'),
              value:
                  '- ${_currencyFmt.format(provider.totalDeductionWeightKg)} KG',
              subtitle: AppStrings.val(context, en: 'Moisture + Refraction', ur: 'نمی و کچرا کٹوتی'),
              color: Colors.red,
              icon: Icons.remove_circle_outline,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: AppStrings.val(context, en: 'Net Certified', ur: 'صاف وزن'),
              value:
                  '${provider.totalNetWeightMaunds.toStringAsFixed(0)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
              subtitle:
                  '${_currencyFmt.format(provider.totalNetWeightKg)} KG',
              color: Colors.green,
              icon: Icons.verified_outlined,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: AppStrings.val(context, en: 'Cold Chain Alerts', ur: 'کولڈ چین الرٹس'),
              value: '${provider.activeColdChainAlerts} ${AppStrings.val(context, en: 'Warnings', ur: 'انتباہ')}',
              subtitle: AppStrings.val(context, en: 'Temperature Excursions', ur: 'درجہ حرارت کا بگاڑ'),
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

  Widget _buildQualityTestsTab(BuildContext context, QualityProvider provider, bool isUrdu) {
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
                    hintText: AppStrings.val(
                      context,
                      en: 'Search certificate #, commodity, party, or vehicle...',
                      ur: 'سرٹیفکیٹ نمبر، جنس، پارٹی یا گاڑی تلاش کریں...',
                    ),
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
                hint: Text(AppStrings.val(context, en: 'All Grades', ur: 'تمام گریڈز')),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(AppStrings.val(context, en: 'All Grades', ur: 'تمام گریڈز')),
                  ),
                  ...QualityGrade.values.map((g) {
                    return DropdownMenuItem(
                      value: g,
                      child: Text(isUrdu ? g.labelUrdu : g.labelEnglish),
                    );
                  }),
                ],
                onChanged: (val) => provider.setGradeFilter(val),
              ),
              const SizedBox(width: 12),
              // Commodity Filter
              if (provider.availableCommodities.isNotEmpty)
                DropdownButton<String?>(
                  value: provider.selectedCommodity,
                  hint: Text(AppStrings.val(context, en: 'All Crops', ur: 'تمام اجناس')),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(AppStrings.val(context, en: 'All Crops', ur: 'تمام اجناس')),
                    ),
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
                          Text(
                            AppStrings.val(
                              context,
                              en: 'No Quality Inspections Found',
                              ur: 'کوئی کوالٹی معائنہ ریکارڈ نہیں ملا',
                            ),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Perform grain moisture tests and calculate certified weight katoti.',
                              ur: 'اناج کی نمی کا معائنہ کریں اور وزنی کٹوتی کا حساب لگائیں۔',
                            ),
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
                            label: Text(AppStrings.val(context, en: 'New Lab Test', ur: 'نیا ٹیسٹ')),
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
                        return _buildInspectionCard(context, item, isUrdu);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildInspectionCard(BuildContext context, QualityInspection item, bool isUrdu) {
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
                        isUrdu ? item.qualityGrade.labelUrdu : item.qualityGrade.labelEnglish,
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
                    '${item.commodityName} ${item.variety.isNotEmpty ? '(${item.variety})' : ''} • ${item.partyName.isNotEmpty ? "${AppStrings.val(context, en: 'Party', ur: 'پارٹی')}: ${item.partyName}" : AppStrings.val(context, en: 'General Lot', ur: 'عام لاٹ')}${item.vehicleNumber.isNotEmpty ? " • ${AppStrings.val(context, en: 'Vehicle', ur: 'گاڑی')}: ${item.vehicleNumber}" : ''}',
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
                  _metricItem(
                    AppStrings.val(context, en: 'Moisture', ur: 'نمی'),
                    '${item.moisturePercentage.toStringAsFixed(1)} % (${AppStrings.val(context, en: 'Base', ur: 'حد')} ${item.baseMoisturePercentage.toStringAsFixed(0)}%)',
                  ),
                  _metricItem(
                    AppStrings.val(context, en: 'Excess Moist.', ur: 'اضافی نمی'),
                    '+ ${excessMoisture.toStringAsFixed(1)} %',
                    color: excessMoisture > 0 ? Colors.blue : null,
                  ),
                  _metricItem(
                    AppStrings.val(context, en: 'Trash', ur: 'کچرا'),
                    '${item.foreignMatterPercentage.toStringAsFixed(1)} %',
                  ),
                  _metricItem(
                    AppStrings.val(context, en: 'Broken Grain', ur: 'ٹوٹا دانہ'),
                    '${item.brokenGrainPercentage.toStringAsFixed(1)} %',
                  ),
                  _metricItem(
                    AppStrings.val(context, en: 'Damaged', ur: 'داغی دانہ'),
                    '${item.damagedGrainPercentage.toStringAsFixed(1)} %',
                  ),
                  _metricItem(
                    AppStrings.val(context, en: 'Total Katoti', ur: 'کل کٹوتی'),
                    '- ${item.totalDeductionPercentage.toStringAsFixed(2)} %',
                    color: Colors.red,
                    isBold: true,
                  ),
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
                    Text(
                      AppStrings.val(context, en: 'Gross Weight', ur: 'بھرا وزن'),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text('${_currencyFmt.format(item.grossWeightKg)} KG',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.val(context, en: 'Katoti Weight', ur: 'کٹوتی وزن'),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
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
                    Text(
                      AppStrings.val(context, en: 'Net Certified', ur: 'صاف وزن'),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${_currencyFmt.format(item.netWeightKg)} KG (${item.netWeightMaunds.toStringAsFixed(1)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')})',
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
                  label: Text(
                    AppStrings.val(context, en: 'Print Cert A4', ur: 'پرنٹ سرٹیفکیٹ'),
                    style: const TextStyle(fontSize: 12),
                  ),
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

  Widget _buildColdChainTab(BuildContext context, QualityProvider provider, bool isUrdu) {
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
                  Text(
                    AppStrings.val(context, en: 'Filter by Chamber: ', ur: 'چیمبر فلٹر: '),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String?>(
                    value: provider.selectedChamber,
                    hint: Text(AppStrings.val(context, en: 'All Chambers', ur: 'تمام چیمبرز')),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.val(context, en: 'All Chambers', ur: 'تمام چیمبرز')),
                      ),
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
                    label: Text(AppStrings.val(context, en: 'Print Audit Sheet', ur: 'آڈٹ شیٹ پرنٹ کریں')),
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
                    label: Text(AppStrings.val(context, en: 'Log Temp Reading', ur: 'ٹمپریچر درج کریں')),
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
                      Text(
                        AppStrings.val(
                          context,
                          en: 'No Cold Chain Temperature Logs Found',
                          ur: 'کولڈ روم درجہ حرارت کا کوئی لاگ نہیں ملا',
                        ),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.val(
                          context,
                          en: 'Record daily cold room core temperatures and humidity readings.',
                          ur: 'روزانہ کولڈ روم درجہ حرارت اور نمی کی ریڈنگز درج کریں۔',
                        ),
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
                                isUrdu
                                    ? log.status.labelUrdu
                                    : log.status.labelEnglish.toUpperCase(),
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
                                '${AppStrings.val(context, en: 'Humidity', ur: 'نمی')}: ${log.humidityPercentage.toStringAsFixed(0)} % RH • ${AppStrings.val(context, en: 'Safe', ur: 'محفوظ')}: ${log.minTempThreshold.toStringAsFixed(0)}-${log.maxTempThreshold.toStringAsFixed(0)} °C • ${AppStrings.val(context, en: 'Sensor', ur: 'سینسر')}: ${log.sensorDeviceId.isEmpty ? (isUrdu ? 'پروب' : 'Probe') : log.sensorDeviceId}',
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

  Widget _buildDeductionsMatrixTab(BuildContext context, bool isUrdu) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.val(
              context,
              en: 'Mandi Standard Moisture & Katoti Matrix',
              ur: 'منڈی معیاری نمی و کٹوتی شیڈول',
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.val(
              context,
              en: 'Official reference standards for moisture baselines and laboratory dockage multipliers.',
              ur: 'نمی کی معیاری حدود اور لیب کٹوتی کے سرکاری و منڈی قواعد۔',
            ),
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
                  Row(
                    children: [
                      const Icon(Icons.grass, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.val(
                          context,
                          en: 'Standard Crop Moisture Limits',
                          ur: 'اجناس میں معیاری نمی کی حد',
                        ),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildMatrixRow(
                    isUrdu ? 'گندم' : 'Wheat',
                    '12.0 %',
                    isUrdu
                        ? '12% سے اوپر: 1:1 وزن کی سوکھی کٹوتی'
                        : 'Above 12% : 1:1 weight shrinkage deduction',
                  ),
                  _buildMatrixRow(
                    isUrdu ? 'دھان / چاول' : 'Paddy (Rice)',
                    '14.0 %',
                    isUrdu
                        ? '14% سے اوپر: 1:1 کٹوتی؛ 22% سے اوپر مال مسترد'
                        : 'Above 14% : 1:1 deduction; above 22% rejected',
                  ),
                  _buildMatrixRow(
                    isUrdu ? 'مکئی' : 'Corn (Maize)',
                    '14.0 %',
                    isUrdu
                        ? '14% سے اوپر: 1:1 ڈرائینگ کٹوتی؛ 18% سے اوپر الی کا خطرہ'
                        : 'Above 14% : 1:1 drying katoti; mold risk above 18%',
                  ),
                  _buildMatrixRow(
                    isUrdu ? 'پھٹی (کپاس)' : 'Cotton (Phutti)',
                    '8.0 %',
                    isUrdu
                        ? '8% سے زیادہ نمی روئی کی رنگت خراب کرتی ہے'
                        : 'Moisture above 8% causes lint discoloration',
                  ),
                  _buildMatrixRow(
                    isUrdu ? 'کینولا و سرسوں' : 'Canola & Oilseeds',
                    '9.0 %',
                    isUrdu
                        ? 'زیادہ نمی سے تیل میں تیزابیت اور بو پیدا ہوتی ہے'
                        : 'High moisture causes rancidity & acidity spike',
                  ),
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
                  Row(
                    children: [
                      const Icon(Icons.tune, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.val(
                          context,
                          en: 'Refraction Dockage Rules',
                          ur: 'کچرا و ٹوٹا دانہ کے اصول',
                        ),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildMatrixRow(
                    isUrdu ? 'کچرا و مٹی' : 'Foreign Matter',
                    isUrdu ? '1:1 کٹوتی' : '1:1 Katoti',
                    isUrdu
                        ? 'ہر 1% کچرا سیدھا 1% کل وزن سے منہا ہوتا ہے'
                        : 'Every 1% trash deducts 1% gross payload directly',
                  ),
                  _buildMatrixRow(
                    isUrdu ? 'ٹوٹا دانہ' : 'Broken Grain',
                    isUrdu ? '0.5:1 کٹوتی' : '0.5:1 Katoti',
                    isUrdu
                        ? 'ٹوٹے دانے پر 50% کٹوتی فیکٹر لاگو ہوتا ہے'
                        : 'Deduction factor of 50% applied to broken kernels',
                  ),
                  _buildMatrixRow(
                    isUrdu ? 'داغی و کیڑا زدہ' : 'Damaged / Weeviled',
                    isUrdu ? '0.75:1 کٹوتی' : '0.75:1 Katoti',
                    isUrdu
                        ? 'کیڑے یا داغی دانے پر 75% کٹوتی لاگو ہوتی ہے'
                        : 'Deduction factor of 75% applied to insect-bored kernels',
                  ),
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
                  Row(
                    children: [
                      const Icon(Icons.ac_unit, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.val(
                          context,
                          en: 'Cold Storage HACCP Climatic Bands',
                          ur: 'کولڈ سٹوریج موسمی حالات',
                        ),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildMatrixRow(
                    isUrdu ? 'آلو (بیج و خوراک)' : 'Potatoes',
                    isUrdu ? '2.0 °C تا 4.0 °C' : '2.0 °C to 4.0 °C',
                    isUrdu ? 'ہوا میں نمی: 85 - 90 % RH' : 'Relative Humidity: 85 - 90 % RH',
                  ),
                  _buildMatrixRow(
                    isUrdu ? 'سیب' : 'Apples',
                    isUrdu ? '-1.0 °C تا 2.0 °C' : '-1.0 °C to 2.0 °C',
                    isUrdu ? 'ہوا میں نمی: 90 - 95 % RH' : 'Relative Humidity: 90 - 95 % RH',
                  ),
                  _buildMatrixRow(
                    isUrdu ? 'خشک پیاز' : 'Dry Onions',
                    isUrdu ? '0.0 °C تا 2.0 °C' : '0.0 °C to 2.0 °C',
                    isUrdu
                        ? 'ہوا میں نمی: 65 - 70 % RH (خشک ہوا کا بہاؤ)'
                        : 'Relative Humidity: 65 - 70 % RH (Dry Air Circulation)',
                  ),
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
