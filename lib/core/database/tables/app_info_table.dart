import 'package:drift/drift.dart';

/// Application metadata (single-row table) retained for future maintenance
/// tooling such as diagnostics, support exports, and backup/restore audits.
@DataClassName('AppInfoEntity')
class AppInfo extends Table {
  /// Fixed primary key; only one app info row exists.
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Schema version of the database at the time this row was written.
  IntColumn get databaseVersion => integer()();

  /// Semantic version of the app that created/last touched this row.
  TextColumn get appVersion => text()();

  /// Timestamp when this installation's app info was first created.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp of the most recent successful backup, if any.
  DateTimeColumn get lastBackup => dateTime().nullable()();

  /// Timestamp of the most recent successful restore, if any.
  DateTimeColumn get lastRestore => dateTime().nullable()();

  /// Stable UUID identifying this installation.
  TextColumn get installationId => text().withLength(min: 36, max: 36)();

  /// Optional human-readable device name.
  TextColumn get deviceName => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}
