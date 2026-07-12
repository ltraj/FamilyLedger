import 'package:family_ledger/export/models/export_metadata_model.dart';

/// Summary of a completed export run, returned by `ExportService.exportAll`.
class ExportResultModel {
  const ExportResultModel({
    required this.metadata,
    required this.exportDirectoryPath,
  });

  /// The metadata written to `metadata.json`, including the full manifest
  /// of files produced.
  final ExportMetadataModel metadata;

  /// Absolute path to the folder containing the export bundle.
  final String exportDirectoryPath;
}
