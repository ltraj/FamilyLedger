/// Compresses a staged export folder into a single `.zip` backup file, and
/// reverses that for import/restore.
///
/// Implementation: [ZipArchiverImpl] in
/// `lib/export/services/impl/zip_archiver_impl.dart`, backed by
/// `package:archive`.
abstract interface class ZipArchiver {
  /// Zips every file and subfolder under [sourceDirectoryPath] into a new
  /// archive at [outputZipPath], with paths inside the archive relative to
  /// [sourceDirectoryPath] (no leading folder name).
  Future<void> zipDirectory({
    required String sourceDirectoryPath,
    required String outputZipPath,
  });

  /// Extracts every entry in the archive at [zipFilePath] into
  /// [outputDirectoryPath], recreating its folder structure.
  Future<void> extractZip({
    required String zipFilePath,
    required String outputDirectoryPath,
  });
}
