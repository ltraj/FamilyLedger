import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/transactions/models/transaction_date_range.dart';
import 'package:family_ledger/features/transactions/models/transaction_sort_option.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current search/sort/filter selection on one person's Transaction
/// screen.
class TransactionQuery {
  const TransactionQuery({
    this.searchText = '',
    this.sort = TransactionSortOption.newest,
    this.typeFilter,
    this.categoryFilter,
    this.dateRange,
  });

  final String searchText;
  final TransactionSortOption sort;

  /// Null means "all types".
  final TransactionType? typeFilter;

  /// Null means "all categories".
  final int? categoryFilter;

  /// Null means "no date restriction".
  final TransactionDateRange? dateRange;

  bool get hasActiveFilter =>
      typeFilter != null || categoryFilter != null || dateRange != null;

  TransactionQuery copyWith({
    String? searchText,
    TransactionSortOption? sort,
    TransactionType? typeFilter,
    bool clearTypeFilter = false,
    int? categoryFilter,
    bool clearCategoryFilter = false,
    TransactionDateRange? dateRange,
    bool clearDateRange = false,
  }) {
    return TransactionQuery(
      searchText: searchText ?? this.searchText,
      sort: sort ?? this.sort,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      categoryFilter: clearCategoryFilter
          ? null
          : (categoryFilter ?? this.categoryFilter),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    );
  }
}

/// Holds one person's Transaction screen search/sort/filter selection.
///
/// Family-scoped by `personId`, like `TransactionsViewModel`, so
/// switching between two people's Transaction screens never mixes up
/// their filters.
class TransactionQueryController extends FamilyNotifier<TransactionQuery, int> {
  @override
  TransactionQuery build(int personId) => const TransactionQuery();

  void setSearchText(String value) {
    state = state.copyWith(searchText: value);
  }

  void setSort(TransactionSortOption value) {
    state = state.copyWith(sort: value);
  }

  void setTypeFilter(TransactionType? value) {
    state = value == null
        ? state.copyWith(clearTypeFilter: true)
        : state.copyWith(typeFilter: value);
  }

  void setCategoryFilter(int? value) {
    state = value == null
        ? state.copyWith(clearCategoryFilter: true)
        : state.copyWith(categoryFilter: value);
  }

  void setDateRange(TransactionDateRange? value) {
    state = value == null
        ? state.copyWith(clearDateRange: true)
        : state.copyWith(dateRange: value);
  }

  void clearFilters() {
    state = TransactionQuery(searchText: state.searchText, sort: state.sort);
  }
}

final transactionQueryProvider =
    NotifierProvider.family<TransactionQueryController, TransactionQuery, int>(
      TransactionQueryController.new,
    );
