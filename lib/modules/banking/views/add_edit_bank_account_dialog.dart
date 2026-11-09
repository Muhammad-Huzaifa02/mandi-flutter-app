import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/bank_account_model.dart';
import 'package:mandi/modules/banking/providers/bank_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Modal dialog for adding or editing a Bank Account.
class AddEditBankAccountDialog extends StatefulWidget {
  final BankAccount? existingAccount;

  const AddEditBankAccountDialog({super.key, this.existingAccount});

  @override
  State<AddEditBankAccountDialog> createState() =>
      _AddEditBankAccountDialogState();
}

class _AddEditBankAccountDialogState extends State<AddEditBankAccountDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedBank;
  late TextEditingController _customBankCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _accountNoCtrl;
  late TextEditingController _ibanCtrl;
  late TextEditingController _branchNameCtrl;
  late TextEditingController _branchCodeCtrl;
  late TextEditingController _openingBalCtrl;
  bool _isDefault = false;
  bool _isActive = true;
  bool _isSaving = false;

  static const List<String> _popularBanks = [
    'Meezan Bank',
    'Habib Bank Limited (HBL)',
    'MCB Bank',
    'Allied Bank Limited (ABL)',
    'United Bank Limited (UBL)',
    'Bank of Punjab (BOP)',
    'Bank Alfalah',
    'Askari Bank',
    'Faysal Bank',
    'Soneri Bank',
    'National Bank of Pakistan (NBP)',
    'Raast / Digital Wallet',
    'JazzCash',
    'EasyPaisa',
    'Other Bank...',
  ];

  @override
  void initState() {
    super.initState();
    final acc = widget.existingAccount;
    if (acc != null) {
      if (_popularBanks.contains(acc.bankName)) {
        _selectedBank = acc.bankName;
        _customBankCtrl = TextEditingController();
      } else {
        _selectedBank = 'Other Bank...';
        _customBankCtrl = TextEditingController(text: acc.bankName);
      }
      _titleCtrl = TextEditingController(text: acc.accountTitle);
      _accountNoCtrl = TextEditingController(text: acc.accountNumber);
      _ibanCtrl = TextEditingController(text: acc.iban);
      _branchNameCtrl = TextEditingController(text: acc.branchName);
      _branchCodeCtrl = TextEditingController(text: acc.branchCode);
      _openingBalCtrl =
          TextEditingController(text: acc.openingBalance.toStringAsFixed(0));
      _isDefault = acc.isDefault;
      _isActive = acc.isActive;
    } else {
      _selectedBank = _popularBanks.first;
      _customBankCtrl = TextEditingController();
      _titleCtrl = TextEditingController();
      _accountNoCtrl = TextEditingController();
      _ibanCtrl = TextEditingController();
      _branchNameCtrl = TextEditingController();
      _branchCodeCtrl = TextEditingController();
      _openingBalCtrl = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _customBankCtrl.dispose();
    _titleCtrl.dispose();
    _accountNoCtrl.dispose();
    _ibanCtrl.dispose();
    _branchNameCtrl.dispose();
    _branchCodeCtrl.dispose();
    _openingBalCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final shopId = context.read<ShopContextProvider>().currentShopId;
      if (shopId == null) {
        throw Exception('No active shop context selected.');
      }

      final bankName = _selectedBank == 'Other Bank...'
          ? _customBankCtrl.text.trim()
          : _selectedBank;

      final opening = double.tryParse(_openingBalCtrl.text.trim()) ?? 0.0;

      final acc = BankAccount(
        id: widget.existingAccount?.id ?? '',
        shopId: shopId,
        bankName: bankName,
        accountTitle: _titleCtrl.text.trim(),
        accountNumber: _accountNoCtrl.text.trim(),
        iban: _ibanCtrl.text.trim().toUpperCase(),
        branchName: _branchNameCtrl.text.trim(),
        branchCode: _branchCodeCtrl.text.trim(),
        openingBalance: opening,
        currentBalance: widget.existingAccount == null
            ? opening
            : widget.existingAccount!.currentBalance,
        isDefault: _isDefault,
        isActive: _isActive,
      );

      final bankProv = context.read<BankProvider>();
      if (widget.existingAccount == null) {
        await bankProv.addBankAccount(acc);
      } else {
        await bankProv.updateBankAccount(acc);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingAccount == null
                  ? 'Bank account added successfully.'
                  : 'Bank account updated.',
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
            content: Text('Error saving bank account: $e'),
            backgroundColor: MColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAccount != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: MRadius.lg),
      child: Container(
        width: 500,
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
                        const Icon(
                          Icons.account_balance,
                          color: MColors.primaryLight,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEdit
                              ? 'Edit Bank Account'
                              : 'Add Bank Account (بینک اکاؤنٹ)',
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
                const Divider(height: 24),

                // Bank Selection
                Text(
                  'Bank / Wallet Name (بینک کا نام)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBank,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: _popularBanks.map((b) {
                    return DropdownMenuItem(value: b, child: Text(b));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedBank = v);
                  },
                ),
                if (_selectedBank == 'Other Bank...') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customBankCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Enter Bank Name *',
                      prefixIcon: Icon(Icons.edit),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter bank name'
                        : null,
                  ),
                ],
                const SizedBox(height: 14),

                // Account Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Title (کھاتہ دار کا نام) *',
                    hintText: 'e.g. Haji Commission Shop',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter account title'
                      : null,
                ),
                const SizedBox(height: 14),

                // Account Number
                TextFormField(
                  controller: _accountNoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Number (اکاؤنٹ نمبر) *',
                    hintText: 'e.g. 010203040506',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter account number'
                      : null,
                ),
                const SizedBox(height: 14),

                // IBAN
                TextFormField(
                  controller: _ibanCtrl,
                  decoration: const InputDecoration(
                    labelText: 'IBAN (24 digits)',
                    hintText: 'PK36MEZN0001020304050601',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 14),

                // Branch Name & Branch Code
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _branchNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Branch Name',
                          hintText: 'e.g. Grain Market',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _branchCodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Code',
                          hintText: 'e.g. 0123',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (!isEdit) ...[
                  // Opening Balance
                  TextFormField(
                    controller: _openingBalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Opening Balance (PKR / ابتدائی رقم)',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                ],

                // Default Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as Default Shop Account'),
                  subtitle: const Text(
                    'Used for quick online transfers & payment reminders',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isDefault,
                  activeThumbColor: MColors.primary,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
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
                        isEdit ? 'Update Account' : 'Save Account',
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
