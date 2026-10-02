import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/models/purchase_order_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/purchase_orders/providers/purchase_order_provider.dart';

class AddPurchaseOrderPage extends StatefulWidget {
  const AddPurchaseOrderPage({super.key});

  @override
  State<AddPurchaseOrderPage> createState() => _AddPurchaseOrderPageState();
}

class _AddPurchaseOrderPageState extends State<AddPurchaseOrderPage> {
  final _formKey = GlobalKey<FormState>();
  Supplier? _selectedSupplier;

  final _totalCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController(text: '0');
  String _status = 'received'; // 'pending' | 'received' | 'cancelled'
  bool _saving = false;

  @override
  void dispose() {
    _totalCtrl.dispose();
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    final provider = context.read<PurchaseOrderProvider>();
    setState(() => _saving = true);

    try {
      final total = double.parse(_totalCtrl.text.trim());
      final paid = double.tryParse(_paidAmountCtrl.text.trim()) ?? 0;

      final po = PurchaseOrder(
        id: '',
        shopId: shopId,
        supplierId: _selectedSupplier?.id,
        supplierName: _selectedSupplier?.name ?? 'Direct Supplier',
        total: total,
        paidAmount: paid,
        status: _status,
      );

      await provider.addPurchaseOrder(po);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase order recorded.')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Record Purchase Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Supplier>(
                initialValue: _selectedSupplier,
                decoration: const InputDecoration(labelText: 'Supplier'),
                hint: const Text('Select Supplier (Optional)'),
                items: suppliers
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.name} (${s.phone})'),
                        ))
                    .toList(),
                onChanged: (s) => setState(() => _selectedSupplier = s),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _totalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Total Purchase Amount (PKR) *',
                  hintText: 'e.g. 50000',
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
                controller: _paidAmountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Paid Amount (PKR)',
                  hintText: 'e.g. 20000',
                  suffixText: 'PKR',
                ),
              ),
              const SizedBox(height: MSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Order Status'),
                items: const [
                  DropdownMenuItem(value: 'received', child: Text('Received')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending Delivery')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
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
                    : const Text('Save Purchase Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
