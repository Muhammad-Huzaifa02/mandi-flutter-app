import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/utils/ledger_calculator.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/payment_model.dart';
import 'package:mandi/data/models/purchase_order_model.dart';
import 'package:mandi/data/models/ledger_entry_model.dart';

void main() {
  group('LedgerCalculator & DSA Algorithms Tests', () {
    test('Customer Ledger Prefix-Sum calculation and sorting', () {
      final now = DateTime(2026, 11, 1, 10, 0);

      // Unordered invoices and payments
      final invoices = [
        Invoice(
          id: 'inv-2',
          shopId: 'shop-1',
          customerId: 'cust-1',
          invoiceNumber: 'INV-002',
          total: 50000,
          pendingAmount: 50000,
          createdAt: now.add(const Duration(days: 3)),
        ),
        Invoice(
          id: 'inv-1',
          shopId: 'shop-1',
          customerId: 'cust-1',
          invoiceNumber: 'INV-001',
          total: 20000,
          receivedAmount: 5000,
          pendingAmount: 15000,
          createdAt: now.add(const Duration(days: 1)),
        ),
      ];

      final payments = [
        Payment(
          id: 'pay-1',
          shopId: 'shop-1',
          partyType: 'customer',
          partyId: 'cust-1',
          amount: 10000,
          method: 'cash',
          reference: 'REC-001',
          createdAt: now.add(const Duration(days: 2)),
        ),
      ];

      const openingBalance = 5000.0;

      final ledger = LedgerCalculator.buildCustomerLedger(
        openingBalance: openingBalance,
        invoices: invoices,
        payments: payments,
      );

      // Chronological order:
      // Day 1: INV-001 (total 20000 Dr) -> Balance = 5000 + 20000 = 25000
      // Day 1: INV-001 immediate received (5000 Cr) -> Balance = 25000 - 5000 = 20000
      // Day 2: REC-001 (10000 Cr) -> Balance = 20000 - 10000 = 10000
      // Day 3: INV-002 (total 50000 Dr) -> Balance = 10000 + 50000 = 60000
      expect(ledger.length, 4);

      expect(ledger[0].reference, 'INV-001');
      expect(ledger[0].debit, 20000);
      expect(ledger[0].runningBalance, 25000);

      expect(ledger[1].reference, 'INV-001-CASH');
      expect(ledger[1].credit, 5000);
      expect(ledger[1].runningBalance, 20000);

      expect(ledger[2].reference, 'REC-001');
      expect(ledger[2].credit, 10000);
      expect(ledger[2].runningBalance, 10000);

      expect(ledger[3].reference, 'INV-002');
      expect(ledger[3].debit, 50000);
      expect(ledger[3].runningBalance, 60000);

      final summary = LedgerCalculator.calculateSummary(openingBalance, ledger);
      expect(summary.totalDebit, 70000);
      expect(summary.totalCredit, 15000);
      expect(summary.closingBalance, 60000);
    });

    test('Supplier Ledger Prefix-Sum calculation', () {
      final now = DateTime(2026, 11, 1, 12, 0);

      final purchaseOrders = [
        PurchaseOrder(
          id: 'po-1',
          shopId: 'shop-1',
          supplierId: 'sup-1',
          total: 80000,
          paidAmount: 20000,
          status: 'received',
          createdAt: now.add(const Duration(days: 1)),
        ),
      ];

      final consignmentInvoices = [
        Invoice(
          id: 'inv-c1',
          shopId: 'shop-1',
          supplierId: 'sup-1',
          invoiceNumber: 'INV-C01',
          total: 100000,
          supplierPayout: 90000, // Net of commission
          createdAt: now.add(const Duration(days: 3)),
        ),
      ];

      final payments = [
        Payment(
          id: 'pay-s1',
          shopId: 'shop-1',
          partyType: 'supplier',
          partyId: 'sup-1',
          amount: 50000,
          method: 'bankTransfer',
          reference: 'PAY-001',
          createdAt: now.add(const Duration(days: 4)),
        ),
      ];

      const openingBalance = 0.0;

      final ledger = LedgerCalculator.buildSupplierLedger(
        openingBalance: openingBalance,
        purchaseOrders: purchaseOrders,
        consignmentInvoices: consignmentInvoices,
        payments: payments,
      );

      // Order:
      // Day 1: PO-1 crop (80000 Cr) -> Balance = 80000
      // Day 1: PO-1 immediate paid (20000 Dr) -> Balance = 60000
      // Day 3: INV-C01 consignment payout (90000 Cr) -> Balance = 150000
      // Day 4: PAY-001 settlement (50000 Dr) -> Balance = 100000
      expect(ledger.length, 4);
      expect(ledger.last.runningBalance, 100000);
    });

    test('Binary Search Range Query algorithm', () {
      final baseDate = DateTime(2026, 11, 1);
      final entries = List.generate(
        10,
        (i) => LedgerEntry(
          id: 'e-$i',
          reference: 'REF-$i',
          date: baseDate.add(Duration(days: i * 2)),
          type: LedgerEntryType.invoice,
          description: 'Entry $i',
          debit: 1000,
          credit: 0,
          runningBalance: 1000.0 * (i + 1),
        ),
      );

      // Range from day 3 to day 9: should match entries on days 4, 6, 8 (3 items: index 2, 3, 4)
      final results = LedgerCalculator.getEntriesInRange(
        entries,
        baseDate.add(const Duration(days: 3)),
        baseDate.add(const Duration(days: 9)),
      );

      expect(results.length, 3);
      expect(results.first.reference, 'REF-2');
      expect(results.last.reference, 'REF-4');
    });
  });
}
