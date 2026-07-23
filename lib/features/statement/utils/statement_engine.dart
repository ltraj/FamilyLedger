import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/friendly_date.dart';
import 'package:family_ledger/core/utils/transaction_aggregator.dart';
import 'package:family_ledger/features/statement/models/statement_period.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/statement/person_statement.dart';
import 'package:family_ledger/projections/statement/statement_line_item.dart';

/// Turns one person's raw transaction history into a plain-language,
/// zero-jargon monthly statement a non-technical reader (the person
/// themselves) can understand — never `advanceReceived`/`expensePaid`/
/// `moneyReturned`/`adjustment`, "running balance", "projection", or a
/// signed amount.
///
/// Pure and static like every other `*Engine` — no Riverpod, no I/O. All
/// money math goes through [BalanceCalculator]/[TransactionAggregator]
/// rather than re-deriving the signed-amount formula here.
abstract final class StatementEngine {
  static PersonStatement build({
    required PersonModel person,
    required List<TransactionModel> transactions,
    required StatementPeriod period,
    List<CategoryModel> categories = const [],
    String currencySymbol = AppConstants.defaultCurrencySymbol,
  }) {
    final periodStart = period.start;
    final periodEnd = period.end;

    final categoriesById = <int, CategoryModel>{
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };

    final periodTransactions =
        TransactionAggregator.filterByDateRange(
          transactions,
          from: periodStart,
          to: periodEnd,
        ).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final giveTransactions = <TransactionModel>[];
    final expenseTransactions = <TransactionModel>[];
    final positiveAdjustments = <TransactionModel>[];
    final negativeAdjustments = <TransactionModel>[];

    for (final transaction in periodTransactions) {
      switch (transaction.transactionType) {
        case TransactionType.advanceReceived:
        case TransactionType.moneyReturned:
          giveTransactions.add(transaction);
        case TransactionType.expensePaid:
          expenseTransactions.add(transaction);
        case TransactionType.adjustment:
          if (transaction.amount < 0) {
            negativeAdjustments.add(transaction);
          } else {
            positiveAdjustments.add(transaction);
          }
      }
    }

    final givenFromPayments = giveTransactions.fold<double>(
      0,
      (sum, t) => sum + BalanceCalculator.signedAmount(t),
    );
    final givenFromAdjustments = positiveAdjustments.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final totalGiven = givenFromPayments + givenFromAdjustments;

    final spentOnExpenses = expenseTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final spentOnAdjustments = negativeAdjustments.fold<double>(
      0,
      (sum, t) => sum + t.amount.abs(),
    );
    final totalSpent = spentOnExpenses + spentOnAdjustments;

    // Balance as of the end of the selected period — not just this
    // period's net change — so a past month's statement still reflects
    // any balance carried in from before it. Uses the same
    // BalanceCalculator formula PersonSummary/TransactionRepository use,
    // so for the current month (the common case, where no transaction
    // falls after periodEnd) this is numerically identical to the
    // person's live balance — just not re-derived from a cached figure,
    // since past periods need a balance as of a date other than "now".
    final closingBalance = BalanceCalculator.calculateBalance([
      for (final t in transactions)
        if (!t.date.isAfter(periodEnd)) t,
    ]);

    final categoryPhrases = _categoryBreakdown(
      expenseTransactions,
      categoriesById: categoriesById,
      currencySymbol: currencySymbol,
    );
    final givenAdjustmentPhrases = _adjustmentBreakdown(
      positiveAdjustments,
      currencySymbol: currencySymbol,
    );
    final spentAdjustmentPhrases = _adjustmentBreakdown(
      negativeAdjustments,
      currencySymbol: currencySymbol,
    );

    return PersonStatement(
      person: person,
      periodLabel: period.label,
      periodStart: periodStart,
      periodEnd: periodEnd,
      gaveLine: _gaveLine(
        totalGiven: totalGiven,
        giveTransactions: giveTransactions,
        adjustmentPhrases: givenAdjustmentPhrases,
        currencySymbol: currencySymbol,
      ),
      spentLine: _spentLine(
        totalSpent: totalSpent,
        categoryPhrases: categoryPhrases,
        adjustmentPhrases: spentAdjustmentPhrases,
        currencySymbol: currencySymbol,
      ),
      balanceLine: _balanceLine(closingBalance, currencySymbol),
      balanceStatus: _balanceStatus(closingBalance),
      items: _items(
        giveTransactions: giveTransactions,
        expenseTransactions: expenseTransactions,
        positiveAdjustments: positiveAdjustments,
        negativeAdjustments: negativeAdjustments,
        categoriesById: categoriesById,
      ),
    );
  }

  static String? _gaveLine({
    required double totalGiven,
    required List<TransactionModel> giveTransactions,
    required List<String> adjustmentPhrases,
    required String currencySymbol,
  }) {
    if (totalGiven <= 0) return null;

    final amountText = CurrencyFormatter.format(
      totalGiven,
      symbol: currencySymbol,
    );

    final qualifier = giveTransactions.length == 1
        ? ' on ${FriendlyDate.format(giveTransactions.single.date)}'
        : giveTransactions.length > 1
        ? ' across ${giveTransactions.length} payments'
        : '';

    final base = 'You gave me $amountText$qualifier';
    if (adjustmentPhrases.isEmpty) return '$base.';
    return '$base, including ${adjustmentPhrases.join(', ')}.';
  }

