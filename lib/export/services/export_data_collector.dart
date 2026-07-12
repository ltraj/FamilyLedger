import 'package:family_ledger/export/models/app_info_export_model.dart';
import 'package:family_ledger/export/models/attachment_reference_model.dart';
import 'package:family_ledger/export/models/category_export_model.dart';
import 'package:family_ledger/export/models/person_export_model.dart';
import 'package:family_ledger/export/models/settings_export_model.dart';
import 'package:family_ledger/export/models/transaction_export_model.dart';

/// Contract for gathering every piece of data an export bundle needs,
/// already converted into export models.
///
/// A future implementation will depend on the existing repository
/// interfaces (`PeopleRepository`, `TransactionRepository`, etc. — see
/// `lib/repositories/`) and the converters in `lib/export/converters/` to
/// build these lists. Repositories and converters are intentionally not
/// referenced from this interface itself, so this contract stays stable
/// even if the underlying persistence layer changes.
///
/// Implementation: [ExportDataCollectorImpl] in
/// `lib/export/services/impl/export_data_collector_impl.dart`.
abstract interface class ExportDataCollector {
  Future<List<PersonExportModel>> collectPeople();

  Future<List<CategoryExportModel>> collectCategories();

  Future<List<TransactionExportModel>> collectTransactions();

  Future<SettingsExportModel> collectSettings();

  Future<AppInfoExportModel> collectApplicationInfo();

  /// Every attachment file that needs to be copied into the attachments
  /// folder, gathered from both people (photographs) and transactions.
  Future<List<AttachmentReferenceModel>> collectAttachmentReferences();
}
