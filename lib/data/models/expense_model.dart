import 'package:flutter/material.dart';

/// Categories of daily agricultural commission shop expenses.
enum ExpenseCategory {
  labor,
  transport,
  packing,
  rent,
  electricity,
  teaFood,
  other,
}

extension ExpenseCategoryX on ExpenseCategory {
  static ExpenseCategory fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'labor':
        return ExpenseCategory.labor;
      case 'transport':
        return ExpenseCategory.transport;
      case 'packing':
        return ExpenseCategory.packing;
      case 'rent':
        return ExpenseCategory.rent;
      case 'electricity':
        return ExpenseCategory.electricity;
      case 'teafood':
      case 'tea_food':
        return ExpenseCategory.teaFood;
      case 'other':
      default:
        return ExpenseCategory.other;
    }
  }

  String toDbString() {
    switch (this) {
      case ExpenseCategory.labor:
        return 'labor';
      case ExpenseCategory.transport:
        return 'transport';
      case ExpenseCategory.packing:
        return 'packing';
      case ExpenseCategory.rent:
        return 'rent';
      case ExpenseCategory.electricity:
        return 'electricity';
      case ExpenseCategory.teaFood:
        return 'tea_food';
      case ExpenseCategory.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseCategory.labor:
        return 'Labor (Mazdoori)';
      case ExpenseCategory.transport:
        return 'Transport & Freight';
      case ExpenseCategory.packing:
        return 'Bags & Packing';
      case ExpenseCategory.rent:
        return 'Shop Rent';
      case ExpenseCategory.electricity:
        return 'Electricity & Bills';
      case ExpenseCategory.teaFood:
        return 'Tea & Refreshments';
      case ExpenseCategory.other:
        return 'Other Expense';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.labor:
        return Icons.engineering_outlined;
      case ExpenseCategory.transport:
        return Icons.local_shipping_outlined;
      case ExpenseCategory.packing:
        return Icons.inventory_2_outlined;
      case ExpenseCategory.rent:
        return Icons.storefront_outlined;
      case ExpenseCategory.electricity:
        return Icons.bolt_outlined;
      case ExpenseCategory.teaFood:
        return Icons.local_cafe_outlined;
      case ExpenseCategory.other:
        return Icons.receipt_long_outlined;
    }
  }
}

/// A shop expense entry.
class Expense {
  final String id;
  final String shopId;
  final ExpenseCategory category;
  final double amount;
  final String note;
  final String reference;
  final String? createdBy;
  final DateTime? createdAt;

  const Expense({
    required this.id,
    required this.shopId,
    this.category = ExpenseCategory.other,
    required this.amount,
    this.note = '',
    this.reference = '',
    this.createdBy,
    this.createdAt,
  });

  factory Expense.fromMap(String id, Map<String, dynamic> d) => Expense(
        id: id,
        shopId: d['shop_id'] as String? ?? '',
        category: ExpenseCategoryX.fromString(d['category'] as String?),
        amount: (d['amount'] as num?)?.toDouble() ?? 0,
        note: d['note'] as String? ?? '',
        reference: d['reference'] as String? ?? '',
        createdBy: d['created_by'] as String?,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toMap() => {
        'shop_id': shopId,
        'category': category.toDbString(),
        'amount': amount,
        'note': note,
        'reference': reference,
      };
}
