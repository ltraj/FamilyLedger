import 'package:drift/drift.dart';

/// Expense categories used to classify transactions.
@DataClassName('CategoryEntity')
class Categories extends Table {
  /// Auto-increment primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Display name of the category.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Material icon identifier (e.g. `bolt`, `wifi`).
  TextColumn get icon => text().withLength(min: 1, max: 100)();

  /// Hex color string (e.g. `#FF9800`).
  TextColumn get color => text().withLength(min: 4, max: 9)();

  /// Whether this is a system-provided default category.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Timestamp when the record was created.
  DateTimeColumn get createdAt => dateTime()();
}
