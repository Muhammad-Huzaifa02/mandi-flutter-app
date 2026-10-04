import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/models/payment_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
import 'package:mandi/modules/payments/providers/payment_provider.dart';

class AddPaymentPage extends StatefulWidget {
  const AddPaymentPage({super.key});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  String _partyType = 'customer'; // 'customer' or 'supplier'
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;

  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final partyId = _partyType == 'customer'
        ? _selectedCustomer?.id
        : _selectedSupplier?.id;

    if (partyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please select a $_partyType.')),
      );
      return;
    }

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    final provider = context.read<PaymentProvider>();
    setState(() => _saving = true);

    try {
      String validPartyId = partyId;
      if (_partyType == 'customer' && _selectedCustomer != null) {
        validPartyId = await SupabaseService.ensureCustomerRow(
          shopId: shopId,
          customerId: _selectedCustomer!.id,
          userId: _selectedCustomer!.userId,
          name: _selectedCustomer!.name,
          phone: _selectedCustomer!.phone,
          email: _selectedCustomer!.email,
        );
      } else if (_partyType == 'supplier' && _selectedSupplier != null) {
        validPartyId = await SupabaseService.ensureSupplierRow(
          shopId: shopId,
          supplierId: _selectedSupplier!.id,
          userId: _selectedSupplier!.userId,
          name: _selectedSupplier!.name,
          phone: _selectedSupplier!.phone,
          email: _selectedSupplier!.email,
        );
      }

      final payment = Payment(
        id: '',
        shopId: shopId,
        partyType: _partyType,
        partyId: validPartyId,
        amount: double.parse(_amountCtrl.text.trim()),
        method: _method,
        reference: _referenceCtrl.text.trim(),
      );

      await provider.addPayment(payment);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment voucher recorded.')),
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
    final customers = context.watch<CustomerProvider>().customers;
    final suppliers = context.watch<SupplierProvider>().suppliers;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment Voucher')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Party Type Selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'customer',
                    label: Text('Customer Receipt'),
                    icon: Icon(Icons.download_outlined),
                  ),
                  ButtonSegment(
                    value: 'supplier',
                    label: Text('Supplier Payment'),
                    icon: Icon(Icons.upload_outlined),
                  ),
                ],
                selected: {_partyType},
                onSelectionChanged: (set) {
                  setState(() {
                    _partyType = set.first;
                    _selectedCustomer = null;
                    _selectedSupplier = null;
                  });
                },
              ),

              const SizedBox(height: MSpacing.lg),

              if (_partyType == 'customer')
                DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  decoration: const InputDecoration(labelText: 'Select Customer *'),
                  items: customers
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} (Balance: Rs. ${c.runningBalance.toStringAsFixed(0)})'),
                          ))
                      .toList(),
                  onChanged: (c) => setState(() => _selectedCustomer = c),
                  validator: (v) => v == null ? 'Please select a customer' : null,
                )
              else
                DropdownButtonFormField<Supplier>(
                  initialValue: _selectedSupplier,
                  decoration: const InputDecoration(labelText: 'Select Supplier *'),
                  items: suppliers
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.name} (Payable: Rs. ${s.runningBalance.toStringAsFixed(0)})'),
                          ))
                      .toList(),
                  onChanged: (s) => setState(() => _selectedSupplier = s),
                  validator: (v) => v == null ? 'Please select a supplier' : null,
                ),

              const SizedBox(height: MSpacing.md),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (PKR) *',
                  hintText: 'e.g. 10000',
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

              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'jazzCash', child: Text('JazzCash')),
                  DropdownMenuItem(value: 'easypaisa', child: Text('Easypaisa')),
                ],
                onChanged: (m) {
                  if (m != null) setState(() => _method = m);
                },
              ),

              const SizedBox(height: MSpacing.md),

              TextFormField(
                controller: _referenceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reference / Voucher #',
                  hintText: 'e.g. Cheque #40129 / Transaction ID',
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
                    : Text(_partyType == 'customer'
                        ? 'Record Receipt'
                        : 'Record Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
