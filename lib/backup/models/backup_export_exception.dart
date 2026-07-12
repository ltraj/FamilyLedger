/// Thrown by [BackupService] when writing the backup file fails — most
/// commonly the chosen destination folder denying write access.
class BackupExportException implements Exception {
  const BackupExportException(this.message);

  final String message;

  @override
  String toString() => 'BackupExportException: $message';
}
