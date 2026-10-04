import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';

class AddEditSupplierProductPage extends StatefulWidget {
  final Supplier supplier;
  final Product? product;

  const AddEditSupplierProductPage({
    super.key,
    required this.supplier,
    this.product,
  });

  @override
  State<AddEditSupplierProductPage> createState() =>
      _AddEditSupplierProductPageState();
}

class _AddEditSupplierProductPageState
    extends State<AddEditSupplierProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _description;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _category = TextEditingController(text: p?.category ?? 'Grains');
    _price = TextEditingController(
        text: p != null ? p.sellingPrice.toStringAsFixed(0) : '');
    _stock = TextEditingController(
        text: p != null ? p.currentStock.toStringAsFixed(0) : '');
    _description = TextEditingController(text: p?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    final provider = context.read<ProductProvider>();
    setState(() => _saving = true);

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        shopId: shopId,
        supplierId: widget.supplier.id,
        supplierName: widget.supplier.name,
        name: _name.text.trim(),
        category: _category.text.trim(),
        sellingPrice: double.parse(_price.text.trim()),
        currentStock: double.tryParse(_stock.text.trim()) ?? 0,
        description: _description.text.trim(),
      );

      if (widget.product != null) {
        await provider.updateProduct(product);
      } else {
        await provider.addProduct(product);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product != null
              ? 'Product updated.'
              : 'Product listed for sale to shop.'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null
            ? 'Edit My Product'
            : 'Offer Product for Sale'),
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
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Organic Wheat Harvest 2024',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: MSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Rate / 40 KG (Maund) *',
                        hintText: 'e.g. 4200',
                        suffixText: 'PKR',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final p = double.tryParse(v.trim());
                        if (p == null || p <= 0) return 'Invalid rate';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Available Supply (KG)',
                        hintText: 'e.g. 1000',
                        suffixText: 'KG',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description / Harvest Notes',
                  hintText: 'Quality details, bag condition, etc.',
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
                            strokeWidth: 2, color: Colors.white))
                    : Text(widget.product != null
                        ? 'Save Changes'
                        : 'Offer Product to Shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
