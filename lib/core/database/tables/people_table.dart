import 'package:drift/drift.dart';
import 'package:family_ledger/core/database/converters/enum_converters.dart';

/// People tracked in the ledger (family members, helpers, etc.).
@DataClassName('PersonEntity')
class People extends Table {
  /// Auto-increment primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Display name of the person.
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Local file path to the person's photo, if any.
  TextColumn get photoPath => text().nullable()();

  /// Whether this is a permanent or temporary contact.
  TextColumn get type => text().map(const PersonTypeConverter())();

  /// Active or archived lifecycle state.
  TextColumn get status => text().map(const PersonStatusConverter())();

  /// Deterministic seed used to generate this person's avatar color and
  /// initial. Null for people created before this column existed, or who
  /// have never had their avatar color regenerated — `PersonModel`'s
  /// `effectiveAvatarSeed` falls back to `id` in that case, so every person
  /// has a stable avatar without requiring a backfill.
  IntColumn get avatarSeed => integer().nullable()();

  /// Position of this person in the user's custom sort order.
  ///
  /// Stored with large gaps between consecutive people (see
  /// `PersonDisplayOrder`) rather than as dense 0, 1, 2, ... values, so a
  /// future drag-and-drop feature can insert a person between two others
  /// by writing a single midpoint value, without renumbering every other
  /// row or changing this column's type or constraints.
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  /// Timestamp when the record was created.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the record was last updated.
  DateTimeColumn get updatedAt => dateTime()();
}
