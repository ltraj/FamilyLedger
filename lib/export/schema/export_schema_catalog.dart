import 'package:family_ledger/export/constants/export_constants.dart';
import 'package:family_ledger/export/models/export_schema_model.dart';

/// Static catalog of field-by-field documentation for every file in an
/// export bundle.
///
/// This is the single source of truth for the content of `schema.json`.
/// It is pure declarative data — no I/O, no dependency on repositories or
/// the database — so it can be reviewed and extended independently of any
/// future export-writing logic.
///
/// Whenever a field is added to, removed from, or renamed in one of the
/// `lib/export/models/*.dart` export models, the corresponding entry here
/// must be updated in the same change. A future test, added alongside the
/// export writer implementation, should assert that every `toJson()` key
/// produced by each export model has a matching entry here.
abstract final class ExportSchemaCatalog {
  /// Builds the full `schema.json` document for the current
  /// [ExportConstants.exportFormatVersion].
  static ExportSchemaDocument get document => const ExportSchemaDocument(
    exportFormatVersion: ExportConstants.exportFormatVersion,
    fileSchemas: [
      _metadataSchema,
      _peopleSchema,
      _categoriesSchema,
      _transactionsSchema,
      _settingsSchema,
      _appInfoSchema,
      _attachmentsSchema,
    ],
  );

  static const ExportFileSchema _metadataSchema = ExportFileSchema(
    fileName: ExportConstants.metadataFileName,
    description:
        'Describes this export bundle itself: when it was generated, which '
        'app and database version produced it, and a table of contents for '
        'every other file in the bundle. Read this file first.',
    fields: [
      ExportFieldSchema(
        fieldName: 'exportFormatVersion',
        description:
            'Version of the export bundle format. Increases whenever file '
            'names, field names, or the schema.json structure change. '
            'Independent of the app version and database schema version.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'exportGeneratedAt',
        description: 'When this export bundle was generated.',
        dataType: ExportFieldDataType.dateAndTime,
      ),
      ExportFieldSchema(
        fieldName: 'applicationVersion',
        description: 'Semantic version of the app that produced this export.',
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'databaseSchemaVersion',
        description:
            'Schema version of the local database at the time of export.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'installationIdentifier',
        description:
            'Stable identifier of the installation this export came from. '
            'Two exports with the same value came from the same device.',
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'deviceName',
        description: 'Human-readable name of the device this export came from.',
        dataType: ExportFieldDataType.text,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'timezone',
        description:
            "The device's local timezone at export time, e.g. "
            '"IST (UTC+05:30)". All dateAndTime fields elsewhere in this '
            'bundle are still stored in UTC (ISO 8601); this field is '
            'context for a human reader, not a conversion instruction.',
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'currencyCode',
        description:
            'ISO 4217 currency code in effect for every amount in this '
            'export. Matches currencyCode in settings.json.',
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'totalPeopleCount',
        description: 'Total number of entries in people.json.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'totalTransactionCount',
        description: 'Total number of entries in transactions.json.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'totalCategoryCount',
        description: 'Total number of entries in categories.json.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'checksum',
        description:
            'SHA-256 hex digest of people.json, categories.json, '
            'transactions.json, settings.json, and app_info.json '
            'concatenated in that order. An importer should recompute '
            'this and refuse to import on a mismatch, since it means the '
            'bundle was altered or corrupted after export.',
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'includedFiles',
        description:
            'One entry per file/folder in this export bundle, each with a '
            'file name, description, and record count, in the order they '
            'appear on disk.',
        dataType: ExportFieldDataType.listOfObjects,
      ),
    ],
  );

