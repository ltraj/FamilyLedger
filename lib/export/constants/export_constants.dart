/// Constant values describing the shape of an export bundle: file names,
/// the attachments folder name, and the export bundle's own format version.
abstract final class ExportConstants {
  /// Version of the export bundle format itself.
  ///
  /// Deliberately independent from the database schema version
  /// (`AppConstants.databaseSchemaVersion`) and the app version
  /// (`AppConstants.appVersion`): the export format — file names, field
  /// names, schema.json's structure — can change without a database
  /// migration or an app release, and vice versa. A future importer should
  /// branch on this number, not on the app version.
  static const int exportFormatVersion = 1;

  /// Describes the export bundle itself. Always the first file a reader
  /// should open.
  static const String metadataFileName = 'metadata.json';

  /// Explains every field in every other exported file.
  static const String schemaFileName = 'schema.json';

  static const String peopleFileName = 'people.json';
  static const String transactionsFileName = 'transactions.json';
  static const String categoriesFileName = 'categories.json';
  static const String settingsFileName = 'settings.json';
  static const String appInfoFileName = 'app_info.json';

  /// The same transactions as `transactions.json`, denormalized into a
  /// spreadsheet-friendly CSV.
  static const String ledgerCsvFileName = 'ledger.csv';

  /// Plain-language summary of the bundle and restore instructions.
  static const String readmeFileName = 'README.md';

  /// Folder holding every file referenced by a `photographFileName` or
  /// `attachmentFileName` field elsewhere in the bundle.
  static const String attachmentsFolderName = 'attachments';
}
