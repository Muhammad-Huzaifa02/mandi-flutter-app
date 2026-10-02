import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/excel_export_service.dart';
import 'package:mandi/data/models/expense_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/expenses/providers/expense_provider.dart';
import 'package:mandi/modules/expenses/views/add_expense_page.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final _searchCtrl = TextEditingController();
  ExpenseCategory? _selectedCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final canLog = shopCtx.hasPermission('manage_expenses');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Excel Report',
            onPressed: () {
              final expenses = context.read<ExpenseProvider>().expenses;
              if (expenses.isNotEmpty) {
                ExcelExportService.exportExpenses(expenses);
              }
            },
          ),
        ],
      ),
      floatingActionButton: canLog
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddExpensePage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Record Expense'),
            )
          : null,
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = provider.search(
            query: _searchCtrl.text,
            categoryFilter: _selectedCategory,
          );

          return Column(
            children: [
              // Total Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(MSpacing.md),
                margin: const EdgeInsets.all(MSpacing.md),
                decoration: BoxDecoration(
                  color: MColors.surface,
                  borderRadius: MRadius.lg,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Expenses',
                            style: MText.bodySm
                                .copyWith(color: MColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${provider.totalExpensesSum.toStringAsFixed(0)}',
                          style: MText.titleLg.copyWith(color: MColors.danger),
                        ),
                      ],
                    ),
                    const Icon(Icons.account_balance_wallet_outlined,
                        color: MColors.danger, size: 32),
                  ],
                ),
              ),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: MSpacing.md),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: MSpacing.xs),
                    ...ExpenseCategory.values.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(right: MSpacing.xs),
                        child: FilterChip(
                          avatar: Icon(cat.icon, size: 16),
                          label: Text(cat.displayName),
                          selected: _selectedCategory == cat,
                          onSelected: (selected) => setState(() =>
                              _selectedCategory = selected ? cat : null),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Input
              Padding(
                padding: const EdgeInsets.all(MSpacing.md),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search expense notes or reference...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),

              Expanded(
                child: expenses.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty && _selectedCategory == null
                              ? 'No expenses logged yet.'
                              : 'No expenses match your filter.',
                          style: MText.bodyMd
                              .copyWith(color: MColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(MSpacing.md),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: MSpacing.sm),
                        itemBuilder: (context, i) {
                          final e = expenses[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: MRadius.md,
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: MColors.danger.withValues(alpha: 0.1),
                                child: Icon(e.category.icon,
                                    color: MColors.danger),
                              ),
                              title: Text(e.category.displayName,
                                  style: MText.titleLg),
                              subtitle: Text(
                                e.note.isNotEmpty
                                    ? e.note
                                    : (e.reference.isNotEmpty
                                        ? 'Ref: ${e.reference}'
                                        : 'No note'),
                                style: MText.bodySm
                                    .copyWith(color: MColors.textSecondary),
                              ),
                              trailing: Text(
                                '- Rs. ${e.amount.toStringAsFixed(0)}',
                                style: MText.titleLg
                                    .copyWith(color: MColors.danger),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
