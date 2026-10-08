import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/modules/invoices/providers/invoice_provider.dart';
import 'package:mandi/modules/expenses/providers/expense_provider.dart';
import 'package:mandi/modules/customers/providers/customer_provider.dart';
import 'package:mandi/modules/suppliers/providers/supplier_provider.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().invoices;
    final expensesSum = context.watch<ExpenseProvider>().totalExpensesSum;
    final customers = context.watch<CustomerProvider>().customers;
    final suppliers = context.watch<SupplierProvider>().suppliers;

    final totalSalesSubtotal =
        invoices.fold(0.0, (sum, i) => sum + i.subtotal);
    final totalCommission =
        invoices.fold(0.0, (sum, i) => sum + i.commission);
    final totalRevenue = totalSalesSubtotal + totalCommission;
    final netProfit = totalCommission - expensesSum;

    final totalReceivables = customers.fold(
        0.0, (sum, c) => sum + (c.runningBalance > 0 ? c.runningBalance : 0));
    final totalPayables = suppliers.fold(
        0.0, (sum, s) => sum + (s.runningBalance > 0 ? s.runningBalance : 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Mandi Profit & Loss Summary GlassCard
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(MSpacing.lg),
              backgroundColor: MColors.primary.withValues(alpha: 0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Net Mandi Profit (Commission - Expenses)',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: MSpacing.xs),
                  Text(
                    'Rs. ${netProfit.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: MSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatColumn(
                        label: 'Commission Earned',
                        value: 'Rs. ${totalCommission.toStringAsFixed(0)}',
                      ),
                      _StatColumn(
                        label: 'Shop Expenses',
                        value: 'Rs. ${expensesSum.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Mandi Sales & Volume Overview GlassCard
            Text('Sales & Volume Overview',
                style: MText.titleLg.copyWith(color: Colors.white)),
            const SizedBox(height: MSpacing.sm),
            GlassCard(
              padding: const EdgeInsets.all(MSpacing.lg),
              child: Column(
                children: [
                  _ReportRow(
                    label: 'Total Sales Invoices Issued',
                    value: '${invoices.length}',
                  ),
                  _ReportRow(
                    label: 'Total Products Volume Sold',
                    value: 'Rs. ${totalSalesSubtotal.toStringAsFixed(0)}',
                  ),
                  _ReportRow(
                    label: 'Total Mandi Commission',
                    value: 'Rs. ${totalCommission.toStringAsFixed(0)}',
                  ),
                  _ReportRow(
                    label: 'Total Gross Revenue',
                    value: 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: MSpacing.lg),

            // Receivables & Payables Ledger Summary
            Text('Ledger Balance Summary',
                style: MText.titleLg.copyWith(color: Colors.white)),
            const SizedBox(height: MSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(MSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer Receivables',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: MSpacing.xs),
                        Text(
                          'Rs. ${totalReceivables.toStringAsFixed(0)}',
                          style: MText.titleLg.copyWith(color: MColors.danger),
                        ),
                        const SizedBox(height: 2),
                        const Text('Money owed to shop',
                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: MSpacing.md),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(MSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Supplier Payables',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: MSpacing.xs),
                        Text(
                          'Rs. ${totalPayables.toStringAsFixed(0)}',
                          style: MText.titleLg.copyWith(color: Colors.greenAccent),
                        ),
                        const SizedBox(height: 2),
                        const Text('Money owed by shop',
                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(value,
              style: MText.titleLg.copyWith(fontSize: 15, color: MColors.gold)),
        ],
      ),
    );
  }
}
