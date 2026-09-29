import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/products/providers/product_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  final List<InvoiceItem> _items = [];

  final _invoiceNumberCtrl = TextEditingController();
  final _commissionPercentCtrl = TextEditingController();
  final _expensesCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');
  final _receivedAmountCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final shop = context.read<ShopContextProvider>().currentShop;
    final defaultComm = shop?.defaultCommissionPercent ?? 0;
    _commissionPercentCtrl.text = defaultComm.toStringAsFixed(1);

    final prefix = shop?.invoicePrefix ?? 'INV';
    final invoices = context.read<InvoiceProvider>().invoices;
    final count = invoices.length + 1;
    final shopNext = shop?.invoiceNextNumber ?? 1;
    final nextNum = shopNext > count ? shopNext : count;
    _invoiceNumberCtrl.text = '$prefix-${nextNum.toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    _invoiceNumberCtrl.dispose();
    _commissionPercentCtrl.dispose();
    _expensesCtrl.dispose();
    _discountCtrl.dispose();
    _receivedAmountCtrl.dispose();
    super.dispose();
  }

  double get _productsSubtotal =>
      _items.fold(0, (sum, item) => sum + item.lineTotal);

  double get _commissionAmount {
    final percent = double.tryParse(_commissionPercentCtrl.text.trim()) ?? 0;
    return _productsSubtotal * (percent / 100.0);
  }

  double get _expensesAmount =>
      double.tryParse(_expensesCtrl.text.trim()) ?? 0;

  double get _discountAmount =>
      double.tryParse(_discountCtrl.text.trim()) ?? 0;

  double get _grandTotal =>
      _productsSubtotal + _commissionAmount + _expensesAmount - _discountAmount;

  double get _receivedAmount =>
      double.tryParse(_receivedAmountCtrl.text.trim()) ?? _grandTotal;

  double get _pendingAmount => _grandTotal - _receivedAmount;

  void _addItemDialog() {
    final products = context.read<ProductProvider>().products;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one product first.')),
      );
      return;
    }

    Product selectedProduct = products.first;
    final qtyCtrl = TextEditingController(text: '1');
    final weightKgCtrl = TextEditingController(text: '40');
    final pricePer40kgCtrl = TextEditingController(
        text: selectedProduct.sellingPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final qty = double.tryParse(qtyCtrl.text) ?? 1;
          final wKg = double.tryParse(weightKgCtrl.text) ?? 0;
          final ratePer40kg = double.tryParse(pricePer40kgCtrl.text) ?? 0;

          final manns = MandiCalculator.kgToMann(wKg);
          final lineTot = manns * ratePer40kg;

          return AlertDialog(
            title: const Text('Add Product Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: products
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text('${p.name} (Stock: ${p.currentStock}kg)'),
                            ))
                        .toList(),
                    onChanged: (p) {
                      if (p != null) {
                        setDialogState(() {
                          selectedProduct = p;
                          pricePer40kgCtrl.text =
                              p.sellingPrice.toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: MSpacing.md),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      final q = double.tryParse(v) ?? 1;
                      setDialogState(() {
                        weightKgCtrl.text = (q * selectedProduct.weightPerUnitKg)
                            .toStringAsFixed(0);
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Bags / Quantity',
                      hintText: 'e.g. 3',
                    ),
                  ),
                  const SizedBox(height: MSpacing.md),
                  TextField(
                    controller: weightKgCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Total Weight (KG) *',
                      suffixText: 'KG',
                    ),
                  ),
                  const SizedBox(height: MSpacing.md),
                  TextField(
                    controller: pricePer40kgCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Rate per 40 KG / Maund (PKR) *',
                      suffixText: 'PKR',
                    ),
                  ),
                  const SizedBox(height: MSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(MSpacing.md),
                    decoration: BoxDecoration(
                      color: MColors.primary.withOpacity(0.08),
                      borderRadius: MRadius.md,
                      border: Border.all(color: MColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mandi Math Breakdown:',
                            style: MText.labelMd),
                        const SizedBox(height: MSpacing.xs),
                        Text(
                          '1. Total Weight: ${wKg.toStringAsFixed(1)} KG',
                          style: MText.bodySm,
                        ),
                        Text(
                          '2. Weight in Mann: ${wKg.toStringAsFixed(1)} KG ÷ 40 = ${manns.toStringAsFixed(2)} Mann',
                          style: MText.bodySm,
                        ),
                        Text(
                          '3. Calculation: ${manns.toStringAsFixed(2)} Mann × Rs. ${ratePer40kg.toStringAsFixed(0)}',
                          style: MText.bodySm,
                        ),
                        const Divider(height: MSpacing.sm),
                        Text(
                          'Line Total: Rs. ${lineTot.toStringAsFixed(0)}',
                          style: MText.titleLg.copyWith(color: MColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (wKg <= 0) return;

                  setState(() {
                    _items.add(InvoiceItem(
                      productId: selectedProduct.id,
                      productName: selectedProduct.name,
                      quantity: qty,
                      weightKg: wKg,
                      unitPrice: ratePer40kg,
                      lineTotal: lineTot,
                    ));
                  });
                  Navigator.pop(dialogCtx);
                },
                child: const Text('Add Item'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item.')),
      );
      return;
    }

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    final provider = context.read<InvoiceProvider>();
    setState(() => _saving = true);

    try {
      final invoice = Invoice(
        id: '',
        shopId: shopId,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name ?? 'Walk-in Customer',
        invoiceNumber: _invoiceNumberCtrl.text.trim(),
        subtotal: _productsSubtotal,
        commission: _commissionAmount,
        expenses: _expensesAmount,
        discount: _discountAmount,
        total: _grandTotal,
        receivedAmount: _receivedAmount,
        pendingAmount: _pendingAmount,
        paymentMethod: _paymentMethod,
        status: _pendingAmount <= 0 ? 'paid' : (_receivedAmount > 0 ? 'partial' : 'unpaid'),
      );

      await provider.createInvoice(
        invoice: invoice,
        items: _items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created & stock updated.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final msg = raw.contains('23505') || raw.contains('duplicate')
          ? 'Invoice number "${_invoiceNumberCtrl.text}" already exists. Please use a unique invoice number.'
          : raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: MColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;

    return Scaffold(
      appBar: AppBar(title: const Text('New Sales Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Invoice Number & Customer Picker
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _invoiceNumberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number *',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpacing.md),
              DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'Customer (Optional / Walk-in)',
                ),
                hint: const Text('Select Customer'),
                items: customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} (${c.phone})'),
                        ))
                    .toList(),
                onChanged: (c) => setState(() => _selectedCustomer = c),
              ),

              const SizedBox(height: MSpacing.lg),

              // Items Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Invoice Items', style: MText.titleLg),
                  OutlinedButton.icon(
                    onPressed: _addItemDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: MSpacing.sm),

              // Line Items List
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(MSpacing.lg),
                  decoration: BoxDecoration(
                    color: MColors.surface,
                    borderRadius: MRadius.md,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      'No items added yet. Tap "Add Item" above.',
                      style: MText.bodyMd.copyWith(color: MColors.textSecondary),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: MSpacing.xs),
                      shape: RoundedRectangleBorder(
                        borderRadius: MRadius.md,
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(item.productName, style: MText.titleLg),
                        subtitle: Text(
                          '${item.weightKg} KG (${MandiCalculator.kgToMann(item.weightKg).toStringAsFixed(2)} Mann) @ Rs. ${item.unitPrice.toStringAsFixed(0)}/40kg',
                          style: MText.bodySm.copyWith(color: MColors.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rs. ${item.lineTotal.toStringAsFixed(0)}',
                              style: MText.titleLg.copyWith(color: MColors.primary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: MColors.danger, size: 20),
                              onPressed: () => setState(() => _items.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: MSpacing.lg),

              // Commission & Charges
              const Text('Commission & Charges', style: MText.titleLg),
              const SizedBox(height: MSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _commissionPercentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Commission %',
                        suffixText: '%',
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _expensesCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Labor / Transport',
                        suffixText: 'PKR',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Discount',
                        suffixText: 'PKR',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: MSpacing.lg),

              // Payment Section
              const Text('Payment Details', style: MText.titleLg),
              const SizedBox(height: MSpacing.sm),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: PaymentMethod.values
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.displayName),
                        ))
                    .toList(),
                onChanged: (m) {
                  if (m != null) setState(() => _paymentMethod = m);
                },
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _receivedAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Received Amount (PKR)',
                  hintText: _grandTotal.toStringAsFixed(0),
                  suffixText: 'PKR',
                ),
              ),

              const SizedBox(height: MSpacing.xl),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(MSpacing.lg),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: MRadius.lg,
                  border: Border.all(color: MColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                        label: 'Products Subtotal:',
                        value: 'Rs. ${_productsSubtotal.toStringAsFixed(0)}'),
                    _SummaryRow(
                        label: 'Mandi Commission:',
                        value: '+ Rs. ${_commissionAmount.toStringAsFixed(0)}'),
                    if (_expensesAmount > 0)
                      _SummaryRow(
                          label: 'Labor/Expenses:',
                          value: '+ Rs. ${_expensesAmount.toStringAsFixed(0)}'),
                    if (_discountAmount > 0)
                      _SummaryRow(
                          label: 'Discount:',
                          value: '- Rs. ${_discountAmount.toStringAsFixed(0)}'),
                    const Divider(height: MSpacing.md),
                    _SummaryRow(
                      label: 'Grand Total:',
                      value: 'Rs. ${_grandTotal.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                    _SummaryRow(
                      label: 'Received:',
                      value: 'Rs. ${_receivedAmount.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                    if (_pendingAmount > 0)
                      _SummaryRow(
                        label: 'Pending Balance:',
                        value: 'Rs. ${_pendingAmount.toStringAsFixed(0)}',
                        color: MColors.danger,
                        isBold: true,
                      ),
                  ],
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create & Save Invoice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? MText.titleLg.copyWith(color: color ?? MColors.textPrimary)
        : MText.bodyMd.copyWith(color: color ?? MColors.textPrimary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
