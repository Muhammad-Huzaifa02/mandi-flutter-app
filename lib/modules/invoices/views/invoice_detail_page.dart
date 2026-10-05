import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/invoice_pdf_generator.dart';
import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';

class InvoiceDetailPage extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  late Invoice _invoice;
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    if (_invoice.items.isEmpty && _invoice.id.isNotEmpty) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    try {
      final items = await SupabaseService.getInvoiceItems(_invoice.id);
      if (mounted) {
        setState(() {
          _invoice = _invoice.copyWith(items: items);
          _loadingItems = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopContextProvider>().currentShop;
    final customers = context.watch<CustomerProvider>().customers;
    final customer = _invoice.customerId != null
        ? customers.where((c) => c.id == _invoice.customerId).firstOrNull
        : null;

    final customerPhone = customer?.phone ?? '';
    final customerEmail = customer?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print / Save PDF',
            onPressed: () {
              InvoicePdfGenerator.printOrShareInvoice(
                invoice: _invoice,
                shopName: shop?.name ?? 'Mandi Shop',
                shopPhone: shop?.phone,
                shopCity: shop?.city,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: MRadius.lg,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_invoice.invoiceNumber, style: MText.titleLg),
                      Chip(
                        label: Text(
                          _invoice.status.toUpperCase(),
                          style: TextStyle(
                            color: _invoice.status == 'paid'
                                ? Colors.green
                                : (_invoice.status == 'partial'
                                    ? Colors.orange
                                    : MColors.danger),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: (_invoice.status == 'paid'
                                ? Colors.green
                                : (_invoice.status == 'partial'
                                    ? Colors.orange
                                    : MColors.danger))
                            .withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  const Divider(height: MSpacing.lg),
                  _InfoRow(
                      label: 'Customer / Buyer',
                      value: _invoice.customerName.isNotEmpty
                          ? _invoice.customerName
                          : 'Walk-in Customer'),
                  if (_invoice.supplierName.isNotEmpty)
                    _InfoRow(
                        label: 'Supplier / Farmer',
                        value: _invoice.supplierName),
                  _InfoRow(
                      label: 'Payment Method',
                      value: _invoice.paymentMethod.displayName),
                  if (_invoice.createdAt != null)
                    _InfoRow(
                      label: 'Date',
                      value:
                          '${_invoice.createdAt!.day}/${_invoice.createdAt!.month}/${_invoice.createdAt!.year}',
                    ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Line Items Section
            const Text('Purchased Items', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),

            if (_loadingItems)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(MSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_invoice.items.isEmpty)
              Text('No item details available.',
                  style: MText.bodyMd.copyWith(color: MColors.textSecondary))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoice.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: MSpacing.xs),
                itemBuilder: (context, i) {
                  final item = _invoice.items[i];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: MRadius.md,
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      title: Text(
                          item.productName.isNotEmpty
                              ? item.productName
                              : 'Item ${i + 1}',
                          style: MText.titleLg),
                      subtitle: Text(
                        MandiCalculator.formatCalculationBreakdown(
                          weightKg: item.weightKg,
                          pricePer40kg: item.unitPrice,
                        ),
                        style:
                            MText.bodySm.copyWith(color: MColors.textSecondary),
                      ),
                      trailing: Text(
                        'Rs. ${item.lineTotal.toStringAsFixed(0)}',
                        style: MText.titleLg.copyWith(color: MColors.primary),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: MSpacing.lg),

            // Financial Summary Card
            Container(
              padding: const EdgeInsets.all(MSpacing.lg),
              decoration: BoxDecoration(
                color: MColors.surface,
                borderRadius: MRadius.lg,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                      label: 'Subtotal:',
                      value: 'Rs. ${_invoice.subtotal.toStringAsFixed(0)}'),
                  _SummaryRow(
                      label: 'Mandi Commission:',
                      value: '+ Rs. ${_invoice.commission.toStringAsFixed(0)}'),
                  if (_invoice.expenses > 0)
                    _SummaryRow(
                        label: 'Expenses:',
                        value: '+ Rs. ${_invoice.expenses.toStringAsFixed(0)}'),
                  if (_invoice.discount > 0)
                    _SummaryRow(
                        label: 'Discount:',
                        value: '- Rs. ${_invoice.discount.toStringAsFixed(0)}'),
                  const Divider(height: MSpacing.md),
                  _SummaryRow(
                    label: 'Grand Total:',
                    value: 'Rs. ${_invoice.total.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                  _SummaryRow(
                    label: 'Received Amount:',
                    value: 'Rs. ${_invoice.receivedAmount.toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                  if (_invoice.pendingAmount > 0)
                    _SummaryRow(
                      label: 'Pending Balance:',
                      value: 'Rs. ${_invoice.pendingAmount.toStringAsFixed(0)}',
                      color: MColors.danger,
                      isBold: true,
                    ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.xl),

            // Print, Email & WhatsApp Share Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      InvoicePdfGenerator.printOrShareInvoice(
                        invoice: _invoice,
                        shopName: shop?.name ?? 'Mandi Shop',
                        shopPhone: shop?.phone,
                        shopCity: shop?.city,
                      );
                    },
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('PDF / Print'),
                  ),
                ),
                const SizedBox(width: MSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                    ),
                    onPressed: () {
                      WhatsAppShareService.shareInvoice(
                        phone: customerPhone,
                        invoice: _invoice,
                        shopName: shop?.name ?? 'Mandi Shop',
                      );
                    },
                    icon: const Icon(Icons.share, color: Colors.white, size: 18),
                    label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                  ),
                ),
                if (customerEmail.isNotEmpty) ...[
                  const SizedBox(width: MSpacing.sm),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: MColors.primary),
                    icon: const Icon(Icons.email_outlined, color: Colors.white),
                    tooltip: 'Email Invoice',
                    onPressed: () {
                      WhatsAppShareService.shareInvoiceViaEmail(
                        email: customerEmail,
                        invoice: _invoice,
                        shopName: shop?.name ?? 'Mandi Shop',
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
          Text(value, style: MText.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        ],
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
