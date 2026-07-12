import 'package:family_ledger/features/reports/models/report_filter.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';

/// Narrows a transaction list to the ones a [ReportFilter] admits.
///
/// Pure function of its inputs, mirroring `TransactionQueryEngine` /
/// `PeopleQueryEngine`. Runs exactly once per report rebuild (see
/// `ReportsViewModel`) — every report section is then computed from the
/// single filtered list, never by re-filtering.
///
/// Needs [peopleById]/[categoriesById] only for the text search, which
/// matches against person name, category name, and remark (all
/// case-insensitive substring matches).
abstract final class ReportFilterEngine {
  static List<TransactionModel> apply(
    List<TransactionModel> transactions, {
    required ReportFilter filter,
    required Map<int, PersonModel> peopleById,
    required Map<int, CategoryModel> categoriesById,
    DateTime? now,
  }) {
    final dateRange = filter.resolveDateRange(now ?? DateTime.now());
    final query = filter.searchText.trim().toLowerCase();

    return [
      for (final transaction in transactions)
        if ((filter.personId == null ||
                transaction.personId == filter.personId) &&
            (filter.categoryId == null ||
                transaction.categoryId == filter.categoryId) &&
            (filter.transactionType == null ||
                transaction.transactionType == filter.transactionType) &&
            (dateRange == null || dateRange.contains(transaction.date)) &&
            (query.isEmpty ||
                _matchesSearch(transaction, query, peopleById, categoriesById)))
          transaction,
    ];
  }

  static bool _matchesSearch(
    TransactionModel transaction,
    String query,
    Map<int, PersonModel> peopleById,
    Map<int, CategoryModel> categoriesById,
  ) {
    final remark = transaction.remark?.toLowerCase() ?? '';
    if (remark.contains(query)) return true;

    final personName =
        peopleById[transaction.personId]?.name.toLowerCase() ?? '';
    if (personName.contains(query)) return true;

    final categoryId = transaction.categoryId;
    final categoryName = categoryId == null
        ? ''
        : categoriesById[categoryId]?.name.toLowerCase() ?? '';
    return categoryName.contains(query);
  }
}
