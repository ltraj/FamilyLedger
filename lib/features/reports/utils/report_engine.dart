import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/transaction_aggregator.dart';
import 'package:family_ledger/features/reports/models/report_date_preset.dart';
import 'package:family_ledger/features/reports/models/report_filter.dart';
import 'package:family_ledger/features/reports/utils/report_filter_engine.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:family_ledger/projections/reports/category_report.dart';
import 'package:family_ledger/projections/reports/ledger_report.dart';
import 'package:family_ledger/projections/reports/monthly_report.dart';
import 'package:family_ledger/projections/reports/own_pocket_report.dart';
import 'package:family_ledger/projections/reports/person_report.dart';
import 'package:family_ledger/projections/reports/person_report_detail.dart';
import 'package:family_ledger/projections/reports/report_breakdowns.dart';
import 'package:family_ledger/projections/reports/report_insight.dart';
import 'package:family_ledger/projections/reports/reports_overview.dart';
import 'package:family_ledger/projections/reports/top_lists_report.dart';
import 'package:family_ledger/projections/transaction_details.dart';

/// Computes every Reports section from raw transaction data — the
/// reports counterpart of `DashboardAggregator`, and like it a pure
/// function of its inputs: no Riverpod, no database, no widgets.
///
/// Design constraints it enforces:
///
/// - **One filter pass.** `ReportFilterEngine.apply` runs once per
///   rebuild; all eight sections are computed from that single list.
/// - **No duplicated calculation.** Grouping and per-transaction figures
///   come from `TransactionAggregator`/`BalanceCalculator`; sections that
///   need each other's numbers (top lists ← monthly, insights ← ledger/
///   categories) receive them instead of recomputing.
/// - **Bounded expensive work.** Running balances and own-pocket portions
///   are only computed for people actually present in the filtered data.
/// - **Nothing stored.** The output is a `ReportsOverview` projection,
///   rebuilt from scratch whenever data or filter changes.
abstract final class ReportEngine {
  /// How many top expenses/advances the person detail screen lists.
  static const int topTransactionsLimit = 5;

  /// How many recent transactions the person detail timeline shows.
  static const int timelineLimit = 30;

  /// The most insights Section 8 will state at once.
  static const int insightsLimit = 6;

  static ReportsOverview buildOverview({
    required List<TransactionModel> allTransactionsNewestFirst,
    required List<PersonSummary> peopleSummaries,
    required List<CategoryModel> categories,
    required ReportFilter filter,
    DateTime? now,
    String currencySymbol = AppConstants.defaultCurrencySymbol,
  }) {
    final currentTime = now ?? DateTime.now();

    final peopleById = <int, PersonModel>{
      for (final summary in peopleSummaries)
        if (summary.person.id != null) summary.person.id!: summary.person,
    };
    // Full-history balances, reused from PeopleViewModel's already-
    // computed summaries rather than re-derived here.
    final balancesByPersonId = <int, double>{
      for (final summary in peopleSummaries)
        if (summary.person.id != null) summary.person.id!: summary.balance,
    };
    final categoriesById = <int, CategoryModel>{
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };

    final filtered = ReportFilterEngine.apply(
      allTransactionsNewestFirst,
      filter: filter,
      peopleById: peopleById,
      categoriesById: categoriesById,
      now: currentTime,
    );

    final filteredByPerson = TransactionAggregator.groupByPerson(filtered);
    final filteredPersonIds = filteredByPerson.keys.toSet();

    final ownPocketById = TransactionAggregator.ownPocketByTransactionId(
      allTransactionsNewestFirst,
      personIds: filteredPersonIds,
    );

    final ledger = _buildLedger(
      filtered,
      filter: filter,
      balancesByPersonId: balancesByPersonId,
      ownPocketById: ownPocketById,
    );
    final personReports = _buildPersonReports(
      filteredByPerson,
      peopleById: peopleById,
      balancesByPersonId: balancesByPersonId,
    );
    final categoryReports = _buildCategoryReports(
      filtered,
      categoriesById: categoriesById,
    );
    final monthlyReports = _buildMonthlyReports(filtered);
    final topLists = _buildTopLists(
      filtered,
      allTransactionsNewestFirst: allTransactionsNewestFirst,
      filteredByPerson: filteredByPerson,
      monthlyReports: monthlyReports,
      peopleById: peopleById,
      categoriesById: categoriesById,
    );
    final ownPocket = _buildOwnPocket(
      filtered,
      ownPocketById: ownPocketById,
      peopleById: peopleById,
      categoriesById: categoriesById,
    );
    final insights = _buildInsights(
      filter: filter,
      ledger: ledger,
      personReports: personReports,
      categoryReports: categoryReports,
      monthlyReports: monthlyReports,
      topLists: topLists,
      currencySymbol: currencySymbol,
    );

    return ReportsOverview(
      ledger: ledger,
      personReports: personReports,
      categoryReports: categoryReports,
      monthlyReports: monthlyReports,
      topLists: topLists,
      ownPocket: ownPocket,
      insights: insights,
      filteredTransactionCount: filtered.length,
    );
  }

