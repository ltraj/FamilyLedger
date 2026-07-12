import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/transaction_aggregator.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _transaction({
  required int id,
  required int personId,
  int? categoryId,
  double amount = 100,
  TransactionType type = TransactionType.advanceReceived,
  required DateTime date,
}) {
  return TransactionModel(
    id: id,
    personId: personId,
    amount: amount,
    transactionType: type,
    categoryId: categoryId,
    date: date,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('TransactionAggregator.groupByPerson', () {
    test('partitions transactions by personId, preserving order', () {
      final t1 = _transaction(id: 1, personId: 1, date: DateTime(2026, 1, 1));
      final t2 = _transaction(id: 2, personId: 2, date: DateTime(2026, 1, 2));
      final t3 = _transaction(id: 3, personId: 1, date: DateTime(2026, 1, 3));

      final grouped = TransactionAggregator.groupByPerson([t1, t2, t3]);

      expect(grouped[1], [t1, t3]);
      expect(grouped[2], [t2]);
    });

    test('returns an empty map for an empty list', () {
      expect(TransactionAggregator.groupByPerson(const []), isEmpty);
    });
  });

  group('TransactionAggregator.filterByDateRange', () {
    test('includes transactions exactly on the boundary dates', () {
      final inRangeStart = _transaction(
        id: 1,
        personId: 1,
        date: DateTime(2026, 3, 1),
      );
      final inRangeEnd = _transaction(
        id: 2,
        personId: 1,
        date: DateTime(2026, 3, 31, 23, 59, 59, 999),
      );
      final beforeRange = _transaction(
        id: 3,
        personId: 1,
        date: DateTime(2026, 2, 28),
      );
      final afterRange = _transaction(
        id: 4,
        personId: 1,
        date: DateTime(2026, 4, 1),
      );

      final result = TransactionAggregator.filterByDateRange(
        [inRangeStart, inRangeEnd, beforeRange, afterRange],
        from: DateTime(2026, 3, 1),
        to: DateTime(2026, 3, 31, 23, 59, 59, 999),
      );

      expect(result, [inRangeStart, inRangeEnd]);
    });
  });

  group('TransactionAggregator.runningBalancesById', () {
    test('computes running balance per person independently', () {
      // Newest-first, matching repository order.
      final transactions = [
        _transaction(
          id: 3,
          personId: 1,
          amount: 50,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 3),
        ),
        _transaction(
          id: 2,
          personId: 2,
          amount: 200,
          date: DateTime(2026, 1, 2),
        ),
        _transaction(
          id: 1,
          personId: 1,
          amount: 500,
          date: DateTime(2026, 1, 1),
        ),
      ];

      final balances = TransactionAggregator.runningBalancesById(transactions);

      expect(balances[1], 500); // person 1, first transaction
      expect(balances[3], 450); // person 1, after the expense
      expect(balances[2], 200); // person 2, unaffected by person 1
    });

    test('honors the personIds filter, computing only for requested people', () {
      final transactions = [
        _transaction(id: 1, personId: 1, amount: 500, date: DateTime(2026, 1, 1)),
        _transaction(id: 2, personId: 2, amount: 200, date: DateTime(2026, 1, 2)),
      ];

      final balances = TransactionAggregator.runningBalancesById(
        transactions,
        personIds: {1},
      );

      expect(balances.containsKey(1), isTrue);
      expect(balances.containsKey(2), isFalse);
    });

    test('is empty for an empty transaction list', () {
      expect(TransactionAggregator.runningBalancesById(const []), isEmpty);
    });
  });

  group('TransactionAggregator.mostFrequentKey', () {
    test('returns the key that appears most often', () {
      final transactions = [
        _transaction(id: 1, personId: 1, date: DateTime(2026, 1, 1)),
        _transaction(id: 2, personId: 2, date: DateTime(2026, 1, 1)),
        _transaction(id: 3, personId: 1, date: DateTime(2026, 1, 1)),
      ];

      final result = TransactionAggregator.mostFrequentKey(
        transactions,
        (t) => t.personId,
      );

      expect(result, 1);
    });

    test('ignores null keys', () {
      final transactions = [
        _transaction(id: 1, personId: 1, categoryId: null, date: DateTime(2026, 1, 1)),
        _transaction(id: 2, personId: 1, categoryId: null, date: DateTime(2026, 1, 1)),
        _transaction(id: 3, personId: 1, categoryId: 5, date: DateTime(2026, 1, 1)),
      ];

      final result = TransactionAggregator.mostFrequentKey(
        transactions,
        (t) => t.categoryId,
      );

      expect(result, 5);
    });

    test('returns null for an empty list', () {
      final result = TransactionAggregator.mostFrequentKey<TransactionModel, int>(
        const [],
        (t) => t.personId,
      );

      expect(result, isNull);
    });
  });
}
