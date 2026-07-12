import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/features/transactions/models/transaction_date_range.dart';
import 'package:family_ledger/features/transactions/models/transaction_sort_option.dart';
import 'package:family_ledger/projections/transaction_details.dart';

/// Search/filter/sort logic for the Transaction screen.
///
/// Pure function of its inputs, with no Riverpod dependency, so it can be
/// unit-tested directly — mirrors `PeopleQueryEngine`.
///
/// Never touches `TransactionDetails.runningBalanceAfter`: that value is
/// fixed at assembly time from the complete chronological history, and
/// stays correct no matter how this engine reorders or narrows the list
/// for display.
abstract final class TransactionQueryEngine {
  static List<TransactionDetails> apply(
    List<TransactionDetails> details, {
    required String searchText,
    required TransactionSortOption sort,
    TransactionType? typeFilter,
    int? categoryFilter,
    TransactionDateRange? dateRange,
  }) {
    final matching = details
        .where((d) => _matchesType(d, typeFilter))
        .where((d) => _matchesCategory(d, categoryFilter))
        .where((d) => _matchesDateRange(d, dateRange))
        .where((d) => _matchesSearch(d, searchText))
        .toList();

    return _sorted(matching, sort);
  }

  static bool _matchesType(TransactionDetails details, TransactionType? type) {
    if (type == null) return true;
    return details.transaction.transactionType == type;
  }

  static bool _matchesCategory(TransactionDetails details, int? categoryId) {
    if (categoryId == null) return true;
    return details.transaction.categoryId == categoryId;
  }

  static bool _matchesDateRange(
    TransactionDetails details,
    TransactionDateRange? dateRange,
  ) {
    if (dateRange == null) return true;
    return dateRange.contains(details.transaction.date);
  }

  static bool _matchesSearch(TransactionDetails details, String searchText) {
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) return true;

    final remark = details.transaction.remark?.toLowerCase() ?? '';
    if (remark.contains(query)) return true;

    final categoryName = details.category?.name.toLowerCase() ?? '';
    if (categoryName.contains(query)) return true;

    if (details.transaction.amount.toString().contains(query)) return true;

    return false;
  }

  static List<TransactionDetails> _sorted(
    List<TransactionDetails> details,
    TransactionSortOption sort,
  ) {
    final sorted = [...details];

    switch (sort) {
      case TransactionSortOption.newest:
        sorted.sort(
          (a, b) => b.transaction.date.compareTo(a.transaction.date),
        );
      case TransactionSortOption.oldest:
        sorted.sort(
          (a, b) => a.transaction.date.compareTo(b.transaction.date),
        );
      case TransactionSortOption.highestAmount:
        sorted.sort(
          (a, b) => BalanceCalculator.signedAmount(
            b.transaction,
          ).compareTo(BalanceCalculator.signedAmount(a.transaction)),
        );
      case TransactionSortOption.lowestAmount:
        sorted.sort(
          (a, b) => BalanceCalculator.signedAmount(
            a.transaction,
          ).compareTo(BalanceCalculator.signedAmount(b.transaction)),
        );
    }

    return sorted;
  }
}
