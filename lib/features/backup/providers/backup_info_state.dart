import 'package:path/path.dart' as p;

/// Everything the Backup screen's info card shows, loaded from
/// `BackupRepository`/`AppInfoRepository` rather than tracked separately —
/// so it can never drift out of sync with what actually happened.
class BackupInfoState {
  const BackupInfoState({
    this.lastBackupDate,
    this.lastBackupSizeBytes,
    this.lastBackupFilePath,
    this.lastRestoreDate,
  });

  final DateTime? lastBackupDate;
  final int? lastBackupSizeBytes;
  final String? lastBackupFilePath;
  final DateTime? lastRestoreDate;

  /// The folder the most recent backup was saved into, derived from its
  /// full file path — this is what "Export Destination" shows, since the
  /// app doesn't otherwise remember a standing destination folder.
  String? get lastBackupDestinationDirectory =>
      lastBackupFilePath == null ? null : p.dirname(lastBackupFilePath!);
}
