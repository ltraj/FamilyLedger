import 'package:drift/drift.dart';

/// Records of database backup files.
@DataClassName('BackupEntity')
class Backups extends Table {
  /// Auto-increment primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Timestamp when the backup was created.
  DateTimeColumn get backupDate => dateTime()();

  /// Local file path to the backup file.
  TextColumn get backupPath => text()();

  /// Size of the backup file in bytes.
  IntColumn get backupSize => integer()();
}
