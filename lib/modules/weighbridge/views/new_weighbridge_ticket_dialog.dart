import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/scale_service.dart';
import 'package:mandi/data/models/weighbridge_ticket_model.dart';
import 'package:mandi/modules/weighbridge/providers/weighbridge_provider.dart';

/// Modal dialog to record a 1st Weight (Gross) ticket on the Mandi Weighbridge.
class NewWeighbridgeTicketDialog extends StatefulWidget {
  const NewWeighbridgeTicketDialog({super.key});

  @override
  State<NewWeighbridgeTicketDialog> createState() =>
      _NewWeighbridgeTicketDialogState();
}

class _NewWeighbridgeTicketDialogState extends State<NewWeighbridgeTicketDialog> {
  final _formKey = GlobalKey<FormState>();

  final _vehicleNumberCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _partyNameCtrl = TextEditingController();
  final _commodityCtrl = TextEditingController();
  final _bagCountCtrl = TextEditingController(text: '0');
  final _grossWeightCtrl = TextEditingController();
  final _kandaFeeCtrl = TextEditingController(text: '200');
  final _operatorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  VehicleType _selectedVehicleType = VehicleType.trolley;
  WeighbridgePartyType _selectedPartyType = WeighbridgePartyType.farmer;
  WeighbridgeFeePaidBy _selectedFeePayer = WeighbridgeFeePaidBy.farmer;

  bool _isSaving = false;
  double _liveScaleWeight = 0.0;
  bool _scaleIsStable = true;
  StreamSubscription<ScaleReading>? _scaleSubscription;