  static String? _spentLine({
    required double totalSpent,
    required List<String> categoryPhrases,
    required List<String> adjustmentPhrases,
    required String currencySymbol,
  }) {
    if (totalSpent <= 0) return null;

    final amountText = CurrencyFormatter.format(
      totalSpent,
      symbol: currencySymbol,
    );

    final breakdownParts = [
      if (categoryPhrases.isNotEmpty) categoryPhrases.join(', '),
      if (adjustmentPhrases.isNotEmpty)
        'including ${adjustmentPhrases.join(', ')}',
    ];

    if (breakdownParts.isEmpty) return 'I spent $amountText for you.';
    return 'I spent $amountText for you: ${breakdownParts.join(', ')}.';
  }

  static String _balanceLine(double balance, String currencySymbol) {
    if (balance > 0) {
      return '${CurrencyFormatter.format(balance, symbol: currencySymbol)} is still with me.';
    }
    if (balance < 0) {
      return 'You owe me ${CurrencyFormatter.format(balance.abs(), symbol: currencySymbol)}.';
    }
    return "We're all settled up.";
  }

  static BalanceStatus _balanceStatus(double balance) {
    if (balance > 0) return BalanceStatus.positive;
    if (balance < 0) return BalanceStatus.negative;
    return BalanceStatus.settled;
  }

  static List<String> _categoryBreakdown(
    List<TransactionModel> expenseTransactions, {
    required Map<int, CategoryModel> categoriesById,
    required String currencySymbol,
  }) {
    final totalsByCategory = <int?, double>{};
    for (final transaction in expenseTransactions) {
      totalsByCategory.update(
        transaction.categoryId,
        (total) => total + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final entries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (final entry in entries)
        '${CurrencyFormatter.format(entry.value, symbol: currencySymbol)} '
            'on ${_categoryLabel(entry.key, categoriesById)}',
    ];
  }

  static List<String> _adjustmentBreakdown(
    List<TransactionModel> adjustments, {
    required String currencySymbol,
  }) {
    final sorted = [...adjustments]
      ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));

    return [
      for (final transaction in sorted)
        '${CurrencyFormatter.format(transaction.amount.abs(), symbol: currencySymbol)} '
            '${_adjustmentPhrase(transaction)}',
    ];
  }

  static List<StatementLineItem> _items({
    required List<TransactionModel> giveTransactions,
    required List<TransactionModel> expenseTransactions,
    required List<TransactionModel> positiveAdjustments,
    required List<TransactionModel> negativeAdjustments,
    required Map<int, CategoryModel> categoriesById,
  }) {
    final items = <StatementLineItem>[
      for (final t in giveTransactions)
        StatementLineItem(
          date: t.date,
          description: 'You gave',
          amount: t.amount,
          direction: StatementDirection.given,
          remark: _normalizedRemark(t.remark),
        ),
      for (final t in expenseTransactions)
        StatementLineItem(
          date: t.date,
          description: _categoryLabel(
            t.categoryId,
            categoriesById,
          ).capitalizeFirst(),
          amount: t.amount,
          direction: StatementDirection.spent,
          remark: _normalizedRemark(t.remark),
        ),
      for (final t in positiveAdjustments)
        StatementLineItem(
          date: t.date,
          description: _adjustmentPhrase(t).capitalizeFirst(),
          amount: t.amount,
          direction: StatementDirection.given,
          remark: _normalizedRemark(t.remark),
        ),
      for (final t in negativeAdjustments)
        StatementLineItem(
          date: t.date,
          description: _adjustmentPhrase(t).capitalizeFirst(),
          amount: t.amount.abs(),
          direction: StatementDirection.spent,
          remark: _normalizedRemark(t.remark),
        ),
    ];

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  static String _categoryLabel(
    int? categoryId,
    Map<int, CategoryModel> categoriesById,
  ) {
    if (categoryId == null) return 'other';
    return categoriesById[categoryId]?.name.toLowerCase() ?? 'other';
  }

  /// A short, plain-language phrase for an adjustment transaction, e.g.
  /// `"sent to Ajit"` for a remark of `"Transfer to Ajit"`. Never the
  /// word "adjustment" — falls back to a neutral "a correction" when the
  /// remark doesn't parse into a natural phrase.
  static String _adjustmentPhrase(TransactionModel transaction) {
    final isOutgoing = transaction.amount < 0;
    final remark = transaction.remark?.trim();

    if (remark == null || remark.isEmpty) {
      return 'a correction';
    }

    final target = _transferTarget(remark);
    if (target != null) {
      return isOutgoing ? 'sent to $target' : 'from $target';
    }

    return 'for $remark';
  }

  static const List<String> _transferPrefixes = [
    'transfer to ',
    'transfer from ',
    'sent to ',
    'from ',
  ];

  static String? _transferTarget(String remark) {
    final lower = remark.toLowerCase();
    for (final prefix in _transferPrefixes) {
      if (lower.startsWith(prefix)) {
        return remark.substring(prefix.length).trim();
      }
    }
    return null;
  }

  /// Trims [remark] and collapses blank input to null, so a
  /// [StatementLineItem] only ever carries a meaningful remark or none —
  /// never an empty-string placeholder for callers to special-case.
  static String? _normalizedRemark(String? remark) {
    final trimmed = remark?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

extension _StringCasing on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
