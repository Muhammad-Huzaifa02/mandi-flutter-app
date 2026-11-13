import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/data/models/farmer_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';

class AddEditFarmerProductPage extends StatefulWidget {
  final Farmer farmer;
  Farmer get supplier => farmer;
  final Product? product;

  AddEditFarmerProductPage({
    super.key,
    Farmer? farmer,
    Farmer? supplier,
    this.product,
  }) : farmer = (farmer ?? supplier)!;

  @override
  State<AddEditFarmerProductPage> createState() =>
      _AddEditFarmerProductPageState();
}

class _AddEditFarmerProductPageState
    extends State<AddEditFarmerProductPage> {
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
    final isUrdu = AppStrings.isUrdu(context);
    if (!_formKey.currentState!.validate()) return;

    final shopId = context.read<ShopContextProvider>().currentShopId;
    if (shopId == null) return;

    setState(() => _saving = true);

    try {
      final prov = context.read<ProductProvider>();
      final name = _name.text.trim();
      final category = _category.text.trim();
      final price = double.tryParse(_price.text.trim()) ?? 0;
      final stock = double.tryParse(_stock.text.trim()) ?? 0;
      final desc = _description.text.trim();

      if (widget.product == null) {
        final newProduct = Product(
          id: '',
          shopId: shopId,
          name: name,
          category: category.isNotEmpty ? category : 'Grains',
          sellingPrice: price,
          currentStock: stock,
          description: desc,
        );
        await prov.addProduct(newProduct);
      } else {
        final updatedProduct = widget.product!.copyWith(
          name: name,
          category: category.isNotEmpty ? category : 'Grains',
          sellingPrice: price,
          currentStock: stock,
          description: desc,
        );
        await prov.updateProduct(updatedProduct);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? (isUrdu ? 'فصل منڈی کیٹلاگ میں شامل ہو گئی۔' : 'Crop added to mandi catalog.')
                : (isUrdu ? 'فصل کی تفصیلات اپ ڈیٹ ہو گئیں۔' : 'Crop details updated.'),
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
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? (isUrdu ? 'فصل میں ترمیم کریں' : 'Edit Crop')
              : (isUrdu ? 'فصل پیش کریں' : 'Offer Crop'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isUrdu
                    ? 'زمیندار: ${widget.supplier.name}'
                    : 'Farmer: ${widget.supplier.name}',
                style: MText.titleMd.copyWith(color: MColors.primary),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'فصل / جنس کا نام *' : 'Crop Name *',
                  hintText: isUrdu ? 'مثلاً گندم، باسمتی 1121، کپاس' : 'e.g. Wheat Super, Basmati 1121, Cotton',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? (isUrdu ? 'لازمی ہے' : 'Required') : null,
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _category,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'زمرہ' : 'Category',
                  hintText: isUrdu ? 'مثلاً اناج، تلہن، دالیں' : 'e.g. Grains, Oilseeds, Pulses',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isUrdu ? 'متوقع قیمت فی من' : 'Expected Price per Maund',
                  hintText: isUrdu ? 'مثلاً 3800' : 'e.g. 3800',
                  suffixText: isUrdu ? 'روپے' : 'PKR',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return double.tryParse(v.trim()) == null
                      ? (isUrdu ? 'درست نمبر درج کریں' : 'Enter a valid number')
                      : null;
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _stock,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isUrdu ? 'متوقع مقدار / بوریاں' : 'Estimated Quantity / Bags',
                  hintText: isUrdu ? 'مثلاً 100' : 'e.g. 100',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return double.tryParse(v.trim()) == null
                      ? (isUrdu ? 'درست نمبر درج کریں' : 'Enter a valid number')
                      : null;
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'فصل کی حالت و تفصیل' : 'Crop Condition & Notes',
                  hintText: isUrdu ? 'مثلاً نمی 12 فیصد، صاف ستھری گندم' : 'e.g. Moisture 12%, clean wheat from Khanewal farm',
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
                    : Text(
                        isEditing
                            ? (isUrdu ? 'تبدیلیاں محفوظ کریں' : 'Save Changes')
                            : (isUrdu ? 'فصل کی پیشکش جمع کریں' : 'Submit Crop Offer'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Backward compatibility alias
typedef AddEditSupplierProductPage = AddEditFarmerProductPage;
