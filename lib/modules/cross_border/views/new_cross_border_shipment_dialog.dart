import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  final _commodityCtrl = TextEditingController(text: 'Pomegranate (قندھاری انار)');
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
        supplierName: _selectedSupplier?.name ?? 'Direct Border Exporter',
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
          const SnackBar(
            content: Text(
                'Cross-border shipment recorded successfully! / مال کامیابی سے درج ہوگیا'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save shipment: $e'),
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
                          const Text(
                            'New Cross-Border Cargo (سرحدی مال)',
                            style: MText.titleMd,
                          ),
                          Text(
                            'Import Transit Manifest & Multi-Currency Ledger',
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
                                decoration: const InputDecoration(
                                  labelText: 'Origin Country / ملک',
                                  prefixIcon: Icon(Icons.flag_outlined, size: 18),
                                ),
                                items: OriginCountry.values.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text('${c.flagEmoji} ${c.labelEnglish}'),
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
                                decoration: const InputDecoration(
                                  labelText: 'Border Checkpoint / بارڈر',
                                  prefixIcon: Icon(Icons.alt_route, size: 18),
                                ),
                                items: BorderCrossing.values.map((b) {
                                  return DropdownMenuItem(
                                    value: b,
                                    child: Text(
                                      b.labelEnglish,
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
                                decoration: const InputDecoration(
                                  labelText: 'Manifest / Shipment #',
                                  prefixIcon: Icon(Icons.tag, size: 18),
                                ),
                                validator: (v) => v?.trim().isEmpty == true
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: MSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _originCityCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Origin City (شہر)',
                                  prefixIcon: Icon(Icons.location_city, size: 18),
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
                                decoration: const InputDecoration(
                                  labelText: 'Vehicle / Truck # (گاڑی نمبر)',
                                  hintText: 'e.g. KBL-4589 / TLR-786',
                                  prefixIcon: Icon(Icons.local_shipping_outlined,
                                      size: 18),
                                ),
                                validator: (v) => v?.trim().isEmpty == true
                                    ? 'Enter vehicle plate'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: MSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _driverNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Driver Name & Phone',
                                  prefixIcon: Icon(Icons.person_outline, size: 18),
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
                                decoration: const InputDecoration(
                                  labelText: 'Customs GD # (سامان پروانہ)',
                                  hintText: 'e.g. TK-2026-GD-1102',
                                  prefixIcon: Icon(Icons.verified_outlined, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: MSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _clearingAgentCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Clearing Agent / ایجنٹ',
                                  prefixIcon: Icon(Icons.support_agent, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: MSpacing.md),

                        // Foreign Supplier Picker
                        DropdownButtonFormField<Supplier>(
                          initialValue: _selectedSupplier,
                          decoration: const InputDecoration(
                            labelText: 'Foreign Supplier / Exporter (مالک مال)',
                            prefixIcon: Icon(Icons.business_outlined, size: 18),
                          ),
                          hint: const Text('Select or Walk-in Border Grower'),
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
                                decoration: const InputDecoration(
                                  labelText: 'Commodity (جنس)',
                                  prefixIcon: Icon(Icons.apple_outlined, size: 18),
                                ),
                                validator: (v) => v?.trim().isEmpty == true
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: MSpacing.sm),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _packageCountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Crates / Bags',
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
                                decoration: const InputDecoration(
                                  labelText: 'Gross KG',
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
                                    'Dual-Currency Valuation (کرنسی کھاتہ)',
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
                                            'Contract Price (${_currency.symbol})',
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
                                      decoration: const InputDecoration(
                                        labelText: 'Rate to PKR (ریٹ)',
                                        prefixIcon: Icon(Icons.trending_up,
                                            size: 18),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: MSpacing.sm),
                              Text(
                                'Base Cargo Value in PKR: Rs. ${_currencyFmt.format(_basePkr)}',
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
                        const Text('Border Tariffs, Freight & Clearance (سرحدی اخراجات)',
                            style: MText.caption),
                        const SizedBox(height: MSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _customsDutyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Customs Duty (PKR)',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: MSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _borderFreightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Border Freight (کرایہ)',
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
                                decoration: const InputDecoration(
                                  labelText: 'Clearing Fees (ایجنٹ)',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: MSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _otherExpensesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Tolls / Other (دیگر)',
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
                                'Advance Disbursed to Supplier (${_currency.symbol} ${_currency.code})',
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
                                  const Text('ESTIMATED LANDED COST / کل لاگت:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
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
                                    'Weight: ${_numberFmt.format(_maunds)} Maunds',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    'Cost / Maund: Rs. ${_currencyFmt.format(_costPerMaund)}',
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
                          decoration: const InputDecoration(
                            labelText: 'Remarks & Border Notes (تفصیل)',
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
                        child: const Text('Cancel / منسوخ'),
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
                          _isSaving ? 'Saving...' : 'Record Border Cargo (درج کریں)',
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
