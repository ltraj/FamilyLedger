import 'dart:convert';
import 'dart:io';

import 'package:family_ledger/export/constants/export_constants.dart';
import 'package:family_ledger/export/models/attachment_reference_model.dart';
import 'package:family_ledger/export/services/export_destination.dart';
import 'package:family_ledger/export/services/export_file_writer.dart';

/// Writes export models to disk as pretty-printed JSON, and copies
/// attachment files into the destination's attachments folder.
class ExportFileWriterImpl implements ExportFileWriter {
  const ExportFileWriterImpl();

  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  @override
  Future<void> writeJsonFile({
    required ExportDestination destination,
    required String fileName,
    required Object? content,
  }) async {
    final path = await destination.resolvePath(fileName);
    await File(path).writeAsString(_jsonEncoder.convert(content));
  }

  @override
  Future<void> writeTextFile({
    required ExportDestination destination,
    required String fileName,
    required String content,
  }) async {
    final path = await destination.resolvePath(fileName);
    await File(path).writeAsString(content);
  }

  @override
  Future<void> writeAttachment({
    required ExportDestination destination,
    required AttachmentReferenceModel attachment,
  }) async {
    final sourceFile = File(attachment.sourceFilePath);
    if (!await sourceFile.exists()) {
      // The referenced file is missing from disk (e.g. the user cleared
      // app storage without going through the app). Skip it rather than
      // fail the whole export — the record itself still exports
      // correctly, just without this one attachment.
      return;
    }

    final destinationPath = await destination.resolvePath(
      '${ExportConstants.attachmentsFolderName}/${attachment.exportedFileName}',
    );
    await sourceFile.copy(destinationPath);
  }
}
