import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/cheque_register_pdf_generator.dart';
import 'package:mandi/data/models/bank_account_model.dart';
import 'package:mandi/data/models/cheque_model.dart';

void main() {
  group('BankAccount Model Tests', () {
    test('serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime.now();
      final account = BankAccount(
        id: 'acc-1',
        shopId: 'shop-abc',
        bankName: 'Meezan Bank',
        accountTitle: 'Al-Madina Commission Agent',
        accountNumber: '010203040506',
        iban: 'PK36MEZN0001020304050601',
        branchName: 'Grain Market Branch',
        branchCode: '0123',
        openingBalance: 500000.0,
        currentBalance: 750000.0,
        isDefault: true,
        isActive: true,
        createdAt: now,
      );

      final map = account.toMap();
      expect(map['shop_id'], 'shop-abc');
      expect(map['bank_name'], 'Meezan Bank');
      expect(map['account_title'], 'Al-Madina Commission Agent');
      expect(map['account_number'], '010203040506');
      expect(map['iban'], 'PK36MEZN0001020304050601');
      expect(map['opening_balance'], 500000.0);
      expect(map['current_balance'], 750000.0);
      expect(map['is_default'], true);
      expect(map['is_active'], true);

      final parsed = BankAccount.fromMap('acc-1', map);
      expect(parsed.id, 'acc-1');
      expect(parsed.bankName, 'Meezan Bank');
      expect(parsed.accountTitle, 'Al-Madina Commission Agent');
      expect(parsed.displayName, 'Meezan Bank - Al-Madina Commission Agent');
      expect(parsed.currentBalance, 750000.0);
      expect(parsed.isDefault, true);
    });

    test('displayName handles empty account title gracefully', () {
      const account = BankAccount(
        id: 'acc-2',
        shopId: 'shop-abc',
        bankName: 'HBL',
      );
      expect(account.displayName, 'HBL');
    });

    test('copyWith creates modified clone properly', () {
      const original = BankAccount(
        id: 'acc-1',
        shopId: 'shop-1',
        bankName: 'MCB',
        currentBalance: 100000,
      );

      final updated = original.copyWith(
        currentBalance: 150000,
        isDefault: true,
      );

      expect(updated.id, 'acc-1');
      expect(updated.bankName, 'MCB');
      expect(updated.currentBalance, 150000);
      expect(updated.isDefault, true);
    });
  });

  group('Cheque Model & ChequeSummary Tests', () {
    test('correctly identifies PDC, Due Today, and Overdue statuses', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final futureDate = today.add(const Duration(days: 7));
      final pastDate = today.subtract(const Duration(days: 3));

      final pdcCheque = Cheque(
        id: 'chq-1',
        shopId: 'shop-1',
        chequeNumber: 'CHQ-1001',
        type: ChequeType.received,
        amount: 250000.0,
        issueDate: today,
        dueDate: futureDate,
        status: ChequeStatus.inHand,
      );

      expect(pdcCheque.isPdc, isTrue);
      expect(pdcCheque.isDueToday, isFalse);
      expect(pdcCheque.isOverdue, isFalse);
      expect(pdcCheque.typeLabelEnglish, 'Received');
      expect(pdcCheque.statusLabelEnglish, 'PDC (In-Hand)');

      final dueTodayCheque = Cheque(
        id: 'chq-2',
        shopId: 'shop-1',
        chequeNumber: 'CHQ-1002',
        type: ChequeType.received,
        amount: 100000.0,
        issueDate: today.subtract(const Duration(days: 5)),
        dueDate: today,
        status: ChequeStatus.inHand,
      );

      expect(dueTodayCheque.isPdc, isFalse);
      expect(dueTodayCheque.isDueToday, isTrue);
      expect(dueTodayCheque.isOverdue, isFalse);

      final overdueCheque = Cheque(
        id: 'chq-3',
        shopId: 'shop-1',
        chequeNumber: 'CHQ-1003',
        type: ChequeType.received,
        amount: 50000.0,
        issueDate: pastDate.subtract(const Duration(days: 2)),
        dueDate: pastDate,
        status: ChequeStatus.inHand,
      );

      expect(overdueCheque.isPdc, isFalse);
      expect(overdueCheque.isDueToday, isFalse);
      expect(overdueCheque.isOverdue, isTrue);
    });

    test('serializes and deserializes all Cheque fields and statuses', () {
      final issue = DateTime(2026, 3, 1);
      final due = DateTime(2026, 3, 15);
      final clearance = DateTime(2026, 3, 16);

      final cheque = Cheque(
        id: 'chq-99',
        shopId: 'shop-mandi',
        chequeNumber: 'CHQ-7788',
        type: ChequeType.issued,
        partyType: 'supplier',
        partyId: 'sup-1',
        partyName: 'Malik Tariq Farmer',
        bankName: 'Bank Alfalah',
        targetBankAccountId: 'acc-1',
        amount: 450000.0,
        issueDate: issue,
        dueDate: due,
        clearanceDate: clearance,
        status: ChequeStatus.cleared,
        notes: 'Paid for Potato lot #44',
      );

      final map = cheque.toMap();
      expect(map['type'], 'issued');
      expect(map['status'], 'cleared');
      expect(map['cheque_number'], 'CHQ-7788');
      expect(map['amount'], 450000.0);

      final parsed = Cheque.fromMap('chq-99', map);
      expect(parsed.id, 'chq-99');
      expect(parsed.type, ChequeType.issued);
      expect(parsed.status, ChequeStatus.cleared);
      expect(parsed.partyName, 'Malik Tariq Farmer');
      expect(parsed.amount, 450000.0);
      expect(parsed.statusLabelUrdu, 'کلیئر شدہ');
    });

    test('ChequeSummary computes accurate financial and count totals', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final list = [
        // In-hand PDC
        Cheque(
          id: '1',
          shopId: 's1',
          chequeNumber: '1',
          type: ChequeType.received,
          amount: 200000.0,
          issueDate: today,
          dueDate: today.add(const Duration(days: 5)),
          status: ChequeStatus.inHand,
        ),
        // In-hand Due Today
        Cheque(
          id: '2',
          shopId: 's1',
          chequeNumber: '2',
          type: ChequeType.received,
          amount: 150000.0,
          issueDate: today.subtract(const Duration(days: 2)),
          dueDate: today,
          status: ChequeStatus.inHand,
        ),
        // Deposited
        Cheque(
          id: '3',
          shopId: 's1',
          chequeNumber: '3',
          type: ChequeType.received,
          amount: 300000.0,
          issueDate: today.subtract(const Duration(days: 1)),
          dueDate: today,
          status: ChequeStatus.deposited,
        ),
        // Cleared
        Cheque(
          id: '4',
          shopId: 's1',
          chequeNumber: '4',
          type: ChequeType.received,
          amount: 500000.0,
          issueDate: today.subtract(const Duration(days: 10)),
          dueDate: today.subtract(const Duration(days: 5)),
          status: ChequeStatus.cleared,
        ),
        // Bounced
        Cheque(
          id: '5',
          shopId: 's1',
          chequeNumber: '5',
          type: ChequeType.received,
          amount: 75000.0,
          issueDate: today.subtract(const Duration(days: 4)),
          dueDate: today.subtract(const Duration(days: 2)),
          status: ChequeStatus.bounced,
          bounceReason: 'Insufficient Funds',
        ),
        // Issued cheque
        Cheque(
          id: '6',
          shopId: 's1',
          chequeNumber: '6',
          type: ChequeType.issued,
          amount: 120000.0,
          issueDate: today,
          dueDate: today.add(const Duration(days: 3)),
          status: ChequeStatus.inHand,
        ),
      ];

      final summary = ChequeSummary.fromCheques(list);

      expect(summary.totalCount, 6);
      expect(summary.inHandCount, 3); // items 1, 2, 6
      expect(summary.inHandAmount, 470000.0); // 200k + 150k + 120k
      expect(summary.dueTodayCount, 1); // item 2
      expect(summary.dueTodayAmount, 150000.0);
      expect(summary.depositedCount, 1);
      expect(summary.depositedAmount, 300000.0);
      expect(summary.clearedCount, 1);
      expect(summary.clearedAmount, 500000.0);
      expect(summary.bouncedCount, 1);
      expect(summary.bouncedAmount, 75000.0);
      expect(summary.totalReceivedAmount, 1225000.0);
      expect(summary.totalIssuedAmount, 120000.0);
    });

    test('generates Cheque Register PDF bytes successfully without error',
        () async {
      final now = DateTime.now();
      final cheques = [
        Cheque(
          id: '1',
          shopId: 's1',
          chequeNumber: 'CHQ-8901',
          type: ChequeType.received,
          partyName: 'Haji Rafiq & Sons',
          bankName: 'Meezan Bank',
          targetBankAccountName: 'HBL Mandi Branch',
          amount: 350000.0,
          issueDate: now,
          dueDate: now.add(const Duration(days: 7)),
          status: ChequeStatus.inHand,
        ),
        Cheque(
          id: '2',
          shopId: 's1',
          chequeNumber: 'CHQ-8902',
          type: ChequeType.received,
          partyName: 'Chaudhry Akram',
          bankName: 'MCB Bank',
          targetBankAccountName: 'Meezan A/C',
          amount: 180000.0,
          issueDate: now,
          dueDate: now,
          status: ChequeStatus.cleared,
        ),
      ];

      final accounts = [
        const BankAccount(
          id: 'b1',
          shopId: 's1',
          bankName: 'Meezan Bank',
          accountTitle: 'Al-Madina Commission',
          currentBalance: 530000.0,
        ),
      ];

      final pdfBytes = await ChequeRegisterPdfGenerator.generateRegisterPdf(
        shopName: 'Al-Madina Commission Shop',
        cheques: cheques,
        bankAccounts: accounts,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
