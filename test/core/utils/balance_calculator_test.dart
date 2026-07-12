import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BalanceCalculator', () {
    test('calculates balance from transaction history', () {
      final transactions = [
        TransactionModel(
          personId: 1,
          amount: 5000,
          transactionType: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        TransactionModel(
          personId: 1,
          amount: 1500,
          transactionType: TransactionType.expensePaid,
          date: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
        TransactionModel(
          personId: 1,
          amount: 500,
          transactionType: TransactionType.moneyReturned,
          date: DateTime(2026, 1, 3),
          createdAt: DateTime(2026, 1, 3),
          updatedAt: DateTime(2026, 1, 3),
        ),
        TransactionModel(
          personId: 1,
          amount: -200,
          transactionType: TransactionType.adjustment,
          date: DateTime(2026, 1, 4),
          createdAt: DateTime(2026, 1, 4),
          updatedAt: DateTime(2026, 1, 4),
        ),
      ];

      // 5000 - 1500 + 500 - 200 = 3800
      expect(BalanceCalculator.calculateBalance(transactions), 3800);
    });

    test('negative balance when expenses exceed advance', () {
      final transactions = [
        TransactionModel(
          personId: 1,
          amount: 1000,
          transactionType: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        TransactionModel(
          personId: 1,
          amount: 2500,
          transactionType: TransactionType.expensePaid,
          date: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
      ];

      expect(BalanceCalculator.calculateBalance(transactions), -1500);
    });

    test('aggregates balances by person', () {
      final transactions = [
        TransactionModel(
          personId: 1,
          amount: 1000,
          transactionType: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        TransactionModel(
          personId: 2,
          amount: 500,
          transactionType: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        TransactionModel(
          personId: 1,
          amount: 300,
          transactionType: TransactionType.expensePaid,
          date: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
      ];

      final balances = BalanceCalculator.calculateBalancesByPerson(
        transactions,
      );

      expect(balances[1], 700);
      expect(balances[2], 500);
    });

    test('running balance accumulates chronologically, per the spec example', () {
      final transactions = [
        TransactionModel(
          personId: 1,
          amount: 5000,
          transactionType: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        TransactionModel(
          personId: 1,
          amount: 850,
          transactionType: TransactionType.expensePaid,
          date: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
        TransactionModel(
          personId: 1,
          amount: 300,
          transactionType: TransactionType.expensePaid,
          date: DateTime(2026, 1, 3),
          createdAt: DateTime(2026, 1, 3),
          updatedAt: DateTime(2026, 1, 3),
        ),
        TransactionModel(
          personId: 1,
          amount: 500,
          transactionType: TransactionType.moneyReturned,
          date: DateTime(2026, 1, 4),
          createdAt: DateTime(2026, 1, 4),
          updatedAt: DateTime(2026, 1, 4),
        ),
      ];

      expect(
        BalanceCalculator.runningBalances(transactions),
        [5000, 4150, 3850, 4350],
      );
    });

    test('running balance list is empty for an empty history', () {
      expect(BalanceCalculator.runningBalances(const []), isEmpty);
    });
  });
}
