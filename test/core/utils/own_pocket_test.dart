import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/core/utils/transaction_aggregator.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _transaction({
  required int id,
  int personId = 1,
  required double amount,
  required TransactionType type,
  required DateTime date,
}) {
  return TransactionModel(
    id: id,
    personId: personId,
    amount: amount,
    transactionType: type,
    date: date,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('BalanceCalculator.ownPocketPortions', () {
    test('an expense fully covered by advance contributes nothing', () {
      final portions = BalanceCalculator.ownPocketPortions([
        _transaction(
          id: 1,
          amount: 500,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
        ),
        _transaction(
          id: 2,
          amount: 200,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 2),
        ),
      ]);

      expect(portions, [0, 0]);
    });

    test('an expense larger than the balance contributes the uncovered part',
        () {
      final portions = BalanceCalculator.ownPocketPortions([
        _transaction(
          id: 1,
          amount: 300,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
        ),
        _transaction(
          id: 2,
          amount: 500,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 2),
        ),
      ]);

      expect(portions, [0, 200]);
    });

    test('with no advance left, the whole expense is own pocket', () {
      final portions = BalanceCalculator.ownPocketPortions([
        _transaction(
          id: 1,
          amount: 100,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 1),
        ),
        _transaction(
          id: 2,
          amount: 50,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 2),
        ),
      ]);

      expect(portions, [100, 50]);
    });

    test('non-expense transactions never contribute', () {
      final portions = BalanceCalculator.ownPocketPortions([
        _transaction(
          id: 1,
          amount: 100,
          type: TransactionType.moneyReturned,
          date: DateTime(2026, 1, 1),
        ),
        _transaction(
          id: 2,
          amount: -50,
          type: TransactionType.adjustment,
          date: DateTime(2026, 1, 2),
        ),
      ]);

      expect(portions, [0, 0]);
    });

    test('coverage tracks the running balance through mixed history', () {
      final portions = BalanceCalculator.ownPocketPortions([
        // Balance: 0 → 400
        _transaction(
          id: 1,
          amount: 400,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
        ),
        // 400 covers 300 fully. Balance → 100.
        _transaction(
          id: 2,
          amount: 300,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 2),
        ),
        // 100 available of 250 → 150 own pocket. Balance → -150.
        _transaction(
          id: 3,
          amount: 250,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 3),
        ),
        // Balance negative → fully own pocket.
        _transaction(
          id: 4,
          amount: 60,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 4),
        ),
      ]);

      expect(portions, [0, 0, 150, 60]);
    });
  });

  group('TransactionAggregator.ownPocketByTransactionId', () {
    test('computes per person independently over newest-first input', () {
      // Newest-first, two people interleaved.
      final transactions = [
        _transaction(
          id: 4,
          personId: 2,
          amount: 100,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 4),
        ),
        _transaction(
          id: 3,
          personId: 1,
          amount: 500,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 3),
        ),
        _transaction(
          id: 2,
          personId: 2,
          amount: 100,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 2),
        ),
        _transaction(
          id: 1,
          personId: 1,
          amount: 300,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
        ),
      ];

      final portions = TransactionAggregator.ownPocketByTransactionId(
        transactions,
      );

      // Person 1: 300 advance, then 500 expense → 200 own pocket.
      expect(portions[3], 200);
      // Person 2: 100 advance, then 100 expense → fully covered; zero
      // entries are omitted.
      expect(portions.containsKey(4), isFalse);
    });

    test('personIds bounds which people are computed', () {
      final transactions = [
        _transaction(
          id: 2,
          personId: 2,
          amount: 100,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 2),
        ),
        _transaction(
          id: 1,
          personId: 1,
          amount: 100,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 1),
        ),
      ];

      final portions = TransactionAggregator.ownPocketByTransactionId(
        transactions,
        personIds: {1},
      );

      expect(portions[1], 100);
      expect(portions.containsKey(2), isFalse);
    });
  });
}
