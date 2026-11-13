import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/theme/locale_provider.dart';
import 'package:mandi/data/models/mandi_rate_model.dart';
import 'package:mandi/modules/rates/providers/mandi_rate_provider.dart';

/// Modal dialog to record daily mandi market commodity rates
/// (*روزانہ منڈی ریٹ اور مارکیٹ بھاؤ اندراج*).
class RecordCommodityRateDialog extends StatefulWidget {
  const RecordCommodityRateDialog({super.key});

  @override
  State<RecordCommodityRateDialog> createState() =>
      _RecordCommodityRateDialogState();
}

class _RecordCommodityRateDialogState extends State<RecordCommodityRateDialog> {
  final _formKey = GlobalKey<FormState>();

  final _commodityCtrl = TextEditingController();
  final _varietyCtrl = TextEditingController();
  final _minRateCtrl = TextEditingController();
  final _maxRateCtrl = TextEditingController();
  final _modalRateCtrl = TextEditingController();
  final _prevModalRateCtrl = TextEditingController();
  final _arrivalsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _qualityGrade;
  bool _isSaving = false;

  List<String> _commonCommodities(bool isUrdu) => isUrdu
      ? const [
          'گندم',
          'چاول سپر کرنل',
          'باسمتی 1121',
          'چاول ایری-6',
          'کپاس / پھٹی',
          'مکئی',
          'سرسوں / رایا',
          'آلو',
          'پیاز',
          'ٹماٹر',
          'لہسن',
          'ادرک',
          'سرخ مرچ',
        ]
      : const [
          'Wheat',
          'Rice Super Kernel',
          'Rice Basmati 1121',
          'Rice Irri-6',
          'Cotton',
          'Corn / Maize',
          'Canola / Mustard',
          'Potato',
          'Onion',
          'Tomato',
          'Garlic',
          'Ginger',
          'Chilli',
        ];

