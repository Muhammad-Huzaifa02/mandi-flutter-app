import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/data/models/purchase_order_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';
import 'package:mandi/modules/purchase_orders/providers/purchase_order_provider.dart';

class AddPurchaseOrderPage extends StatefulWidget {
  const AddPurchaseOrderPage({super.key});

  @override
  State<AddPurchaseOrderPage> createState() => _AddPurchaseOrderPageState();
}

class _AddPurchaseOrderPageState extends State<AddPurchaseOrderPage> {
  final _formKey = GlobalKey<FormState>();
  Supplier? _selectedSupplier;
  Product? _selectedProduct;

  final _weightCtrl = TextEditingController();
  final _ratePer40kgCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController(text: '0');
  String _status = 'received'; // 'pending' | 'received' | 'cancelled'
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _ratePer40kgCtrl.dispose();
    _totalCtrl.dispose();
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final r = double.tryParse(_ratePer40kgCtrl.text.trim()) ?? 0;
    if (w > 0 && r > 0) {
      final calcTotal = (w / 40.0) * r;
      _totalCtrl.text = calcTotal.toStringAsFixed(0);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isUrdu = AppStrings.isUrdu(context);
    final shopId = context.read<ShopContextProvider>().currentShopId!;
    final provider = context.read<PurchaseOrderProvider>();
    setState(() => _saving = true);

    try {
      final total = double.parse(_totalCtrl.text.trim());
      final paid = double.tryParse(_paidAmountCtrl.text.trim()) ?? 0;
      final w = double.tryParse(_weightCtrl.text.trim()) ?? 0;
      final r = double.tryParse(_ratePer40kgCtrl.text.trim()) ?? 0;

      String? validSupplierId;
      if (_selectedSupplier != null) {
        validSupplierId = await SupabaseService.ensureSupplierRow(
          shopId: shopId,
          supplierId: _selectedSupplier!.id,
          userId: _selectedSupplier!.userId,
          name: _selectedSupplier!.name,
          phone: _selectedSupplier!.phone,
          email: _selectedSupplier!.email,
        );
      }

      final po = PurchaseOrder(
        id: '',
        shopId: shopId,
        supplierId: validSupplierId,
        supplierName: _selectedSupplier?.name ?? (isUrdu ? 'براہ راست زمیندار' : 'Direct Farmer'),
        total: total,
        paidAmount: paid,
        status: _status,
      );

      // Atomically records PO, increases stock, creates inventory txn, & updates running balance in PostgreSQL
      await provider.addPurchaseOrder(
        po,
        productId: _selectedProduct?.id,
        weightKg: w,
        ratePer40kg: r,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu
              ? 'خریداری آرڈر کامیابی سے محفوظ ہو گیا!'
              : 'Purchase order recorded & product stock updated atomically!'),
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
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final products = context.watch<ProductProvider>().products;
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final r = double.tryParse(_ratePer40kgCtrl.text.trim()) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.val(
          context,
          en: 'Record Purchase Order',
          ur: 'خریداری کا آرڈر درج کریں',
        )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Supplier>(
                initialValue: _selectedSupplier,
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Farmer',
                    ur: 'زمیندار',
                  ),
                ),
                hint: Text(AppStrings.val(
                  context,
                  en: 'Select Farmer (Optional)',
                  ur: 'زمیندار منتخب کریں (اختیاری)',
                )),
                items: suppliers
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.name} (${s.phone})'),
                        ))
                    .toList(),
                onChanged: (s) => setState(() => _selectedSupplier = s),
              ),
              const SizedBox(height: MSpacing.md),

              DropdownButtonFormField<Product>(
                initialValue: _selectedProduct,
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Product Purchased',
                    ur: 'خریدی گئی جنس / آئٹم',
                  ),
                ),
                hint: Text(AppStrings.val(
                  context,
                  en: 'Select Product',
                  ur: 'پروڈکٹ منتخب کریں',
                )),
                items: products
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} (${AppStrings.val(context, en: "Stock:", ur: "اسٹاک:")} ${p.currentStock} kg)',
                          ),
                        ))
                    .toList(),
                onChanged: (p) {
                  if (p != null) {
                    setState(() {
                      _selectedProduct = p;
                      if (p.purchasePrice > 0) {
                        _ratePer40kgCtrl.text =
                            p.purchasePrice.toStringAsFixed(0);
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: MSpacing.md),

              Text(
                AppStrings.val(
                  context,
                  en: 'Direct Purchase Calculation',
                  ur: 'خریداری کا حساب کتاب',
                ),
                style: MText.titleLg,
              ),
              const SizedBox(height: MSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        _calculateTotal();
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: AppStrings.val(
                          context,
                          en: 'Weight (KG)',
                          ur: 'وزن (کلو)',
                        ),
                        hintText: 'e.g. 200',
                        suffixText: AppStrings.val(
                          context,
                          en: 'KG',
                          ur: 'کلو',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _ratePer40kgCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        _calculateTotal();
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: AppStrings.val(
                          context,
                          en: 'Rate / 40 KG (Maund)',
                          ur: 'نرخ فی من (40 کلو)',
                        ),
                        hintText: 'e.g. 4000',
                        suffixText: AppStrings.val(
                          context,
                          en: 'PKR',
                          ur: 'روپے',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (w > 0 && r > 0) ...[
                const SizedBox(height: MSpacing.xs),
                Text(
                  '${(w / 40.0).toStringAsFixed(2)} ${AppStrings.val(context, en: "Maunds @ Rs.", ur: "من @ روپے")} ${r.toStringAsFixed(0)} / 40kg',
                  style: MText.bodySm.copyWith(color: MColors.textSecondary),
                ),
              ],

              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _totalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Total Purchase Amount (PKR) *',
                    ur: 'کل خریداری رقم (روپے) *',
                  ),
                  hintText: 'e.g. 50000',
                  suffixText: 'PKR',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppStrings.val(
                      context,
                      en: 'Required',
                      ur: 'ضروری ہے',
                    );
                  }
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) {
                    return AppStrings.val(
                      context,
                      en: 'Enter a valid amount',
                      ur: 'درست رقم درج کریں',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _paidAmountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Paid Amount (PKR)',
                    ur: 'ادا شدہ رقم (روپے)',
                  ),
                  hintText: 'e.g. 20000',
                  suffixText: 'PKR',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Order Status',
                    ur: 'آرڈر کی صورتحال',
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'received',
                    child: Text(AppStrings.val(
                      context,
                      en: 'Received',
                      ur: 'موصول شدہ',
                    )),
                  ),
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text(AppStrings.val(
                      context,
                      en: 'Pending Delivery',
                      ur: 'زیر التواء ترسیل',
                    )),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text(AppStrings.val(
                      context,
                      en: 'Cancelled',
                      ur: 'منسوخ',
                    )),
                  ),
                ],
                onChanged: (s) {
                  if (s != null) setState(() => _status = s);
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
                    : Text(AppStrings.val(
                        context,
                        en: 'Save Purchase Order',
                        ur: 'خریداری آرڈر محفوظ کریں',
                      )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
