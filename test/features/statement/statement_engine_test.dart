import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/statement/models/statement_period.dart';
import 'package:family_ledger/features/statement/utils/statement_engine.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/statement/person_statement.dart';
import 'package:family_ledger/projections/statement/statement_line_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 7, 1);

  final nani = PersonModel(
    id: 1,
    name: 'Nani',
    type: PersonType.permanent,
    status: PersonStatus.active,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  final electricity = CategoryModel(
    id: 10,
    name: 'Electricity',
    icon: 'bolt',
    color: '#FF9800',
    isDefault: true,
    createdAt: createdAt,
  );
  final recharge = CategoryModel(
    id: 11,
    name: 'Recharge',
    icon: 'phone',
    color: '#2196F3',
    isDefault: true,
    createdAt: createdAt,
  );
  final categories = [electricity, recharge];

  var nextId = 0;
  TransactionModel transaction({
    required double amount,
    required TransactionType type,
    int? categoryId,
    String? remark,
    required DateTime date,
  }) {
    return TransactionModel(
      id: ++nextId,
      personId: nani.id!,
      amount: amount,
      transactionType: type,
      categoryId: categoryId,
      remark: remark,
      date: date,
      createdAt: date,
      updatedAt: date,
    );
  }

  final july = StatementPeriod(year: 2026, month: 7);

  group('StatementEngine.build', () {
    test('positive balance: gave more than spent', () {
      final transactions = [
        transaction(
          amount: 9000,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 7, 9),
        ),
        transaction(
          amount: 500,
          type: TransactionType.expensePaid,
          categoryId: electricity.id,
          date: DateTime(2026, 7, 10),
        ),
        transaction(
          amount: 200,
          type: TransactionType.expensePaid,
          categoryId: recharge.id,
          date: DateTime(2026, 7, 12),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      expect(statement.gaveLine, 'You gave me ₹9,000.00 on 9 Jul 2026.');
      expect(
        statement.spentLine,
        'I spent ₹700.00 for you: ₹500.00 on electricity, ₹200.00 on recharge.',
      );
      expect(statement.balanceLine, '₹8,300.00 is still with me.');
      expect(statement.balanceStatus, BalanceStatus.positive);
      expect(statement.periodLabel, 'July 2026');
      expect(statement.items, hasLength(3));
    });

    test('negative balance: spent more than given ("you owe me")', () {
      final transactions = [
        transaction(
          amount: 500,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 7, 3),
        ),
        transaction(
          amount: 1500,
          type: TransactionType.expensePaid,
          categoryId: electricity.id,
          date: DateTime(2026, 7, 5),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      expect(statement.balanceLine, 'You owe me ₹1,000.00.');
      expect(statement.balanceStatus, BalanceStatus.negative);
    });

    test('exactly settled', () {
      final transactions = [
        transaction(
          amount: 1000,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 7, 3),
        ),
        transaction(
          amount: 1000,
          type: TransactionType.expensePaid,
          categoryId: electricity.id,
          date: DateTime(2026, 7, 5),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      expect(statement.balanceLine, "We're all settled up.");
      expect(statement.balanceStatus, BalanceStatus.settled);
    });

    test('multi-category spent breakdown is sorted largest first', () {
      final transactions = [
        transaction(
          amount: 5000,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 7, 1),
        ),
        transaction(
          amount: 200,
          type: TransactionType.expensePaid,
          categoryId: recharge.id,
          date: DateTime(2026, 7, 2),
        ),
        transaction(
          amount: 900,
          type: TransactionType.expensePaid,
          categoryId: electricity.id,
          date: DateTime(2026, 7, 3),
        ),
        // Uncategorized expense falls into a plain "other" bucket.
        transaction(
          amount: 300,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 7, 4),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      expect(
        statement.spentLine,
        'I spent ₹1,400.00 for you: ₹900.00 on electricity, '
        '₹300.00 on other, ₹200.00 on recharge.',
      );
    });

    test('gives but no spends: spentLine is null', () {
      final transactions = [
        transaction(
          amount: 2000,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 7, 9),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      expect(statement.gaveLine, 'You gave me ₹2,000.00 on 9 Jul 2026.');
      expect(statement.spentLine, isNull);
      expect(statement.balanceLine, '₹2,000.00 is still with me.');
    });

    test('several gives in the period are described as "across N payments"', () {
      final transactions = [
        transaction(
          amount: 1000,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 7, 1),
        ),
        transaction(
          amount: 2000,
          type: TransactionType.moneyReturned,
          date: DateTime(2026, 7, 15),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      expect(statement.gaveLine, 'You gave me ₹3,000.00 across 2 payments.');
    });

    test(
      'outgoing adjustment (e.g. a transfer) folds into the spent line '
      'in plain words, never as "adjustment"',
      () {
        final transactions = [
          transaction(
            amount: 500,
            type: TransactionType.expensePaid,
            categoryId: electricity.id,
            date: DateTime(2026, 7, 2),
          ),
          transaction(
            amount: -9000,
            type: TransactionType.adjustment,
            remark: 'Transfer to Ajit',
            date: DateTime(2026, 7, 20),
          ),
        ];

        final statement = StatementEngine.build(
          person: nani,
          transactions: transactions,
          period: july,
          categories: categories,
        );

        expect(
          statement.spentLine,
          'I spent ₹9,500.00 for you: ₹500.00 on electricity, '
          'including ₹9,000.00 sent to Ajit.',
        );
        expect(statement.spentLine, isNot(contains('adjustment')));
        expect(statement.spentLine, isNot(contains('-')));

        final adjustmentItem = statement.items.firstWhere(
          (item) => item.description.contains('Ajit'),
        );
        expect(adjustmentItem.description, 'Sent to Ajit');
        expect(adjustmentItem.amount, 9000);
        expect(adjustmentItem.direction, StatementDirection.spent);
      },
    );

    test('incoming adjustment folds into the gave line in plain words', () {
      final transactions = [
        transaction(
          amount: 100,
          type: TransactionType.adjustment,
          remark: 'Transfer from Ajit',
          date: DateTime(2026, 7, 6),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      expect(
        statement.gaveLine,
        'You gave me ₹100.00, including ₹100.00 from Ajit.',
      );
    });

    test('adjustment with no remark falls back to a jargon-free phrase', () {
      final transactions = [
        transaction(
          amount: -50,
          type: TransactionType.adjustment,
          date: DateTime(2026, 7, 6),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      expect(statement.spentLine, 'I spent ₹50.00 for you: including ₹50.00 a correction.');
      expect(statement.spentLine, isNot(contains('adjustment')));
    });

    test('balance carried from before the period is reflected in the '
        'closing balance, not just this period\'s net change', () {
      final transactions = [
        // Balance of 1000 already held before July.
        transaction(
          amount: 1000,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 6, 1),
        ),
        transaction(
          amount: 200,
          type: TransactionType.expensePaid,
          categoryId: electricity.id,
          date: DateTime(2026, 7, 5),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      // This period alone: -200. Carried balance: 1000. Closing: 800.
      expect(statement.balanceLine, '₹800.00 is still with me.');
      // Nothing was given in July itself.
      expect(statement.gaveLine, isNull);
    });

    test('no activity in the period at all', () {
      final statement = StatementEngine.build(
        person: nani,
        transactions: const [],
        period: july,
        categories: categories,
      );

      expect(statement.gaveLine, isNull);
      expect(statement.spentLine, isNull);
      expect(statement.balanceLine, "We're all settled up.");
      expect(statement.items, isEmpty);
    });

    test('a line item with a remark carries it through', () {
      final transactions = [
        transaction(
          amount: 500,
          type: TransactionType.expensePaid,
          categoryId: electricity.id,
          remark: 'Paid via UPI',
          date: DateTime(2026, 7, 10),
        ),
      ];

      final statement = StatementEngine.build(
        person: nani,
        transactions: transactions,
        period: july,
        categories: categories,
      );

      final item = statement.items.single;
      expect(item.remark, 'Paid via UPI');
    });

    test(
      'a line item without a remark leaves it null, not a placeholder string',
      () {
        final transactions = [
          transaction(
            amount: 500,
            type: TransactionType.expensePaid,
            categoryId: electricity.id,
            date: DateTime(2026, 7, 10),
          ),
          // A blank/whitespace-only remark should also collapse to null.
          transaction(
            amount: 200,
            type: TransactionType.expensePaid,
            categoryId: recharge.id,
            remark: '   ',
            date: DateTime(2026, 7, 11),
          ),
        ];

        final statement = StatementEngine.build(
          person: nani,
          transactions: transactions,
          period: july,
          categories: categories,
        );

        expect(statement.items, hasLength(2));
        for (final item in statement.items) {
          expect(item.remark, isNull);
        }
      },
    );
  });
}
