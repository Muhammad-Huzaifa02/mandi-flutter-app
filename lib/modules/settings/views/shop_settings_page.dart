import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/theme/locale_provider.dart';
import 'package:mandi/core/theme/theme_provider.dart';
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
  bool _uploadingLogo = false;

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

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || !mounted) return;

    final shopCtx = context.read<ShopContextProvider>();
    final shopId = shopCtx.currentShopId;
    if (shopId == null) return;

    setState(() => _uploadingLogo = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final publicUrl = await SupabaseService.uploadShopLogo(
        shopId: shopId,
        bytes: bytes,
        fileName: pickedFile.name,
      );

      setState(() {
        _logoUrl.text = publicUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop logo uploaded successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to upload logo: $e'),
            backgroundColor: MColors.danger),
      );
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
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
              // Logo Avatar Picker
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: MColors.primary.withValues(alpha: 0.1),
                      backgroundImage: _logoUrl.text.isNotEmpty
                          ? NetworkImage(_logoUrl.text)
                          : null,
                      child: _logoUrl.text.isEmpty
                          ? const Icon(Icons.storefront_outlined,
                              size: 40, color: MColors.primary)
                          : null,
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: MColors.primary,
                        padding: const EdgeInsets.all(8),
                      ),
                      icon: _uploadingLogo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                      tooltip: 'Upload Logo from Gallery',
                      onPressed: _uploadingLogo ? null : _pickAndUploadLogo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MSpacing.xs),
              Center(
                child: TextButton.icon(
                  onPressed: _uploadingLogo ? null : _pickAndUploadLogo,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Change Shop Logo Image'),
                ),
              ),

              const SizedBox(height: MSpacing.md),

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
              const SizedBox(height: MSpacing.lg),
              const Text('Shop Brand Color Theme', style: MText.titleLg),
              const SizedBox(height: MSpacing.sm),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return Wrap(
                    spacing: MSpacing.sm,
                    runSpacing: MSpacing.sm,
                    children: AppTheme.brandColorOptions.map((opt) {
                      final name = opt['name'] as String;
                      final color = opt['color'] as Color;
                      final isSelected = themeProvider.primaryBrandColor == color;

                      return ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: color,
                          radius: 10,
                        ),
                        label: Text(name),
                        selected: isSelected,
                        onSelected: (_) {
                          themeProvider.setBrandColor(color);
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: MSpacing.lg),
              const Text('Text & Font Size Adjustment', style: MText.titleLg),
              const SizedBox(height: MSpacing.sm),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 0.85, label: Text('Small')),
                      ButtonSegment(value: 1.0, label: Text('Normal')),
                      ButtonSegment(value: 1.15, label: Text('Large')),
                      ButtonSegment(value: 1.30, label: Text('XL')),
                    ],
                    selected: {themeProvider.fontScale},
                    onSelectionChanged: (set) {
                      themeProvider.setFontScale(set.first);
                    },
                  );
                },
              ),

              const SizedBox(height: MSpacing.lg),
              const Text('App Language (زبان)', style: MText.titleLg),
              const SizedBox(height: MSpacing.sm),
              Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) {
                  return SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'en',
                        label: Text('English'),
                        icon: Icon(Icons.language),
                      ),
                      ButtonSegment(
                        value: 'ur',
                        label: Text('اردو (Urdu)'),
                        icon: Icon(Icons.translate),
                      ),
                    ],
                    selected: {localeProvider.isUrdu ? 'ur' : 'en'},
                    onSelectionChanged: (set) {
                      localeProvider.setLocale(Locale(set.first));
                    },
                  );
                },
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
