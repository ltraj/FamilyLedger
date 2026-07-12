/// Constant values for the backup/restore feature: file naming and the
/// export format versions this build knows how to import.
abstract final class BackupConstants {
  /// Builds the file name for a new backup archive, e.g.
  /// `FamilyLedger_Backup_2026-08-14_18-30.zip`.
  static String backupFileName(DateTime timestamp) {
    final year = timestamp.year.toString().padLeft(4, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return 'FamilyLedger_Backup_$year-$month-${day}_$hour-$minute.zip';
  }

  /// Export bundle format versions this build can import.
  ///
  /// A single supported version today; a future app release that changes
  /// the export bundle format should add the new version here without
  /// removing the old one, and teach [ImportValidator] to branch on it,
  /// so backups made by older app versions keep importing.
  static const Set<int> supportedExportFormatVersions = {1};
}
