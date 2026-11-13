import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/data/services/employee_functions_service.dart';

class AddFarmerPage extends StatefulWidget {
  const AddFarmerPage({super.key});

  @override
  State<AddFarmerPage> createState() => _AddFarmerPageState();
}

class _AddFarmerPageState extends State<AddFarmerPage> {
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
    final isUrdu = AppStrings.isUrdu(context);
    if (!_formKey.currentState!.validate()) return;

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    setState(() => _saving = true);

    try {
      final balance = double.tryParse(_openingBalance.text.trim());
      await AccountInviteService.inviteFarmer(
        shopId: shopId,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        productsSupplied: _productsSupplied.text.trim(),
        openingBalance: balance,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? 'زمیندار شامل کر لیا گیا اور دعوت نامہ بھیج دیا گیا۔'
                : 'Farmer added & invitation sent.',
          ),
        ),
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
    final isUrdu = AppStrings.isUrdu(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'نیا زمیندار شامل کریں' : 'Add Farmer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'زمیندار کا نام *' : 'Farmer Name *',
                  hintText: isUrdu ? 'مثلاً چوہدری اسلم / حاجی اکرم' : 'e.g. Seth Bilal / Chaudhry Aslam',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? (isUrdu ? 'لازمی ہے' : 'Required') : null,
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'فون نمبر *' : 'Phone Number *',
                  hintText: 'e.g. 03001234567',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? (isUrdu ? 'لازمی ہے' : 'Required') : null,
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'ای میل ایڈریس *' : 'Email Address *',
                  hintText: 'e.g. farmer@example.com',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return isUrdu ? 'لازمی ہے' : 'Required';
                  return v.contains('@') ? null : (isUrdu ? 'درست ای میل درج کریں' : 'Enter a valid email');
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _productsSupplied,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'فصلیں و جنس' : 'Crops / Produce',
                  hintText: isUrdu ? 'مثلاً گندم، دھان، کپاس، مکئی' : 'e.g. Wheat, Basmati Rice, Cotton, Maize',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _openingBalance,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: isUrdu ? 'ابتدائی بقایا رقم (روپے)' : 'Opening Balance (PKR)',
                  hintText: isUrdu
                      ? '0 (مثبت = واجب الادا، منفی = ایڈوانس پیشگی)'
                      : '0 (positive = you owe farmer, negative = advance paid)',
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
                    : Text(isUrdu ? 'زمیندار محفوظ کریں' : 'Add Farmer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Backward compatibility alias
typedef AddSupplierPage = AddFarmerPage;
