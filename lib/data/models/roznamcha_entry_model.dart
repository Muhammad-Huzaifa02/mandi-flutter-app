import 'package:flutter/material.dart';

enum RoznamchaType {
  cashIn,
  cashOut,
}

enum RoznamchaSource {
  openingBalance,
  invoiceSale,
  customerPayment,
  supplierPayout,
  purchaseOrder,
  expense,
}

/// Represents a single cash movement line item in the Daily Roznamcha (Cash Day Book).
class RoznamchaEntry {
  final String id;
  final DateTime dateTime;
  final String reference;
  final String partyName;
  final String description;
  final RoznamchaType type;
  final RoznamchaSource source;
  final double amount;
  final double runningBalance;

  const RoznamchaEntry({
    required this.id,
    required this.dateTime,
    required this.reference,
    required this.partyName,
    required this.description,
    required this.type,
    required this.source,
    required this.amount,
    this.runningBalance = 0.0,
  });

  bool get isCashIn => type == RoznamchaType.cashIn;
  bool get isCashOut => type == RoznamchaType.cashOut;

  String get sourceDisplayName {
    switch (source) {
      case RoznamchaSource.openingBalance:
        return 'Opening Cash (نقد ابتدائی)';
      case RoznamchaSource.invoiceSale:
        return 'Cash Sale (نقد فروخت)';
      case RoznamchaSource.customerPayment:
        return 'Customer Recovery (وصولی کھاتہ)';
      case RoznamchaSource.supplierPayout:
        return 'Supplier Payout (ادائیگی زمیندار)';
      case RoznamchaSource.purchaseOrder:
        return 'Procurement Cash (خریداری نقد)';
      case RoznamchaSource.expense:
        return 'Daily Expense (روزمرہ خرچ)';
    }
  }

  IconData get icon {
    switch (source) {
      case RoznamchaSource.openingBalance:
        return Icons.account_balance_wallet_outlined;
      case RoznamchaSource.invoiceSale:
        return Icons.point_of_sale_outlined;
      case RoznamchaSource.customerPayment:
        return Icons.arrow_downward_rounded;
      case RoznamchaSource.supplierPayout:
        return Icons.arrow_upward_rounded;
      case RoznamchaSource.purchaseOrder:
        return Icons.shopping_bag_outlined;
      case RoznamchaSource.expense:
        return Icons.receipt_long_outlined;
    }
  }

  Color get color {
    switch (type) {
      case RoznamchaType.cashIn:
        return const Color(0xFF2E7D32); // Deep Green
      case RoznamchaType.cashOut:
        return const Color(0xFFC62828); // Vibrant Red
    }
  }

  RoznamchaEntry copyWith({
    String? id,
    DateTime? dateTime,
    String? reference,
    String? partyName,
    String? description,
    RoznamchaType? type,
    RoznamchaSource? source,
    double? amount,
    double? runningBalance,
  }) {
    return RoznamchaEntry(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      reference: reference ?? this.reference,
      partyName: partyName ?? this.partyName,
      description: description ?? this.description,
      type: type ?? this.type,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      runningBalance: runningBalance ?? this.runningBalance,
    );
  }
}

/// Encapsulates the daily cash reconciliation summary.
class RoznamchaDailyReport {
  final DateTime date;
  final double openingBalance;
  final double totalCashIn;
  final double totalCashOut;
  final double netCashChange;
  final double closingBalance;
  final List<RoznamchaEntry> entries;

  const RoznamchaDailyReport({
    required this.date,
    required this.openingBalance,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.netCashChange,
    required this.closingBalance,
    required this.entries,
  });

  List<RoznamchaEntry> get cashInEntries =>
      entries.where((e) => e.isCashIn).toList();

  List<RoznamchaEntry> get cashOutEntries =>
      entries.where((e) => e.isCashOut).toList();
}
