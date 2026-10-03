import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/data/models/customer_model.dart';
import 'package:mandi/data/models/supplier_model.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';
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
  Supplier? _selectedSupplier;
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
      _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get _commissionPercent =>
      double.tryParse(_commissionPercentCtrl.text.trim()) ?? 0;

  double get _commissionAmount =>
      MandiCalculator.calculateCommissionAmount(_productsSubtotal, _commissionPercent);

  double get _expensesAmount =>
      double.tryParse(_expensesCtrl.text.trim()) ?? 0;

  double get _discountAmount =>
      double.tryParse(_discountCtrl.text.trim()) ?? 0;

  double get _grandTotal => MandiCalculator.calculateInvoiceTotal(
        subtotal: _productsSubtotal,
        commissionAmount: _commissionAmount,
        expensesAmount: _expensesAmount,
        discountAmount: _discountAmount,
      );

  double get _receivedAmount =>
      double.tryParse(_receivedAmountCtrl.text.trim()) ?? _grandTotal;

  double get _pendingAmount =>
      (_grandTotal - _receivedAmount) > 0 ? (_grandTotal - _receivedAmount) : 0;

  double get _netSupplierPayout =>
      (_productsSubtotal - _commissionAmount - _expensesAmount) > 0
          ? (_productsSubtotal - _commissionAmount - _expensesAmount)
          : 0;

  void _addItemDialog() {
    final products = context.read<ProductProvider>().products;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add products first.')),
      );
      return;
    }

    Product? selectedProduct = products.first;
    final weightCtrl = TextEditingController();
    final priceCtrl =
        TextEditingController(text: selectedProduct.sellingPrice.toStringAsFixed(0));
    final quantityCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final w = double.tryParse(weightCtrl.text.trim()) ?? 0;
          final p = double.tryParse(priceCtrl.text.trim()) ?? 0;
          final calcTotal = MandiCalculator.calculateLineTotal(w, p);

          return AlertDialog(
            title: const Text('Add Product Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Product>(
                    initialValue: selectedProduct,
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: products
                        .map((prod) => DropdownMenuItem(
                              value: prod,
                              child: Text('${prod.name} (Stock: ${prod.currentStock}kg)'),
                            ))
                        .toList(),
                    onChanged: (p) {
                      if (p != null) {
                        setDialogState(() {
                          selectedProduct = p;
                          priceCtrl.text = p.sellingPrice.toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: MSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: weightCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setDialogState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Weight (KG) *',
                            hintText: 'e.g. 200',
                            suffixText: 'KG',
                          ),
                        ),
                      ),
                      const SizedBox(width: MSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: quantityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Bags/Bori',
                            hintText: 'e.g. 5',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MSpacing.sm),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Rate per 40 KG (Maund) *',
                      hintText: 'e.g. 4000',
                      suffixText: 'PKR',
                    ),
                  ),
                  const SizedBox(height: MSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(MSpacing.md),
                    decoration: BoxDecoration(
                      color: MColors.primary.withValues(alpha: 0.08),
                      borderRadius: MRadius.md,
                      border: Border.all(color: MColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mandi Math Breakdown:',
                            style: MText.labelMd),
                        const SizedBox(height: 2),
                        Text(
                          MandiCalculator.formatCalculationBreakdown(
                            weightKg: w,
                            pricePer40kg: p,
                          ),
                          style: MText.bodySm,
                        ),
                        const Divider(height: MSpacing.sm),
                        Text(
                          'Line Total: Rs. ${calcTotal.toStringAsFixed(0)}',
                          style:
                              MText.titleLg.copyWith(color: MColors.primary),
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
              ElevatedButton(
                onPressed: () {
                  final w = double.tryParse(weightCtrl.text.trim()) ?? 0;
                  final p = double.tryParse(priceCtrl.text.trim()) ?? 0;
                  final q = double.tryParse(quantityCtrl.text.trim()) ?? 1;

                  if (w <= 0 || p <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter valid weight and price.')),
                    );
                    return;
                  }

                  setState(() {
                    _items.add(InvoiceItem(
                      productId: selectedProduct!.id,
                      productName: selectedProduct!.name,
                      quantity: q,
                      weightKg: w,
                      unitPrice: p,
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
        supplierId: _selectedSupplier?.id,
        supplierName: _selectedSupplier?.name ?? '',
        invoiceNumber: _invoiceNumberCtrl.text.trim(),
        subtotal: _productsSubtotal,
        commission: _commissionAmount,
        expenses: _expensesAmount,
        discount: _discountAmount,
        total: _grandTotal,
        receivedAmount: _receivedAmount,
        pendingAmount: _pendingAmount,
        paymentMethod: _paymentMethod,
      );

      final id = await provider.createInvoice(
        invoice: invoice,
        items: _items,
      );

      // If supplier is selected (Option A: Consignment Sale), credit net payout to supplier running balance
      if (_selectedSupplier != null) {
        final netPayout = _netSupplierPayout;
        if (netPayout > 0) {
          final client = Supabase.instance.client;
          final current = (await client
              .from('suppliers')
              .select('running_balance')
              .eq('id', _selectedSupplier!.id)
              .single())['running_balance'] as num? ?? 0;

          await client
              .from('suppliers')
              .update({'running_balance': current.toDouble() + netPayout})
              .eq('id', _selectedSupplier!.id);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Invoice $id created & stock deducted successfully.')),
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
      appBar: AppBar(title: const Text('Create Sales Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                initialValue: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'Customer (Buyer / Walk-in)',
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
              const SizedBox(height: MSpacing.md),
              DropdownButtonFormField<Supplier>(
                initialValue: _selectedSupplier,
                decoration: const InputDecoration(
                  labelText: 'Supplier / Farmer (Aawak - Consignment)',
                ),
                hint: const Text('Select Supplier / Farmer (Optional)'),
                items: suppliers
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.name} (${s.phone})'),
                        ))
                    .toList(),
                onChanged: (s) => setState(() => _selectedSupplier = s),
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
                  padding: const EdgeInsets.all(MSpacing.xl),
                  decoration: BoxDecoration(
                    color: MColors.surface,
                    borderRadius: MRadius.md,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text('No items added yet. Click "+ Add Item".',
                        style: MText.bodyMd
                            .copyWith(color: MColors.textSecondary)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: MSpacing.xs),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: MRadius.md,
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(item.productName, style: MText.titleLg),
                        subtitle: Text(
                          MandiCalculator.formatCalculationBreakdown(
                            weightKg: item.weightKg,
                            pricePer40kg: item.unitPrice,
                          ),
                          style: MText.bodySm
                              .copyWith(color: MColors.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Rs. ${item.lineTotal.toStringAsFixed(0)}',
                                style: MText.titleLg
                                    .copyWith(color: MColors.primary)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: MColors.danger),
                              onPressed: () =>
                                  setState(() => _items.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: MSpacing.lg),

              // Mandi Calculations
              const Text('Mandi Commission & Expenses', style: MText.titleLg),
              const SizedBox(height: MSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _commissionPercentCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Mazdoori / Kiraya (Expenses)',
                        suffixText: 'PKR',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _discountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Discount (PKR)',
                  suffixText: 'PKR',
                ),
              ),

              const SizedBox(height: MSpacing.lg),

              // Payment Section
              const Text('Payment Details', style: MText.titleLg),
              const SizedBox(height: MSpacing.sm),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _paymentMethod,
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                  border: Border.all(color: MColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                        label: 'Products Subtotal:',
                        value: 'Rs. ${_productsSubtotal.toStringAsFixed(0)}'),
                    _SummaryRow(
                        label: 'Commission ($_commissionPercent%):',
                        value:
                            '+ Rs. ${_commissionAmount.toStringAsFixed(0)}'),
                    _SummaryRow(
                        label: 'Mazdoori / Kiraya:',
                        value: '+ Rs. ${_expensesAmount.toStringAsFixed(0)}'),
                    if (_discountAmount > 0)
                      _SummaryRow(
                          label: 'Discount:',
                          value:
                              '- Rs. ${_discountAmount.toStringAsFixed(0)}'),
                    const Divider(height: MSpacing.md),
                    _SummaryRow(
                      label: 'Grand Total:',
                      value: 'Rs. ${_grandTotal.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                    if (_selectedSupplier != null) ...[
                      const Divider(height: MSpacing.md),
                      _SummaryRow(
                        label: 'Net Payout to Supplier:',
                        value: 'Rs. ${_netSupplierPayout.toStringAsFixed(0)}',
                        color: Colors.green,
                        isBold: true,
                      ),
                    ],
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Issue Sales Invoice'),
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
