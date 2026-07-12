import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/dashboard/utils/dashboard_aggregator.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/attention_item.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:flutter_test/flutter_test.dart';

PersonSummary _personSummary({
  required int id,
  required String name,
  PersonType type = PersonType.permanent,
  PersonStatus status = PersonStatus.active,
  double balance = 0,
  int transactionCount = 0,
  DateTime? lastTransactionDate,
}) {
  final now = DateTime(2026, 1, 1);
  return PersonSummary(
    person: PersonModel(
      id: id,
      name: name,
      type: type,
      status: status,
      createdAt: now,
      updatedAt: now,
    ),
    balance: balance,
    transactionCount: transactionCount,
    lastTransactionDate: lastTransactionDate,
  );
}

TransactionModel _transaction({
  required int id,
  required int personId,
  double amount = 100,
  TransactionType type = TransactionType.advanceReceived,
  int? categoryId,
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

CategoryModel _category({required int id, required String name}) {
  return CategoryModel(
    id: id,
    name: name,
    icon: 'category',
    color: '#000000',
    isDefault: false,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('DashboardAggregator', () {
    test('sums positive balances into totalAdvanceHeld and negative into totalOwedToMe', () {
      final people = [
        _personSummary(id: 1, name: 'A', balance: 5000),
        _personSummary(id: 2, name: 'B', balance: -800),
        _personSummary(id: 3, name: 'C', balance: 300),
        _personSummary(id: 4, name: 'D', balance: -200),
      ];

      final summary = DashboardAggregator.assemble(
        peopleSummaries: people,
        transactionsNewestFirst: const [],
        categories: const [],
        now: DateTime(2026, 7, 15),
      );

      expect(summary.totalAdvanceHeld, 5300);
      expect(summary.totalOwedToMe, 1000);
      expect(summary.netPosition, 4300);
    });

    test('excludes archived people from totals and the people list', () {
      final people = [
        _personSummary(id: 1, name: 'Active', balance: 1000),
        _personSummary(
          id: 2,
          name: 'Archived',
          status: PersonStatus.archived,
          balance: 5000,
        ),
      ];

      final summary = DashboardAggregator.assemble(
        peopleSummaries: people,
        transactionsNewestFirst: const [],
        categories: const [],
        now: DateTime(2026, 7, 15),
      );

      expect(summary.people, hasLength(1));
      expect(summary.people.single.person.name, 'Active');
      expect(summary.totalAdvanceHeld, 1000);
      expect(summary.activePersonCount, 1);
    });

    test(
        'thisMonthExpenses only counts expensePaid transactions dated in the current month',
        () {
      final transactions = [
        _transaction(
          id: 1,
          personId: 1,
          amount: 500,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 7, 1),
        ),
        _transaction(
          id: 2,
          personId: 1,
          amount: 300,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 6, 30),
        ),
        _transaction(
          id: 3,
          personId: 1,
          amount: 1000,
          type: TransactionType.advanceReceived,
          date: DateTime(2026, 7, 5),
        ),
      ];

      final summary = DashboardAggregator.assemble(
        peopleSummaries: [_personSummary(id: 1, name: 'A')],
        transactionsNewestFirst: transactions,
        categories: const [],
        now: DateTime(2026, 7, 15),
      );

      expect(summary.thisMonthExpenses, 500);
    });

    test('assigns at most one attention reason per person, in priority order', () {
      final people = [
        _personSummary(
          id: 1,
          name: 'Negative',
          type: PersonType.temporary,
          balance: -100,
        ),
        _personSummary(id: 2, name: 'LowAdvance', balance: 200),
        _personSummary(
          id: 3,
          name: 'TemporaryPending',
          type: PersonType.temporary,
          balance: 800,
        ),
        _personSummary(id: 4, name: 'Fine', balance: 800),
        _personSummary(
          id: 5,
          name: 'ZeroTemporary',
          type: PersonType.temporary,
        ),
      ];

      final summary = DashboardAggregator.assemble(
        peopleSummaries: people,
        transactionsNewestFirst: const [],
        categories: const [],
        now: DateTime(2026, 7, 15),
      );

      expect(summary.attentionItems, hasLength(3));
      expect(
        summary.attentionItems.map((item) => item.personSummary.person.name),
        ['Negative', 'LowAdvance', 'TemporaryPending'],
      );
      expect(summary.attentionItems[0].reason, AttentionReason.negativeBalance);
      expect(
        summary.attentionItems[1].reason,
        AttentionReason.lowRemainingAdvance,
      );
      expect(
        summary.attentionItems[2].reason,
        AttentionReason.temporaryPersonPending,
      );
    });

    test(
        'recent activity is limited to the 10 newest transactions, with correct running balance',
        () {
      final chronological = [
        for (var i = 0; i < 12; i++)
          _transaction(
            id: i + 1,
            personId: 1,
            amount: 100,
            date: DateTime(2026, 1, 1 + i),
          ),
      ];
      final newestFirst = chronological.reversed.toList();

      final summary = DashboardAggregator.assemble(
        peopleSummaries: [_personSummary(id: 1, name: 'A')],
        transactionsNewestFirst: newestFirst,
        categories: const [],
        now: DateTime(2026, 7, 15),
      );

      expect(summary.recentActivity, hasLength(10));
      expect(summary.recentActivity.first.transaction.id, 12);
      expect(summary.recentActivity.first.runningBalanceAfter, 1200);
      expect(summary.recentActivity.last.transaction.id, 3);
      expect(summary.recentActivity.last.runningBalanceAfter, 300);
    });

    test('insights identify the right person, category, and transaction', () {
      final now = DateTime(2026, 7, 15);
      final people = [
        _personSummary(id: 1, name: 'Highest', balance: 5000),
        _personSummary(id: 2, name: 'MostOwing', balance: -2000),
        _personSummary(id: 3, name: 'Other', balance: 100),
      ];

      final wifi = _category(id: 10, name: 'WiFi');
      final food = _category(id: 11, name: 'Food');

      final transactions = [
        _transaction(
          id: 1,
          personId: 3,
          amount: 50,
          type: TransactionType.expensePaid,
          categoryId: wifi.id,
          date: DateTime(2026, 7, 1),
        ),
        _transaction(
          id: 2,
          personId: 3,
          amount: 60,
          type: TransactionType.expensePaid,
          categoryId: wifi.id,
          date: DateTime(2026, 7, 2),
        ),
        _transaction(
          id: 3,
          personId: 3,
          amount: 900,
          type: TransactionType.expensePaid,
          categoryId: food.id,
          date: DateTime(2026, 7, 3),
        ),
        _transaction(
          id: 4,
          personId: 1,
          amount: 200,
          categoryId: wifi.id,
          date: DateTime(2026, 7, 4),
        ),
      ];

      final summary = DashboardAggregator.assemble(
        peopleSummaries: people,
        transactionsNewestFirst: transactions.reversed.toList(),
        categories: [wifi, food],
        now: now,
      );

      expect(summary.highestAdvancePerson?.person.name, 'Highest');
      expect(summary.mostOwingPerson?.person.name, 'MostOwing');
      expect(summary.mostActivePersonThisMonth?.person.name, 'Other');
      expect(summary.mostUsedCategory?.name, 'WiFi');
      expect(summary.largestExpenseThisMonth?.transaction.id, 3);
      expect(summary.largestExpenseThisMonth?.transaction.amount, 900);
    });

    test('returns a zeroed-out summary for no people and no transactions', () {
      final summary = DashboardAggregator.assemble(
        peopleSummaries: const [],
        transactionsNewestFirst: const [],
        categories: const [],
        now: DateTime(2026, 7, 15),
      );

      expect(summary.totalAdvanceHeld, 0);
      expect(summary.totalOwedToMe, 0);
      expect(summary.netPosition, 0);
      expect(summary.activePersonCount, 0);
      expect(summary.thisMonthExpenses, 0);
      expect(summary.people, isEmpty);
      expect(summary.attentionItems, isEmpty);
      expect(summary.recentActivity, isEmpty);
      expect(summary.highestAdvancePerson, isNull);
      expect(summary.mostOwingPerson, isNull);
      expect(summary.mostActivePersonThisMonth, isNull);
      expect(summary.mostUsedCategory, isNull);
      expect(summary.largestExpenseThisMonth, isNull);
    });
  });
}
