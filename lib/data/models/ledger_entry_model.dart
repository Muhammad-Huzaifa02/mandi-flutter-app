import 'package:intl/intl.dart';

/// The financial category/origin of a transaction in a Mandi ledger.
enum LedgerEntryType {
  openingBalance,
  invoice,
  payment,
  purchaseOrder,
  payout,
}

/// Domain model representing a single financial debit/credit entry in an
/// itemized customer or supplier account ledger (Khata).
///
/// Implements [Comparable] to allow efficient chronological sorting ($O(N \log N)$)
/// and two-pointer timeline merging ($O(N + M)$).
class LedgerEntry implements Comparable<LedgerEntry> {
  final String id;
  final String reference;
  final DateTime date;
  final LedgerEntryType type;
  final String description;
  final double debit;   // Dr: increases receivable (customer) or decreases payable (supplier payment)
  final double credit;  // Cr: decreases receivable (customer payment) or increases payable (supplier harvest)
  final double runningBalance; // Net balance after this transaction

  const LedgerEntry({
    required this.id,
    required this.reference,
    required this.date,
    required this.type,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });

  /// Formatted date string (e.g., '09/11/2026').
  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);

  /// Human-readable badge text for this transaction type.
  String get typeLabel {
    switch (type) {
      case LedgerEntryType.openingBalance:
        return 'Opening Bal';
      case LedgerEntryType.invoice:
        return 'Sale Invoice';
      case LedgerEntryType.payment:
        return 'Cash Receipt';
      case LedgerEntryType.purchaseOrder:
        return 'Crop Received';
      case LedgerEntryType.payout:
        return 'Farmer Payout';
    }
  }

  /// Chronological comparison for sorting algorithms.
  @override
  int compareTo(LedgerEntry other) {
    final cmp = date.compareTo(other.date);
    if (cmp != 0) return cmp;
    // Secondary tie-breaker by transaction ID
    return id.compareTo(other.id);
  }

  LedgerEntry copyWith({
    String? id,
    String? reference,
    DateTime? date,
    LedgerEntryType? type,
    String? description,
    double? debit,
    double? credit,
    double? runningBalance,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      runningBalance: runningBalance ?? this.runningBalance,
    );
  }

  @override
  String toString() =>
      'LedgerEntry(ref: $reference, date: $formattedDate, Dr: $debit, Cr: $credit, Bal: $runningBalance)';
}
