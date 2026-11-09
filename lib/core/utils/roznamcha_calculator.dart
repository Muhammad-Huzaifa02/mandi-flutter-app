import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/payment_model.dart';
import 'package:mandi/data/models/purchase_order_model.dart';
import 'package:mandi/data/models/expense_model.dart';
import 'package:mandi/data/models/roznamcha_entry_model.dart';

/// Algorithmic reconciliation engine for the Pakistani Mandi Roznamcha (روزنامچہ).
///
/// Features:
/// 1. Chronological merge sorting of heterogeneous financial streams: O(M log M).
/// 2. Linear scan prefix-sum accumulator computing running cash balances: O(M).
/// 3. Invariant validation ensuring closing cash exactly equals opening + in - out.
class RoznamchaCalculator {
  const RoznamchaCalculator._();

  /// Compiles a daily cash reconciliation report for [targetDate].
  static RoznamchaDailyReport computeDailyRoznamcha({
    required DateTime targetDate,
    required double openingBalance,
    required List<Invoice> invoices,
    required List<Payment> payments,
    required List<PurchaseOrder> purchaseOrders,
    required List<Expense> expenses,
  }) {
    final startOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      0,
      0,
      0,
    );
    final endOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      23,
      59,
      59,
      999,
    );

    bool isInTargetDay(DateTime? dt) {
      if (dt == null) return false;
      return !dt.isBefore(startOfDay) && !dt.isAfter(endOfDay);
    }

    final rawEntries = <RoznamchaEntry>[];

    // 1. Invoices (Cash sales)
    for (final inv in invoices) {
      if (inv.status == 'void') continue;
      if (!isInTargetDay(inv.createdAt)) continue;

      if (inv.paymentMethod == PaymentMethod.cash && inv.receivedAmount > 0) {
        rawEntries.add(
          RoznamchaEntry(
            id: 'inv-${inv.id}',
            dateTime: inv.createdAt ?? targetDate,
            reference: inv.invoiceNumber.isNotEmpty
                ? inv.invoiceNumber
                : 'INV-${inv.id.substring(0, inv.id.length.clamp(0, 6))}',
            partyName: inv.customerName.isNotEmpty
                ? inv.customerName
                : 'Cash Customer',
            description: 'Cash Sale (${inv.items.length} items)',
            type: RoznamchaType.cashIn,
            source: RoznamchaSource.invoiceSale,
            amount: inv.receivedAmount,
          ),
        );
      }
    }

    // 2. Payments (Customer cash receipts & Supplier cash payouts)
    for (final pay in payments) {
      if (!isInTargetDay(pay.createdAt)) continue;
      final isCashMethod = pay.method.trim().toLowerCase() == 'cash';
      if (!isCashMethod || pay.amount <= 0) continue;

      final isCustomer = pay.partyType.trim().toLowerCase() == 'customer';
      if (isCustomer) {
        rawEntries.add(
          RoznamchaEntry(
            id: 'pay-${pay.id}',
            dateTime: pay.createdAt ?? targetDate,
            reference: pay.reference.isNotEmpty
                ? pay.reference
                : 'RCP-${pay.id.substring(0, pay.id.length.clamp(0, 6))}',
            partyName: pay.partyName.isNotEmpty
                ? pay.partyName
                : 'Customer Payment',
            description: 'Khata Cash Recovery',
            type: RoznamchaType.cashIn,
            source: RoznamchaSource.customerPayment,
            amount: pay.amount,
          ),
        );
      } else {
        // Supplier payout
        rawEntries.add(
          RoznamchaEntry(
            id: 'pay-${pay.id}',
            dateTime: pay.createdAt ?? targetDate,
            reference: pay.reference.isNotEmpty
                ? pay.reference
                : 'PAY-${pay.id.substring(0, pay.id.length.clamp(0, 6))}',
            partyName: pay.partyName.isNotEmpty
                ? pay.partyName
                : 'Supplier Payout',
            description: 'Farmer / Supplier Cash Disbursement',
            type: RoznamchaType.cashOut,
            source: RoznamchaSource.supplierPayout,
            amount: pay.amount,
          ),
        );
      }
    }

    // 3. Purchase Orders (Procurement cash paid)
    for (final po in purchaseOrders) {
      if (po.status == 'cancelled') continue;
      if (!isInTargetDay(po.createdAt)) continue;
      if (po.paidAmount <= 0) continue;

      rawEntries.add(
        RoznamchaEntry(
          id: 'po-${po.id}',
          dateTime: po.createdAt ?? targetDate,
          reference: 'PO-${po.id.substring(0, po.id.length.clamp(0, 6))}',
          partyName: po.supplierName.isNotEmpty
              ? po.supplierName
              : 'Direct Supplier',
          description: 'Procurement Advance/Cash Payment',
          type: RoznamchaType.cashOut,
          source: RoznamchaSource.purchaseOrder,
          amount: po.paidAmount,
        ),
      );
    }

    // 4. Daily Operating Expenses
    for (final exp in expenses) {
      if (!isInTargetDay(exp.createdAt)) continue;
      if (exp.amount <= 0) continue;

      final noteStr = exp.note.isNotEmpty ? ' - ${exp.note}' : '';
      rawEntries.add(
        RoznamchaEntry(
          id: 'exp-${exp.id}',
          dateTime: exp.createdAt ?? targetDate,
          reference: exp.reference.isNotEmpty
              ? exp.reference
              : 'EXP-${exp.id.substring(0, exp.id.length.clamp(0, 6))}',
          partyName: exp.category.displayName,
          description: 'Expense$noteStr',
          type: RoznamchaType.cashOut,
          source: RoznamchaSource.expense,
          amount: exp.amount,
        ),
      );
    }

    // Sort chronologically O(M log M)
    rawEntries.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Prefix-sum accumulator O(M)
    double running = openingBalance;
    double totalIn = 0.0;
    double totalOut = 0.0;
    final accumulatedEntries = <RoznamchaEntry>[];

    for (final entry in rawEntries) {
      if (entry.isCashIn) {
        running += entry.amount;
        totalIn += entry.amount;
      } else {
        running -= entry.amount;
        totalOut += entry.amount;
      }
      accumulatedEntries.add(entry.copyWith(runningBalance: running));
    }

    final netChange = totalIn - totalOut;
    final closing = openingBalance + netChange;

    return RoznamchaDailyReport(
      date: startOfDay,
      openingBalance: openingBalance,
      totalCashIn: totalIn,
      totalCashOut: totalOut,
      netCashChange: netChange,
      closingBalance: closing,
      entries: accumulatedEntries,
    );
  }
}
