import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/quality_inspection_model.dart';
import 'package:mandi/modules/quality/providers/quality_provider.dart';

/// Modal dialog to log cold storage temperature, humidity, and HACCP compliance
/// (*کولڈ سٹوریج درجہ حرارت، نمی اور آڈٹ لاگ اندراج*).
class LogColdChainTempDialog extends StatefulWidget {
  final String? preselectedChamber;

  const LogColdChainTempDialog({super.key, this.preselectedChamber});

  @override
  State<LogColdChainTempDialog> createState() => _LogColdChainTempDialogState();
}

class _LogColdChainTempDialogState extends State<LogColdChainTempDialog> {
  final _formKey = GlobalKey<FormState>();

  DateTime _recordedAt = DateTime.now();

  final _chamberCtrl = TextEditingController();
  final _tempCtrl = TextEditingController(text: '2.5');
  final _humidityCtrl = TextEditingController(text: '88');
  final _minTempCtrl = TextEditingController(text: '1.0');
  final _maxTempCtrl = TextEditingController(text: '4.0');
  final _sensorCtrl = TextEditingController(text: 'Probe-T101');
  final _inspectorCtrl = TextEditingController(text: 'Munshi Akram');
  final _correctiveActionCtrl = TextEditingController();

  bool _isSaving = false;
  bool _initialized = false;

