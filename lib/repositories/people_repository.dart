import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/models/person_model.dart';

/// Contract for persisting and retrieving people in the ledger.
abstract interface class PeopleRepository {
  /// Returns all people, optionally filtered by [status].
  Future<List<PersonModel>> getAll({PersonStatus? status});

  /// Returns a single person by [id], or null if not found.
  Future<PersonModel?> getById(int id);

  /// Inserts a new person and returns the generated ID.
  Future<int> insert(PersonModel person);

  /// Updates an existing person. Returns true if a row was updated.
  Future<bool> update(PersonModel person);

  /// Archives a person instead of deleting them.
  ///
  /// Transactions linked to this person are preserved.
  Future<bool> archive(int id);

  /// Permanently deletes a person by [id].
  ///
  /// The database rejects this while any transaction still references
  /// [id] (see the `people` foreign key on `transactions.personId`), so
  /// callers should only offer deletion after confirming the person has no
  /// transaction history — [archive] should be offered instead when they do.
  Future<bool> delete(int id);

  /// Permanently deletes every person, regardless of status.
  ///
  /// Used only by restore, to empty the table before reimporting a
  /// backup. The database rejects this while any transaction still
  /// references a person, so callers must delete all transactions first.
  Future<void> deleteAll();
}
