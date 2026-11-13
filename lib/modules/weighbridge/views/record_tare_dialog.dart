import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/scale_service.dart';
import 'package:mandi/core/utils/weighbridge_slip_pdf_generator.dart';
import 'package:mandi/data/models/weighbridge_ticket_model.dart';
import 'package:mandi/modules/weighbridge/providers/weighbridge_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Modal dialog to record 2nd Weight (Tare) for an empty vehicle returning to the weighbridge.
class RecordTareDialog extends StatefulWidget {
  final WeighbridgeTicket ticket;

  const RecordTareDialog({super.key, required this.ticket});

  @override
  State<RecordTareDialog> createState() => _RecordTareDialogState();
}

class _RecordTareDialogState extends State<RecordTareDialog> {
  final _formKey = GlobalKey<FormState>();

  final _tareWeightCtrl = TextEditingController();
  final _deductionKgCtrl = TextEditingController(text: '0');
  final _deductionReasonCtrl = TextEditingController();

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
    _tareWeightCtrl.dispose();
    _deductionKgCtrl.dispose();
    _deductionReasonCtrl.dispose();
    super.dispose();
  }

  void _fetchFromScale() {
    if (_liveScaleWeight > 0) {
      _tareWeightCtrl.text = _liveScaleWeight.toStringAsFixed(1);
      setState(() {});
    } else {
      // Simulate typical empty trolley/truck tare weight for demo
      ScaleService().startSimulation(targetWeightKg: 2480.0);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          _tareWeightCtrl.text = '2480';
          setState(() {});
        }
      });
    }
  }

  Future<void> _completeTareWeight({bool printSlip = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final tareWeight = double.tryParse(_tareWeightCtrl.text.trim()) ?? 0.0;
    if (tareWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Please enter a valid Tare Weight > 0 KG',
              ur: 'برائے مہربانی درست خالی وزن درج کریں (> 0 کلوگرام)',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (tareWeight >= widget.ticket.grossWeightKg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.val(
              context,
              en: 'Tare weight (${_numberFmt.format(tareWeight)} KG) cannot be >= Gross weight (${_numberFmt.format(widget.ticket.grossWeightKg)} KG)',
              ur: 'خالی وزن (${_numberFmt.format(tareWeight)} کلوگرام) بھرے وزن (${_numberFmt.format(widget.ticket.grossWeightKg)} کلوگرام) کے برابر یا زیادہ نہیں ہو سکتا',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final deductionKg = double.tryParse(_deductionKgCtrl.text.trim()) ?? 0.0;

    setState(() => _isSaving = true);
    try {
      final prov = context.read<WeighbridgeProvider>();
      final shopName =
          context.read<ShopContextProvider>().currentShop?.name ??
              'Mandi Commission Shop';

      await prov.recordTareWeight(
        ticketId: widget.ticket.id,
        grossWeightKg: widget.ticket.grossWeightKg,
        tareWeightKg: tareWeight,
        deductionKg: deductionKg,
        deductionReason: _deductionReasonCtrl.text.trim(),
      );

      if (!mounted) return;

      if (printSlip) {
        final updatedTicket = widget.ticket.copyWith(
          tareWeightKg: tareWeight,
          deductionKg: deductionKg,
          deductionReason: _deductionReasonCtrl.text.trim(),
          status: WeighbridgeStatus.completed,
          tareWeighedAt: DateTime.now(),
        );

        final pdfBytes =
            await WeighbridgeSlipPdfGenerator.generateSlipPdf(
          ticket: updatedTicket,
          shopName: shopName,
        );

        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'Kanda_Slip_${updatedTicket.ticketNumber}.pdf',
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        final finalWeight =
            (widget.ticket.grossWeightKg - tareWeight - deductionKg)
                .clamp(0.0, double.infinity);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.val(
                context,
                en: 'Tare weight completed successfully! Net Weight: ${_numberFmt.format(finalWeight)} KG',
                ur: 'گاڑی کا خالی وزن کامیابی سے مکمل ہو گیا۔ صاف وزن: ${_numberFmt.format(finalWeight)} کلوگرام',
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
            content: Text('${AppStrings.val(context, en: "Failed to record tare", ur: "خالی وزن درج کرنے میں خرابی")}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppStrings.isUrdu(context);
    final tareWeight = double.tryParse(_tareWeightCtrl.text.trim()) ?? 0.0;
    final deductionKg = double.tryParse(_deductionKgCtrl.text.trim()) ?? 0.0;
    final netWeight = (widget.ticket.grossWeightKg - tareWeight).clamp(0.0, double.infinity);
    final finalWeight = (netWeight - deductionKg).clamp(0.0, double.infinity);
    final finalMaunds = finalWeight / 40.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
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
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: MRadius.sm,
                          ),
                          child: const Icon(
                            Icons.rv_hookup_rounded,
                            color: Colors.amber,
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
                                en: 'Record 2nd Weight (Tare)',
                                ur: 'گاڑی کا دوسرا وزن (خالی گاڑی)',
                              ),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${AppStrings.val(context, en: "Slip", ur: "پرچی")} #${widget.ticket.ticketNumber} | ${widget.ticket.vehicleNumber}',
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

                // ── Body ──────────────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1st Weight Reference Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: MRadius.md,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppStrings.val(context, en: "Vehicle", ur: "گاڑی")}: ${widget.ticket.vehicleNumber} (${isUrdu ? widget.ticket.vehicleType.labelUrdu : widget.ticket.vehicleType.labelEnglish})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${AppStrings.val(context, en: "Party", ur: "کھاتہ")}: ${widget.ticket.partyName.isEmpty ? (isUrdu ? "عام" : "Walk-in") : widget.ticket.partyName} | ${AppStrings.val(context, en: "Crop", ur: "جنس")}: ${widget.ticket.commodityName}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppStrings.val(context, en: '1st Gross Weight', ur: 'پہلا بھرا وزن'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '${_numberFmt.format(widget.ticket.grossWeightKg)} KG',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: MColors.primary,
                                    ),
                                  ),
                                  Text(
                                    '${_numberFmt.format(widget.ticket.grossMaunds)} ${AppStrings.val(context, en: "Maunds", ur: "من")}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Digital Scale Capture Box
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
                                        AppStrings.val(context, en: 'Digital Scale Reading', ur: 'الیکٹرانک ترازو پیمانہ'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _scaleIsStable ? AppStrings.val(context, en: 'STABLE', ur: 'مستحکم') : AppStrings.val(context, en: 'MOTION...', ur: 'متحرک...'),
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: _fetchFromScale,
                                    icon: const Icon(Icons.download, size: 16),
                                    label: Text(AppStrings.val(context, en: 'Capture Tare', ur: 'خالی وزن لیں')),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      backgroundColor: Colors.amber.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tare Weight Input
                        TextFormField(
                          controller: _tareWeightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                          decoration: InputDecoration(
                            labelText: '${AppStrings.val(context, en: '2nd Weight (Tare KG)', ur: 'دوسرا وزن (خالی گاڑی کلوگرام)')} *',
                            suffixText: 'KG',
                            border: OutlineInputBorder(
                              borderRadius: MRadius.sm,
                            ),
                            prefixIcon: const Icon(Icons.rv_hookup),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return AppStrings.val(context, en: 'Tare weight required', ur: 'خالی وزن لازمی درج کریں');
                            }
                            final num = double.tryParse(val.trim());
                            if (num == null || num <= 0) {
                              return AppStrings.val(context, en: 'Must be > 0', ur: '0 سے زیادہ ہونا چاہیے');
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Deductions (Katoti) & Deduction Reason
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _deductionKgCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Deduction (KG)', ur: 'کٹوتی (کلوگرام)'),
                                  suffixText: 'KG',
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                  prefixIcon: const Icon(Icons.remove_circle_outline),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _deductionReasonCtrl,
                                decoration: InputDecoration(
                                  labelText: AppStrings.val(context, en: 'Deduction Reason', ur: 'وجہ کٹوتی'),
                                  hintText: AppStrings.val(context, en: 'e.g. Moisture, Dust, Bag tare', ur: 'مثلاً نمی، گرد، بوری کٹوتی'),
                                  border: OutlineInputBorder(
                                    borderRadius: MRadius.sm,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Live Calculation Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: MColors.primary.withValues(alpha: 0.08),
                            borderRadius: MRadius.md,
                            border: Border.all(
                              color: MColors.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.val(context, en: 'Net Vehicle Weight:', ur: 'صاف وزن گاڑی:'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '${_numberFmt.format(netWeight)} KG',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (deductionKg > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppStrings.val(context, en: 'Deductions:', ur: 'کٹوتی:'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Text(
                                      '-${_numberFmt.format(deductionKg)} KG',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.val(context, en: 'Final Payable Weight', ur: 'خالص قابلِ ادائیگی وزن'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: MColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${_numberFmt.format(finalWeight)} KG',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: MColors.primary,
                                        ),
                                      ),
                                      Text(
                                        '${_numberFmt.format(finalMaunds)} ${AppStrings.val(context, en: 'Maunds', ur: 'من')}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _completeTareWeight(printSlip: false),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(AppStrings.val(context, en: 'Complete', ur: 'مکمل کریں')),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _completeTareWeight(printSlip: true),
                      icon: const Icon(Icons.print, size: 16),
                      label: Text(AppStrings.val(context, en: 'Save & Print Slip', ur: 'محفوظ اور پرچی پرنٹ کریں')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
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
