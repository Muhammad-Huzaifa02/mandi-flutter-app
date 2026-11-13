import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
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
  final Customer? initialCustomer;
  final Supplier? initialSupplier;
  final String? initialPartyType; // 'customer' or 'supplier'

  const AddPaymentPage({
    super.key,
    this.initialCustomer,
    this.initialSupplier,
    this.initialPartyType,
  });

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  late String _partyType;
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;

  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _partyType = widget.initialPartyType ??
        (widget.initialSupplier != null ? 'supplier' : 'customer');
    _selectedCustomer = widget.initialCustomer;
    _selectedSupplier = widget.initialSupplier;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isUrdu = AppStrings.isUrdu(context);
    final partyId = _partyType == 'customer'
        ? _selectedCustomer?.id
        : _selectedSupplier?.id;

    if (partyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? (_partyType == 'customer'
                    ? 'براہ کرم گاہک منتخب کریں۔'
                    : 'براہ کرم زمیندار منتخب کریں۔')
                : 'Please select a ${_partyType == "customer" ? "customer" : "farmer"}.',
          ),
        ),
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
        SnackBar(
          content: Text(
            isUrdu
                ? (_partyType == 'customer'
                    ? 'گاہک کی وصولی درج ہو گئی۔'
                    : 'زمیندار کی ادائیگی درج ہو گئی۔')
                : (_partyType == 'customer'
                    ? 'Customer receipt recorded.'
                    : 'Farmer payment recorded.'),
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
    final customers = context.watch<CustomerProvider>().customers;
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final isLockedParty = widget.initialPartyType != null ||
        widget.initialCustomer != null ||
        widget.initialSupplier != null;

    final appBarTitle = _partyType == 'customer'
        ? AppStrings.val(
            context,
            en: 'Record Customer Receipt',
            ur: 'گاہک کی وصولی درج کریں',
          )
        : AppStrings.val(
            context,
            en: 'Record Farmer Payment',
            ur: 'زمیندار کی ادائیگی درج کریں',
          );

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Party Type Selector
              if (!isLockedParty) ...[
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'customer',
                      label: Text(AppStrings.val(
                        context,
                        en: 'Customer Receipt',
                        ur: 'گاہک کی وصولی',
                      )),
                      icon: const Icon(Icons.download_outlined),
                    ),
                    ButtonSegment(
                      value: 'supplier',
                      label: Text(AppStrings.val(
                        context,
                        en: 'Farmer Payment',
                        ur: 'زمیندار کی ادائیگی',
                      )),
                      icon: const Icon(Icons.upload_outlined),
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
              ],

              if (_partyType == 'customer')
                DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(
                      context,
                      en: 'Select Customer *',
                      ur: 'گاہک منتخب کریں *',
                    ),
                  ),
                  items: customers
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.name} (${AppStrings.val(context, en: "Balance: Rs.", ur: "بقایا: روپے")} ${c.runningBalance.toStringAsFixed(0)})',
                            ),
                          ))
                      .toList(),
                  onChanged: (c) => setState(() => _selectedCustomer = c),
                  validator: (v) => v == null
                      ? AppStrings.val(
                          context,
                          en: 'Please select a customer',
                          ur: 'براہ کرم گاہک منتخب کریں',
                        )
                      : null,
                )
              else
                DropdownButtonFormField<Supplier>(
                  initialValue: _selectedSupplier,
                  decoration: InputDecoration(
                    labelText: AppStrings.val(
                      context,
                      en: 'Select Farmer *',
                      ur: 'زمیندار منتخب کریں *',
                    ),
                  ),
                  items: suppliers
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              '${s.name} (${AppStrings.val(context, en: "Payable: Rs.", ur: "واجب الادا: روپے")} ${s.runningBalance.toStringAsFixed(0)})',
                            ),
                          ))
                      .toList(),
                  onChanged: (s) => setState(() => _selectedSupplier = s),
                  validator: (v) => v == null
                      ? AppStrings.val(
                          context,
                          en: 'Please select a farmer',
                          ur: 'براہ کرم زمیندار منتخب کریں',
                        )
                      : null,
                ),

              const SizedBox(height: MSpacing.md),

              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Payment Amount (PKR) *',
                    ur: 'ادائیگی کی رقم (روپے) *',
                  ),
                  hintText: 'e.g. 10000',
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

              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Payment Method',
                    ur: 'ادائیگی کا ذریعہ',
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'cash',
                    child: Text(AppStrings.val(context, en: 'Cash', ur: 'نقد کیش')),
                  ),
                  DropdownMenuItem(
                    value: 'bank',
                    child: Text(AppStrings.val(context, en: 'Bank Transfer', ur: 'بینک ٹرانسفر')),
                  ),
                  const DropdownMenuItem(value: 'jazzCash', child: Text('JazzCash')),
                  const DropdownMenuItem(value: 'easypaisa', child: Text('Easypaisa')),
                ],
                onChanged: (m) {
                  if (m != null) setState(() => _method = m);
                },
              ),

              const SizedBox(height: MSpacing.md),

              TextFormField(
                controller: _referenceCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.val(
                    context,
                    en: 'Reference / Voucher #',
                    ur: 'حوالہ / واؤچر نمبر',
                  ),
                  hintText: AppStrings.val(
                    context,
                    en: 'e.g. Cheque #40129 / Transaction ID',
                    ur: 'مثلاً چیک نمبر 40129 / ٹرانزیکشن آئی ڈی',
                  ),
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
                        ? AppStrings.val(context, en: 'Record Receipt', ur: 'وصولی محفوظ کریں')
                        : AppStrings.val(context, en: 'Record Payment', ur: 'ادائیگی محفوظ کریں')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
