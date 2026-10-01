import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class ShopSettingsPage extends StatefulWidget {
  const ShopSettingsPage({super.key});

  @override
  State<ShopSettingsPage> createState() => _ShopSettingsPageState();
}

class _ShopSettingsPageState extends State<ShopSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _logoUrl;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _commission;
  late final TextEditingController _invoicePrefix;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final shop = context.read<ShopContextProvider>().currentShop;
    _name = TextEditingController(text: shop?.name ?? '');
    _logoUrl = TextEditingController(text: shop?.logoUrl ?? '');
    _phone = TextEditingController(text: shop?.phone ?? '');
    _whatsapp = TextEditingController(text: shop?.whatsapp ?? '');
    _email = TextEditingController(text: shop?.email ?? '');
    _address = TextEditingController(text: shop?.address ?? '');
    _city = TextEditingController(text: shop?.city ?? '');
    _commission = TextEditingController(
        text: shop?.defaultCommissionPercent.toStringAsFixed(1) ?? '5.0');
    _invoicePrefix = TextEditingController(text: shop?.invoicePrefix ?? 'INV');
  }

  @override
  void dispose() {
    _name.dispose();
    _logoUrl.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _commission.dispose();
    _invoicePrefix.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final shopCtx = context.read<ShopContextProvider>();
    final shopId = shopCtx.currentShopId!;
    setState(() => _saving = true);

    try {
      final updateData = {
        'name': _name.text.trim(),
        'logo_url': _logoUrl.text.trim(),
        'phone': _phone.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'default_commission_percent':
            double.tryParse(_commission.text.trim()) ?? 0,
        'invoice_prefix': _invoicePrefix.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.updateShop(shopId, updateData);
      await shopCtx.refreshShop();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop settings updated.')),
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
      appBar: AppBar(title: const Text('Shop Settings')),
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
                  labelText: 'Shop Name *',
                  hintText: 'e.g. Al-Madina Commission Shop',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _logoUrl,
                decoration: const InputDecoration(
                  labelText: 'Shop Logo URL',
                  hintText: 'https://example.com/logo.png',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        hintText: 'e.g. 03001234567',
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _whatsapp,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp',
                        hintText: 'e.g. 03001234567',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Shop Email',
                  hintText: 'e.g. shop@example.com',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(
                        labelText: 'Mandi City',
                        hintText: 'e.g. Multan',
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Shop #4, Grain Market',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpacing.lg),
              const Text('Mandi Invoicing Defaults', style: MText.titleLg),
              const SizedBox(height: MSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _commission,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Default Commission %',
                        suffixText: '%',
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _invoicePrefix,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Prefix',
                        hintText: 'e.g. INV',
                      ),
                    ),
                  ),
                ],
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
                    : const Text('Save Shop Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
