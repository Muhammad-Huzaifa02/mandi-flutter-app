import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/cheque_model.dart';
import 'package:mandi/modules/banking/providers/bank_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Modal dialog to record a new Cheque or Post-Dated Cheque (PDC).
class AddEditChequeDialog extends StatefulWidget {
  final Cheque? existingCheque;
  final ChequeType defaultType;

  const AddEditChequeDialog({
    super.key,
    this.existingCheque,
    this.defaultType = ChequeType.received,
  });

  @override
  State<AddEditChequeDialog> createState() => _AddEditChequeDialogState();
}

class _AddEditChequeDialogState extends State<AddEditChequeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateFmt = DateFormat('dd/MM/yyyy');

  late ChequeType _type;
  late String _partyType; // 'customer', 'supplier', 'other'
  String? _partyId;
  late TextEditingController _partyNameCtrl;
  late TextEditingController _chequeNoCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;

  late DateTime _issueDate;
  late DateTime _dueDate;
  String? _targetBankAccountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existingCheque;
    if (c != null) {
      _type = c.type;
      _partyType = c.partyType;
      _partyId = c.partyId;
      _partyNameCtrl = TextEditingController(text: c.partyName);
      _chequeNoCtrl = TextEditingController(text: c.chequeNumber);
      _bankNameCtrl = TextEditingController(text: c.bankName);
      _amountCtrl =
          TextEditingController(text: c.amount.toStringAsFixed(0));
      _notesCtrl = TextEditingController(text: c.notes);
      _issueDate = c.issueDate;
      _dueDate = c.dueDate;
      _targetBankAccountId = c.targetBankAccountId;
    } else {
      _type = widget.defaultType;
      _partyType = widget.defaultType == ChequeType.received ? 'customer' : 'supplier';
      _partyNameCtrl = TextEditingController();
      _chequeNoCtrl = TextEditingController();
      _bankNameCtrl = TextEditingController();
      _amountCtrl = TextEditingController();
      _notesCtrl = TextEditingController();
      _issueDate = DateTime.now();
      _dueDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _partyNameCtrl.dispose();
    _chequeNoCtrl.dispose();
    _bankNameCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isPdc {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(_dueDate.year, _dueDate.month, _dueDate.day);
    return due.isAfter(today);
  }

  Future<void> _pickDate({required bool isDueDate}) async {
    final initial = isDueDate ? _dueDate : _issueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _issueDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final shopId = context.read<ShopContextProvider>().currentShopId;
      if (shopId == null) {
        throw Exception('No active shop context selected.');
      }

      final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
      if (amt <= 0) {
        throw Exception('Amount must be greater than zero.');
      }

      final cheque = Cheque(
        id: widget.existingCheque?.id ?? '',
        shopId: shopId,
        chequeNumber: _chequeNoCtrl.text.trim(),
        type: _type,
        partyType: _partyType,
        partyId: _partyId,
        partyName: _partyNameCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        targetBankAccountId: _targetBankAccountId,
        amount: amt,
        issueDate: _issueDate,
        dueDate: _dueDate,
        status: widget.existingCheque?.status ?? ChequeStatus.inHand,
        notes: _notesCtrl.text.trim(),
      );

      final bankProv = context.read<BankProvider>();
      if (widget.existingCheque == null) {
        await bankProv.addCheque(cheque);
      } else {
        await bankProv.updateCheque(cheque);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cheque saved successfully in Cheque Register.',
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
            content: Text('Error saving cheque: $e'),
            backgroundColor: MColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingCheque != null;
    final customers = context.watch<CustomerProvider>().customers;
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final bankAccounts = context.watch<BankProvider>().bankAccounts;

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
                          Icons.request_quote_outlined,
                          color: _type == ChequeType.received
                              ? MColors.primary
                              : MColors.gold,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEdit
                              ? 'Edit Cheque Record'
                              : 'Record Cheque (چیک درج کریں)',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                const Divider(height: 20),

                // Cheque Type Segmented Toggle (Received vs Issued)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: MRadius.md,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: isEdit
                              ? null
                              : () => setState(() {
                                    _type = ChequeType.received;
                                    _partyType = 'customer';
                                    _partyId = null;
                                    _partyNameCtrl.clear();
                                  }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _type == ChequeType.received
                                  ? MColors.primary
                                  : Colors.transparent,
                              borderRadius: MRadius.sm,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Received / وصولی (From Buyer)',
                              style: TextStyle(
                                color: _type == ChequeType.received
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: isEdit
                              ? null
                              : () => setState(() {
                                    _type = ChequeType.issued;
                                    _partyType = 'supplier';
                                    _partyId = null;
                                    _partyNameCtrl.clear();
                                  }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _type == ChequeType.issued
                                  ? MColors.gold
                                  : Colors.transparent,
                              borderRadius: MRadius.sm,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Issued / ادائیگی (To Farmer)',
                              style: TextStyle(
                                color: _type == ChequeType.issued
                                    ? Colors.black87
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Party Type Selection
                Row(
                  children: [
                    Text(
                      'Party Category: ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Customer (خریدار)'),
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
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Supplier (زمیندار)'),
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
                      label: const Text('Other'),
                      selected: _partyType == 'other',
                      onSelected: (v) {
                        if (v) {
                          setState(() {
                            _partyType = 'other';
                            _partyId = null;
                            _partyNameCtrl.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Party Picker / Input
                if (_partyType == 'customer' && customers.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _partyId,
                    decoration: const InputDecoration(
                      labelText: 'Select Customer (پارٹی کا نام) *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: customers.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.name} (${c.phone})'),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final found =
                            customers.firstWhere((c) => c.id == id);
                        setState(() {
                          _partyId = id;
                          _partyNameCtrl.text = found.name;
                        });
                      }
                    },
                    validator: (v) => _partyNameCtrl.text.trim().isEmpty
                        ? 'Please select or enter party name'
                        : null,
                  )
                else if (_partyType == 'supplier' && suppliers.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _partyId,
                    decoration: const InputDecoration(
                      labelText: 'Select Supplier / Farmer (زمیندار) *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: suppliers.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.name} (${s.phone})'),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final found =
                            suppliers.firstWhere((s) => s.id == id);
                        setState(() {
                          _partyId = id;
                          _partyNameCtrl.text = found.name;
                        });
                      }
                    },
                    validator: (v) => _partyNameCtrl.text.trim().isEmpty
                        ? 'Please select or enter party name'
                        : null,
                  )
                else
                  TextFormField(
                    controller: _partyNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Party / Drawer Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter party name'
                        : null,
                  ),
                const SizedBox(height: 14),

                // Cheque Number & Drawn Bank
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _chequeNoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cheque Number (چیک نمبر) *',
                          hintText: 'e.g. 786012',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _bankNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Drawn On Bank (بینک) *',
                          hintText: 'e.g. HBL / MCB',
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Amount (PKR)
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cheque Amount (رقم روپیہ) *',
                    hintText: 'e.g. 250000',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter amount';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Enter valid amount > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Issue Date & Due Date (PDC)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isDueDate: false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Issue Date',
                            prefixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(_dateFmt.format(_issueDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isDueDate: true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Due Date (PDC / تاریخ ادائیگی)',
                            prefixIcon:
                                const Icon(Icons.event_available, size: 18),
                            suffix: _isPdc
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: MColors.gold,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PDC',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          child: Text(_dateFmt.format(_dueDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Optional Target Bank Account
                if (bankAccounts.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: _targetBankAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Deposit In Bank Account (اختیاری)',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Not Deposited Yet (In Safe/Vault)'),
                      ),
                      ...bankAccounts.map((b) {
                        return DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(b.displayName),
                        );
                      }),
                    ],
                    onChanged: (id) =>
                        setState(() => _targetBankAccountId = id),
                  ),
                  const SizedBox(height: 14),
                ],

                // Notes / Reference
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Remarks (تفصیل)',
                    hintText: 'e.g. Received against Invoice #102',
                    prefixIcon: Icon(Icons.note_alt_outlined),
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
                      child: const Text('Cancel'),
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
                        isEdit ? 'Update Cheque' : 'Save Cheque',
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
