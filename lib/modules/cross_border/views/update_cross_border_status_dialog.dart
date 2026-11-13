import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/cross_border_shipment_model.dart';
import 'package:mandi/modules/consignment/views/add_consignment_lot_page.dart';
import 'package:mandi/modules/cross_border/providers/cross_border_provider.dart';

/// Modal dialog to update transit status, record foreign farmer settlements,
/// or bridge into an incoming Mandi Consignment Lot.
class UpdateCrossBorderStatusDialog extends StatefulWidget {
  final CrossBorderShipment shipment;

  const UpdateCrossBorderStatusDialog({super.key, required this.shipment});

  @override
  State<UpdateCrossBorderStatusDialog> createState() =>
      _UpdateCrossBorderStatusDialogState();
}

class _UpdateCrossBorderStatusDialogState
    extends State<UpdateCrossBorderStatusDialog> {
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _additionalPaymentCtrl = TextEditingController();

  late CrossBorderShipmentStatus _selectedStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.shipment.status;
  }

  @override
  void dispose() {
    _additionalPaymentCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    final isUrdu = AppStrings.isUrdu(context);
    setState(() => _isUpdating = true);
    try {
      await context.read<CrossBorderProvider>().updateShipmentStatus(
            id: widget.shipment.id,
            newStatus: _selectedStatus,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUrdu
                ? 'مال کی حالت تبدیل ہو کر ${_selectedStatus.labelUrdu} ہو گئی'
                : 'Shipment status updated to ${_selectedStatus.labelEnglish}'),
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
                ? 'حالت تبدیل کرنے میں ناکامی: $e'
                : 'Failed to update status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _recordPayment() async {
    final isUrdu = AppStrings.isUrdu(context);
    final payAmount = double.tryParse(_additionalPaymentCtrl.text) ?? 0.0;
    if (payAmount <= 0) return;

    setState(() => _isUpdating = true);
    try {
      await context.read<CrossBorderProvider>().recordSupplierPayment(
            shipment: widget.shipment,
            additionalForeignAmount: payAmount,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUrdu
                ? 'زمیندار کو ${widget.shipment.currency.symbol} ${_currencyFmt.format(payAmount)} کی ادائیگی محفوظ کر لی گئی'
                : 'Recorded ${widget.shipment.currency.symbol} ${_currencyFmt.format(payAmount)} payment to farmer'),
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
                ? 'ادائیگی درج کرنے میں ناکامی: $e'
                : 'Failed to record payment: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _bridgeToConsignmentLot() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddConsignmentLotPage(
          initialVehicleNumber: widget.shipment.vehicleNumber,
          initialBags: widget.shipment.packageCount,
          initialWeightKg: widget.shipment.grossWeightKg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.shipment;
    final isUrdu = AppStrings.isUrdu(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
        child: GlassCard(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: s.status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.sync_alt_rounded,
                        color: s.status.color, size: 24),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.val(
                            context,
                            en: 'Update Cargo Status',
                            ur: 'مال کی حالت تبدیل کریں',
                          ),
                          style: MText.titleMd.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${s.shipmentNumber} • ${s.originCountry.flagEmoji} ${s.vehicleNumber}',
                          style: MText.caption.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
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

              const SizedBox(height: MSpacing.md),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Selection
                      Text(
                        AppStrings.val(
                          context,
                          en: 'Change Cargo Status:',
                          ur: 'سرحدی مال کی موجودہ حالت:',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: MSpacing.xs),
                      DropdownButtonFormField<CrossBorderShipmentStatus>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.traffic_outlined, size: 18),
                        ),
                        items: CrossBorderShipmentStatus.values.map((st) {
                          return DropdownMenuItem(
                            value: st,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: st.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isUrdu ? st.labelUrdu : st.labelEnglish,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),

                      const SizedBox(height: MSpacing.sm),
                      ElevatedButton.icon(
                        onPressed: _isUpdating ? null : _updateStatus,
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: Text(AppStrings.val(
                          context,
                          en: 'Save Status',
                          ur: 'حالت محفوظ کریں',
                        )),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: MSpacing.lg),
                      const Divider(),
                      const SizedBox(height: MSpacing.sm),

                      // Supplier Settlement Box
                      Container(
                        padding: const EdgeInsets.all(MSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.val(context, en: "Foreign Farmer Ledger", ur: "غیر ملکی زمیندار کھاتہ")} (${s.currency.code}):',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Total Contract:',
                                    ur: 'کل معاہدہ:',
                                  ),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  '${s.currency.symbol} ${_currencyFmt.format(s.foreignContractAmount)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Disbursed So Far:',
                                    ur: 'ادا شدہ رقم:',
                                  ),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  '${s.currency.symbol} ${_currencyFmt.format(s.paidToSupplierForeign)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                            const Divider(height: 10),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Outstanding Debt:',
                                    ur: 'بقایا واجب الادا:',
                                  ),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${s.currency.symbol} ${_currencyFmt.format(s.computedRemainingSupplierForeign)} (Rs. ${_currencyFmt.format(s.computedRemainingSupplierPkr)})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: s.computedRemainingSupplierForeign > 0
                                        ? Colors.red.shade800
                                        : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (s.computedRemainingSupplierForeign > 0) ...[
                              TextFormField(
                                controller: _additionalPaymentCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText:
                                      '${AppStrings.val(context, en: "Add Payment", ur: "ادائیگی درج کریں")} (${s.currency.symbol} ${s.currency.code})',
                                  hintText: 'e.g. 2000',
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _isUpdating ? null : _recordPayment,
                                icon: const Icon(Icons.payment, size: 16),
                                label: Text(AppStrings.val(
                                  context,
                                  en: 'Record Foreign Payment',
                                  ur: 'غیر ملکی ادائیگی درج کریں',
                                )),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: MSpacing.lg),
                      const Divider(),
                      const SizedBox(height: MSpacing.sm),

                      // 1-Click Bridge to Consignment Lot (Dheri)
                      Container(
                        padding: const EdgeInsets.all(MSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.secondary
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    color: theme.colorScheme.secondary,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Mandi Auction Bridge',
                                    ur: 'آمد و ڈھیری انضمام',
                                  ),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.val(
                                context,
                                en: 'When vehicle reaches the Mandi yard, create a Consignment Lot to start auction bidding.',
                                ur: 'جب گاڑی منڈی کے پھڑ پر پہنچ جائے تو بولی شروع کرنے کے لیے ڈھیری لاٹ بنائیں۔',
                              ),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _bridgeToConsignmentLot,
                                icon: const Icon(Icons.add_shopping_cart,
                                    size: 16),
                                label: Text(AppStrings.val(
                                  context,
                                  en: 'Create Consignment Lot',
                                  ur: 'ڈھیری لاٹ بنائیں',
                                )),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: MSpacing.md),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.val(
                  context,
                  en: 'Close',
                  ur: 'بند کریں',
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
