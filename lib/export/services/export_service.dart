import 'package:family_ledger/export/models/export_result_model.dart';
import 'package:family_ledger/export/services/export_destination.dart';

/// Top-level contract for producing a full export bundle.
///
/// A future implementation orchestrates `ExportDataCollector` (what to
/// export), `ExportSchemaCatalog` (how to document it), and
/// `ExportFileWriter` (where/how to write it) to produce metadata.json,
/// schema.json, one file per entity, and the attachments folder at
/// [destination].
///
/// This is the only entry point a future export UI should depend on — it
/// should not need to know about collectors, mappers, or writers.
///
/// Implementation: [ExportServiceImpl] in
/// `lib/export/services/impl/export_service_impl.dart`.
abstract interface class ExportService {
  Future<ExportResultModel> exportAll(ExportDestination destination);
}