  List<String> _chamberPresets(bool isUrdu) => isUrdu
      ? [
          'چیمبر 1 (آلو کولڈ سٹور)',
          'چیمبر 2 (سیب و پھل روم)',
          'چیمبر 3 (پیاز وینٹی لیشن)',
          'چیمبر 4 (پری کولنگ سیل)',
          'منڈی جنرل گودام 1',
        ]
      : [
          'Chamber 1 (Potato Cold Store)',
          'Chamber 2 (Apple & Fruit Room)',
          'Chamber 3 (Onion Dry Ventilation)',
          'Chamber 4 (Pre-Cooling Cell)',
          'General Mandi Godown # 1',
        ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (widget.preselectedChamber != null &&
          widget.preselectedChamber!.isNotEmpty) {
        _chamberCtrl.text = widget.preselectedChamber!;
      } else {
        _chamberCtrl.text = AppStrings.val(
          context,
          en: 'Chamber 1 (Potato Cold Store)',
          ur: 'چیمبر 1 (آلو کولڈ سٹور)',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tempCtrl.addListener(_updateUi);
    _minTempCtrl.addListener(_updateUi);
    _maxTempCtrl.addListener(_updateUi);
  }

  void _updateUi() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chamberCtrl.dispose();
    _tempCtrl.dispose();
    _humidityCtrl.dispose();
    _minTempCtrl.dispose();
    _maxTempCtrl.dispose();
    _sensorCtrl.dispose();
    _inspectorCtrl.dispose();
    _correctiveActionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppStrings.isUrdu(context);
    final temp = double.tryParse(_tempCtrl.text.trim()) ?? 0.0;
    final minT = double.tryParse(_minTempCtrl.text.trim()) ?? 0.0;
    final maxT = double.tryParse(_maxTempCtrl.text.trim()) ?? 4.0;

    final evalStatus =
        ColdChainLog.evaluateStatus(temp: temp, minT: minT, maxT: maxT);

    final statusColor = evalStatus == ColdChainStatus.optimal
        ? Colors.green
        : (evalStatus == ColdChainStatus.warning ? Colors.orange : Colors.red);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
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
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.ac_unit, color: Colors.blue),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Cold Chain Temp & Humidity',
                              ur: 'کولڈ چین درجہ حرارت و نمی لاگ',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textPrimary,
                            ),
                          ),
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Log cold room climate, sensor readings & alerts',
                              ur: 'کولڈ روم موسمی ریکارڈ، سینسر ریڈنگز اور الرٹس',
                            ),
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

                // Chamber & Date
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Chamber *', ur: 'کولڈ روم *'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Autocomplete<String>(
                            initialValue:
                                TextEditingValue(text: _chamberCtrl.text),
                            optionsBuilder: (textEditingValue) {
                              final presets = _chamberPresets(isUrdu);
                              if (textEditingValue.text.isEmpty) {
                                return presets;
                              }
                              return presets.where((p) => p
                                  .toLowerCase()
                                  .contains(
                                      textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (val) {
                              _chamberCtrl.text = val;
                              setState(() {});
                            },
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmitted) {
                              _chamberCtrl.addListener(() {
                                if (controller.text != _chamberCtrl.text) {
                                  controller.text = _chamberCtrl.text;
                                }
                              });
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: AppStrings.val(
                                    context,
                                    en: 'e.g. Chamber 1, Potato Room',
                                    ur: 'مثلاً چیمبر 1، آلو سٹور',
                                  ),
                                  prefixIcon: const Icon(
                                      Icons.warehouse_outlined,
                                      size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                                onChanged: (v) => _chamberCtrl.text = v,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? AppStrings.val(context, en: 'Required', ur: 'لازمی ہے')
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
                          Text(
                            AppStrings.val(context, en: 'Date & Time', ur: 'تاریخ و وقت'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _recordedAt,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                final now = DateTime.now();
                                setState(() {
                                  _recordedAt = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    now.hour,
                                    now.minute,
                                  );
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                prefixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18),
                              ),
                              child: Text(
                                DateFormat('dd MMM, hh:mm a')
                                    .format(_recordedAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Temperature & Humidity
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Temperature (°C) *',
                              ur: 'درجہ حرارت (°C) *',
                            ),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tempCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: '°C',
                              prefixIcon:
                                  const Icon(Icons.thermostat, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? AppStrings.val(context, en: 'Required', ur: 'لازمی ہے')
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Relative Humidity (%) *',
                              ur: 'ہوا میں نمی (%) *',
                            ),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _humidityCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: '% RH',
                              prefixIcon:
                                  const Icon(Icons.water_drop_outlined, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? AppStrings.val(context, en: 'Required', ur: 'لازمی ہے')
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Thresholds & Status Preview
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Min Safe Temp', ur: 'کم از کم حد'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _minTempCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
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
                          Text(
                            AppStrings.val(context, en: 'Max Safe Temp', ur: 'زیادہ سے زیادہ حد'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _maxTempCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
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
                          Text(
                            AppStrings.val(context, en: 'Compliance Status', ur: 'حالت معیار'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              isUrdu
                                  ? evalStatus.labelUrdu
                                  : evalStatus.labelEnglish.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Sensor & Inspector
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Probe / Sensor ID', ur: 'سینسر / پروب آئی ڈی'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _sensorCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. Testo 174T, Digital Probe',
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Inspector Name', ur: 'انسپکٹر / منشی'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _inspectorCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. Munshi Akram',
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
                const SizedBox(height: 14),

                // Corrective Action
                Text(
                  AppStrings.val(context, en: 'Corrective Action', ur: 'احتیاطی تدابیر'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _correctiveActionCtrl,
                  decoration: InputDecoration(
                    hintText: AppStrings.val(
                      context,
                      en: 'e.g. Normal circulation, or Thermostat adjusted by 1°C',
                      ur: 'مثلاً نارمل ایئر گردش، یا تھرموسٹیٹ 1 ڈگری تبدیل کیا گیا',
                    ),
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
                      child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _saveReading,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        AppStrings.val(context, en: 'Save Reading', ur: 'ریڈنگ محفوظ کریں'),
                      ),
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

  Future<void> _saveReading() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final temp = double.tryParse(_tempCtrl.text.trim()) ?? 0.0;
    final hum = double.tryParse(_humidityCtrl.text.trim()) ?? 0.0;
    final minT = double.tryParse(_minTempCtrl.text.trim()) ?? 0.0;
    final maxT = double.tryParse(_maxTempCtrl.text.trim()) ?? 4.0;

    final provider = context.read<QualityProvider>();
    final success = await provider.logColdChainReading(
      chamberName: _chamberCtrl.text.trim(),
      recordedAt: _recordedAt,
      temperatureCelsius: temp,
      humidityPercentage: hum,
      minTempThreshold: minT,
      maxTempThreshold: maxT,
      sensorDeviceId: _sensorCtrl.text.trim(),
      inspectorName: _inspectorCtrl.text.trim(),
      correctiveAction: _correctiveActionCtrl.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cold chain reading logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record temperature reading. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
