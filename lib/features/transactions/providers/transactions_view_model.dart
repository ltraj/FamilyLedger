import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/features/transactions/models/transaction_exceptions.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/transaction_details.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maximum length of a transaction's remark.
const int maxTransactionRemarkLength = 500;

/// Loads one person's transactions as fully-assembled [TransactionDetails]
/// (transaction + resolved person + resolved category + running balance),
/// and exposes every mutation the Transaction screen can trigger.
///
/// Parametrized by `personId` (Riverpod's `.family`), so each person gets
/// their own independent instance — and `autoDispose`, so that instance
/// (and the person-scoped database watch stream underneath it) is torn
/// down when its Transaction screen closes instead of living for the rest
/// of the app's lifetime.
final transactionsViewModelProvider =
    AsyncNotifierProvider.autoDispose.family<
      TransactionsViewModel,
      List<TransactionDetails>,
      int
    >(TransactionsViewModel.new);

/// Business logic for the Transaction screen.
///
/// Transactions are watched reactively through
/// [personTransactionsStreamProvider], so this rebuilds automatically
/// whenever this person's transactions change anywhere in the app —
/// including this view model's own mutations — with no manual
/// `invalidate()` call anywhere. People and categories are read as
/// one-shot [Future]s: neither is mutated from this screen, and (as with
/// `PeopleViewModel`) a table only needs its own reactive stream once
/// something actually mutates it out from under a screen that depends on
/// it.
class TransactionsViewModel
    extends AutoDisposeFamilyAsyncNotifier<List<TransactionDetails>, int> {
  @override
  Future<List<TransactionDetails>> build(int personId) async {
    final chronological = await ref.watch(
      personTransactionsStreamProvider(personId).future,
    );
    // watchByPersonId (like getByPersonId) is newest-first; running
    // balance needs oldest-first.
    final oldestFirst = chronological.reversed.toList();

    final person = await ref.read(peopleRepositoryProvider).getById(personId);
    if (person == null) return const [];

    final categories = await ref.watch(categoriesListProvider.future);
    final categoriesById = {
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };

    final runningBalances = BalanceCalculator.runningBalances(oldestFirst);

    final detailsOldestFirst = <TransactionDetails>[
      for (var i = 0; i < oldestFirst.length; i++)
        TransactionDetails(
          transaction: oldestFirst[i],
          person: person,
          category: _categoryFor(oldestFirst[i], categoriesById),
          runningBalanceAfter: runningBalances[i],
        ),
    ];

    // Back to newest-first for display.
    return detailsOldestFirst.reversed.toList();
  }

  CategoryModel? _categoryFor(
    TransactionModel transaction,
    Map<int, CategoryModel> categoriesById,
  ) {
    final categoryId = transaction.categoryId;
    if (categoryId == null) return null;
    return categoriesById[categoryId];
  }

  /// Adds a new transaction for this person.
  ///
  /// [amount] must be a positive magnitude; the stored sign is derived
  /// from [transactionType] — except `adjustment`, where the sign is
  /// meaningful and taken from [amount] directly (pass a negative value
  /// for a downward adjustment). Throws
  /// [InvalidTransactionAmountException] or [RemarkTooLongException] and
  /// writes nothing if invalid.
  Future<void> addTransaction({
    required double amount,
    required TransactionType transactionType,
    int? categoryId,
    String? remark,
    required DateTime date,
  }) async {
    _validateAmount(amount, transactionType);
    _validateRemark(remark);

    final now = DateTime.now();
    await ref.read(transactionRepositoryProvider).insert(
      TransactionModel(
        personId: arg,
        amount: amount,
        transactionType: transactionType,
        categoryId: categoryId,
        remark: _normalizedRemark(remark),
        date: date,
        createdAt: now,
        updatedAt: now,
      ),
    );
    // No manual refresh: personTransactionsStreamProvider picks this up
    // on its own, and build() re-runs because it watches that stream.
  }

  /// Updates an existing transaction. See [addTransaction] for validation
  /// rules.
  Future<void> updateTransaction({
    required TransactionModel original,
    required double amount,
    required TransactionType transactionType,
    int? categoryId,
    String? remark,
    required DateTime date,
  }) async {
    _validateAmount(amount, transactionType);
    _validateRemark(remark);

    await ref.read(transactionRepositoryProvider).update(
      original.copyWith(
        amount: amount,
        transactionType: transactionType,
        categoryId: categoryId,
        remark: _normalizedRemark(remark),
        date: date,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Permanently deletes a transaction. The Transaction screen is
  /// responsible for confirming with the user before calling this.
  Future<void> deleteTransaction(int transactionId) async {
    await ref.read(transactionRepositoryProvider).delete(transactionId);
  }

  void _validateAmount(double amount, TransactionType transactionType) {
    if (transactionType == TransactionType.adjustment) {
      if (amount == 0) throw const InvalidTransactionAmountException();
      return;
    }
    if (amount <= 0) throw const InvalidTransactionAmountException();
  }

  void _validateRemark(String? remark) {
    if (remark != null && remark.length > maxTransactionRemarkLength) {
      throw const RemarkTooLongException(maxTransactionRemarkLength);
    }
  }

  String? _normalizedRemark(String? remark) {
    if (remark == null) return null;
    final trimmed = remark.trim();
    return trimmed.isEmpty ? null : remark;
  }
}
