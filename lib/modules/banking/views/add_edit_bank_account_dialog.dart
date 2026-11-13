import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
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
        throw Exception(AppStrings.val(
          context,
          en: 'No active shop context selected.',
          ur: 'کوئی فعال دکان منتخب نہیں ہے۔',
        ));
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
        final successMsg = widget.existingAccount == null
            ? AppStrings.val(
                context,
                en: 'Bank account added successfully.',
                ur: 'بینک اکاؤنٹ کامیابی سے شامل ہو گیا۔',
              )
            : AppStrings.val(
                context,
                en: 'Bank account updated.',
                ur: 'بینک اکاؤنٹ اپ ڈیٹ ہو گیا۔',
              );
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: MColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.val(
              context,
              en: 'Error saving bank account: $e',
              ur: 'بینک اکاؤنٹ محفوظ کرنے میں خرابی: $e',
            )),
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
                              ? AppStrings.val(
                                  context,
                                  en: 'Edit Bank Account',
                                  ur: 'بینک اکاؤنٹ میں ترمیم',
                                )
                              : AppStrings.val(
                                  context,
                                  en: 'Add Bank Account',
                                  ur: 'بینک اکاؤنٹ شامل کریں',
                                ),
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
                  AppStrings.val(
                    context,
                    en: 'Bank / Wallet Name',
                    ur: 'بینک کا نام',
                  ),
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
                    decoration: InputDecoration(
                      labelText: AppStrings.val(
                        context,
                        en: 'Enter Bank Name *',
                        ur: 'بینک کا نام درج کریں *',
                      ),
                      prefixIcon: const Icon(Icons.edit),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? AppStrings.val(
                            context,
                            en: 'Please enter bank name',
                            ur: 'براہ کرم بینک کا نام درج کریں',
                          )
                        : null,
                  ),
                ],
                const SizedBox(height: 14),

                // Account Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(
                      context,
                      en: 'Account Title *',
                      ur: 'کھاتہ دار کا نام *',
                    ),
                    hintText: AppStrings.val(
                      context,
                      en: 'e.g. Haji Commission Shop',
                      ur: 'مثلاً حاجی کمیشن شاپ',
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? AppStrings.val(
                          context,
                          en: 'Please enter account title',
                          ur: 'براہ کرم کھاتہ دار کا نام درج کریں',
                        )
                      : null,
                ),
                const SizedBox(height: 14),

                // Account Number
                TextFormField(
                  controller: _accountNoCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(
                      context,
                      en: 'Account Number *',
                      ur: 'اکاؤنٹ نمبر *',
                    ),
                    hintText: 'e.g. 010203040506',
                    prefixIcon: const Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? AppStrings.val(
                          context,
                          en: 'Please enter account number',
                          ur: 'براہ کرم اکاؤنٹ نمبر درج کریں',
                        )
                      : null,
                ),
                const SizedBox(height: 14),

                // IBAN
                TextFormField(
                  controller: _ibanCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(
                      context,
                      en: 'IBAN (24 digits)',
                      ur: 'آئی بین (24 ہندسے)',
                    ),
                    hintText: 'PK36MEZN0001020304050601',
                    prefixIcon: const Icon(Icons.numbers),
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
                        decoration: InputDecoration(
                          labelText: AppStrings.val(
                            context,
                            en: 'Branch Name',
                            ur: 'برانچ کا نام',
                          ),
                          hintText: AppStrings.val(
                            context,
                            en: 'e.g. Grain Market',
                            ur: 'مثلاً غلہ منڈی',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _branchCodeCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.val(
                            context,
                            en: 'Branch Code',
                            ur: 'برانچ کوڈ',
                          ),
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
                    decoration: InputDecoration(
                      labelText: AppStrings.val(
                        context,
                        en: 'Opening Balance (PKR)',
                        ur: 'ابتدائی رقم (روپے)',
                      ),
                      prefixIcon:
                          const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                ],

                // Default Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.val(
                    context,
                    en: 'Set as Default Shop Account',
                    ur: 'دکان کا بنیادی اکاؤنٹ بنائیں',
                  )),
                  subtitle: Text(
                    AppStrings.val(
                      context,
                      en: 'Used for quick online transfers & payment reminders',
                      ur: 'آن لائن ٹرانسفر اور یاد دہانیوں کے لیے استعمال ہوگا',
                    ),
                    style: const TextStyle(fontSize: 12),
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
                      child: Text(AppStrings.val(
                        context,
                        en: 'Cancel',
                        ur: 'منسوخ',
                      )),
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
                        AppStrings.val(
                          context,
                          en: isEdit ? 'Update Account' : 'Save Account',
                          ur: isEdit ? 'اکاؤنٹ اپ ڈیٹ کریں' : 'اکاؤنٹ محفوظ کریں',
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
