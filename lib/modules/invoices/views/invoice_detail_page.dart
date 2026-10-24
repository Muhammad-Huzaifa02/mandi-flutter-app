import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/core/utils/invoice_pdf_generator.dart';
import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/core/utils/thermal_receipt_service.dart';
import 'package:mandi/core/utils/whatsapp_share_service.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';

class InvoiceDetailPage extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  late Invoice _invoice;
  bool _loadingItems = false;
  bool _cancelling = false;

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

  Future<void> _showCancelInvoiceDialog() async {
    final reasonController = TextEditingController();
    final shopCtx = context.read<ShopContextProvider>();
    final member = shopCtx.currentMember;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel & Void Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this invoice?\n\n'
              '• Product stock will be automatically restored.\n'
              '• Customer balance adjustment will be reversed.\n'
              '• An audit log entry will be recorded.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: MSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                hintText: 'e.g., Wrong quantity entered / Order returned',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MColors.danger),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Void Invoice', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);

    try {
      final invoiceProvider = context.read<InvoiceProvider>();
      await invoiceProvider.cancelInvoice(
        invoiceId: _invoice.id,
        actorId: member?.id ?? '',
        actorName: member?.name ?? 'Shop Member',
        reason: reasonController.text.trim(),
      );

      setState(() {
        _invoice = _invoice.copyWith(status: 'void');
        _cancelling = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice cancelled and stock restored successfully!'),
          backgroundColor: MColors.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel invoice: $e'),
          backgroundColor: MColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopContextProvider>().currentShop;
    final shopCtx = context.watch<ShopContextProvider>();
    final customers = context.watch<CustomerProvider>().customers;
    final customer = _invoice.customerId != null
        ? customers.where((c) => c.id == _invoice.customerId).firstOrNull
        : null;

    final customerPhone = customer?.phone ?? '';
    final customerEmail = customer?.email ?? '';
    final isVoid = _invoice.status == 'void' || _invoice.status == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_outlined),
            tooltip: 'Print Thermal POS Slip (80mm)',
            onPressed: () {
              ThermalReceiptService.printThermalSlip(
                invoice: _invoice,
                shopName: shop?.name ?? 'Mandi Shop',
                shopPhone: shop?.phone,
                shopCity: shop?.city,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print A4 PDF Invoice',
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
            if (isVoid)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.bottom(MSpacing.md),
                padding: const EdgeInsets.symmetric(
                    vertical: MSpacing.sm, horizontal: MSpacing.md),
                decoration: BoxDecoration(
                  color: MColors.danger.withValues(alpha: 0.2),
                  border: Border.all(color: MColors.danger),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: MColors.danger),
                    SizedBox(width: MSpacing.xs),
                    Expanded(
                      child: Text(
                        'THIS INVOICE HAS BEEN VOIDED / CANCELLED',
                        style: TextStyle(
                          color: MColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Glass Header Card
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_invoice.invoiceNumber,
                          style: MText.titleLg.copyWith(color: Colors.white)),
                      Chip(
                        label: Text(
                          _invoice.status.toUpperCase(),
                          style: TextStyle(
                            color: isVoid
                                ? MColors.danger
                                : (_invoice.status == 'paid'
                                    ? Colors.greenAccent
                                    : (_invoice.status == 'partial'
                                        ? Colors.orangeAccent
                                        : MColors.danger)),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: (isVoid
                                ? MColors.danger
                                : (_invoice.status == 'paid'
                                    ? Colors.green
                                    : (_invoice.status == 'partial'
                                        ? Colors.orange
                                        : MColors.danger)))
                            .withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const Divider(height: MSpacing.lg, color: Colors.white24),
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
            Text('Purchased Items',
                style: MText.titleLg.copyWith(color: Colors.white)),
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
                  style: MText.bodyMd.copyWith(color: Colors.white70))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoice.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: MSpacing.xs),
                itemBuilder: (context, i) {
                  final item = _invoice.items[i];
                  return GlassCard(
                    padding: const EdgeInsets.all(MSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName.isNotEmpty
                                    ? item.productName
                                    : 'Item ${i + 1}',
                                style: MText.titleLg.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                MandiCalculator.formatCalculationBreakdown(
                                  weightKg: item.weightKg,
                                  pricePer40kg: item.unitPrice,
                                ),
                                style: MText.bodySm
                                    .copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rs. ${item.lineTotal.toStringAsFixed(0)}',
                          style: MText.titleLg.copyWith(color: MColors.gold),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: MSpacing.lg),

            // Glass Financial Summary Card
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
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
                  const Divider(height: MSpacing.md, color: Colors.white24),
                  _SummaryRow(
                    label: 'Grand Total:',
                    value: 'Rs. ${_invoice.total.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                  _SummaryRow(
                    label: 'Received Amount:',
                    value: 'Rs. ${_invoice.receivedAmount.toStringAsFixed(0)}',
                    color: Colors.greenAccent,
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      InvoicePdfGenerator.printOrShareInvoice(
                        invoice: _invoice,
                        shopName: shop?.name ?? 'Mandi Shop',
                        shopPhone: shop?.phone,
                        shopCity: shop?.city,
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('PDF / Print',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: MSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      WhatsAppShareService.shareInvoice(
                        phone: customerPhone,
                        invoice: _invoice,
                        shopName: shop?.name ?? 'Mandi Shop',
                      );
                    },
                    icon: const Icon(Icons.share, color: Colors.white, size: 18),
                    label: const Text('WhatsApp',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
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

            if (!isVoid && shopCtx.hasPermission('create_invoice')) ...[
              const SizedBox(height: MSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MColors.danger,
                    side: const BorderSide(color: MColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _cancelling ? null : _showCancelInvoiceDialog,
                  icon: _cancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: MColors.danger),
                        )
                      : const Icon(Icons.block, size: 18),
                  label: Text(
                      _cancelling ? 'Cancelling Invoice...' : 'Void / Cancel Invoice',
                      style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
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
          Text(label, style: MText.bodyMd.copyWith(color: Colors.white70)),
          Text(value, style: MText.bodyMd.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
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
        ? MText.titleLg.copyWith(color: color ?? Colors.white)
        : MText.bodyMd.copyWith(color: color ?? Colors.white70);

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
