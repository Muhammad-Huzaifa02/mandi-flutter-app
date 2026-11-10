import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  StreamSubscription<ScaleReading>? _scaleSub;

  final _numberFmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    // Listen to scale stream
    _scaleSub = ScaleService().readingStream.listen((reading) {
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
    _scaleSub?.cancel();
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
        const SnackBar(
          content: Text('Please enter a valid Gross Weight (وزن بھرا) > 0 KG'),
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
          const SnackBar(
            content: Text(
              '1st Weight recorded successfully. Awaiting empty vehicle (Tare weight)!',
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
            content: Text('Failed to save ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteredGross = double.tryParse(_grossWeightCtrl.text.trim()) ?? 0.0;
    final enteredMaunds = enteredGross / 40.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record 1st Weight (Gross / بھرا)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'دھرم کنڈا: گاڑی کا پہلا وزن درج کریں',
                              style: TextStyle(
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
                                      const Text(
                                        'Digital Scale Indicator',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _scaleIsStable
                                            ? 'Status: STABLE (ST)'
                                            : 'Status: MOTION (US)...',
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
                                    label: const Text('Capture'),
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
                                  labelText: 'Vehicle Number * (گاڑی نمبر)',
                                  hintText: 'e.g. LES-8920, FDN-4411',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon:
                                      const Icon(Icons.local_shipping_outlined),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<VehicleType>(
                                initialValue: _selectedVehicleType,
                                decoration: InputDecoration(
                                  labelText: 'Vehicle Type (قسم گاڑی)',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                                items: VehicleType.values.map((v) {
                                  return DropdownMenuItem(
                                    value: v,
                                    child: Text(
                                      '${v.labelEnglish} (${v.labelUrdu})',
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
                                  labelText: 'Driver Name (ڈرائیور نام)',
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
                                  labelText: 'Driver Phone (فون نمبر)',
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
                                  labelText: 'Party / Farmer (مالک مال / زمیندار)',
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
                                  labelText: 'Party Type',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                                items: WeighbridgePartyType.values.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      '${p.labelEnglish} (${p.labelUrdu})',
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
                                  labelText: 'Commodity (جنس / فصل)',
                                  hintText: 'e.g. Wheat (گندم), Paddy (دھان)',
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
                                  labelText: 'Bags (تعداد بوری)',
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
                                            '1st Weight (Gross / بھرا وزن KG) *',
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
                                          return 'Gross weight required';
                                        }
                                        final num = double.tryParse(val.trim());
                                        if (num == null || num <= 0) {
                                          return 'Must be > 0';
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
                                          const Text(
                                            'Weight in Maunds (من)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_numberFmt.format(enteredMaunds)} Maunds',
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
                                  labelText: 'Kanda Fee (کنڈا فیس Rs)',
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
                                  labelText: 'Fee Paid By (فیس دہندہ)',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                                items: WeighbridgeFeePaidBy.values.map((f) {
                                  return DropdownMenuItem(
                                    value: f,
                                    child: Text(
                                      '${f.labelEnglish} (${f.labelUrdu})',
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
                                  labelText: 'Weighmaster / Operator (کنڈا انچارج)',
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
                                  labelText: 'Notes (خصوصی نوٹ)',
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
                      child: const Text('Cancel'),
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
                        _isSaving ? 'Recording...' : 'Record 1st Weight (محفوظ)',
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
