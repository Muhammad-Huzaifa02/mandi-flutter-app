import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/modules/fleet/providers/fleet_provider.dart';

/// Modal dialog to record fuel purchases (Diesel, Petrol, CNG, Oil)
/// and mechanical repairs (*ڈیزل، مبلائل و مینٹیننس لاگ اندراج*).
class LogFuelExpenseDialog extends StatefulWidget {
  final String? preselectedVehicleId;
  final String? preselectedTripId;

  const LogFuelExpenseDialog({
    super.key,
    this.preselectedVehicleId,
    this.preselectedTripId,
  });

  @override
  State<LogFuelExpenseDialog> createState() => _LogFuelExpenseDialogState();
}

class _LogFuelExpenseDialogState extends State<LogFuelExpenseDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedVehicleId;
  String? _selectedTripId;
  DateTime _logDate = DateTime.now();
  String _fuelType = 'diesel';

  final _pumpVendorCtrl = TextEditingController(text: 'PSO Pump Arifwala');
  final _litersCtrl = TextEditingController(text: '50');
  final _ratePerLiterCtrl = TextEditingController(text: '280');
  final _totalCostCtrl = TextEditingController(text: '14000');
  final _odometerCtrl = TextEditingController();
  final _voucherCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isSaving = false;

  final Map<String, String> _fuelTypes = {
    'diesel': 'Diesel (ڈیزل)',
    'petrol': 'Petrol (پٹرول)',
    'cng': 'CNG (گیس)',
    'engine_oil': 'Engine Oil & Filter (مبلائل)',
    'maintenance': 'Workshop Repair (مرمت و خرابی)',
    'tire_puncture': 'Tire & Tube (ٹائر و پنکچر)',
  };

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.preselectedVehicleId;
    _selectedTripId = widget.preselectedTripId;

    _litersCtrl.addListener(_computeTotal);
    _ratePerLiterCtrl.addListener(_computeTotal);
  }

  void _computeTotal() {
    final l = double.tryParse(_litersCtrl.text.trim()) ?? 0.0;
    final r = double.tryParse(_ratePerLiterCtrl.text.trim()) ?? 0.0;
    final total = l * r;
    if (total > 0) {
      _totalCostCtrl.text = total.toStringAsFixed(0);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pumpVendorCtrl.dispose();
    _litersCtrl.dispose();
    _ratePerLiterCtrl.dispose();
    _totalCostCtrl.dispose();
    _odometerCtrl.dispose();
    _voucherCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FleetProvider>();
    final vehicles = provider.vehicles.where((v) => v.isActive).toList();

    if (_selectedVehicleId == null && vehicles.isNotEmpty) {
      _selectedVehicleId = vehicles.first.id;
    }

    final vehicleTrips = provider.trips
        .where((t) => t.vehicleId == _selectedVehicleId)
        .toList();

    final currencyFmt = NumberFormat('#,##0', 'en_US');
    final totalCost = double.tryParse(_totalCostCtrl.text.trim()) ?? 0.0;

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
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_gas_station,
                          color: Colors.amber),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Log Fuel / Expense (ڈیزل و خرچ لاگ)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Fuel purchases, lubricants & fleet maintenance',
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

                // Vehicle & Date
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Vehicle / گاڑی *',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          if (vehicles.isEmpty)
                            const Text('No vehicles available',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 12))
                          else
                            DropdownButtonFormField<String>(
                              initialValue: _selectedVehicleId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: vehicles.map((v) {
                                return DropdownMenuItem(
                                  value: v.id,
                                  child: Text(
                                    '${v.registrationNumber} (${v.vehicleType.labelEnglish})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedVehicleId = val;
                                    _selectedTripId = null;
                                  });
                                }
                              },
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Select vehicle'
                                  : null,
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
                            'Date / تاریخ',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _logDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => _logDate = picked);
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
                                DateFormat('dd MMM yyyy').format(_logDate),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Expense Type & Optional Trip Link
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expense Type / قسم خرچہ',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _fuelType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: _fuelTypes.entries.map((e) {
                              return DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value,
                                    style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _fuelType = val);
                              }
                            },
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
                            'Linked Trip (اختیاری ٹرپ لنک)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String?>(
                            initialValue: _selectedTripId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No Trip (General Fleet)',
                                    style: TextStyle(fontSize: 12)),
                              ),
                              ...vehicleTrips.map((t) {
                                return DropdownMenuItem<String?>(
                                  value: t.id,
                                  child: Text(
                                    '${t.tripNumber} (${t.origin} -> ${t.destination})',
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedTripId = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pump / Vendor Name & Voucher Number
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pump / Vendor / پٹرول پمپ یا دکان *',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _pumpVendorCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. PSO Petrol Station / Shell Mandi',
                              prefixIcon: const Icon(Icons.storefront_outlined,
                                  size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
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
                            'Voucher # / پرچی نمبر',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _voucherCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. V-9082',
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

                // Liters, Rate, Total
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quantity / Liters / مقدار',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _litersCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              suffixText: 'Ltr/Qty',
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rate / ریٹ فی لیٹر',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _ratePerLiterCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Cost / کل لاگت *',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _totalCostCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) {
                              final cost = double.tryParse(v ?? '') ?? 0;
                              return cost <= 0 ? 'Enter cost' : null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Odometer (KM)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Odometer / موجودہ میٹر ریڈنگ (KM)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _odometerCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: 'e.g. 54200',
                              suffixText: 'KM',
                              prefixIcon:
                                  const Icon(Icons.speed_outlined, size: 18),
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

                // Notes
                const Text(
                  'Remarks / تفصیل',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Full tank before Faisalabad dispatch',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Total Highlight Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Fuel / Expense Payable:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        'Rs. ${currencyFmt.format(totalCost)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
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
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _saveFuelLog,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Log Expense (خرچ درج کریں)'),
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

  Future<void> _saveFuelLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) return;

    setState(() => _isSaving = true);

    final liters = double.tryParse(_litersCtrl.text.trim()) ?? 0.0;
    final rate = double.tryParse(_ratePerLiterCtrl.text.trim()) ?? 0.0;
    final odo = double.tryParse(_odometerCtrl.text.trim()) ?? 0.0;

    final provider = context.read<FleetProvider>();
    final success = await provider.logFuelOrExpense(
      vehicleId: _selectedVehicleId!,
      tripId: _selectedTripId,
      logDate: _logDate,
      fuelType: _fuelType,
      pumpOrVendorName: _pumpVendorCtrl.text.trim(),
      liters: liters,
      ratePerLiter: rate,
      odometerKm: odo,
      receiptVoucherNumber: _voucherCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fuel expense logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record fuel expense. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