  static const ExportFileSchema _peopleSchema = ExportFileSchema(
    fileName: ExportConstants.peopleFileName,
    description:
        'One entry per person tracked in the ledger, including archived '
        'people. Balances are never stored; they are always calculated '
        'from transactions.json at read time.',
    fields: [
      ExportFieldSchema(
        fieldName: 'personIdentifier',
        description:
            'Identifier for this person, unique within this export. '
            'Referenced by personIdentifier in transactions.json.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'fullName',
        description: "The person's display name.",
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'contactType',
        description: 'Whether this is a long-term or short-term contact.',
        dataType: ExportFieldDataType.text,
        valueMeanings: {
          'permanent': 'A long-term contact, e.g. a family member.',
          'temporary': 'A short-term contact, e.g. a one-time helper.',
        },
      ),
      ExportFieldSchema(
        fieldName: 'lifecycleStatus',
        description: "The person's visibility in the app.",
        dataType: ExportFieldDataType.text,
        valueMeanings: {
          'active': 'Visible and can receive new transactions.',
          'archived':
              'Hidden from active lists; existing transactions are '
              'preserved.',
        },
      ),
      ExportFieldSchema(
        fieldName: 'photographFileName',
        description:
            "File name of the person's photograph inside the attachments "
            'folder.',
        dataType: ExportFieldDataType.fileName,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'sortPosition',
        description:
            "This person's position in the user's custom sort order. "
            'Lower values sort first. Not necessarily contiguous — do '
            'not assume adjacent people differ by exactly 1.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'avatarColorSeed',
        description:
            "Seed used to generate this person's avatar color and "
            'initial in the app\'s user interface. Null means the app '
            'derives it from personIdentifier instead. Not meaningful '
            'outside the app.',
        dataType: ExportFieldDataType.wholeNumber,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'recordCreatedAt',
        description: 'When this person was first added.',
        dataType: ExportFieldDataType.dateAndTime,
      ),
      ExportFieldSchema(
        fieldName: 'recordUpdatedAt',
        description: 'When this person was last edited.',
        dataType: ExportFieldDataType.dateAndTime,
      ),
    ],
  );

  static const ExportFileSchema _categoriesSchema = ExportFileSchema(
    fileName: ExportConstants.categoriesFileName,
    description:
        'One entry per expense category used to classify transactions.',
    fields: [
      ExportFieldSchema(
        fieldName: 'categoryIdentifier',
        description:
            'Identifier for this category, unique within this export. '
            'Referenced by categoryIdentifier in transactions.json.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'categoryName',
        description: 'Display name of the category.',
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'iconIdentifier',
        description:
            'Identifier of the icon used to represent this category in '
            "the app's user interface. Not meaningful outside the app.",
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'colorHexCode',
        description:
            'Hex color code (e.g. #FF9800) used to represent this '
            "category in the app's user interface.",
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'isSystemDefinedDefault',
        description:
            'True if this category was created by the app itself; false '
            'if the user created it.',
        dataType: ExportFieldDataType.trueOrFalse,
      ),
      ExportFieldSchema(
        fieldName: 'recordCreatedAt',
        description: 'When this category was created.',
        dataType: ExportFieldDataType.dateAndTime,
      ),
    ],
  );

  static const ExportFileSchema _transactionsSchema = ExportFileSchema(
    fileName: ExportConstants.transactionsFileName,
    description:
        'One entry per financial movement between the user and a person. '
        "A person's balance is the sum of their transactions' amount "
        'values.',
    fields: [
      ExportFieldSchema(
        fieldName: 'transactionIdentifier',
        description:
            'Identifier for this transaction, unique within this '
            'export.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'personIdentifier',
        description:
            'Identifies which person this transaction belongs to. '
            'Matches a personIdentifier value in people.json.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'categoryIdentifier',
        description:
            'Identifies the expense category of this transaction, if '
            'any. Matches a categoryIdentifier value in categories.json.',
        dataType: ExportFieldDataType.wholeNumber,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'transactionType',
        description: 'The kind of financial movement this record represents.',
        dataType: ExportFieldDataType.text,
        valueMeanings: {
          'advanceReceived': 'Money received in advance from the person.',
          'expensePaid':
              'An expense paid using advance money, or the person\'s own '
              'money if the balance was already negative.',
          'moneyReturned': 'Money returned to the person.',
          'adjustment':
              'A manual correction to the balance, positive or negative.',
        },
      ),
      ExportFieldSchema(
        fieldName: 'amount',
        description: 'Signed transaction amount.',
        dataType: ExportFieldDataType.decimalNumber,
        valueMeanings: {
          'positive': 'Money received.',
          'negative': 'Money spent.',
        },
      ),
      ExportFieldSchema(
        fieldName: 'remark',
        description: 'Free-text note attached to the transaction.',
        dataType: ExportFieldDataType.text,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'attachmentFileName',
        description:
            'File name of an attachment (receipt, bill, etc.) inside the '
            'attachments folder.',
        dataType: ExportFieldDataType.fileName,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'transactionDate',
        description:
            'Date and time the transaction occurred, as shown to the '
            'user in the app. May differ from recordCreatedAt if entered '
            'after the fact.',
        dataType: ExportFieldDataType.dateAndTime,
      ),
      ExportFieldSchema(
        fieldName: 'runningBalance',
        description:
            "This person's balance immediately after this transaction, "
            'in chronological order. A convenience figure only — never a '
            'source of truth. Balances are always derived fresh from '
            'transaction history; recompute from amount values if in '
            'doubt.',
        dataType: ExportFieldDataType.decimalNumber,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'recordCreatedAt',
        description: 'When this transaction record was created.',
        dataType: ExportFieldDataType.dateAndTime,
      ),
      ExportFieldSchema(
        fieldName: 'recordUpdatedAt',
        description: 'When this transaction record was last edited.',
        dataType: ExportFieldDataType.dateAndTime,
      ),
    ],
  );

