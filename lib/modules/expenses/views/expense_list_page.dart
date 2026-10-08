import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
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
              // Total Summary GlassCard
              GlassCard(
                margin: const EdgeInsets.all(MSpacing.md),
                padding: const EdgeInsets.all(MSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Expenses',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${provider.totalExpensesSum.toStringAsFixed(0)}',
                          style: MText.titleLg
                              .copyWith(color: MColors.danger, fontSize: 22),
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
                          style: MText.bodyMd.copyWith(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(MSpacing.md),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: MSpacing.sm),
                        itemBuilder: (context, i) {
                          final e = expenses[i];
                          return GlassCard(
                            padding: const EdgeInsets.all(MSpacing.md),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      MColors.danger.withValues(alpha: 0.2),
                                  child: Icon(e.category.icon,
                                      color: MColors.danger),
                                ),
                                const SizedBox(width: MSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.category.displayName,
                                          style: MText.titleLg
                                              .copyWith(color: Colors.white)),
                                      Text(
                                        e.note.isNotEmpty
                                            ? e.note
                                            : (e.reference.isNotEmpty
                                                ? 'Ref: ${e.reference}'
                                                : 'No note'),
                                        style: MText.bodySm
                                            .copyWith(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '- Rs. ${e.amount.toStringAsFixed(0)}',
                                  style: MText.titleLg
                                      .copyWith(color: MColors.danger),
                                ),
                              ],
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
