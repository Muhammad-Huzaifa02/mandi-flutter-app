import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/expense_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/expenses/providers/expense_provider.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  ExpenseCategory _category = ExpenseCategory.labor;
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    final provider = context.read<ExpenseProvider>();
    setState(() => _saving = true);

    try {
      final expense = Expense(
        id: '',
        shopId: shopId,
        category: _category,
        amount: double.parse(_amount.text.trim()),
        reference: _reference.text.trim(),
        note: _note.text.trim(),
      );

      await provider.addExpense(expense);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense logged successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: MColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: ExpenseCategory.values
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 20, color: MColors.primary),
                              const SizedBox(width: MSpacing.sm),
                              Text(cat.displayName),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (cat) {
                  if (cat != null) setState(() => _category = cat);
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (PKR) *',
                  hintText: 'e.g. 1500',
                  suffixText: 'PKR',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Receipt / Reference #',
                  hintText: 'e.g. Voucher #102',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Details',
                  hintText: 'e.g. Unloading 50 bags of wheat',
                ),
              ),
              const SizedBox(height: MSpacing.xl),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
