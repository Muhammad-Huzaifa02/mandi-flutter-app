import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/utils/roznamcha_calculator.dart';
import 'package:mandi/data/models/expense_model.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/payment_model.dart';
import 'package:mandi/data/models/purchase_order_model.dart';
import 'package:mandi/data/models/roznamcha_entry_model.dart';

void main() {
  group('RoznamchaCalculator Tests', () {
    final today = DateTime(2026, 11, 10, 12, 0);
    final yesterday = DateTime(2026, 11, 9, 12, 0);

    test('reconciles empty day correctly with opening balance', () {
      final report = RoznamchaCalculator.computeDailyRoznamcha(
        targetDate: today,
        openingBalance: 50000.0,
        invoices: [],
        payments: [],
        purchaseOrders: [],
        expenses: [],
      );

      expect(report.openingBalance, 50000.0);
      expect(report.totalCashIn, 0.0);
      expect(report.totalCashOut, 0.0);
      expect(report.netCashChange, 0.0);
      expect(report.closingBalance, 50000.0);
      expect(report.entries, isEmpty);
    });

    test('reconciles heterogeneous transactions chronologically with prefix-sum running balance', () {
      final invoices = [
        // Cash sale today at 9:00 AM
        Invoice(
          id: 'inv1',
          shopId: 'shop1',
          invoiceNumber: 'INV-001',
          customerName: 'Chaudhry Akram',
          receivedAmount: 25000.0,
          paymentMethod: PaymentMethod.cash,
          status: 'paid',
          createdAt: DateTime(2026, 11, 10, 9, 0),
        ),
        // Cash sale yesterday (should be filtered out)
        Invoice(
          id: 'inv2',
          shopId: 'shop1',
          invoiceNumber: 'INV-002',
          customerName: 'Old Customer',
          receivedAmount: 15000.0,
          paymentMethod: PaymentMethod.cash,
          status: 'paid',
          createdAt: yesterday,
        ),
        // Credit sale today (no cash received, should not appear in cash Roznamcha)
        Invoice(
          id: 'inv3',
          shopId: 'shop1',
          invoiceNumber: 'INV-003',
          customerName: 'Credit Customer',
          receivedAmount: 0.0,
          paymentMethod: PaymentMethod.other,
          status: 'unpaid',
          createdAt: DateTime(2026, 11, 10, 10, 0),
        ),
      ];

      final payments = [
        // Customer cash payment at 11:00 AM
        Payment(
          id: 'pay1',
          shopId: 'shop1',
          partyType: 'customer',
          partyId: 'cust1',
          partyName: 'Malik Tariq',
          amount: 10000.0,
          method: 'cash',
          reference: 'RCP-101',
          createdAt: DateTime(2026, 11, 10, 11, 0),
        ),
        // Supplier payout in cash at 2:00 PM
        Payment(
          id: 'pay2',
          shopId: 'shop1',
          partyType: 'supplier',
          partyId: 'supp1',
          partyName: 'Haji Sharif',
          amount: 18000.0,
          method: 'cash',
          reference: 'PAY-201',
          createdAt: DateTime(2026, 11, 10, 14, 0),
        ),
        // Bank transfer payment (should be ignored for physical Cash Day Book)
        Payment(
          id: 'pay3',
          shopId: 'shop1',
          partyType: 'supplier',
          partyId: 'supp2',
          partyName: 'Bank Supplier',
          amount: 50000.0,
          method: 'bank',
          createdAt: DateTime(2026, 11, 10, 15, 0),
        ),
      ];

      final purchaseOrders = [
        // Cash paid on PO at 1:00 PM
        PurchaseOrder(
          id: 'po1',
          shopId: 'shop1',
          supplierName: 'Wheat Farmer Direct',
          total: 30000.0,
          paidAmount: 12000.0,
          createdAt: DateTime(2026, 11, 10, 13, 0),
        ),
      ];

      final expenses = [
        // Mazdoori expense at 3:00 PM
        Expense(
          id: 'exp1',
          shopId: 'shop1',
          category: ExpenseCategory.labor,
          amount: 3000.0,
          note: 'Bags loading',
          reference: 'EXP-1',
          createdAt: DateTime(2026, 11, 10, 15, 0),
        ),
      ];

      final report = RoznamchaCalculator.computeDailyRoznamcha(
        targetDate: today,
        openingBalance: 20000.0,
        invoices: invoices,
        payments: payments,
        purchaseOrders: purchaseOrders,
        expenses: expenses,
      );

      // Verify transaction count
      expect(report.entries.length, 5);

      // Total Cash In = 25,000 (inv1) + 10,000 (pay1) = 35,000
      expect(report.totalCashIn, 35000.0);

      // Total Cash Out = 12,000 (po1) + 18,000 (pay2) + 3,000 (exp1) = 33,000
      expect(report.totalCashOut, 33000.0);

      // Net Change = 35,000 - 33,000 = +2,000
      expect(report.netCashChange, 2000.0);

      // Closing = 20,000 + 2,000 = 22,000
      expect(report.closingBalance, 22000.0);

      // Verify Chronological Order:
      // 1. 09:00 AM (inv1): +25,000 -> Running: 45,000
      // 2. 11:00 AM (pay1): +10,000 -> Running: 55,000
      // 3. 01:00 PM (po1):  -12,000 -> Running: 43,000
      // 4. 02:00 PM (pay2): -18,000 -> Running: 25,000
      // 5. 03:00 PM (exp1):  -3,000 -> Running: 22,000
      expect(report.entries[0].reference, 'INV-001');
      expect(report.entries[0].type, RoznamchaType.cashIn);
      expect(report.entries[0].runningBalance, 45000.0);

      expect(report.entries[1].reference, 'RCP-101');
      expect(report.entries[1].type, RoznamchaType.cashIn);
      expect(report.entries[1].runningBalance, 55000.0);

      expect(report.entries[2].source, RoznamchaSource.purchaseOrder);
      expect(report.entries[2].type, RoznamchaType.cashOut);
      expect(report.entries[2].runningBalance, 43000.0);

      expect(report.entries[3].reference, 'PAY-201');
      expect(report.entries[3].type, RoznamchaType.cashOut);
      expect(report.entries[3].runningBalance, 25000.0);

      expect(report.entries[4].reference, 'EXP-1');
      expect(report.entries[4].type, RoznamchaType.cashOut);
      expect(report.entries[4].runningBalance, 22000.0);

      // Check helper getters
      expect(report.cashInEntries.length, 2);
      expect(report.cashOutEntries.length, 3);
    });
  });
}
