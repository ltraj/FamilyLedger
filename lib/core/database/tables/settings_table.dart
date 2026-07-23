import 'package:drift/drift.dart';
import 'package:family_ledger/core/database/converters/enum_converters.dart';

/// Application-wide user preferences (single-row table).
@DataClassName('SettingsEntity')
class Settings extends Table {
  /// Fixed primary key; only one settings row exists.
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Preferred application theme.
  TextColumn get theme => text().map(const AppThemeModeConverter())();

  /// ISO 4217 currency code (e.g. `INR`).
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// How often automatic backups should run.
  ///
  /// Legacy column: superseded by [autoBackupIntervalDays], which can
  /// express arbitrary "every N days" intervals this enum cannot. Kept
  /// (rather than dropped) because removing it would force a table
  /// rebuild and change the export bundle's settings.json shape, breaking
  /// import of every previously created backup. Nothing reads it for
  /// scheduling anymore.
  TextColumn get backupFrequency =>
      text().map(const BackupFrequencyConverter())();

  /// Days between automatic backups. Null means automatic backup is OFF —
  /// nullable-as-off avoids a magic 0 sentinel and makes the v7 migration
  /// a plain ADD COLUMN with no backfill: existing installations keep
  /// their current behavior (no automatic backups) until they opt in.
  IntColumn get autoBackupIntervalDays => integer().nullable()();

  /// The folder automatic backups are written into, persisted so the user
  /// picks it once and is never prompted again. Null until first chosen.
  TextColumn get autoBackupDirectory => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
