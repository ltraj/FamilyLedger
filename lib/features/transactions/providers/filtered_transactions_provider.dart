import 'package:family_ledger/features/transactions/providers/transaction_query_controller.dart';
import 'package:family_ledger/features/transactions/providers/transactions_view_model.dart';
import 'package:family_ledger/features/transactions/utils/transaction_query_engine.dart';
import 'package:family_ledger/projections/transaction_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One person's transaction list after applying their current
/// [transactionQueryProvider] selection (search, sort, type/category/date
/// filters) to [transactionsViewModelProvider]'s data.
///
/// The Transaction screen watches only this provider for its list
/// content, the same way the People screen only watches
/// `filteredPeopleProvider`.
final filteredTransactionsProvider = Provider.family<
  AsyncValue<List<TransactionDetails>>,
  int
>((ref, personId) {
  final query = ref.watch(transactionQueryProvider(personId));
  final details = ref.watch(transactionsViewModelProvider(personId));

  return details.whenData(
    (value) => TransactionQueryEngine.apply(
      value,
      searchText: query.searchText,
      sort: query.sort,
      typeFilter: query.typeFilter,
      categoryFilter: query.categoryFilter,
      dateRange: query.dateRange,
    ),
  );
});
