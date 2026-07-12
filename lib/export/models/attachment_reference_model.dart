/// Describes one file that needs to be copied into an export bundle's
/// `attachments` folder.
///
/// This is an internal working model used while building an export — it is
/// never itself serialized to JSON. Other export models reference
/// attachments only by file name (see `PersonExportModel.photographFileName`
/// and `TransactionExportModel.attachmentFileName`), never by the
/// [sourceFilePath] carried here, because absolute device paths are not
/// portable across installations.
class AttachmentReferenceModel {
  const AttachmentReferenceModel({
    required this.sourceFilePath,
    required this.exportedFileName,
    required this.originatingRecordDescription,
  });

  /// Absolute path to the file on this device's local storage today.
  final String sourceFilePath;

  /// File name this attachment will have once copied into the export
  /// bundle's `attachments` folder.
  final String exportedFileName;

  /// Human-readable description of which record this attachment belongs
  /// to, e.g. `Photograph for person: Asha` — useful for logging and error
  /// messages if the copy fails.
  final String originatingRecordDescription;
}
