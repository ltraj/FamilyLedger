import 'package:family_ledger/models/transaction_model.dart';

/// Contract for persisting and retrieving transactions.
abstract interface class TransactionRepository {
  /// Returns all transactions ordered by date descending.
  Future<List<TransactionModel>> getAll();

  /// Returns all transactions for a specific person.
  Future<List<TransactionModel>> getByPersonId(int personId);

  /// Returns a single transaction by [id], or null if not found.
  Future<TransactionModel?> getById(int id);

  /// Inserts a new transaction and returns the generated ID.
  Future<int> insert(TransactionModel transaction);

  /// Updates an existing transaction. Returns true if a row was updated.
  Future<bool> update(TransactionModel transaction);

  /// Permanently deletes a transaction by [id].
  Future<bool> delete(int id);

  /// Permanently deletes every transaction.
  ///
  /// Used only by restore, to empty the table before reimporting a
  /// backup. Must run before [PeopleRepository.deleteAll] and
  /// [CategoryRepository.deleteAll], since transactions hold the foreign
  /// keys referencing both.
  Future<void> deleteAll();

  /// Calculates the current balance for a person from their transaction history.
  ///
  /// Balance is never stored; it is always derived at read time.
  Future<double> calculateBalance(int personId);

  /// Reactive stream of every transaction, ordered the same way as
  /// [getAll].
  ///
  /// Emits a new snapshot whenever any row in the `transactions` table
  /// changes — insert, update, or delete — including changes made
  /// through a different [TransactionRepository] instance elsewhere in
  /// the app, since this is driven by the database itself rather than by
  /// this repository's own method calls. Callers that need to stay in
  /// sync with transaction data should watch this instead of polling
  /// [getAll] and manually invalidating.
  Stream<List<TransactionModel>> watchAll();

  /// Reactive stream of a single person's transactions, ordered the same
  /// way as [getByPersonId]. See [watchAll] for the reactivity guarantee.
  Stream<List<TransactionModel>> watchByPersonId(int personId);
}
