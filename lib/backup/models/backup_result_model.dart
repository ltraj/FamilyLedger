/// Summary of a completed backup run, returned by [BackupService].
class BackupResultModel {
  const BackupResultModel({
    required this.zipFilePath,
    required this.fileSizeBytes,
    required this.createdAt,
    required this.peopleCount,
    required this.transactionCount,
    required this.categoryCount,
  });

  /// Absolute path to the final `.zip` file, wherever the user chose to
  /// save it via the Storage Access Framework.
  final String zipFilePath;

  final int fileSizeBytes;
  final DateTime createdAt;

  final int peopleCount;
  final int transactionCount;
  final int categoryCount;
}
