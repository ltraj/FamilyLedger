import 'package:drift/drift.dart';
import 'package:family_ledger/core/database/converters/enum_converters.dart';
import 'package:family_ledger/core/database/tables/categories_table.dart';
import 'package:family_ledger/core/database/tables/people_table.dart';

/// Financial movements between the user and a person.
///
/// The three indexes cover this table's hot query paths — SQLite does not
/// index foreign keys on its own, so without them `watchByPersonId`, the
/// category-reassignment in `CategoryRepository.delete`, and the
/// date-ordered `getAll`/`watchAll` all full-scan, re-running on every
/// table change once the ledger grows large.
@DataClassName('TransactionEntity')
@TableIndex(name: 'idx_transactions_person_id', columns: {#personId})
@TableIndex(name: 'idx_transactions_category_id', columns: {#categoryId})
@TableIndex(name: 'idx_transactions_date', columns: {#date})
class Transactions extends Table {
  /// Auto-increment primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to the associated person.
  ///
  /// Transactions are preserved when a person is archived.
  IntColumn get personId => integer().references(People, #id)();

  /// Monetary amount (always stored as a positive value).
  RealColumn get amount => real()();

  /// Type of transaction determining balance impact.
  TextColumn get transactionType =>
      text().map(const TransactionTypeConverter())();

  /// Optional foreign key to an expense category.
  ///
  /// A category can never be deleted while transactions still reference it:
  /// `CategoryRepository.delete` requires every linked transaction to be
  /// reassigned to a replacement category first, in the same atomic
  /// operation as the deletion. This constraint is a defense-in-depth
  /// backstop against any code path that deletes a category without going
  /// through that reassignment.
  IntColumn get categoryId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// Free-text note for the transaction.
  TextColumn get remark => text().nullable()();

  /// Local file path to an attachment (receipt, bill, etc.).
  TextColumn get attachmentPath => text().nullable()();

  /// Date the transaction occurred (user-facing date).
  DateTimeColumn get date => dateTime()();

  /// Timestamp when the record was created.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the record was last updated.
  DateTimeColumn get updatedAt => dateTime()();
}
