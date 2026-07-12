import 'package:family_ledger/export/models/attachment_reference_model.dart';
import 'package:family_ledger/export/services/export_destination.dart';

/// Contract for writing export models to files on an [ExportDestination].
///
/// Kept separate from [ExportDataCollector] so the two concerns — "what
/// data to export" and "how/where to write it" — can change independently.
/// For example, swapping local-folder export for direct-to-zip export only
/// requires a new [ExportFileWriter], not a new data collector.
///
/// Implementation: [ExportFileWriterImpl] in
/// `lib/export/services/impl/export_file_writer_impl.dart`.
abstract interface class ExportFileWriter {
  /// Serializes [content] as pretty-printed, human-readable JSON and
  /// writes it to [fileName] on [destination].
  Future<void> writeJsonFile({
    required ExportDestination destination,
    required String fileName,
    required Object? content,
  });

  /// Writes [content] verbatim (no JSON encoding) to [fileName] on
  /// [destination]. Used for non-JSON bundle members — `ledger.csv`,
  /// `README.md`.
  Future<void> writeTextFile({
    required ExportDestination destination,
    required String fileName,
    required String content,
  });

  /// Copies the file described by [attachment] into the attachments
  /// folder on [destination].
  Future<void> writeAttachment({
    required ExportDestination destination,
    required AttachmentReferenceModel attachment,
  });
}
