import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/projection.dart';

/// A transaction paired with the person and category it references,
/// already resolved, plus its running balance, so a transaction list can
/// render everything it needs — name/avatar, category icon/color, and
/// "balance after this transaction" — without a lookup or a recomputation
/// per row.
///
/// Assembled by `TransactionsViewModel` the same way `PeopleViewModel`
/// assembles `PersonSummary`: watch/read the raw repositories, then join
/// and compute in memory. See `lib/features/transactions/providers/
/// transactions_view_model.dart`.
class TransactionDetails implements Projection {
  const TransactionDetails({
    required this.transaction,
    required this.person,
    required this.category,
    required this.runningBalanceAfter,
  });

  final TransactionModel transaction;
  final PersonModel person;

  /// Null when the transaction has no category. A non-null
  /// `transaction.categoryId` should always resolve to a real category
  /// here: `CategoryRepository.delete` reassigns every affected
  /// transaction to a replacement category before the old one can be
  /// removed, so a transaction is never left pointing at a category that
  /// no longer exists.
  final CategoryModel? category;

  /// This person's balance immediately after this transaction, in true
  /// chronological order — not affected by whatever search/filter/sort
  /// is currently applied to the list this object appears in. See
  /// `BalanceCalculator.runningBalances`.
  final double runningBalanceAfter;
}
