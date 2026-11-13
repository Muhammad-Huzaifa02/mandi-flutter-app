import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/cross_border_shipment_model.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/modules/cross_border/providers/cross_border_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Modal dialog to record a new international cross-border cargo consignment.
class NewCrossBorderShipmentDialog extends StatefulWidget {
  const NewCrossBorderShipmentDialog({super.key});

  @override
  State<NewCrossBorderShipmentDialog> createState() =>
      _NewCrossBorderShipmentDialogState();
}

class _NewCrossBorderShipmentDialogState
    extends State<NewCrossBorderShipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  OriginCountry _originCountry = OriginCountry.afghanistan;
  BorderCrossing _borderCrossing = BorderCrossing.torkham;
  TradeCurrency _currency = TradeCurrency.usd;
  final CrossBorderShipmentStatus _status = CrossBorderShipmentStatus.inTransit;

  late final TextEditingController _shipmentNumberCtrl;
  final _originCityCtrl = TextEditingController(text: 'Kandahar');
  final _vehicleNumberCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _customsGdCtrl = TextEditingController();
  final _clearingAgentCtrl = TextEditingController();
  late final TextEditingController _commodityCtrl;
  final _packageTypeCtrl = TextEditingController(text: 'Wooden Crate');
  final _packageCountCtrl = TextEditingController(text: '650');
  final _weightKgCtrl = TextEditingController(text: '13000'); // ~325 Maunds
  final _foreignAmountCtrl = TextEditingController(text: '12000'); // $12,000 USD
  late final TextEditingController _exchangeRateCtrl;
  final _customsDutyCtrl = TextEditingController(text: '350000'); // PKR
  final _borderFreightCtrl = TextEditingController(text: '280000'); // PKR
  final _clearingChargesCtrl = TextEditingController(text: '45000'); // PKR
  final _otherExpensesCtrl = TextEditingController(text: '15000'); // PKR
  final _paidForeignCtrl = TextEditingController(text: '4000'); // $4,000 initial deposit
  final _notesCtrl = TextEditingController();

  Supplier? _selectedSupplier;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    _shipmentNumberCtrl =
        TextEditingController(text: 'CBS-${DateTime.now().year}-$randomSuffix');
    _commodityCtrl = TextEditingController(text: 'Pomegranate');
    _exchangeRateCtrl =
        TextEditingController(text: _currency.standardMarketRate.toString());
  }

  @override
  void dispose() {
    _shipmentNumberCtrl.dispose();
    _originCityCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _customsGdCtrl.dispose();
    _clearingAgentCtrl.dispose();
    _commodityCtrl.dispose();
    _packageTypeCtrl.dispose();
    _packageCountCtrl.dispose();
    _weightKgCtrl.dispose();
    _foreignAmountCtrl.dispose();
    _exchangeRateCtrl.dispose();
    _customsDutyCtrl.dispose();
    _borderFreightCtrl.dispose();
    _clearingChargesCtrl.dispose();
    _otherExpensesCtrl.dispose();
    _paidForeignCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onCurrencyChanged(TradeCurrency newCurr) {
    setState(() {
      _currency = newCurr;
      _exchangeRateCtrl.text = newCurr.standardMarketRate.toString();
    });
  }

  void _onCountryChanged(OriginCountry country) {
    setState(() {
      _originCountry = country;
      if (country == OriginCountry.afghanistan) {
        _borderCrossing = BorderCrossing.torkham;
        _originCityCtrl.text = 'Kandahar';
      } else if (country == OriginCountry.iran) {
        _borderCrossing = BorderCrossing.taftan;
        _originCityCtrl.text = 'Zahedan';
      } else if (country == OriginCountry.centralAsia) {
        _borderCrossing = BorderCrossing.torkham;
        _originCityCtrl.text = 'Tashkent';
      }
    });
  }

  double get _foreignPrice => double.tryParse(_foreignAmountCtrl.text) ?? 0.0;
  double get _rate => double.tryParse(_exchangeRateCtrl.text) ?? 1.0;
  double get _basePkr => _foreignPrice * _rate;
  double get _customs => double.tryParse(_customsDutyCtrl.text) ?? 0.0;
  double get _freight => double.tryParse(_borderFreightCtrl.text) ?? 0.0;
  double get _clearing => double.tryParse(_clearingChargesCtrl.text) ?? 0.0;
  double get _otherExp => double.tryParse(_otherExpensesCtrl.text) ?? 0.0;
  double get _totalLandedPkr => _basePkr + _customs + _freight + _clearing + _otherExp;
  double get _grossKg => double.tryParse(_weightKgCtrl.text) ?? 0.0;
  double get _maunds => _grossKg / 40.0;
  double get _costPerMaund => _maunds > 0 ? (_totalLandedPkr / _maunds) : 0.0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isUrdu = AppStrings.isUrdu(context);
    setState(() => _isSaving = true);
    final shopId = context.read<ShopContextProvider>().currentShopId ?? '';

    try {
      final shipment = CrossBorderShipment(
        id: '',
        shopId: shopId,
        shipmentNumber: _shipmentNumberCtrl.text.trim(),
        originCountry: _originCountry,
        originCity: _originCityCtrl.text.trim(),
        borderCrossing: _borderCrossing,
        vehicleNumber: _vehicleNumberCtrl.text.trim(),
        driverName: _driverNameCtrl.text.trim(),
        driverPhone: _driverPhoneCtrl.text.trim(),
        customsGdNumber: _customsGdCtrl.text.trim(),
        customsClearanceDate: DateTime.now(),
        clearingAgentName: _clearingAgentCtrl.text.trim(),
        supplierId: _selectedSupplier?.id,
        supplierName: _selectedSupplier?.name ??
            (isUrdu ? 'براہ راست بارڈر زمیندار' : 'Direct Border Farmer'),
        commodity: _commodityCtrl.text.trim(),
        packageType: _packageTypeCtrl.text.trim(),
        packageCount: int.tryParse(_packageCountCtrl.text) ?? 0,
        grossWeightKg: _grossKg,
        currency: _currency,
        exchangeRateToPkr: _rate,
        foreignContractAmount: _foreignPrice,
        basePkrAmount: _basePkr,
        customsDutyPkr: _customs,
        borderFreightPkr: _freight,
        clearingChargesPkr: _clearing,
        otherExpensesPkr: _otherExp,
        totalLandedCostPkr: _totalLandedPkr,
        paidToSupplierForeign: double.tryParse(_paidForeignCtrl.text) ?? 0.0,
        remainingSupplierForeign:
            (_foreignPrice - (double.tryParse(_paidForeignCtrl.text) ?? 0.0))
                .clamp(0.0, double.infinity),
        status: _status,
        notes: _notesCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await context.read<CrossBorderProvider>().createShipment(shipment);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUrdu
                ? 'سرحدی مال کامیابی سے درج کر لیا گیا!'
                : 'Cross-border shipment recorded successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUrdu
                ? 'مال محفوظ کرنے میں ناکامی: $e'
                : 'Failed to save shipment: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final isUrdu = AppStrings.isUrdu(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: GlassCard(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.public_rounded,
                          color: theme.colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: MSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(
                              context,
                              en: 'New Cross-Border Cargo',
                              ur: 'سرحدی مال',
                            ),
                            style: MText.titleMd,
                          ),
                          Text(
                            AppStrings.val(
                              context,
                              en: 'Import Transit Manifest & Multi-Currency Ledger',
                              ur: 'درآمدی ٹرانزٹ مینی فیسٹ اور کثیر کرنسی کھاتہ',
                            ),
                            style: MText.caption.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6)),
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

                const SizedBox(height: MSpacing.md),

                // Scrollable Form Fields
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section: Origin Country & Border
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<OriginCountry>(
                                initialValue: _originCountry,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Origin Country',
                                    ur: 'ملک',
                                  ),
                                  prefixIcon: const Icon(Icons.flag_outlined, size: 18),
                                ),
                                items: OriginCountry.values.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text('${c.flagEmoji} ${isUrdu ? c.labelUrdu : c.labelEnglish}'),
                                  );
                                }).toList(),
                                onChanged: (c) {
                                  if (c != null) _onCountryChanged(c);
                                },
                              ),
                            ),
                            const SizedBox(width: MSpacing.md),
                            Expanded(
                              child: DropdownButtonFormField<BorderCrossing>(
                                initialValue: _borderCrossing,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Border Checkpoint',
                                    ur: 'بارڈر چیک پوائنٹ',
                                  ),
                                  prefixIcon: const Icon(Icons.alt_route, size: 18),
                                ),
                                items: BorderCrossing.values.map((b) {
                                  return DropdownMenuItem(
                                    value: b,
                                    child: Text(
                                      isUrdu ? b.labelUrdu : b.labelEnglish,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (b) {
                                  if (b != null) {
                                    setState(() => _borderCrossing = b);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: MSpacing.md),

                        // Manifest # and Origin City
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _shipmentNumberCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Manifest / Shipment #',
                                    ur: 'مینی فیسٹ / مال نمبر',
                                  ),
                                  prefixIcon: const Icon(Icons.tag, size: 18),
                                ),
                                validator: (v) => v?.trim().isEmpty == true
                                    ? AppStrings.val(
                                        context,
                                        en: 'Required',
                                        ur: 'ضروری ہے',
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: MSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _originCityCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Origin City',
                                    ur: 'روانگی کا شہر',
                                  ),
                                  prefixIcon: const Icon(Icons.location_city, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: MSpacing.md),

                        // Vehicle & Driver Details
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _vehicleNumberCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Vehicle / Truck #',
                                    ur: 'گاڑی نمبر',
                                  ),
                                  hintText: 'e.g. KBL-4589',
                                  prefixIcon: const Icon(Icons.local_shipping_outlined,
                                      size: 18),
                                ),
                                validator: (v) => v?.trim().isEmpty == true
                                    ? AppStrings.val(
                                        context,
                                        en: 'Enter vehicle plate',
                                        ur: 'گاڑی کا نمبر درج کریں',
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: MSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _driverNameCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Driver Name & Phone',
                                    ur: 'ڈرائیور کا نام اور فون',
                                  ),
                                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: MSpacing.md),

                        // Customs GD # and Clearing Agent
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _customsGdCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Customs GD #',
                                    ur: 'کسٹم جی ڈی نمبر',
                                  ),
                                  hintText: 'e.g. TK-2026-GD-1102',
                                  prefixIcon: const Icon(Icons.verified_outlined, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: MSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _clearingAgentCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Clearing Agent',
                                    ur: 'کسٹم کلیئرنگ ایجنٹ',
                                  ),
                                  prefixIcon: const Icon(Icons.support_agent, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: MSpacing.md),

                        // Foreign Farmer Picker
                        DropdownButtonFormField<Supplier>(
                          initialValue: _selectedSupplier,
                          decoration: InputDecoration(
                            labelText: AppStrings.val(
                              context,
                              en: 'Foreign Farmer / Exporter',
                              ur: 'غیر ملکی زمیندار / برآمد کنندہ',
                            ),
                            prefixIcon: const Icon(Icons.business_outlined, size: 18),
                          ),
                          hint: Text(AppStrings.val(
                            context,
                            en: 'Select or Walk-in Border Grower',
                            ur: 'زمیندار منتخب کریں',
                          )),
                          items: suppliers.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text('${s.name} (${s.phone})'),
                            );
                          }).toList(),
                          onChanged: (s) => setState(() => _selectedSupplier = s),
                        ),

                        const SizedBox(height: MSpacing.md),

                        // Commodity & Packaging
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _commodityCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Commodity',
                                    ur: 'جنس',
                                  ),
                                  prefixIcon: const Icon(Icons.apple_outlined, size: 18),
                                ),
                                validator: (v) => v?.trim().isEmpty == true
                                    ? AppStrings.val(
                                        context,
                                        en: 'Required',
                                        ur: 'ضروری ہے',
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: MSpacing.sm),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _packageCountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Crates / Bags',
                                    ur: 'پیٹیاں / بوریاں',
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: MSpacing.sm),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _weightKgCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Gross KG',
                                    ur: 'کل وزن (کلو)',
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: MSpacing.lg),

                        // DUAL-CURRENCY VALUATION SECTION
                        Container(
                          padding: const EdgeInsets.all(MSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.val(
                                      context,
                                      en: 'Dual-Currency Valuation',
                                      ur: 'کرنسی حساب کتاب',
                                    ),
                                    style: MText.bodyMd.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  SegmentedButton<TradeCurrency>(
                                    segments: TradeCurrency.values.map((c) {
                                      return ButtonSegment(
                                        value: c,
                                        label: Text(c.code),
                                      );
                                    }).toList(),
                                    selected: {_currency},
                                    onSelectionChanged: (set) =>
                                        _onCurrencyChanged(set.first),
                                    style: const ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: MSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _foreignAmountCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText:
                                            '${AppStrings.val(context, en: "Contract Price", ur: "معاہدہ قیمت")} (${_currency.symbol})',
                                        prefixIcon: const Icon(
                                            Icons.currency_exchange,
                                            size: 18),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: MSpacing.md),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _exchangeRateCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: AppStrings.val(
                                          context,
                                          en: 'Rate to PKR',
                                          ur: 'روپیہ میں ایکسچینج ریٹ',
                                        ),
                                        prefixIcon: const Icon(Icons.trending_up,
                                            size: 18),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: MSpacing.sm),
                              Text(
                                '${AppStrings.val(context, en: "Base Cargo Value in PKR: Rs.", ur: "پاکستانی روپے میں مال کی بنیادی قیمت: روپے")} ${_currencyFmt.format(_basePkr)}',
                                style: MText.bodySm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: MSpacing.md),

                        // BORDER CHARGES SECTION
                        Text(
                          AppStrings.val(
                            context,
                            en: 'Border Tariffs, Freight & Clearance',
                            ur: 'سرحدی اخراجات، ڈیوٹی اور کرایہ',
                          ),
                          style: MText.caption,
                        ),
                        const SizedBox(height: MSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _customsDutyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Customs Duty (PKR)',
                                    ur: 'کسٹم ڈیوٹی (روپے)',
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: MSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _borderFreightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Border Freight (PKR)',
                                    ur: 'بارڈر کرایہ (روپے)',
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _clearingChargesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Clearing Fees (PKR)',
                                    ur: 'کلیئرنگ فیس (روپے)',
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: MSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _otherExpensesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(
                                    context,
                                    en: 'Tolls / Other (PKR)',
                                    ur: 'دیگر اخراجات (روپے)',
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: MSpacing.md),

                        // Initial Disbursed Payment to Supplier
                        TextFormField(
                          controller: _paidForeignCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                '${AppStrings.val(context, en: "Advance Disbursed to Farmer", ur: "زمیندار کو پیشگی ادائیگی")} (${_currency.symbol} ${_currency.code})',
                            prefixIcon: const Icon(Icons.payment, size: 18),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: MSpacing.lg),

                        // LIVE LANDED ECONOMICS KPI PREVIEW
                        Container(
                          padding: const EdgeInsets.all(MSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.val(
                                      context,
                                      en: 'ESTIMATED LANDED COST:',
                                      ur: 'منڈی پہنچ کل لاگت:',
                                    ),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                  Text(
                                    'Rs. ${_currencyFmt.format(_totalLandedPkr)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${AppStrings.val(context, en: "Weight:", ur: "وزن:")} ${_numberFmt.format(_maunds)} ${AppStrings.val(context, en: "Maunds", ur: "من")}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    '${AppStrings.val(context, en: "Cost / Maund: Rs.", ur: "لاگت فی من: روپے")} ${_currencyFmt.format(_costPerMaund)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: MSpacing.md),

                        TextFormField(
                          controller: _notesCtrl,
                          decoration: InputDecoration(
                            labelText: AppStrings.val(
                              context,
                              en: 'Remarks & Border Notes',
                              ur: 'تفصیل و نوٹس',
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: MSpacing.md),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppStrings.val(
                          context,
                          en: 'Cancel',
                          ur: 'منسوخ',
                        )),
                      ),
                    ),
                    const SizedBox(width: MSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isSaving
                              ? AppStrings.val(context, en: 'Saving...', ur: 'محفوظ ہو رہا ہے...')
                              : AppStrings.val(context, en: 'Record Border Cargo', ur: 'سرحدی مال درج کریں'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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
}
