import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/expense_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Streams every Expense for the active shop.
/// Rebuilt via ChangeNotifierProxyProvider whenever ShopContextProvider's
/// currentShopId changes.
class ExpenseProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  String? _shopId;

  List<Expense> _expenses = [];
  bool _isLoading = true;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;

  double get totalExpensesSum =>
      _expenses.fold(0, (sum, e) => sum + e.amount);

  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _expenses = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _sub = SupabaseService.expensesStream(shopId).listen((rows) {
      _expenses = rows
          .map((r) => Expense.fromMap(r['id'] as String, r))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Expense> search({String query = '', ExpenseCategory? categoryFilter}) {
    var result = _expenses;
    if (categoryFilter != null) {
      result = result.where((e) => e.category == categoryFilter).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      result = result
          .where((e) =>
              e.category.displayName.toLowerCase().contains(q) ||
              e.note.toLowerCase().contains(q) ||
              e.reference.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  Future<void> addExpense(Expense expense) async {
    await SupabaseService.addExpense(expense.toMap());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