  static const ExportFileSchema _settingsSchema = ExportFileSchema(
    fileName: ExportConstants.settingsFileName,
    description:
        'The single application settings record for this installation. A '
        'JSON object, not a list.',
    fields: [
      ExportFieldSchema(
        fieldName: 'themePreference',
        description: 'Preferred application theme.',
        dataType: ExportFieldDataType.text,
        valueMeanings: {
          'system': "Follow the device's system setting.",
          'light': 'Always use the light theme.',
          'dark': 'Always use the dark theme.',
        },
      ),
      ExportFieldSchema(
        fieldName: 'currencyCode',
        description: 'ISO 4217 currency code used to display amounts.',
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'automaticBackupFrequency',
        description: 'How often automatic backups are created.',
        dataType: ExportFieldDataType.text,
        valueMeanings: {
          'never': 'Automatic backups are disabled.',
          'daily': 'A backup is created once per day.',
          'weekly': 'A backup is created once per week.',
          'monthly': 'A backup is created once per month.',
        },
      ),
    ],
  );

  static const ExportFileSchema _appInfoSchema = ExportFileSchema(
    fileName: ExportConstants.appInfoFileName,
    description:
        'The single application metadata record for this installation. '
        'Describes the installation the data came from, as opposed to '
        'metadata.json, which describes this export bundle. A JSON '
        'object, not a list.',
    fields: [
      ExportFieldSchema(
        fieldName: 'installationIdentifier',
        description: 'Stable identifier of this installation.',
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'databaseSchemaVersion',
        description:
            'Schema version of the local database at the time of export.',
        dataType: ExportFieldDataType.wholeNumber,
      ),
      ExportFieldSchema(
        fieldName: 'applicationVersion',
        description:
            'Semantic version of the app that created or last touched '
            'this record.',
        dataType: ExportFieldDataType.text,
      ),
      ExportFieldSchema(
        fieldName: 'deviceName',
        description: 'Human-readable name of this device.',
        dataType: ExportFieldDataType.text,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'lastBackupCompletedAt',
        description: 'When the most recent successful backup completed.',
        dataType: ExportFieldDataType.dateAndTime,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'lastRestoreCompletedAt',
        description: 'When the most recent successful restore completed.',
        dataType: ExportFieldDataType.dateAndTime,
        isNullable: true,
      ),
      ExportFieldSchema(
        fieldName: 'recordCreatedAt',
        description:
            "When this installation's app info record was first created.",
        dataType: ExportFieldDataType.dateAndTime,
      ),
    ],
  );

  static const ExportFileSchema _attachmentsSchema = ExportFileSchema(
    fileName: ExportConstants.attachmentsFolderName,
    description:
        'Folder containing every file referenced by photographFileName in '
        'people.json and attachmentFileName in transactions.json. Not a '
        'JSON file, so it has no fields of its own — files inside it are '
        'named by whichever record references them and carry no further '
        'internal structure.',
    fields: [],
  );
}
