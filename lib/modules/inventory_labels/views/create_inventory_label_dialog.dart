// Modal Dialog for Creating Barcode & QR Code Pallet / Lot Labels
// (*نیا بارکوڈ و کیو آر انوینٹری لیبل فارم*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/inventory_label_pdf_generator.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/inventory_label_model.dart';
import 'package:mandi/modules/inventory_labels/providers/inventory_label_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class CreateInventoryLabelDialog extends StatefulWidget {
  final InventoryLabelType initialType;
  final String? initialCommodity;
  final String? initialParty;
  final String? initialVehicle;
  final int? initialBags;
  final double? initialGrossKg;

  const CreateInventoryLabelDialog({
    super.key,
    this.initialType = InventoryLabelType.lot,
    this.initialCommodity,
    this.initialParty,
    this.initialVehicle,
    this.initialBags,
    this.initialGrossKg,
  });

  @override
  State<CreateInventoryLabelDialog> createState() =>
      _CreateInventoryLabelDialogState();
}

class _CreateInventoryLabelDialogState
    extends State<CreateInventoryLabelDialog> {
  final _formKey = GlobalKey<FormState>();

  late InventoryLabelType _labelType;
  late PackageType _packageType;
  String _qualityGrade = 'grade_b_faq';

  late TextEditingController _labelCodeCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _commodityCtrl;
  final _varietyCtrl = TextEditingController(text: 'Standard');
  late TextEditingController _partyCtrl;
  late TextEditingController _vehicleCtrl;
  late TextEditingController _bagCountCtrl;
  late TextEditingController _grossWeightCtrl;
  final _facilityCtrl = TextEditingController(text: 'Main Mandi Godown');
  final _bayCtrl = TextEditingController(text: 'Bay A-01, Stack 1');
  final _notesCtrl = TextEditingController();

  double _computedNetKg = 0.0;
  double _computedNetMaunds = 0.0;
  double _computedTareKg = 0.0;
  bool _isSaving = false;

  List<String> _getPopularCommodities(bool isUrdu) {
    if (isUrdu) {
      return [
        'گندم',
        'سپر باسمتی چاول',
        'باسمتی ۱۱۲۱ کائنات',
        'مکئی',
        'کپاس / پھٹی',
        'کینولا',
        'سورج مکھی',
        'آلو',
        'پیاز',
        'کنو',
      ];
    }
    return [
      'Wheat',
      'Super Basmati Rice',
      'Basmati 1121 Kainat',
      'Corn / Maize',
      'Cotton',
      'Canola',
      'Sunflower',
      'Potato',
      'Onion',
      'Kinnow Citrus',
    ];
  }

  @override
  void initState() {
    super.initState();
    _labelType = widget.initialType;
    _packageType = PackageType.juteBag;

    final provider = context.read<InventoryLabelProvider>();
    final code = provider.nextLabelCode(type: _labelType);
    final barcode = provider.nextBarcodeValue(code);

    _labelCodeCtrl = TextEditingController(text: code);
    _barcodeCtrl = TextEditingController(text: barcode);
    _commodityCtrl = TextEditingController(
        text: widget.initialCommodity ?? 'Wheat');
    _partyCtrl = TextEditingController(text: widget.initialParty ?? '');
    _vehicleCtrl = TextEditingController(text: widget.initialVehicle ?? '');
    _bagCountCtrl = TextEditingController(
        text: (widget.initialBags ?? 100).toString());
    _grossWeightCtrl = TextEditingController(
        text: (widget.initialGrossKg ?? 10100.0).toStringAsFixed(0));

    _recomputeWeights();
  }

  @override
  void dispose() {
    _labelCodeCtrl.dispose();
    _barcodeCtrl.dispose();
    _commodityCtrl.dispose();
    _varietyCtrl.dispose();
    _partyCtrl.dispose();
    _vehicleCtrl.dispose();
    _bagCountCtrl.dispose();
    _grossWeightCtrl.dispose();
    _facilityCtrl.dispose();
    _bayCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(InventoryLabelType? newType) {
    if (newType == null) return;
    setState(() {
      _labelType = newType;
      final provider = context.read<InventoryLabelProvider>();
      final code = provider.nextLabelCode(type: _labelType);
      _labelCodeCtrl.text = code;
      _barcodeCtrl.text = provider.nextBarcodeValue(code);
    });
  }

  void _recomputeWeights() {
    final gross = double.tryParse(_grossWeightCtrl.text.trim()) ?? 0.0;
    final bags = int.tryParse(_bagCountCtrl.text.trim()) ?? 0;

    final res = InventoryLabel.computeWeightMath(
      grossWeightKg: gross,
      bagCount: bags,
      packageType: _packageType,
    );

    setState(() {
      _computedTareKg = res['totalTareKg'] ?? 0.0;
      _computedNetKg = res['netWeightKg'] ?? 0.0;
      _computedNetMaunds = res['netWeightMaunds'] ?? 0.0;
    });
  }

  String _getQrPayload() {
    final shopCtx = context.read<ShopContextProvider>();
    final shopId = shopCtx.currentShopId ?? 'shop-01';

    return InventoryLabel.generateQrPayload(
      shopId: shopId,
      labelCode: _labelCodeCtrl.text.trim(),
      commodityName: _commodityCtrl.text.trim(),
      bagCount: int.tryParse(_bagCountCtrl.text.trim()) ?? 0,
      netWeightKg: _computedNetKg,
      netWeightMaunds: _computedNetMaunds,
      qualityGrade: _qualityGrade,
      facilityName: _facilityCtrl.text.trim(),
      bayOrStack: _bayCtrl.text.trim(),
    );
  }

  Future<void> _submit({bool printAfter = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<InventoryLabelProvider>();
    final shopCtx = context.read<ShopContextProvider>();

    final gross = double.tryParse(_grossWeightCtrl.text.trim()) ?? 0.0;
    final bags = int.tryParse(_bagCountCtrl.text.trim()) ?? 0;
    final code = _labelCodeCtrl.text.trim();
    final barcode = _barcodeCtrl.text.trim().isNotEmpty
        ? _barcodeCtrl.text.trim()
        : provider.nextBarcodeValue(code);
    final qr = _getQrPayload();

    try {
      final labelId = await provider.createLabel(
        labelCode: code,
        barcodeValue: barcode,
        qrPayload: qr,
        labelType: _labelType,
        commodityName: _commodityCtrl.text.trim(),
        variety: _varietyCtrl.text.trim(),
        partyName: _partyCtrl.text.trim(),
        vehicleNumber: _vehicleCtrl.text.trim(),
        bagCount: bags,
        packageType: _packageType,
        grossWeightKg: gross,
        netWeightKg: _computedNetKg,
        netWeightMaunds: _computedNetMaunds,
        qualityGrade: _qualityGrade,
        facilityName: _facilityCtrl.text.trim(),
        bayOrStack: _bayCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        status: LabelStatus.active,
      );

      if (!mounted) return;

      if (printAfter) {
        final label = InventoryLabel(
          id: labelId,
          shopId: shopCtx.currentShopId ?? '',
          labelCode: code,
          barcodeValue: barcode,
          qrPayload: qr,
          labelType: _labelType,
          commodityName: _commodityCtrl.text.trim(),
          variety: _varietyCtrl.text.trim(),
          partyName: _partyCtrl.text.trim(),
          vehicleNumber: _vehicleCtrl.text.trim(),
          bagCount: bags,
          packageType: _packageType,
          grossWeightKg: gross,
          netWeightKg: _computedNetKg,
          netWeightMaunds: _computedNetMaunds,
          qualityGrade: _qualityGrade,
          facilityName: _facilityCtrl.text.trim(),
          bayOrStack: _bayCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          status: LabelStatus.active,
          createdAt: DateTime.now(),
        );

        final shop = shopCtx.currentShop;
        await InventoryLabelPdfGenerator.printSinglePalletPlacard(
          label: label,
          shopName: shop?.name ?? 'Mandi Enterprise',
          shopAddress: shop?.address,
          shopPhone: shop?.phone,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inventory Label $code created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create label: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              MColors.primary.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            color: MColors.primaryLight,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppStrings.val(context,
                              en: 'Generate Inventory Barcode / QR',
                              ur: 'بارکوڈ اور کیو آر پیلیٹ لیبل'),
                          style: MText.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),

                // Live Barcode & QR Code Preview Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      // Barcode 1D preview
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '1D CODE128 BARCODE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 50,
                              child: BarcodeWidget(
                                barcode: Barcode.code128(),
                                data: _barcodeCtrl.text.isNotEmpty
                                    ? _barcodeCtrl.text
                                    : 'MND1001',
                                drawText: true,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const VerticalDivider(width: 1, color: Colors.black26),
                      const SizedBox(width: 12),

                      // QR 2D preview
                      Column(
                        children: [
                          Text(
                            '2D QR CODE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: BarcodeWidget(
                              barcode: Barcode.qrCode(),
                              data: _labelCodeCtrl.text.isNotEmpty
                                  ? _labelCodeCtrl.text
                                  : 'MANDI-LABEL',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MSpacing.md),

                // Label Type & Code Row
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Label Category', ur: 'لیبل کی قسم'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<InventoryLabelType>(
                            initialValue: _labelType,
                            dropdownColor: MColors.surfaceDark,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: InventoryLabelType.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(
                                  AppStrings.isUrdu(context) ? t.labelUrdu : t.labelEnglish,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: _onTypeChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MSpacing.sm),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Label Code', ur: 'لیبل کوڈ'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _labelCodeCtrl,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppStrings.val(context, en: 'Required', ur: 'لازمی')
                                : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MSpacing.sm),

                // Commodity & Variety
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Commodity', ur: 'جنس'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Autocomplete<String>(
                            initialValue: TextEditingValue(
                                text: _commodityCtrl.text),
                            optionsBuilder: (textEditingValue) {
                              final list = _getPopularCommodities(AppStrings.isUrdu(context));
                              if (textEditingValue.text.isEmpty) {
                                return list;
                              }
                              return list.where((c) => c
                                  .toLowerCase()
                                  .contains(
                                      textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (selection) {
                              _commodityCtrl.text = selection;
                              setState(() {});
                            },
                            fieldViewBuilder:
                                (context, ctrl, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: ctrl,
                                focusNode: focusNode,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: AppStrings.val(context, en: 'e.g. Wheat', ur: 'مثلاً گندم'),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                onChanged: (v) {
                                  _commodityCtrl.text = v;
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MSpacing.sm),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Variety', ur: 'قسم / ورائٹی'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _varietyCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: AppStrings.val(context, en: 'e.g. Kainat 1121', ur: 'مثلاً کائنات ۱۱۲۱'),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
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
                const SizedBox(height: MSpacing.sm),

                // Party & Vehicle
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Grower / Farmer Party', ur: 'زمیندار / بیوپاری'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _partyCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: AppStrings.val(context, en: 'e.g. Haji Bashir Ahmad', ur: 'مثلاً حاجی بشیر احمد'),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
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
                    const SizedBox(width: MSpacing.sm),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Vehicle Number', ur: 'گاڑی نمبر'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _vehicleCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'FD-8921',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
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
                const SizedBox(height: MSpacing.sm),

                // Packaging & Bag Count
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Packaging Type', ur: 'باردانہ کی قسم'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<PackageType>(
                            initialValue: _packageType,
                            dropdownColor: MColors.surfaceDark,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: PackageType.values.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(
                                  AppStrings.isUrdu(context) ? p.labelUrdu : p.labelEnglish,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (p) {
                              if (p != null) {
                                setState(() => _packageType = p);
                                _recomputeWeights();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MSpacing.sm),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Bag Count', ur: 'تعداد بوریاں'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _bagCountCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '100',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppStrings.val(context, en: 'Required', ur: 'لازمی')
                                : null,
                            onChanged: (_) => _recomputeWeights(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MSpacing.sm),

                // Gross Weight & Computed Math
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Gross Weight (KG)', ur: 'بھرا وزن (کلوگرام)'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _grossWeightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '10000',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppStrings.val(context, en: 'Required', ur: 'لازمی')
                                : null,
                            onChanged: (_) => _recomputeWeights(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MSpacing.sm),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Quality Grade', ur: 'معیار / گریڈ'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _qualityGrade,
                            dropdownColor: MColors.surfaceDark,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'grade_a_super',
                                child: Text(AppStrings.val(context, en: 'Grade A (Super)', ur: 'گریڈ اے (اعلیٰ)'),
                                    style: const TextStyle(color: Colors.white)),
                              ),
                              DropdownMenuItem(
                                value: 'grade_b_faq',
                                child: Text(AppStrings.val(context, en: 'Grade B (Standard FAQ)', ur: 'گریڈ بی (معیاری)'),
                                    style: const TextStyle(color: Colors.white)),
                              ),
                              DropdownMenuItem(
                                value: 'grade_c_substandard',
                                child: Text(AppStrings.val(context, en: 'Grade C (Substandard)', ur: 'گریڈ سی (زیادہ نمی)'),
                                    style: const TextStyle(color: Colors.white)),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Text(AppStrings.val(context, en: 'Rejected / Unfit', ur: 'مسترد شدہ (ناقص)'),
                                    style: const TextStyle(color: Colors.white)),
                              ),
                            ],
                            onChanged: (g) {
                              if (g != null) setState(() => _qualityGrade = g);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MSpacing.sm),

                // Weight Calculation Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: MColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(AppStrings.val(context, en: 'Tare Deduct', ur: 'باردانہ کٹوتی'),
                              style: MText.caption
                                  .copyWith(color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            '${_computedTareKg.toStringAsFixed(1)} KG',
                            style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(AppStrings.val(context, en: 'Net Weight', ur: 'صاف وزن'),
                              style: MText.caption
                                  .copyWith(color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            '${_computedNetKg.toStringAsFixed(1)} KG',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(AppStrings.val(context, en: 'Mandi Maunds', ur: 'من'),
                              style: MText.caption
                                  .copyWith(color: MColors.primaryLight)),
                          const SizedBox(height: 2),
                          Text(
                            '${_computedNetMaunds.toStringAsFixed(2)} ${AppStrings.val(context, en: 'Mnds', ur: 'من')}',
                            style: const TextStyle(
                              color: MColors.primaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MSpacing.sm),

                // Location / Facility
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Facility / Location', ur: 'گودام یا مقام'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _facilityCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Main Godown',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
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
                    const SizedBox(width: MSpacing.sm),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.val(context, en: 'Bay / Stack', ur: 'چٹہ / بلاک'),
                            style: MText.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _bayCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Bay B-02, Stack 4',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
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
                const SizedBox(height: MSpacing.sm),

                // Notes
                Text(
                  AppStrings.val(context, en: 'Instructions / Notes', ur: 'ہدایات / تفصیل'),
                  style: MText.caption.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: AppStrings.val(context, en: 'Special stacking or preservation instructions...', ur: 'سٹوریج اور دیکھ بھال کی خصوصی ہدایات...'),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: MSpacing.md),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () => _submit(printAfter: true),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: Text(AppStrings.val(context, en: 'Save & Print A4', ur: 'محفوظ و پرنٹ کریں')),
                      ),
                    ),
                    const SizedBox(width: MSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            _isSaving ? null : () => _submit(printAfter: false),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(AppStrings.val(context, en: 'Save Label', ur: 'لیبل محفوظ کریں')),
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
