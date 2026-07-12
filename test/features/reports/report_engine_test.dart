import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/features/reports/models/report_date_preset.dart';
import 'package:family_ledger/features/reports/models/report_filter.dart';
import 'package:family_ledger/features/reports/utils/report_engine.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:family_ledger/projections/reports/category_report.dart';
import 'package:family_ledger/projections/reports/reports_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 15);

  final nani = PersonModel(
    id: 1,
    name: 'Nani',
    type: PersonType.permanent,
    status: PersonStatus.active,
    createdAt: now,
    updatedAt: now,
  );
  final sudha = PersonModel(
    id: 2,
    name: 'Sudha',
    type: PersonType.permanent,
    status: PersonStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  final electricity = CategoryModel(
    id: 10,
    name: 'Electricity',
    icon: 'bolt',
    color: '#FF9800',
    isDefault: true,
    createdAt: now,
  );
  final wifi = CategoryModel(
    id: 11,
    name: 'WiFi',
    icon: 'wifi',
    color: '#2196F3',
    isDefault: true,
    createdAt: now,
  );
  final groceries = CategoryModel(
    id: 12,
    name: 'Groceries',
    icon: 'cart',
    color: '#4CAF50',
    isDefault: true,
    createdAt: now,
  );
  final categories = [electricity, wifi, groceries];

  var nextId = 0;
  TransactionModel transaction({
    required int personId,
    required double amount,
    required TransactionType type,
    int? categoryId,
    String? remark,
    required DateTime date,
  }) {
    return TransactionModel(
      id: ++nextId,
      personId: personId,
      amount: amount,
      transactionType: type,
      categoryId: categoryId,
      remark: remark,
      date: date,
      createdAt: date,
      updatedAt: date,
    );
  }

  // Nani: 1000 advance (May), 400 electricity (May), 300 electricity
  // (June), 500 wifi (July) → last expense only partly covered (300
  // available → 200 own pocket). Balance: 1000-400-300-500 = -200.
  // Sudha: 600 advance (June), 100 groceries (June), 50 wifi (July),
  // 100 returned (July), uncategorized 80 expense (July).
  // Balance: 600-100-50+100-80 = 470.
  late List<TransactionModel> all;
  setUp(() {
    nextId = 0;
    final chronological = [
      transaction(
        personId: 1,
        amount: 1000,
        type: TransactionType.advanceReceived,
        date: DateTime(2026, 5, 1),
      ),
      transaction(
        personId: 1,
        amount: 400,
        type: TransactionType.expensePaid,
        categoryId: 10,
        remark: 'May power bill',
        date: DateTime(2026, 5, 20),
      ),
      transaction(
        personId: 1,
        amount: 300,
        type: TransactionType.expensePaid,
        categoryId: 10,
        date: DateTime(2026, 6, 18),
      ),
      transaction(
        personId: 2,
        amount: 600,
        type: TransactionType.advanceReceived,
        date: DateTime(2026, 6, 2),
      ),
      transaction(
        personId: 2,
        amount: 100,
        type: TransactionType.expensePaid,
        categoryId: 12,
        date: DateTime(2026, 6, 10),
      ),
      transaction(
        personId: 1,
        amount: 500,
        type: TransactionType.expensePaid,
        categoryId: 11,
        date: DateTime(2026, 7, 5),
      ),
      transaction(
        personId: 2,
        amount: 50,
        type: TransactionType.expensePaid,
        categoryId: 11,
        date: DateTime(2026, 7, 8),
      ),
      transaction(
        personId: 2,
        amount: 100,
        type: TransactionType.moneyReturned,
        date: DateTime(2026, 7, 10),
      ),
      transaction(
        personId: 2,
        amount: 80,
        type: TransactionType.expensePaid,
        date: DateTime(2026, 7, 12),
      ),
    ];
    all = chronological.reversed.toList(); // repository order: newest-first
  });

  List<PersonSummary> summaries() {
    final balances = BalanceCalculator.calculateBalancesByPerson(all);
    return [
      PersonSummary(
        person: nani,
        balance: balances[1] ?? 0,
        transactionCount: 4,
        lastTransactionDate: DateTime(2026, 7, 5),
      ),
      PersonSummary(
        person: sudha,
        balance: balances[2] ?? 0,
        transactionCount: 5,
        lastTransactionDate: DateTime(2026, 7, 12),
      ),
    ];
  }

  ReportsOverview build({ReportFilter filter = const ReportFilter()}) {
    return ReportEngine.buildOverview(
      allTransactionsNewestFirst: all,
      peopleSummaries: summaries(),
      categories: categories,
      filter: filter,
      now: now,
    );
  }

  group('ledger section', () {
    test('unfiltered totals cover every movement', () {
      final ledger = build().ledger;

      expect(ledger.totalAdvanceReceived, 1600);
      expect(ledger.totalExpenses, 400 + 300 + 100 + 500 + 50 + 80);
      expect(ledger.totalMoneyReturned, 100);
      expect(ledger.currentBalance, -200 + 470);
      expect(ledger.netPosition, closeTo(-200 + 470, 0.001));
      // Nani's July 500 had only 300 advance left → 200 own pocket.
      expect(ledger.ownPocketExpenses, 200);
    });

    test('date filter changes period figures but not current balance', () {
      final ledger = build(
        filter: const ReportFilter(datePreset: ReportDatePreset.thisMonth),
      ).ledger;

      expect(ledger.totalExpenses, 500 + 50 + 80); // July only
      expect(ledger.totalAdvanceReceived, 0);
      expect(ledger.totalMoneyReturned, 100);
      expect(ledger.netPosition, closeTo(-500 - 50 + 100 - 80, 0.001));
      // Point-in-time fact — unchanged by the date filter.
      expect(ledger.currentBalance, 270);
    });

    test('person filter narrows current balance to that person', () {
      final ledger = build(filter: const ReportFilter(personId: 1)).ledger;

      expect(ledger.currentBalance, -200);
      expect(ledger.totalAdvanceReceived, 1000);
    });

    test('own pocket portions stay correct under a date filter', () {
      // July only: the 500 expense still knows it had 300 of advance
      // cover, because portions are computed over full history.
      final ledger = build(
        filter: const ReportFilter(datePreset: ReportDatePreset.thisMonth),
      ).ledger;

      expect(ledger.ownPocketExpenses, 200);
    });
  });

  group('person analysis section', () {
    test('builds one report per person with correct figures', () {
      final reports = build().personReports;

      expect(reports, hasLength(2));
      // Sudha has 5 transactions, Nani 4 → most active first.
      expect(reports.first.person.name, 'Sudha');

      final naniReport = reports[1];
      expect(naniReport.currentBalance, -200);
      expect(naniReport.advanceReceived, 1000);
      expect(naniReport.expenses, 1200);
      expect(naniReport.largestExpense, 500);
      expect(naniReport.largestAdvance, 1000);
      expect(naniReport.transactionCount, 4);
      expect(naniReport.firstTransactionDate, DateTime(2026, 5, 1));
      expect(naniReport.latestTransactionDate, DateTime(2026, 7, 5));
      expect(
        naniReport.averageTransaction,
        closeTo((1000 + 400 + 300 + 500) / 4, 0.001),
      );
    });

    test('only people with filtered transactions appear', () {
      final reports = build(
        filter: const ReportFilter(categoryId: 12),
      ).personReports;

      expect(reports, hasLength(1));
      expect(reports.single.person.name, 'Sudha');
    });
  });

  group('category analysis section', () {
    test('groups by category with an uncategorized bucket', () {
      final reports = build().categoryReports;

      // Electricity, WiFi, Groceries, and two uncategorized buckets'
      // worth of advances/returns... all uncategorized fall into one
      // null bucket.
      final names = [
        for (final report in reports) report.category?.name ?? 'none',
      ];
      expect(names, contains('Electricity'));
      expect(names, contains('WiFi'));
      expect(names, contains('Groceries'));
      expect(names, contains('none'));

      final electricityReport = reports.firstWhere(
        (report) => report.category?.name == 'Electricity',
      );
      expect(electricityReport.total, 700);
      expect(electricityReport.expenseTotal, 700);
      expect(electricityReport.transactionCount, 2);
      expect(electricityReport.largest, 400);
      expect(electricityReport.smallest, 300);
      expect(electricityReport.mostRecentDate, DateTime(2026, 6, 18));
      expect(electricityReport.average, 350);
    });

    test('uncategorized bucket separates expenses from other movements', () {
      final reports = build().categoryReports;
      final uncategorized = reports.firstWhere(
        (report) => report.category == null,
      );

      // 1000 + 600 advances, 100 returned, 80 expense — total magnitude.
      expect(uncategorized.total, 1780);
      // But only the 80 was actual spending.
      expect(uncategorized.expenseTotal, 80);
    });

    test('sortCategoryReports orders by amount, frequency, alphabetical', () {
      final reports = build().categoryReports;

      final byAmount = ReportEngine.sortCategoryReports(
        reports,
        CategoryReportSort.amount,
      );
      expect(byAmount.first.total, 1780);

      final byFrequency = ReportEngine.sortCategoryReports(
        reports,
        CategoryReportSort.frequency,
      );
      // Uncategorized: two advances + one return + one expense.
      expect(byFrequency.first.transactionCount, 4);
      expect(byFrequency.first.category, isNull);

      final alphabetical = ReportEngine.sortCategoryReports(
        reports,
        CategoryReportSort.alphabetical,
      );
      expect(alphabetical.first.category?.name, 'Electricity');
      expect(alphabetical.last.category, isNull); // "no category" last
    });
  });

  group('monthly analysis section', () {
    test('one row per month, oldest first, with cumulative running balance',
        () {
      final months = build().monthlyReports;

      expect(months, hasLength(3));
      expect(months[0].month, DateTime(2026, 5));
      expect(months[1].month, DateTime(2026, 6));
      expect(months[2].month, DateTime(2026, 7));

      expect(months[0].advances, 1000);
      expect(months[0].expenses, 400);
      expect(months[0].netChange, 600);
      expect(months[0].runningBalance, 600);

      expect(months[1].advances, 600);
      expect(months[1].expenses, 400);
      expect(months[1].netChange, 200);
      expect(months[1].runningBalance, 800);

      expect(months[2].expenses, 630);
      expect(months[2].moneyReturned, 100);
      expect(months[2].netChange, closeTo(-530, 0.001));
      expect(months[2].runningBalance, closeTo(270, 0.001));
    });
  });

  group('top lists section', () {
    test('finds the extremes of the filtered period', () {
      final topLists = build().topLists;

      expect(topLists.highestExpense?.transaction.amount, 500);
      expect(topLists.highestAdvance?.transaction.amount, 1000);
      expect(topLists.largestTransaction?.transaction.amount, 1000);
      expect(topLists.mostActivePerson?.person.name, 'Sudha');
      expect(topLists.mostActivePerson?.transactionCount, 5);
      // Electricity and WiFi are tied at 2 uses; ties resolve to the
      // first key encountered in newest-first order, which is WiFi
      // (July 8) — deterministic, documented on mostFrequentKey.
      expect(topLists.mostUsedCategory?.category.name, 'WiFi');
      expect(topLists.mostUsedCategory?.transactionCount, 2);
      expect(topLists.largestExpenseMonth?.month, DateTime(2026, 7));
    });

    test('is all-null for an empty filtered set', () {
      final topLists = build(
        filter: const ReportFilter(searchText: 'zzz-no-match'),
      ).topLists;

      expect(topLists.highestExpense, isNull);
      expect(topLists.highestAdvance, isNull);
      expect(topLists.largestTransaction, isNull);
      expect(topLists.mostActivePerson, isNull);
      expect(topLists.mostUsedCategory, isNull);
      expect(topLists.largestExpenseMonth, isNull);
    });
  });

  group('own pocket section', () {
    test('breaks the total down by month, person, and category', () {
      final ownPocket = build().ownPocket;

      expect(ownPocket.total, 200);
      expect(ownPocket.monthly.single.month, DateTime(2026, 7));
      expect(ownPocket.monthly.single.value, 200);
      expect(ownPocket.perPerson.single.person.name, 'Nani');
      expect(ownPocket.perCategory.single.category?.name, 'WiFi');
    });

    test('reports empty when advances covered everything', () {
      final ownPocket = build(
        filter: const ReportFilter(personId: 2),
      ).ownPocket;

      expect(ownPocket.isEmpty, isTrue);
      expect(ownPocket.perPerson, isEmpty);
    });
  });

  group('spending trends (derived series)', () {
    test('monthly series mirror the monthly reports', () {
      final overview = build();

      expect(
        [for (final point in overview.monthlyExpensesTrend) point.value],
        [400, 400, 630],
      );
      expect(
        [for (final point in overview.monthlyAdvancesTrend) point.value],
        [1000, 600, 0],
      );
    });

    test('category spending is expense-only, largest first', () {
      final spending = build().categorySpending;

      expect(spending.first.category?.name, 'Electricity');
      expect(spending.first.amount, 700);
      // The uncategorized bucket contributes only its 80 expense, not
      // the 1600 of advances that share the null category.
      final uncategorized = spending.firstWhere(
        (item) => item.category == null,
      );
      expect(uncategorized.amount, 80);
    });
  });

  group('insights section', () {
    test('states top spending category and most active person', () {
      final messages = [for (final i in build().insights) i.message];

      expect(
        messages,
        contains('Most spending is on Electricity (₹700.00).'),
      );
      expect(
        messages,
        contains('Most active person overall is Sudha (5 transactions).'),
      );
      expect(
        messages,
        contains('₹200.00 of expenses came from your own pocket, beyond '
            'advances.'),
      );
    });

    test('third-highest category insight requires three spending categories',
        () {
      final messages = [for (final i in build().insights) i.message];
      // Electricity 700, WiFi 550, Groceries 100, uncategorized (80,
      // excluded — no name to state). Third = Groceries.
      expect(
        messages,
        contains('Groceries is the third highest expense category.'),
      );

      // With only one person's electricity spending, no third category.
      final filtered = build(filter: const ReportFilter(categoryId: 10));
      final filteredMessages = [
        for (final i in filtered.insights) i.message,
      ];
      expect(
        filteredMessages.any((m) => m.contains('third highest')),
        isFalse,
      );
    });

    test('most-active insight is skipped when only one person is in view',
        () {
      final messages = [
        for (final i in build(filter: const ReportFilter(personId: 1)).insights)
          i.message,
      ];
      expect(messages.any((m) => m.contains('Most active')), isFalse);
    });

    test('balance insight states direction from the current balance', () {
      final holding = build(filter: const ReportFilter(personId: 2));
      expect(
        [for (final i in holding.insights) i.message],
        contains('You are currently holding ₹470.00 in advances.'),
      );

      final owed = build(filter: const ReportFilter(personId: 1));
      expect(
        [for (final i in owed.insights) i.message],
        contains('You are currently owed ₹200.00 overall.'),
      );
    });

    test('no insights are invented for an empty filtered set', () {
      final overview = build(
        filter: const ReportFilter(searchText: 'zzz-no-match'),
      );
      // The only permissible statement is the point-in-time balance one.
      for (final insight in overview.insights) {
        expect(insight.message, contains('currently'));
      }
    });
  });

  group('person detail report', () {
    test('computes trend, usage, tops, and averages from full history', () {
      final naniTransactions = [
        for (final transaction in all)
          if (transaction.personId == 1) transaction,
      ];

      final detail = ReportEngine.buildPersonDetail(
        person: nani,
        personTransactionsNewestFirst: naniTransactions,
        categories: categories,
      );

      expect(detail.currentBalance, -200);
      expect(detail.totalExpenses, 1200);
      expect(detail.averageMonthlyExpense, 400); // 1200 over 3 months
      expect(detail.monthlySpendingTrend, hasLength(3)); // May, Jun, Jul
      expect(detail.categoryUsage.first.category?.name, 'Electricity');
      expect(detail.largestExpenses.first.transaction.amount, 500);
      expect(detail.largestAdvances.single.transaction.amount, 1000);
      expect(detail.timeline.first.transaction.date, DateTime(2026, 7, 5));
      expect(detail.isEmpty, isFalse);
    });

    test('fills zero months into the spending trend', () {
      final gappy = [
        transaction(
          personId: 1,
          amount: 100,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 1, 10),
        ),
        transaction(
          personId: 1,
          amount: 200,
          type: TransactionType.expensePaid,
          date: DateTime(2026, 4, 10),
        ),
      ].reversed.toList();

      final detail = ReportEngine.buildPersonDetail(
        person: nani,
        personTransactionsNewestFirst: gappy,
        categories: categories,
      );

      expect(detail.monthlySpendingTrend, hasLength(4)); // Jan–Apr
      expect(detail.monthlySpendingTrend[1].value, 0); // Feb
      expect(detail.monthlySpendingTrend[2].value, 0); // Mar
      // Zero months don't dilute the average: 300 / 2 spending months.
      expect(detail.averageMonthlyExpense, 150);
    });
  });

  group('performance', () {
    test('handles a large dataset in one engine pass quickly', () {
      final large = <TransactionModel>[];
      var id = 100000;
      for (var i = 0; i < 20000; i++) {
        final date = DateTime(2024, 1 + (i ~/ 900), 1 + (i % 28));
        large.add(
          TransactionModel(
            id: ++id,
            personId: 1 + (i % 2),
            amount: (i % 500) + 1,
            transactionType:
                TransactionType.values[i % TransactionType.values.length],
            categoryId: i % 3 == 0 ? null : 10 + (i % 3),
            date: date,
            createdAt: date,
            updatedAt: date,
          ),
        );
      }
      large.sort((a, b) => b.date.compareTo(a.date));

      final stopwatch = Stopwatch()..start();
      final overview = ReportEngine.buildOverview(
        allTransactionsNewestFirst: large,
        peopleSummaries: summaries(),
        categories: categories,
        filter: const ReportFilter(),
        now: now,
      );
      stopwatch.stop();

      expect(overview.filteredTransactionCount, 20000);
      // Generous bound: catches an accidental O(n²) (which would take
      // minutes here), not normal machine-speed variance.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });
}
