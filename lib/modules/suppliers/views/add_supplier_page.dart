import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/data/services/employee_functions_service.dart';

class AddSupplierPage extends StatefulWidget {
  const AddSupplierPage({super.key});

  @override
  State<AddSupplierPage> createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _productsSupplied = TextEditingController();
  final _openingBalance = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _productsSupplied.dispose();
    _openingBalance.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    setState(() => _saving = true);

    try {
      final balance = double.tryParse(_openingBalance.text.trim());
      await AccountInviteService.inviteSupplier(
        shopId: shopId,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        productsSupplied: _productsSupplied.text.trim(),
        openingBalance: balance,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier added & invitation sent.')),
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
      appBar: AppBar(title: const Text('Add Supplier')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. Malik Traders / Seth Bilal',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'e.g. 03001234567',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'e.g. supplier@example.com',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return v.contains('@') ? null : 'Enter a valid email';
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _productsSupplied,
                decoration: const InputDecoration(
                  labelText: 'Products Supplied',
                  hintText: 'e.g. Wheat, Basmati Rice, Maize',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _openingBalance,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Opening Balance (PKR)',
                  hintText: '0 (positive = you owe them, negative = advance paid)',
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
                    : const Text('Add Supplier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
