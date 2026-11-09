import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/payment_model.dart';
import 'package:mandi/data/models/purchase_order_model.dart';
import 'package:mandi/data/models/ledger_entry_model.dart';

/// Account statement summary metrics calculated over a ledger timeline.
class LedgerSummary {
  final double openingBalance;
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final int transactionCount;

  const LedgerSummary({
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    required this.transactionCount,
  });
}

/// Algorithmic Ledger Engine applying Data Structures & Algorithms (DSA):
/// 1. Chronological Merge Algorithm: Unifies disparate transaction streams ($O((N+M) \log (N+M))$)
/// 2. Prefix-Sum Accumulator: Computes exact progressive running balances ($O(N)$)
/// 3. Binary Search Range Querying: Filters chronological ledgers in $O(\log N)$ time.
class LedgerCalculator {
  /// Builds a chronologically sorted, progressive running-balance ledger for a Customer.
  ///
  /// In customer accounting:
  ///  - Sale Invoices represent Debits (Dr: Customer owes the shop).
  ///  - Payments received represent Credits (Cr: Money paid to the shop).
  ///  - Running Balance = Opening Balance + Cumulative(Debits) - Cumulative(Credits).
  static List<LedgerEntry> buildCustomerLedger({
    required double openingBalance,
    required List<Invoice> invoices,
    required List<Payment> payments,
  }) {
    final rawEntries = <LedgerEntry>[];

    // Filter out void/cancelled invoices
    for (final inv in invoices) {
      if (inv.status == 'void' || inv.status == 'cancelled') continue;
      final date = inv.createdAt ?? DateTime.now();

      // Full invoice total is charged to customer as Debit
      rawEntries.add(LedgerEntry(
        id: inv.id,
        reference: inv.invoiceNumber,
        date: date,
        type: LedgerEntryType.invoice,
        description: 'Grain Sale (${inv.paymentMethod.displayName})',
        debit: inv.total,
        credit: 0,
        runningBalance: 0, // Computed in prefix-sum pass
      ));

      // If invoice had an immediate received amount, record immediate payment credit
      if (inv.receivedAmount > 0) {
        rawEntries.add(LedgerEntry(
          id: '${inv.id}_rcv',
          reference: '${inv.invoiceNumber}-CASH',
          date: date.add(const Duration(milliseconds: 1)),
          type: LedgerEntryType.payment,
          description: 'Payment at Invoice Checkout',
          debit: 0,
          credit: inv.receivedAmount,
          runningBalance: 0,
        ));
      }
    }

    // Add standalone cash payments
    for (final pay in payments) {
      if (pay.partyType.toLowerCase() != 'customer') continue;
      final date = pay.createdAt ?? DateTime.now();
      rawEntries.add(LedgerEntry(
        id: pay.id,
        reference: pay.reference.isNotEmpty ? pay.reference : 'REC-${pay.id.substring(0, 6)}',
        date: date,
        type: LedgerEntryType.payment,
        description: 'Cash Receipt (${pay.method})',
        debit: 0,
        credit: pay.amount,
        runningBalance: 0,
      ));
    }

    // Step 1 (DSA): Chronological Sort using Comparable
    rawEntries.sort();

    // Step 2 (DSA): Prefix-Sum Accumulation Algorithm (Linear Scan O(N))
    double currentBalance = openingBalance;
    final finalizedLedger = <LedgerEntry>[];

    for (final entry in rawEntries) {
      currentBalance = currentBalance + entry.debit - entry.credit;
      finalizedLedger.add(entry.copyWith(runningBalance: currentBalance));
    }

    return finalizedLedger;
  }