  @override
  void dispose() {
    _commodityCtrl.dispose();
    _varietyCtrl.dispose();
    _minRateCtrl.dispose();
    _maxRateCtrl.dispose();
    _modalRateCtrl.dispose();
    _prevModalRateCtrl.dispose();
    _arrivalsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _currentModal => double.tryParse(_modalRateCtrl.text.trim()) ?? 0.0;
  double get _prevModal =>
      double.tryParse(_prevModalRateCtrl.text.trim()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final trendMap = MandiCommodityRate.computeTrendMetrics(_currentModal, _prevModal);
    final trend = trendMap['trend'] as MarketTrend;
    final changePkr = trendMap['changePkr'] as double;
    final changePercent = trendMap['changePercent'] as double;

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
                        color: MColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.trending_up, color: MColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Record Mandi Rate', ur: 'اندراج منڈی ریٹ'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textPrimary,
                            ),
                          ),
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Daily Commodity Rate & Market Arrival Notice',
                              ur: 'روزانہ منڈی جنس ریٹ اور آمد کا نوٹس',
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
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Commodity Name Autocomplete
                Text(
                  '${AppStrings.tr(context, 'commodity')} *',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    final commList = _commonCommodities(context.read<LocaleProvider>().isUrdu);
                    if (textEditingValue.text.isEmpty) {
                      return commList;
                    }
                    return commList.where((c) => c
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (val) {
                    _commodityCtrl.text = val;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Select or enter commodity (e.g. Wheat)',
                        prefixIcon: const Icon(Icons.eco_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter commodity name';
                        }
                        return null;
                      },
                      onChanged: (v) => _commodityCtrl.text = v,
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Variety and Quality Grade
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Variety', ur: 'قسم'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _varietyCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. Super Kernel, Desi',
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
                          Text(
                            AppStrings.val(context, en: 'Quality Grade', ur: 'معیار و درجہ'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _qualityGrade ?? 'Grade A',
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: [
                              DropdownMenuItem(
                                  value: 'Grade A',
                                  child: Text(AppStrings.val(context, en: 'Grade A', ur: 'درجہ اول'))),
                              DropdownMenuItem(
                                  value: 'Grade B',
                                  child: Text(AppStrings.val(context, en: 'Grade B', ur: 'درجہ دوم'))),
                              DropdownMenuItem(
                                  value: 'Grade C',
                                  child: Text(AppStrings.val(context, en: 'Grade C', ur: 'درجہ سوم'))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _qualityGrade = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Rate Date & Arrivals Maunds
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Rate Date', ur: 'تاریخ'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat('dd MMM yyyy')
                                      .format(_selectedDate)),
                                  const Icon(Icons.calendar_today, size: 16),
                                ],
                              ),
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
                            AppStrings.val(context, en: 'Arrivals in Maunds', ur: 'آمد بمقدار من'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _arrivalsCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: 'e.g. 500 Maunds',
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

                // Rate Fields (Min, Max, Modal)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Min Rate', ur: 'کم از کم ریٹ'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _minRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: 'PKR / Maund',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? AppStrings.tr(context, 'required')
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Max Rate', ur: 'زیادہ سے زیادہ ریٹ'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _maxRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: 'PKR / Maund',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? AppStrings.tr(context, 'required')
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Modal Rate *', ur: 'سودا ریٹ *'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _modalRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: 'PKR / Maund',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => v == null || v.isEmpty
                                ? AppStrings.tr(context, 'required')
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Previous Rate & Calculated Market Trend Indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Previous Modal Rate', ur: 'گزشتہ سودا ریٹ'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _prevModalRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Optional (e.g. 4200)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
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
                            AppStrings.val(context, en: 'Market Trend', ur: 'مارکیٹ رجحان'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: trend == MarketTrend.bullish
                                  ? Colors.green.shade50
                                  : trend == MarketTrend.bearish
                                      ? Colors.red.shade50
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: trend == MarketTrend.bullish
                                    ? Colors.green.shade300
                                    : trend == MarketTrend.bearish
                                        ? Colors.red.shade300
                                        : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  trend == MarketTrend.bullish
                                      ? Icons.arrow_upward
                                      : trend == MarketTrend.bearish
                                          ? Icons.arrow_downward
                                          : Icons.remove,
                                  size: 18,
                                  color: trend == MarketTrend.bullish
                                      ? Colors.green.shade800
                                      : trend == MarketTrend.bearish
                                          ? Colors.red.shade800
                                          : Colors.grey.shade800,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _prevModal > 0
                                        ? '${context.watch<LocaleProvider>().isUrdu ? trend.labelUrdu : trend.labelEnglish} (${changePkr >= 0 ? "+" : ""}${changePkr.toStringAsFixed(0)} PKR / ${changePercent.toStringAsFixed(1)}%)'
                                        : AppStrings.val(context, en: 'Stable', ur: 'مستحکم'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: trend == MarketTrend.bullish
                                          ? Colors.green.shade900
                                          : trend == MarketTrend.bearish
                                              ? Colors.red.shade900
                                              : Colors.grey.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_currentModal > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '💡 Calculated per KG rate: Rs. ${(_currentModal / 40.0).toStringAsFixed(2)} / KG',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Notes
                Text(
                  AppStrings.val(context, en: 'Remarks', ur: 'تفصیل / ریمارکس'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Dry quality lot, high buyer demand from Karachi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.tr(context, 'cancel')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _saveRate,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: Text(AppStrings.val(context, en: 'Save Rate', ur: 'ریٹ محفوظ کریں')),
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

  Future<void> _saveRate() async {
    if (!_formKey.currentState!.validate()) return;

    final commodity = _commodityCtrl.text.trim();
    if (commodity.isEmpty) return;

    setState(() => _isSaving = true);

    final minRate = double.tryParse(_minRateCtrl.text.trim()) ?? 0.0;
    final maxRate = double.tryParse(_maxRateCtrl.text.trim()) ?? 0.0;
    final modalRate = double.tryParse(_modalRateCtrl.text.trim()) ?? 0.0;
    final prevModalRate = double.tryParse(_prevModalRateCtrl.text.trim()) ?? 0.0;
    final arrivals = double.tryParse(_arrivalsCtrl.text.trim()) ?? 0.0;

    final provider = context.read<MandiRateProvider>();
    final success = await provider.recordCommodityRate(
      commodityName: commodity,
      variety: _varietyCtrl.text.trim(),
      rateDate: _selectedDate,
      minRatePerMaund: minRate,
      maxRatePerMaund: maxRate,
      modalRatePerMaund: modalRate,
      previousModalRate: prevModalRate,
      arrivalsMaunds: arrivals,
      qualityGrade: _qualityGrade ?? 'Grade A',
      notes: _notesCtrl.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mandi commodity rate recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record commodity rate. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
