import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/quality_inspection_model.dart';
import 'package:mandi/modules/quality/providers/quality_provider.dart';

/// Modal dialog to record laboratory quality analysis, grain moisture testing,
/// and automated katoti deductions (*جنس نمی، لیب کوالٹی گریڈنگ اور کٹوتی اندراج*).
class NewQualityInspectionDialog extends StatefulWidget {
  final String? preselectedCommodity;
  final String? preselectedLotId;
  final String? preselectedVehicleNumber;
  final String? preselectedPartyName;
  final double? preselectedGrossWeightKg;

  const NewQualityInspectionDialog({
    super.key,
    this.preselectedCommodity,
    this.preselectedLotId,
    this.preselectedVehicleNumber,
    this.preselectedPartyName,
    this.preselectedGrossWeightKg,
  });

  @override
  State<NewQualityInspectionDialog> createState() =>
      _NewQualityInspectionDialogState();
}

class _NewQualityInspectionDialogState
    extends State<NewQualityInspectionDialog> {
  final _formKey = GlobalKey<FormState>();

  final DateTime _inspectionDate = DateTime.now();

  final _commodityCtrl = TextEditingController(text: 'Corn / مکئی');
  final _varietyCtrl = TextEditingController(text: 'Pioneer 30Y87');
  final _vehicleCtrl = TextEditingController();
  final _partyCtrl = TextEditingController();
  final _grossWeightCtrl = TextEditingController(text: '12000');
  final _sampleWeightCtrl = TextEditingController(text: '500');

  final _moistureCtrl = TextEditingController(text: '16.5');
  final _baseMoistureCtrl = TextEditingController(text: '14.0');
  final _foreignMatterCtrl = TextEditingController(text: '1.2');
  final _brokenGrainCtrl = TextEditingController(text: '1.5');
  final _damagedGrainCtrl = TextEditingController(text: '0.8');

  final _tempCtrl = TextEditingController();
  final _humidityCtrl = TextEditingController();
  final _chamberCtrl = TextEditingController();
  final _testerNameCtrl = TextEditingController(text: 'Lab Munshi');
  final _notesCtrl = TextEditingController();

  QualityGrade? _selectedGrade;
  bool _isSaving = false;

  final List<String> _popularCommodities = [
    'Corn / مکئی (Maize)',
    'Wheat / گندم',
    'Paddy / دھان (Basmati Rice)',
    'Cotton / پھٹی (Phutti)',
    'Canola / کینولا (Rape Mustard)',
    'Potato / آلو',
    'Onion / پیاز',
    'Chana / چنا (Gram Pulses)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCommodity != null) {
      _commodityCtrl.text = widget.preselectedCommodity!;
    }
    if (widget.preselectedVehicleNumber != null) {
      _vehicleCtrl.text = widget.preselectedVehicleNumber!;
    }
    if (widget.preselectedPartyName != null) {
      _partyCtrl.text = widget.preselectedPartyName!;
    }
    if (widget.preselectedGrossWeightKg != null &&
        widget.preselectedGrossWeightKg! > 0) {
      _grossWeightCtrl.text =
          widget.preselectedGrossWeightKg!.toStringAsFixed(0);
    }

    _grossWeightCtrl.addListener(_onParamChanged);
    _moistureCtrl.addListener(_onParamChanged);
    _baseMoistureCtrl.addListener(_onParamChanged);
    _foreignMatterCtrl.addListener(_onParamChanged);
    _brokenGrainCtrl.addListener(_onParamChanged);
    _damagedGrainCtrl.addListener(_onParamChanged);
  }

  void _onParamChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _commodityCtrl.dispose();
    _varietyCtrl.dispose();
    _vehicleCtrl.dispose();
    _partyCtrl.dispose();
    _grossWeightCtrl.dispose();
    _sampleWeightCtrl.dispose();
    _moistureCtrl.dispose();
    _baseMoistureCtrl.dispose();
    _foreignMatterCtrl.dispose();
    _brokenGrainCtrl.dispose();
    _damagedGrainCtrl.dispose();
    _tempCtrl.dispose();
    _humidityCtrl.dispose();
    _chamberCtrl.dispose();
    _testerNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grossKg = double.tryParse(_grossWeightCtrl.text.trim()) ?? 0.0;
    final moisture = double.tryParse(_moistureCtrl.text.trim()) ?? 0.0;
    final baseMoisture = double.tryParse(_baseMoistureCtrl.text.trim()) ?? 14.0;
    final foreignMatter =
        double.tryParse(_foreignMatterCtrl.text.trim()) ?? 0.0;
    final broken = double.tryParse(_brokenGrainCtrl.text.trim()) ?? 0.0;
    final damaged = double.tryParse(_damagedGrainCtrl.text.trim()) ?? 0.0;

    final ded = QualityInspection.computeDeductions(
      moisturePercentage: moisture,
      baseMoisturePercentage: baseMoisture,
      foreignMatterPercentage: foreignMatter,
      brokenGrainPercentage: broken,
      damagedGrainPercentage: damaged,
      grossWeightKg: grossKg,
    );

    final suggestedGrade = ded['suggestedGrade'] as QualityGrade;
    final activeGrade = _selectedGrade ?? suggestedGrade;

    final currencyFmt = NumberFormat('#,##0', 'en_US');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.biotech_outlined,
                          color: Colors.teal),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quality Lab & Moisture Test (کوالٹی معائنہ و کٹوتی)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Moisture content %, refraction test & certified weight deduction',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Commodity & Variety
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Commodity / جنس *',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Autocomplete<String>(
                            initialValue:
                                TextEditingValue(text: _commodityCtrl.text),
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return _popularCommodities;
                              }
                              return _popularCommodities.where((c) => c
                                  .toLowerCase()
                                  .contains(
                                      textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (val) {
                              _commodityCtrl.text = val;
                              if (val.contains('Wheat')) {
                                _baseMoistureCtrl.text = '12.0';
                              } else if (val.contains('Paddy')) {
                                _baseMoistureCtrl.text = '14.0';
                              } else if (val.contains('Corn')) {
                                _baseMoistureCtrl.text = '14.0';
                              }
                              setState(() {});
                            },
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmitted) {
                              _commodityCtrl.addListener(() {
                                if (controller.text != _commodityCtrl.text) {
                                  controller.text = _commodityCtrl.text;
                                }
                              });
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Corn / مکئی or Wheat / گندم',
                                  prefixIcon: const Icon(Icons.grass, size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                                onChanged: (v) => _commodityCtrl.text = v,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Variety / قسم',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _varietyCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. 1121 Kainat, Akbar-19',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Vehicle, Party, Gross Weight
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle # / گاڑی نمبر',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _vehicleCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'e.g. T-8912, LES-4412',
                              prefixIcon: const Icon(Icons.local_shipping,
                                  size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Grower / Party / زمیندار نام',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _partyCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. Chaudhry Tariq',
                              prefixIcon:
                                  const Icon(Icons.person_outline, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gross Weight / بھرا وزن *',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _grossWeightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: 'KG',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) {
                              final d = double.tryParse(v ?? '') ?? -1;
                              return d <= 0 ? 'Enter gross weight' : null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Laboratory Parameters Section
                const Text(
                  'Lab Parameters & Refraction Test / نمی و کچرا کٹوتی ٹیسٹ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: MColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Moisture % & Base Moisture %
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Moisture % (نمی کا تناسب) *',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.blue),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _moistureCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            validator: (v) {
                              final d = double.tryParse(v ?? '') ?? -1;
                              return d < 0 ? 'Enter moisture' : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Base Moisture / معیاری حد',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _baseMoistureCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foreign Matter / کچرا %',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _foreignMatterCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Broken Grain & Damaged Grain
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Broken Grain / ٹوٹا دانہ %',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _brokenGrainCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Damaged / داغی دانہ %',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _damagedGrainCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quality Grade / گریڈ',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<QualityGrade>(
                            initialValue: activeGrade,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            items: QualityGrade.values.map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text(g.labelEnglish,
                                    style: const TextStyle(fontSize: 11)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGrade = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Deduction Summary Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Excess Moisture',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 3),
                          Text(
                            '+ ${(ded['excessMoisture'] as double).toStringAsFixed(1)} %',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blue),
                          ),
                        ],
                      ),
                      Container(
                          height: 30, width: 1, color: Colors.teal.shade200),
                      Column(
                        children: [
                          Text('Total Deduction %',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 3),
                          Text(
                            '${(ded['totalDeductionPct'] as double).toStringAsFixed(2)} %',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.red),
                          ),
                        ],
                      ),
                      Container(
                          height: 30, width: 1, color: Colors.teal.shade200),
                      Column(
                        children: [
                          Text('Katoti Weight (کٹوتی)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 3),
                          Text(
                            '- ${currencyFmt.format(ded['deductionKg'])} KG',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.red),
                          ),
                        ],
                      ),
                      Container(
                          height: 30, width: 1, color: Colors.teal.shade200),
                      Column(
                        children: [
                          Text('Certified Net (صاف وزن)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 3),
                          Text(
                            '${currencyFmt.format(ded['netWeightKg'])} KG',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.teal),
                          ),
                          Text(
                            '${(ded['netWeightMaunds'] as double).toStringAsFixed(2)} من',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Cold Storage / Temp (Optional)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Core Temp (°C) / درجہ حرارت',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tempCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: 'e.g. 3.5',
                              suffixText: '°C',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Humidity % / نمی (RH)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _humidityCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: 'e.g. 85',
                              suffixText: '% RH',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chamber / کولڈ روم #',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _chamberCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. Chamber-2B',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Remarks
                const Text(
                  'Inspector Remarks / ہدایات و تبصرہ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Moisture detected via digital probe, certified for immediate milling',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _saveInspection,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Certify & Save (سرٹیفکیٹ محفوظ کریں)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveInspection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final grossKg = double.tryParse(_grossWeightCtrl.text.trim()) ?? 0.0;
    final moisture = double.tryParse(_moistureCtrl.text.trim()) ?? 0.0;
    final baseMoisture = double.tryParse(_baseMoistureCtrl.text.trim()) ?? 14.0;
    final foreignMatter =
        double.tryParse(_foreignMatterCtrl.text.trim()) ?? 0.0;
    final broken = double.tryParse(_brokenGrainCtrl.text.trim()) ?? 0.0;
    final damaged = double.tryParse(_damagedGrainCtrl.text.trim()) ?? 0.0;
    final sampleWeight =
        double.tryParse(_sampleWeightCtrl.text.trim()) ?? 500.0;

    final temp = double.tryParse(_tempCtrl.text.trim());
    final hum = double.tryParse(_humidityCtrl.text.trim());

    final provider = context.read<QualityProvider>();
    final success = await provider.recordInspection(
      lotId: widget.preselectedLotId,
      inspectionDate: _inspectionDate,
      commodityName: _commodityCtrl.text.trim(),
      variety: _varietyCtrl.text.trim(),
      vehicleNumber: _vehicleCtrl.text.trim(),
      partyName: _partyCtrl.text.trim(),
      sampleWeightGrams: sampleWeight,
      moisturePercentage: moisture,
      baseMoisturePercentage: baseMoisture,
      foreignMatterPercentage: foreignMatter,
      brokenGrainPercentage: broken,
      damagedGrainPercentage: damaged,
      grossWeightKg: grossKg,
      qualityGrade: _selectedGrade,
      temperatureCelsius: temp,
      humidityPercentage: hum,
      chamberOrLocation: _chamberCtrl.text.trim(),
      testerName: _testerNameCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Quality certificate & moisture deduction recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save inspection report. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
