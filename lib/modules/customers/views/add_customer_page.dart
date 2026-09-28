import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/data/services/employee_functions_service.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _openingBalance = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _openingBalance.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    setState(() => _saving = true);

    try {
      final balance = double.tryParse(_openingBalance.text.trim());
      await AccountInviteService.inviteCustomer(
        shopId: shopId,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        openingBalance: balance,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added & invitation sent.')),
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
      appBar: AppBar(title: const Text('Add Customer')),
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
                  hintText: 'e.g. Chaudhry Ahmad',
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
                  hintText: 'e.g. customer@example.com',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return v.contains('@') ? null : 'Enter a valid email';
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(
                  labelText: 'City / Mandi Location',
                  hintText: 'e.g. Multan',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g. Shop #12, Grain Market',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _openingBalance,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Opening Balance (PKR)',
                  hintText: '0 (positive = owes you, negative = advance)',
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
                    : const Text('Add Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
