import 'package:family_ledger/export/models/export_metadata_model.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/settings_model.dart';
import 'package:family_ledger/models/transaction_model.dart';

/// A fully parsed, validated backup bundle, ready to be written into the
/// database by [RestoreService].
///
/// Only ever constructed by [ImportValidator] after every structural and
/// integrity check has passed — there is no path that hands a
/// [RestoreService] partially-checked data.
class ImportBundleModel {
  const ImportBundleModel({
    required this.metadata,
    required this.people,
    required this.categories,
    required this.transactions,
    required this.settings,
    required this.attachmentsDirectoryPath,
  });

  /// The backup's own metadata.json, already validated (format version,
  /// checksum).
  final ExportMetadataModel metadata;

  final List<PersonModel> people;
  final List<CategoryModel> categories;
  final List<TransactionModel> transactions;
  final SettingsModel settings;

  /// Absolute path to the extracted bundle's `attachments` folder, whether
  /// or not it contains any files. [RestoreService] resolves
  /// `photoPath`/`attachmentPath` values against this.
  final String attachmentsDirectoryPath;
}