  /// Builds a chronologically sorted, progressive running-balance ledger for a Supplier.
  ///
  /// In supplier accounting:
  ///  - Harvest produce received (Purchase Orders / Consignment Payouts) represents Credit (Cr: Shop owes farmer).
  ///  - Payments disbursed to farmer represent Debit (Dr: Shop paid farmer).
  ///  - Running Balance = Opening Balance + Cumulative(Credits) - Cumulative(Debits).
  static List<LedgerEntry> buildSupplierLedger({
    required double openingBalance,
    required List<PurchaseOrder> purchaseOrders,
    required List<Invoice> consignmentInvoices,
    required List<Payment> payments,
  }) {
    final rawEntries = <LedgerEntry>[];

    // Purchase orders
    for (final po in purchaseOrders) {
      if (po.status == 'cancelled') continue;
      final date = po.createdAt ?? DateTime.now();
      rawEntries.add(LedgerEntry(
        id: po.id,
        reference: 'PO-${po.id.length > 6 ? po.id.substring(0, 6) : po.id}',
        date: date,
        type: LedgerEntryType.purchaseOrder,
        description: 'Crop Shipment Received',
        debit: 0,
        credit: po.total,
        runningBalance: 0,
      ));

      if (po.paidAmount > 0) {
        rawEntries.add(LedgerEntry(
          id: '${po.id}_paid',
          reference: 'PO-${po.id.length > 6 ? po.id.substring(0, 6) : po.id}-PAID',
          date: date.add(const Duration(milliseconds: 1)),
          type: LedgerEntryType.payout,
          description: 'Immediate Payout at Delivery',
          debit: po.paidAmount,
          credit: 0,
          runningBalance: 0,
        ));
      }
    }

    // Consignment sales invoices
    for (final inv in consignmentInvoices) {
      if (inv.status == 'void' || inv.status == 'cancelled') continue;
      if (inv.supplierPayout <= 0) continue;
      final date = inv.createdAt ?? DateTime.now();
      rawEntries.add(LedgerEntry(
        id: inv.id,
        reference: inv.invoiceNumber,
        date: date,
        type: LedgerEntryType.invoice,
        description: 'Consignment Auction Payout (Net of commission)',
        debit: 0,
        credit: inv.supplierPayout,
        runningBalance: 0,
      ));
    }

    // Standalone payments to supplier
    for (final pay in payments) {
      if (pay.partyType.toLowerCase() != 'supplier') continue;
      final date = pay.createdAt ?? DateTime.now();
      rawEntries.add(LedgerEntry(
        id: pay.id,
        reference: pay.reference.isNotEmpty ? pay.reference : 'PAY-${pay.id.substring(0, 6)}',
        date: date,
        type: LedgerEntryType.payout,
        description: 'Settlement Payout to Farmer (${pay.method})',
        debit: pay.amount,
        credit: 0,
        runningBalance: 0,
      ));
    }

    // Step 1: Sort chronologically
    rawEntries.sort();

    // Step 2: Prefix-sum pass for supplier (Credits increase payable, Debits decrease payable)
    double currentBalance = openingBalance;
    final finalizedLedger = <LedgerEntry>[];

    for (final entry in rawEntries) {
      currentBalance = currentBalance + entry.credit - entry.debit;
      finalizedLedger.add(entry.copyWith(runningBalance: currentBalance));
    }

    return finalizedLedger;
  }

  /// Calculates summary financial totals across the ledger timeline.
  static LedgerSummary calculateSummary(
    double openingBalance,
    List<LedgerEntry> entries, {
    bool isCustomer = true,
  }) {
    double totalDr = 0;
    double totalCr = 0;

    for (final e in entries) {
      totalDr += e.debit;
      totalCr += e.credit;
    }

    final closing = isCustomer
        ? (openingBalance + totalDr - totalCr)
        : (openingBalance + totalCr - totalDr);

    return LedgerSummary(
      openingBalance: openingBalance,
      totalDebit: totalDr,
      totalCredit: totalCr,
      closingBalance: closing,
      transactionCount: entries.length,
    );
  }

  /// Binary Search Algorithm (DSA: O(log N)) to find lower bound index in a sorted ledger.
  static int lowerBound(List<LedgerEntry> entries, DateTime targetDate) {
    int low = 0;
    int high = entries.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (entries[mid].date.isBefore(targetDate)) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  /// Binary Search Range Querying (DSA: O(log N)) to slice entries within date range.
  static List<LedgerEntry> getEntriesInRange(
    List<LedgerEntry> sortedEntries,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (sortedEntries.isEmpty) return const [];
    final startIdx = lowerBound(sortedEntries, startDate);
    int endIdx = lowerBound(sortedEntries, endDate.add(const Duration(days: 1)));
    if (startIdx >= sortedEntries.length) return const [];
    return sortedEntries.sublist(startIdx, endIdx.clamp(0, sortedEntries.length));
  }
}