  /// Re-sorts Section 3 for the user's sort choice. Pure, so the section
  /// widget stays display-only. Ties (and the alphabetical placement of
  /// the null-category bucket) resolve to keep the list stable and the
  /// "no category" row last.
  static List<CategoryReport> sortCategoryReports(
    List<CategoryReport> reports,
    CategoryReportSort sort,
  ) {
    final sorted = [...reports];
    switch (sort) {
      case CategoryReportSort.amount:
        sorted.sort((a, b) => b.total.compareTo(a.total));
      case CategoryReportSort.frequency:
        sorted.sort((a, b) => b.transactionCount.compareTo(a.transactionCount));
      case CategoryReportSort.alphabetical:
        sorted.sort((a, b) {
          final aName = a.category?.name;
          final bName = b.category?.name;
          if (aName == null) return bName == null ? 0 : 1;
          if (bName == null) return -1;
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
    }
    return sorted;
  }

  /// Builds the per-person detail report from that person's full history.
  /// See `PersonReportDetail` for why the global filter deliberately does
  /// not apply here.
  static PersonReportDetail buildPersonDetail({
    required PersonModel person,
    required List<TransactionModel> personTransactionsNewestFirst,
    required List<CategoryModel> categories,
  }) {
    final categoriesById = <int, CategoryModel>{
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };

    final oldestFirst = personTransactionsNewestFirst.reversed.toList();
    final runningBalances = BalanceCalculator.runningBalances(oldestFirst);
    final runningBalanceById = <int, double>{
      for (var i = 0; i < oldestFirst.length; i++)
        if (oldestFirst[i].id != null) oldestFirst[i].id!: runningBalances[i],
    };

    TransactionDetails toDetails(TransactionModel transaction) =>
        TransactionDetails(
          transaction: transaction,
          person: person,
          category: transaction.categoryId == null
              ? null
              : categoriesById[transaction.categoryId],
          runningBalanceAfter: runningBalanceById[transaction.id] ?? 0,
        );

    final expenses = [
      for (final transaction in personTransactionsNewestFirst)
        if (transaction.transactionType == TransactionType.expensePaid)
          transaction,
    ];
    final advances = [
      for (final transaction in personTransactionsNewestFirst)
        if (transaction.transactionType == TransactionType.advanceReceived)
          transaction,
    ];

    final expensesByMonth = <DateTime, double>{};
    for (final expense in expenses) {
      final month = DateTime(expense.date.year, expense.date.month);
      expensesByMonth.update(
        month,
        (total) => total + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final totalExpenses = expensesByMonth.values.fold(0.0, (a, b) => a + b);

    final spendingByCategory = <int?, double>{};
    for (final expense in expenses) {
      spendingByCategory.update(
        expense.categoryId,
        (total) => total + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final categoryUsage = [
      for (final entry in spendingByCategory.entries)
        CategoryAmount(
          category: entry.key == null ? null : categoriesById[entry.key],
          amount: entry.value,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    List<TransactionModel> topBy(List<TransactionModel> source) {
      final sorted = [...source]
        ..sort((a, b) => b.amount.compareTo(a.amount));
      return sorted.take(topTransactionsLimit).toList();
    }

    return PersonReportDetail(
      currentBalance: BalanceCalculator.calculateBalance(oldestFirst),
      totalExpenses: totalExpenses,
      averageMonthlyExpense: expensesByMonth.isEmpty
          ? 0
          : totalExpenses / expensesByMonth.length,
      monthlySpendingTrend: _filledMonthlyTrend(expensesByMonth),
      categoryUsage: categoryUsage,
      largestExpenses: topBy(expenses).map(toDetails).toList(),
      largestAdvances: topBy(advances).map(toDetails).toList(),
      timeline: personTransactionsNewestFirst
          .take(timelineLimit)
          .map(toDetails)
          .toList(),
    );
  }

  // ---------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------

  static LedgerReport _buildLedger(
    List<TransactionModel> filtered, {
    required ReportFilter filter,
    required Map<int, double> balancesByPersonId,
    required Map<int, double> ownPocketById,
  }) {
    var advances = 0.0;
    var expenses = 0.0;
    var returned = 0.0;
    var adjustments = 0.0;
    var ownPocket = 0.0;
    var netPosition = 0.0;

    for (final transaction in filtered) {
      switch (transaction.transactionType) {
        case TransactionType.advanceReceived:
          advances += transaction.amount;
        case TransactionType.expensePaid:
          expenses += transaction.amount;
          ownPocket += ownPocketById[transaction.id] ?? 0;
        case TransactionType.moneyReturned:
          returned += transaction.amount;
        case TransactionType.adjustment:
          adjustments += transaction.amount;
      }
      netPosition += BalanceCalculator.signedAmount(transaction);
    }

    // Point-in-time figure: only the person filter narrows it (see
    // LedgerReport's doc comment).
    final currentBalance = filter.personId != null
        ? balancesByPersonId[filter.personId] ?? 0
        : balancesByPersonId.values.fold(0.0, (a, b) => a + b);

    return LedgerReport(
      currentBalance: currentBalance,
      totalAdvanceReceived: advances,
      totalExpenses: expenses,
      totalMoneyReturned: returned,
      totalAdjustments: adjustments,
      ownPocketExpenses: ownPocket,
      netPosition: netPosition,
    );
  }

  static List<PersonReport> _buildPersonReports(
    Map<int, List<TransactionModel>> filteredByPerson, {
    required Map<int, PersonModel> peopleById,
    required Map<int, double> balancesByPersonId,
  }) {
    final reports = <PersonReport>[];

    filteredByPerson.forEach((personId, transactions) {
      final person = peopleById[personId];
      if (person == null) return;

      var advances = 0.0;
      var expenses = 0.0;
      var returned = 0.0;
      var magnitudeTotal = 0.0;
      double? largestExpense;
      double? largestAdvance;
      // Newest-first order is preserved by groupByPerson.
      final latestDate = transactions.first.date;
      final firstDate = transactions.last.date;

      for (final transaction in transactions) {
        magnitudeTotal += transaction.amount.abs();
        switch (transaction.transactionType) {
          case TransactionType.advanceReceived:
            advances += transaction.amount;
            if (largestAdvance == null || transaction.amount > largestAdvance) {
              largestAdvance = transaction.amount;
            }
          case TransactionType.expensePaid:
            expenses += transaction.amount;
            if (largestExpense == null || transaction.amount > largestExpense) {
              largestExpense = transaction.amount;
            }
          case TransactionType.moneyReturned:
            returned += transaction.amount;
          case TransactionType.adjustment:
            break;
        }
      }

      reports.add(
        PersonReport(
          person: person,
          currentBalance: balancesByPersonId[personId] ?? 0,
          advanceReceived: advances,
          expenses: expenses,
          moneyReturned: returned,
          transactionCount: transactions.length,
          averageTransaction: magnitudeTotal / transactions.length,
          largestExpense: largestExpense,
          largestAdvance: largestAdvance,
          firstTransactionDate: firstDate,
          latestTransactionDate: latestDate,
        ),
      );
    });

    reports.sort((a, b) {
      final byActivity = b.transactionCount.compareTo(a.transactionCount);
      if (byActivity != 0) return byActivity;
      return a.person.name.toLowerCase().compareTo(b.person.name.toLowerCase());
    });
    return reports;
  }

  static List<CategoryReport> _buildCategoryReports(
    List<TransactionModel> filtered, {
    required Map<int, CategoryModel> categoriesById,
  }) {
    final byCategory = <int?, List<TransactionModel>>{};
    for (final transaction in filtered) {
      (byCategory[transaction.categoryId] ??= []).add(transaction);
    }

    final reports = <CategoryReport>[];
    byCategory.forEach((categoryId, transactions) {
      var total = 0.0;
      var expenseTotal = 0.0;
      var largest = 0.0;
      var smallest = double.infinity;
      var mostRecent = transactions.first.date;

      for (final transaction in transactions) {
        final magnitude = transaction.amount.abs();
        total += magnitude;
        if (transaction.transactionType == TransactionType.expensePaid) {
          expenseTotal += transaction.amount;
        }
        if (magnitude > largest) largest = magnitude;
        if (magnitude < smallest) smallest = magnitude;
        if (transaction.date.isAfter(mostRecent)) {
          mostRecent = transaction.date;
        }
      }

      reports.add(
        CategoryReport(
          category: categoryId == null ? null : categoriesById[categoryId],
          total: total,
          expenseTotal: expenseTotal,
          average: total / transactions.length,
          largest: largest,
          smallest: smallest,
          transactionCount: transactions.length,
          mostRecentDate: mostRecent,
        ),
      );
    });

    reports.sort((a, b) => b.total.compareTo(a.total));
    return reports;
  }

  static List<MonthlyReport> _buildMonthlyReports(
    List<TransactionModel> filtered,
  ) {
    final byMonth = <DateTime, List<TransactionModel>>{};
    for (final transaction in filtered) {
      final month = DateTime(transaction.date.year, transaction.date.month);
      (byMonth[month] ??= []).add(transaction);
    }

    final months = byMonth.keys.toList()..sort();
    final reports = <MonthlyReport>[];
    var runningBalance = 0.0;

    for (final month in months) {
      var advances = 0.0;
      var expenses = 0.0;
      var returned = 0.0;
      var adjustments = 0.0;
      var netChange = 0.0;

      for (final transaction in byMonth[month]!) {
        switch (transaction.transactionType) {
          case TransactionType.advanceReceived:
            advances += transaction.amount;
          case TransactionType.expensePaid:
            expenses += transaction.amount;
          case TransactionType.moneyReturned:
            returned += transaction.amount;
          case TransactionType.adjustment:
            adjustments += transaction.amount;
        }
        netChange += BalanceCalculator.signedAmount(transaction);
      }

      runningBalance += netChange;
      reports.add(
        MonthlyReport(
          month: month,
          advances: advances,
          expenses: expenses,
          moneyReturned: returned,
          adjustments: adjustments,
          netChange: netChange,
          runningBalance: runningBalance,
        ),
      );
    }

    return reports;
  }

  static TopListsReport _buildTopLists(
    List<TransactionModel> filtered, {
    required List<TransactionModel> allTransactionsNewestFirst,
    required Map<int, List<TransactionModel>> filteredByPerson,
    required List<MonthlyReport> monthlyReports,
    required Map<int, PersonModel> peopleById,
    required Map<int, CategoryModel> categoriesById,
  }) {
    TransactionModel? highestExpense;
    TransactionModel? highestAdvance;
    TransactionModel? largestTransaction;

    for (final transaction in filtered) {
      final magnitude = transaction.amount.abs();
      if (largestTransaction == null ||
          magnitude > largestTransaction.amount.abs()) {
        largestTransaction = transaction;
      }
      switch (transaction.transactionType) {
        case TransactionType.expensePaid:
          if (highestExpense == null ||
              transaction.amount > highestExpense.amount) {
            highestExpense = transaction;
          }
        case TransactionType.advanceReceived:
          if (highestAdvance == null ||
              transaction.amount > highestAdvance.amount) {
            highestAdvance = transaction;
          }
        case TransactionType.moneyReturned:
        case TransactionType.adjustment:
          break;
      }
    }

    // Resolve TransactionDetails only for the (at most three) winners —
    // running balances bounded to just their people.
    final winners = <TransactionModel>[
      if (highestExpense != null) highestExpense,
      if (highestAdvance != null) highestAdvance,
      if (largestTransaction != null) largestTransaction,
    ];
    final runningBalanceById = winners.isEmpty
        ? const <int, double>{}
        : TransactionAggregator.runningBalancesById(
            allTransactionsNewestFirst,
            personIds: {for (final winner in winners) winner.personId},
          );

    TransactionDetails? toDetails(TransactionModel? transaction) {
      if (transaction == null) return null;
      final person = peopleById[transaction.personId];
      if (person == null) return null;
      return TransactionDetails(
        transaction: transaction,
        person: person,
        category: transaction.categoryId == null
            ? null
            : categoriesById[transaction.categoryId],
        runningBalanceAfter: runningBalanceById[transaction.id] ?? 0,
      );
    }

    TopPersonActivity? mostActivePerson;
    filteredByPerson.forEach((personId, transactions) {
      final person = peopleById[personId];
      if (person == null) return;
      if (mostActivePerson == null ||
          transactions.length > mostActivePerson!.transactionCount) {
        mostActivePerson = TopPersonActivity(
          person: person,
          transactionCount: transactions.length,
        );
      }
    });

    final mostUsedCategoryId = TransactionAggregator.mostFrequentKey(
      filtered,
      (transaction) => transaction.categoryId,
    );
    final mostUsedCategory = mostUsedCategoryId == null
        ? null
        : categoriesById[mostUsedCategoryId];
    TopCategoryUsage? mostUsedCategoryUsage;
    if (mostUsedCategory != null) {
      final count = filtered
          .where((transaction) => transaction.categoryId == mostUsedCategoryId)
          .length;
      mostUsedCategoryUsage = TopCategoryUsage(
        category: mostUsedCategory,
        transactionCount: count,
      );
    }

    MonthlyReport? largestExpenseMonth;
    for (final month in monthlyReports) {
      if (month.expenses <= 0) continue;
      if (largestExpenseMonth == null ||
          month.expenses > largestExpenseMonth.expenses) {
        largestExpenseMonth = month;
      }
    }

    return TopListsReport(
      highestExpense: toDetails(highestExpense),
      highestAdvance: toDetails(highestAdvance),
      largestTransaction: toDetails(largestTransaction),
      mostActivePerson: mostActivePerson,
      mostUsedCategory: mostUsedCategoryUsage,
      largestExpenseMonth: largestExpenseMonth,
    );
  }

  static OwnPocketReport _buildOwnPocket(
    List<TransactionModel> filtered, {
    required Map<int, double> ownPocketById,
    required Map<int, PersonModel> peopleById,
    required Map<int, CategoryModel> categoriesById,
  }) {
    var total = 0.0;
    final byMonth = <DateTime, double>{};
    final byPerson = <int, double>{};
    final byCategory = <int?, double>{};

    for (final transaction in filtered) {
      final portion = ownPocketById[transaction.id] ?? 0;
      if (portion == 0) continue;

      total += portion;
      byMonth.update(
        DateTime(transaction.date.year, transaction.date.month),
        (amount) => amount + portion,
        ifAbsent: () => portion,
      );
      byPerson.update(
        transaction.personId,
        (amount) => amount + portion,
        ifAbsent: () => portion,
      );
      byCategory.update(
        transaction.categoryId,
        (amount) => amount + portion,
        ifAbsent: () => portion,
      );
    }

    final monthly = [
      for (final entry in byMonth.entries)
        TrendPoint(month: entry.key, value: entry.value),
    ]..sort((a, b) => a.month.compareTo(b.month));

    final perPerson = [
      for (final entry in byPerson.entries)
        if (peopleById[entry.key] case final person?)
          PersonAmount(person: person, amount: entry.value),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    final perCategory = [
      for (final entry in byCategory.entries)
        CategoryAmount(
          category: entry.key == null ? null : categoriesById[entry.key],
          amount: entry.value,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return OwnPocketReport(
      total: total,
      monthly: monthly,
      perPerson: perPerson,
      perCategory: perCategory,
    );
  }

  static List<ReportInsight> _buildInsights({
    required ReportFilter filter,
    required LedgerReport ledger,
    required List<PersonReport> personReports,
    required List<CategoryReport> categoryReports,
    required List<MonthlyReport> monthlyReports,
    required TopListsReport topLists,
    required String currencySymbol,
  }) {
    final insights = <ReportInsight>[];
    final periodLabel = _periodLabel(filter.datePreset);

    // Spending per category, expenses only, largest first.
    final spendingRanked = [
      for (final report in categoryReports)
        if (report.category != null && report.expenseTotal > 0) report,
    ]..sort((a, b) => b.expenseTotal.compareTo(a.expenseTotal));

    if (spendingRanked.isNotEmpty) {
      final top = spendingRanked.first;
      insights.add(
        ReportInsight(
          kind: ReportInsightKind.spending,
          message:
              'Most spending is on ${top.category!.name} '
              '(${CurrencyFormatter.format(top.expenseTotal, symbol: currencySymbol)}).',
        ),
      );
    }
    if (spendingRanked.length >= 3) {
      final third = spendingRanked[2];
      insights.add(
        ReportInsight(
          kind: ReportInsightKind.category,
          message:
              '${third.category!.name} is the third highest expense '
              'category.',
        ),
      );
    }

    final mostActive = topLists.mostActivePerson;
    if (mostActive != null && personReports.length > 1) {
      insights.add(
        ReportInsight(
          kind: ReportInsightKind.person,
          message:
              'Most active person $periodLabel is ${mostActive.person.name} '
              '(${mostActive.transactionCount} transactions).',
        ),
      );
    }

    if (ledger.ownPocketExpenses > 0) {
      insights.add(
        ReportInsight(
          kind: ReportInsightKind.ownPocket,
          message:
              '${CurrencyFormatter.format(ledger.ownPocketExpenses, symbol: currencySymbol)} of '
              'expenses came from your own pocket, beyond advances.',
        ),
      );
    }

    if (monthlyReports.length >= 2 && topLists.largestExpenseMonth != null) {
      final peak = topLists.largestExpenseMonth!;
      insights.add(
        ReportInsight(
          kind: ReportInsightKind.spending,
          message:
              'Highest spending month: ${_monthLabel(peak.month)} '
              '(${CurrencyFormatter.format(peak.expenses, symbol: currencySymbol)}).',
        ),
      );
    }

    if (ledger.currentBalance > 0) {
      insights.add(
        ReportInsight(
          kind: ReportInsightKind.balance,
          message:
              'You are currently holding '
              '${CurrencyFormatter.format(ledger.currentBalance, symbol: currencySymbol)} in '
              'advances.',
        ),
      );
    } else if (ledger.currentBalance < 0) {
      insights.add(
        ReportInsight(
          kind: ReportInsightKind.balance,
          message:
              'You are currently owed '
              '${CurrencyFormatter.format(-ledger.currentBalance, symbol: currencySymbol)} overall.',
        ),
      );
    }

    return insights.take(insightsLimit).toList();
  }

  static String _periodLabel(ReportDatePreset preset) => switch (preset) {
    ReportDatePreset.allTime => 'overall',
    ReportDatePreset.today => 'today',
    ReportDatePreset.yesterday => 'yesterday',
    ReportDatePreset.last7Days => 'in the last 7 days',
    ReportDatePreset.last30Days => 'in the last 30 days',
    ReportDatePreset.thisMonth => 'this month',
    ReportDatePreset.lastMonth => 'last month',
    ReportDatePreset.thisYear => 'this year',
    ReportDatePreset.custom => 'in the selected period',
  };

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _monthLabel(DateTime month) =>
      '${_monthNames[month.month - 1]} ${month.year}';

  /// Turns a sparse month→amount map into a dense oldest-first trend,
  /// inserting explicit zero months between the first and last, so a
  /// chart shows quiet months as real gaps instead of skipping them.
  static List<TrendPoint> _filledMonthlyTrend(Map<DateTime, double> byMonth) {
    if (byMonth.isEmpty) return const [];

    final months = byMonth.keys.toList()..sort();
    final result = <TrendPoint>[];
    var cursor = months.first;
    final last = months.last;

    while (!cursor.isAfter(last)) {
      result.add(TrendPoint(month: cursor, value: byMonth[cursor] ?? 0));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return result;
  }
}
