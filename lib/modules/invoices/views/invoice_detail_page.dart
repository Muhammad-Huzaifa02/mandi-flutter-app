import 'package:flutter/material.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/mandi_calculator.dart';
import 'package:mandi/data/models/invoice_model.dart';

class InvoiceDetailPage extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(invoice.invoiceNumber)),
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
                      Text(invoice.invoiceNumber, style: MText.titleLg),
                      Chip(
                        label: Text(
                          invoice.status.toUpperCase(),
                          style: TextStyle(
                            color: invoice.status == 'paid'
                                ? Colors.green
                                : (invoice.status == 'partial'
                                    ? Colors.orange
                                    : MColors.danger),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: (invoice.status == 'paid'
                                ? Colors.green
                                : (invoice.status == 'partial'
                                    ? Colors.orange
                                    : MColors.danger))
                            .withOpacity(0.1),
                      ),
                    ],
                  ),
                  const Divider(height: MSpacing.lg),
                  _InfoRow(label: 'Customer', value: invoice.customerName.isNotEmpty ? invoice.customerName : 'Walk-in Customer'),
                  _InfoRow(
                      label: 'Payment Method',
                      value: invoice.paymentMethod.displayName),
                  if (invoice.createdAt != null)
                    _InfoRow(
                      label: 'Date',
                      value:
                          '${invoice.createdAt!.day}/${invoice.createdAt!.month}/${invoice.createdAt!.year}',
                    ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Line Items
            const Text('Purchased Items', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            if (invoice.items.isEmpty)
              Text('No item details available.',
                  style: MText.bodyMd.copyWith(color: MColors.textSecondary))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoice.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: MSpacing.xs),
                itemBuilder: (context, i) {
                  final item = invoice.items[i];
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
                      value: 'Rs. ${invoice.subtotal.toStringAsFixed(0)}'),
                  _SummaryRow(
                      label: 'Mandi Commission:',
                      value: '+ Rs. ${invoice.commission.toStringAsFixed(0)}'),
                  if (invoice.expenses > 0)
                    _SummaryRow(
                        label: 'Expenses:',
                        value: '+ Rs. ${invoice.expenses.toStringAsFixed(0)}'),
                  if (invoice.discount > 0)
                    _SummaryRow(
                        label: 'Discount:',
                        value: '- Rs. ${invoice.discount.toStringAsFixed(0)}'),
                  const Divider(height: MSpacing.md),
                  _SummaryRow(
                    label: 'Grand Total:',
                    value: 'Rs. ${invoice.total.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                  _SummaryRow(
                    label: 'Received Amount:',
                    value: 'Rs. ${invoice.receivedAmount.toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                  if (invoice.pendingAmount > 0)
                    _SummaryRow(
                      label: 'Pending Balance:',
                      value: 'Rs. ${invoice.pendingAmount.toStringAsFixed(0)}',
                      color: MColors.danger,
                      isBold: true,
                    ),
                ],
              ),
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