  final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _connectScaleListener();
  }

  void _connectScaleListener() {
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
    _vehicleNumberCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _partyNameCtrl.dispose();
    _commodityCtrl.dispose();
    _bagCountCtrl.dispose();
    _grossWeightCtrl.dispose();
    _kandaFeeCtrl.dispose();
    _operatorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _fetchFromScale() {
    if (_liveScaleWeight > 0) {
      _grossWeightCtrl.text = _liveScaleWeight.toStringAsFixed(1);
      setState(() {});
    } else {
      // If scale at 0, simulate vehicle weight for demo
      ScaleService().startSimulation(targetWeightKg: 8520.0);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          _grossWeightCtrl.text = '8520';
          setState(() {});
        }
      });
    }
  }

  Future<void> _saveTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final grossWeight = double.tryParse(_grossWeightCtrl.text.trim()) ?? 0.0;
    if (grossWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Please enter a valid Gross Weight > 0 KG',
              ur: 'برائے مہربانی درست بھرا وزن درج کریں (> 0 کلوگرام)',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prov = context.read<WeighbridgeProvider>();
      await prov.createGrossTicket(
        vehicleNumber: _vehicleNumberCtrl.text.trim().toUpperCase(),
        vehicleType: _selectedVehicleType,
        driverName: _driverNameCtrl.text.trim(),
        driverPhone: _driverPhoneCtrl.text.trim(),
        partyName: _partyNameCtrl.text.trim(),
        partyType: _selectedPartyType,
        commodityName: _commodityCtrl.text.trim(),
        grossWeightKg: grossWeight,
        bagCount: int.tryParse(_bagCountCtrl.text.trim()) ?? 0,
        kandaFee: double.tryParse(_kandaFeeCtrl.text.trim()) ?? 0.0,
        feePaidBy: _selectedFeePayer,
        operatorName: _operatorCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.val(
                context,
                en: '1st Weight recorded successfully. Awaiting empty vehicle (Tare weight)!',
                ur: 'گاڑی کا پہلا وزن کامیابی سے درج ہو گیا۔ اب خالی گاڑی کا وزن درکار ہے۔',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.val(context, en: "Failed to save ticket", ur: "پرچی محفوظ کرنے میں خرابی")}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppStrings.isUrdu(context);
    final enteredGross = double.tryParse(_grossWeightCtrl.text.trim()) ?? 0.0;
    final enteredMaunds = enteredGross / 40.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MColors.primary.withValues(alpha: 0.1),
                            borderRadius: MRadius.sm,
                          ),
                          child: const Icon(
                            Icons.scale_rounded,
                            color: MColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.val(
                                context,
                                en: 'Record 1st Weight (Gross)',
                                ur: 'گاڑی کا پہلا وزن (بھرا گاڑی)',
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              AppStrings.val(
                                context,
                                en: 'Weighbridge: Record gross weight of loaded vehicle',
                                ur: 'دھرم کنڈا: بھری گاڑی کا ابتدائی وزن درج کریں',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),

                // ── Form Scrollable Body ──────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scale Live Reading Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.04),
                            borderRadius: MRadius.md,
                            border: Border.all(
                              color: _scaleIsStable
                                  ? MColors.primaryLight
                                  : Colors.orange,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.sensors,
                                    size: 20,
                                    color: _scaleIsStable
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.val(
                                          context,
                                          en: 'Digital Scale Indicator',
                                          ur: 'الیکٹرانک ترازو پیمانہ',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _scaleIsStable
                                            ? AppStrings.val(
                                                context,
                                                en: 'Status: STABLE (ST)',
                                                ur: 'حالت: مستحکم (ST)',
                                              )
                                            : AppStrings.val(
                                                context,
                                                en: 'Status: MOTION (US)...',
                                                ur: 'حالت: متحرک (US)...',
                                              ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _scaleIsStable
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${_numberFmt.format(_liveScaleWeight)} KG',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: _fetchFromScale,
                                    icon: const Icon(Icons.download, size: 16),
                                    label: Text(
                                      AppStrings.val(
                                        context,
                                        en: 'Capture',
                                        ur: 'وزن لیں',
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      backgroundColor: MColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Vehicle No & Vehicle Type
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _vehicleNumberCtrl,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: '${AppStrings.val(context, en: 'Vehicle Number', ur: 'گاڑی نمبر')} *',
                                  hintText: 'e.g. LES-8920, FDN-4411',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon:
                                      const Icon(Icons.local_shipping_outlined),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty)
                                        ? AppStrings.val(context, en: 'Required', ur: 'لازمی درج کریں')
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<VehicleType>(
                                initialValue: _selectedVehicleType,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Vehicle Type', ur: 'گاڑی کی قسم'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                                items: VehicleType.values.map((v) {
                                  return DropdownMenuItem(
                                    value: v,
                                    child: Text(
                                      isUrdu ? v.labelUrdu : v.labelEnglish,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedVehicleType = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Driver Name & Driver Phone
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _driverNameCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Driver Name', ur: 'ڈرائیور کا نام'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _driverPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Driver Phone', ur: 'ڈرائیور فون نمبر'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Party Name & Party Type
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _partyNameCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Farmer / Party Name', ur: 'زمیندار / کھاتہ کا نام'),
                                  hintText: 'e.g. Chaudhry Akram, Haji Bashir',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<WeighbridgePartyType>(
                                initialValue: _selectedPartyType,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Party Type', ur: 'کھاتہ کی قسم'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                                items: WeighbridgePartyType.values.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      isUrdu ? p.labelUrdu : p.labelEnglish,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedPartyType = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Commodity & Bag Count
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _commodityCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Commodity', ur: 'جنس / فصل'),
                                  hintText: AppStrings.val(context, en: 'e.g. Wheat, Paddy, Corn', ur: 'مثلاً گندم، دھان، مکئی'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon:
                                      const Icon(Icons.grass_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _bagCountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Bags Count', ur: 'تعداد بوریاں'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon:
                                      const Icon(Icons.inventory_2_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Gross Weight Input & Calculated Maunds
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: MColors.primary.withValues(alpha: 0.05),
                            borderRadius: MRadius.md,
                            border: Border.all(
                              color: MColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _grossWeightCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: MColors.primary,
                                      ),
                                      decoration: InputDecoration(
                                        labelText:
                                            '${AppStrings.val(context, en: '1st Weight (Gross KG)', ur: 'پہلا وزن (بھرا وزن کلوگرام)')} *',
                                        suffixText: 'KG',
                                        border: OutlineInputBorder(
                                          borderRadius: MRadius.sm,
                                        ),
                                        prefixIcon:
                                            const Icon(Icons.fitness_center),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return AppStrings.val(context, en: 'Gross weight required', ur: 'بھرا وزن لازمی درج کریں');
                                        }
                                        final num = double.tryParse(val.trim());
                                        if (num == null || num <= 0) {
                                          return AppStrings.val(context, en: 'Must be > 0', ur: '0 سے زیادہ ہونا چاہیے');
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: MRadius.sm,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppStrings.val(context, en: 'Weight in Maunds', ur: 'وزن بلحاظ من'),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_numberFmt.format(enteredMaunds)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: MColors.primary,
                                            ),
                                          ),
                                          const Text(
                                            'KG ÷ 40.0',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Kanda Fee & Fee Payer
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _kandaFeeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Kanda Fee (PKR)', ur: 'کنڈا فیس (روپے)'),
                                  prefixText: 'Rs. ',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<WeighbridgeFeePaidBy>(
                                initialValue: _selectedFeePayer,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Fee Paid By', ur: 'فیس دہندہ'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                                items: WeighbridgeFeePaidBy.values.map((f) {
                                  return DropdownMenuItem(
                                    value: f,
                                    child: Text(
                                      isUrdu ? f.labelUrdu : f.labelEnglish,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedFeePayer = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Operator & Notes
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _operatorCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Weighmaster / Operator', ur: 'کنڈا انچارج'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _notesCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Notes / Remarks', ur: 'خصوصی نوٹ'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),

                // ── Action Buttons ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.val(context, en: 'Cancel', ur: 'منسوخ کریں')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTicket,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSaving
                            ? AppStrings.val(context, en: 'Recording...', ur: 'محفوظ ہو رہا ہے...')
                            : AppStrings.val(context, en: 'Record 1st Weight', ur: 'پہلا وزن محفوظ کریں'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: MRadius.sm,
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
