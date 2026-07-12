/// Abstraction over where an export bundle's files are written.
///
/// The first implementation will likely resolve paths inside a folder the
/// user chose via the platform file picker. Because this is a contract
/// rather than a concrete folder path, later implementations — writing
/// into a zip archive, or a Google Drive folder for cloud sync — can
/// satisfy it without any change to `ExportService` or `ExportFileWriter`.
///
/// Implementation: [LocalDirectoryExportDestination] in
/// `lib/export/services/impl/local_directory_export_destination.dart`,
/// used as a staging folder that `ExportService` zips as its final step.
abstract interface class ExportDestination {
  /// Returns a writable absolute path for [relativePath] inside this
  /// destination, creating any intermediate folders as needed.
  ///
  /// Example: `resolvePath('attachments/person_12.jpg')`.
  Future<String> resolvePath(String relativePath);
}
