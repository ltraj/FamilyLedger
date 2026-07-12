import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/transaction_aggregator.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/attention_item.dart';
import 'package:family_ledger/projections/dashboard_summary.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:family_ledger/projections/transaction_details.dart';

/// The remaining-advance figure below which an otherwise-fine (non-
/// negative) balance still earns a place in the Attention Center.
const double lowRemainingAdvanceThreshold = 500;

/// How many of the most recent transactions the Dashboard shows.
const int recentActivityLimit = 10;

/// Assembles [DashboardSummary] from data other parts of the app already
/// compute or fetch — never from scratch.
///
/// A pure function of its inputs (no Riverpod, no database), so it's
/// directly unit-testable. [DashboardViewModel] (in
/// `lib/features/dashboard/providers/dashboard_view_model.dart`) is the
/// only caller, wiring this to the app's reactive providers. Grouping,
/// date-range filtering, running balances, and "most common key" all
/// come from [TransactionAggregator] rather than being re-derived here —
/// see that class for why.
abstract final class DashboardAggregator {
  static DashboardSummary assemble({
    required List<PersonSummary> peopleSummaries,
    required List<TransactionModel> transactionsNewestFirst,
    required List<CategoryModel> categories,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final activePeople = [
      for (final summary in peopleSummaries)
        if (summary.person.status == PersonStatus.active) summary,
    ];

    final totalAdvanceHeld = _sumWhere(activePeople, (s) => s.balance > 0);
    final totalOwedToMe = -_sumWhere(activePeople, (s) => s.balance < 0);

    final thisMonthTransactions = TransactionAggregator.filterByDateRange(
      transactionsNewestFirst,
      from: DateTime(currentTime.year, currentTime.month, 1),
      to: DateTime(currentTime.year, currentTime.month + 1, 0, 23, 59, 59, 999),
    );
    final thisMonthExpenses = _sumTransactionsWhere(
      thisMonthTransactions,
      (t) => t.transactionType == TransactionType.expensePaid,
    );

    final attentionItems = [
      for (final summary in activePeople)
        if (_attentionReasonFor(summary) case final reason?)
          AttentionItem(personSummary: summary, reason: reason),
    ];

    final peopleById = <int, PersonModel>{
      for (final summary in peopleSummaries)
        if (summary.person.id != null) summary.person.id!: summary.person,
    };
    final categoriesById = <int, CategoryModel>{
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };

    final recentTransactions = transactionsNewestFirst
        .take(recentActivityLimit)
        .toList();
    final largestExpenseThisMonthTransaction = _largestBy(
      thisMonthTransactions.where(
        (t) => t.transactionType == TransactionType.expensePaid,
      ),
      (t) => t.amount,
    );

    final targetTransactions = [
      ...recentTransactions,
      if (largestExpenseThisMonthTransaction != null)
        largestExpenseThisMonthTransaction,
    ];
    // Bounded to the people referenced by targetTransactions — a small,
    // fixed-size set — rather than to everyone in the ledger.
    final runningBalanceByTransactionId =
        TransactionAggregator.runningBalancesById(
          transactionsNewestFirst,
          personIds: {
            for (final transaction in targetTransactions)
              transaction.personId,
          },
        );

    TransactionDetails toDetails(TransactionModel transaction) {
      return TransactionDetails(
        transaction: transaction,
        person: peopleById[transaction.personId]!,
        category: transaction.categoryId == null
            ? null
            : categoriesById[transaction.categoryId],
        runningBalanceAfter: runningBalanceByTransactionId[transaction.id] ?? 0,
      );
    }

    final recentActivity = recentTransactions.map(toDetails).toList();
    final largestExpenseThisMonth = largestExpenseThisMonthTransaction == null
        ? null
        : toDetails(largestExpenseThisMonthTransaction);

    final highestAdvancePerson = _extremeBy(
      activePeople.where((s) => s.balance > 0),
      (s) => s.balance,
      highest: true,
    );
    final mostOwingPerson = _extremeBy(
      activePeople.where((s) => s.balance < 0),
      (s) => s.balance,
      highest: false,
    );

    final summariesByPersonId = <int, PersonSummary>{
      for (final summary in peopleSummaries)
        if (summary.person.id != null) summary.person.id!: summary,
    };
    final mostActivePersonId = TransactionAggregator.mostFrequentKey(
      thisMonthTransactions,
      (t) => t.personId,
    );
    final mostActivePersonThisMonth = mostActivePersonId == null
        ? null
        : summariesByPersonId[mostActivePersonId];

    final mostUsedCategoryId = TransactionAggregator.mostFrequentKey(
      transactionsNewestFirst,
      (t) => t.categoryId,
    );
    final mostUsedCategory = mostUsedCategoryId == null
        ? null
        : categoriesById[mostUsedCategoryId];

    return DashboardSummary(
      totalAdvanceHeld: totalAdvanceHeld,
      totalOwedToMe: totalOwedToMe,
      thisMonthExpenses: thisMonthExpenses,
      people: activePeople,
      attentionItems: attentionItems,
      recentActivity: recentActivity,
      highestAdvancePerson: highestAdvancePerson,
      mostOwingPerson: mostOwingPerson,
      mostActivePersonThisMonth: mostActivePersonThisMonth,
      mostUsedCategory: mostUsedCategory,
      largestExpenseThisMonth: largestExpenseThisMonth,
    );
  }

  static double _sumWhere(
    List<PersonSummary> summaries,
    bool Function(PersonSummary) test,
  ) {
    var total = 0.0;
    for (final summary in summaries) {
      if (test(summary)) total += summary.balance;
    }
    return total;
  }

  static double _sumTransactionsWhere(
    List<TransactionModel> transactions,
    bool Function(TransactionModel) test,
  ) {
    var total = 0.0;
    for (final transaction in transactions) {
      if (test(transaction)) total += transaction.amount;
    }
    return total;
  }

  /// Assigns at most one [AttentionReason] per person, in priority order,
  /// so a person is never shown with more than one attention card.
  static AttentionReason? _attentionReasonFor(PersonSummary summary) {
    final balance = summary.balance;

    if (balance < 0) return AttentionReason.negativeBalance;
    if (balance > 0 && balance < lowRemainingAdvanceThreshold) {
      return AttentionReason.lowRemainingAdvance;
    }
    if (summary.person.type == PersonType.temporary && balance != 0) {
      return AttentionReason.temporaryPersonPending;
    }
    return null;
  }

  static T? _largestBy<T>(Iterable<T> items, num Function(T) value) {
    T? largest;
    for (final item in items) {
      if (largest == null || value(item) > value(largest)) largest = item;
    }
    return largest;
  }

  static T? _extremeBy<T>(
    Iterable<T> items,
    num Function(T) value, {
    required bool highest,
  }) {
    T? extreme;
    for (final item in items) {
      if (extreme == null ||
          (highest ? value(item) > value(extreme) : value(item) < value(extreme))) {
        extreme = item;
      }
    }
    return extreme;
  }
}
