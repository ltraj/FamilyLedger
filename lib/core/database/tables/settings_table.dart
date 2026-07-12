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
  TextColumn get backupFrequency =>
      text().map(const BackupFrequencyConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
