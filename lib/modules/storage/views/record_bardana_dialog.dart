import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/bardana_model.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/storage/providers/storage_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Modal dialog to record Bardana (Bags / Sacks / Crates) issuance, return, or write-off.
class RecordBardanaDialog extends StatefulWidget {
  final BardanaDirection defaultDirection;

  const RecordBardanaDialog({
    super.key,
    this.defaultDirection = BardanaDirection.issued,
  });

  @override
  State<RecordBardanaDialog> createState() => _RecordBardanaDialogState();
}

class _RecordBardanaDialogState extends State<RecordBardanaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  late BardanaDirection _direction;
  BardanaType _bardanaType = BardanaType.jute;
  String _partyType = 'supplier'; // 'supplier' or 'customer'
  String? _partyId;
  late TextEditingController _partyNameCtrl;
  late TextEditingController _bagCountCtrl;
  late TextEditingController _depositRateCtrl;
  late TextEditingController _notesCtrl;
  DateTime _txDate = DateTime.now();
  DateTime _dueReturnDate = DateTime.now().add(const Duration(days: 14));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _direction = widget.defaultDirection;
    _partyNameCtrl = TextEditingController();
    _bagCountCtrl = TextEditingController(text: '50');
    _depositRateCtrl = TextEditingController(text: '250'); // 250 PKR per jute bag
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _partyNameCtrl.dispose();
    _bagCountCtrl.dispose();
    _depositRateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalDeposit {
    final count = int.tryParse(_bagCountCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(_depositRateCtrl.text.trim()) ?? 0.0;
    return count * rate;
  }

  void _onBardanaTypeChanged(BardanaType type) {
    setState(() {
      _bardanaType = type;
      switch (type) {
        case BardanaType.jute:
          _depositRateCtrl.text = '250';
          break;
        case BardanaType.plasticPp:
          _depositRateCtrl.text = '70';
          break;
        case BardanaType.woodenCrate:
          _depositRateCtrl.text = '120';
          break;
        case BardanaType.plasticCrate:
          _depositRateCtrl.text = '350';
          break;
        case BardanaType.other:
          break;
      }
    });
  }

  Future<void> _submit() async {
    final isUrdu = AppStrings.isUrdu(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final shopId = context.read<ShopContextProvider>().currentShopId;
      if (shopId == null) {
        throw Exception(isUrdu ? 'کوئی فعال دکان منتخب نہیں کی گئی۔' : 'No active shop context.');
      }

      final count = int.tryParse(_bagCountCtrl.text.trim()) ?? 0;
      final rate = double.tryParse(_depositRateCtrl.text.trim()) ?? 0.0;

      final tx = BardanaTransaction(
        id: '',
        shopId: shopId,
        partyType: _partyType,
        partyId: _partyId,
        partyName: _partyNameCtrl.text.trim(),
        bardanaType: _bardanaType,
        direction: _direction,
        bagCount: count,
        unitDepositRate: rate,
        totalDepositAmount: count * rate,
        transactionDate: _txDate,
        dueReturnDate:
            _direction == BardanaDirection.issued ? _dueReturnDate : null,
        status: _direction == BardanaDirection.returned
            ? BardanaStatus.returned
            : BardanaStatus.pending,
        notes: _notesCtrl.text.trim(),
      );

      await context.read<StorageProvider>().recordBardana(tx);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _direction == BardanaDirection.issued
                  ? (isUrdu
                      ? 'باردانہ جاری کر کے کھاتے میں درج کر دیا گیا۔'
                      : 'Bardana issued and logged in party ledger.')
                  : (isUrdu
                      ? 'باردانہ واپسی کامیابی کے ساتھ درج ہو گئی۔'
                      : 'Bardana return recorded successfully.'),
            ),
            backgroundColor: MColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrdu ? 'باردانہ کے اندراج میں خرابی: $e' : 'Error recording Bardana: $e',
            ),
            backgroundColor: MColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppStrings.isUrdu(context);
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final customers = context.watch<CustomerProvider>().customers;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: _direction == BardanaDirection.issued
                              ? Colors.orange.shade800
                              : MColors.primaryLight,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _direction == BardanaDirection.issued
                              ? (isUrdu ? 'باردانہ جاری کریں' : 'Issue Bardana')
                              : (isUrdu ? 'باردانہ واپسی درج کریں' : 'Return Bardana'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 18),

                // Direction Toggle
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_upward, size: 14),
                            const SizedBox(width: 4),
                            Text(isUrdu ? 'پارٹی کو جاری کریں' : 'Issue to Party'),
                          ],
                        ),
                        selected: _direction == BardanaDirection.issued,
                        selectedColor: Colors.orange.shade100,
                        onSelected: (v) {
                          if (v) setState(() => _direction = BardanaDirection.issued);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_downward, size: 14),
                            const SizedBox(width: 4),
                            Text(isUrdu ? 'پارٹی سے واپسی' : 'Return from Party'),
                          ],
                        ),
                        selected: _direction == BardanaDirection.returned,
                        selectedColor: MColors.primary.withValues(alpha: 0.15),
                        onSelected: (v) {
                          if (v) setState(() => _direction = BardanaDirection.returned);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bardana Type Chips
                Text(
                  isUrdu ? 'باردانہ کی قسم:' : 'Packaging Type:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(isUrdu ? 'پٹ سن بوری' : 'Jute Sack'),
                      selected: _bardanaType == BardanaType.jute,
                      onSelected: (_) => _onBardanaTypeChanged(BardanaType.jute),
                    ),
                    ChoiceChip(
                      label: Text(isUrdu ? 'پلاسٹک تھیلا' : 'Plastic Bag PP'),
                      selected: _bardanaType == BardanaType.plasticPp,
                      onSelected: (_) =>
                          _onBardanaTypeChanged(BardanaType.plasticPp),
                    ),
                    ChoiceChip(
                      label: Text(isUrdu ? 'لکڑی کریٹ' : 'Wooden Crate'),
                      selected: _bardanaType == BardanaType.woodenCrate,
                      onSelected: (_) =>
                          _onBardanaTypeChanged(BardanaType.woodenCrate),
                    ),
                    ChoiceChip(
                      label: Text(isUrdu ? 'پلاسٹک کریٹ' : 'Plastic Crate'),
                      selected: _bardanaType == BardanaType.plasticCrate,
                      onSelected: (_) =>
                          _onBardanaTypeChanged(BardanaType.plasticCrate),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Party Type
                Row(
                  children: [
                    Text(
                      isUrdu ? 'پارٹی زمرہ: ' : 'Party Category: ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(isUrdu ? 'زمیندار' : 'Farmer'),
                      selected: _partyType == 'supplier',
                      onSelected: (v) {
                        if (v) {
                          setState(() {
                            _partyType = 'supplier';
                            _partyId = null;
                            _partyNameCtrl.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(isUrdu ? 'خریدار' : 'Customer'),
                      selected: _partyType == 'customer',
                      onSelected: (v) {
                        if (v) {
                          setState(() {
                            _partyType = 'customer';
                            _partyId = null;
                            _partyNameCtrl.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Party Dropdown / Text
                if (_partyType == 'supplier' && suppliers.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _partyId,
                    decoration: InputDecoration(
                      labelText: isUrdu ? 'زمیندار منتخب کریں *' : 'Select Farmer *',
                      prefixIcon: const Icon(Icons.person),
                    ),
                    items: suppliers.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.name} (${s.phone})'),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final found = suppliers.firstWhere((s) => s.id == id);
                        setState(() {
                          _partyId = id;
                          _partyNameCtrl.text = found.name;
                        });
                      }
                    },
                    validator: (v) => _partyNameCtrl.text.trim().isEmpty
                        ? (isUrdu ? 'براہ کرم زمیندار منتخب کریں' : 'Please select or enter farmer name')
                        : null,
                  )
                else if (_partyType == 'customer' && customers.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _partyId,
                    decoration: InputDecoration(
                      labelText: isUrdu ? 'خریدار منتخب کریں *' : 'Select Customer *',
                      prefixIcon: const Icon(Icons.person),
                    ),
                    items: customers.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.name} (${c.phone})'),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final found = customers.firstWhere((c) => c.id == id);
                        setState(() {
                          _partyId = id;
                          _partyNameCtrl.text = found.name;
                        });
                      }
                    },
                    validator: (v) => _partyNameCtrl.text.trim().isEmpty
                        ? (isUrdu ? 'براہ کرم خریدار منتخب کریں' : 'Please select or enter customer name')
                        : null,
                  )
                else
                  TextFormField(
                    controller: _partyNameCtrl,
                    decoration: InputDecoration(
                      labelText: isUrdu ? 'پارٹی کا نام *' : 'Party Name *',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (isUrdu ? 'براہ کرم نام درج کریں' : 'Please enter party name')
                        : null,
                  ),
                const SizedBox(height: 14),

                // Bag Count & Deposit Rate
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bagCountCtrl,
                        decoration: InputDecoration(
                          labelText: isUrdu ? 'تعداد بوریاں *' : 'Quantity / Bags *',
                          hintText: '50',
                          prefixIcon: const Icon(Icons.pin),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return isUrdu ? 'لازمی ہے' : 'Required';
                          }
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) {
                            return isUrdu ? '0 سے بڑا ہونا چاہیے' : 'Must be > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _depositRateCtrl,
                        decoration: InputDecoration(
                          labelText: isUrdu ? 'سیکیورٹی ریٹ فی بوری' : 'Deposit per Bag',
                          hintText: '250',
                          prefixIcon: const Icon(Icons.monetization_on_outlined),
                          suffixText: isUrdu
                              ? 'روپے ${_currencyFmt.format(_totalDeposit)}'
                              : 'Rs. ${_currencyFmt.format(_totalDeposit)}',
                          suffixStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: MColors.primaryLight,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Transaction Date & Due Return Date
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _txDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _txDate = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: isUrdu ? 'تاریخ' : 'Date',
                            prefixIcon: const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(_dateFmt.format(_txDate)),
                        ),
                      ),
                    ),
                    if (_direction == BardanaDirection.issued) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueReturnDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _dueReturnDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: isUrdu ? 'واپسی کی تاریخ' : 'Return Due Date',
                              prefixIcon:
                                  const Icon(Icons.event_available, size: 18),
                            ),
                            child: Text(_dateFmt.format(_dueReturnDate)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'تفصیل و گاڑی نمبر' : 'Notes & Vehicle Info',
                    hintText: isUrdu ? 'مثلاً سوزوکی پک اپ #LES-881' : 'e.g. Sent via Suzuki Pick-up #LES-881',
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _direction == BardanaDirection.issued
                            ? (isUrdu ? 'باردانہ جاری کریں' : 'Issue Bardana')
                            : (isUrdu ? 'واپسی درج کریں' : 'Record Return'),
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
