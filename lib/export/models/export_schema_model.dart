/// Describes the JSON data type of an [ExportFieldSchema] in plain
/// language, so `schema.json` is understandable without any Dart type
/// knowledge.
enum ExportFieldDataType {
  text,
  wholeNumber,
  decimalNumber,
  trueOrFalse,
  dateAndTime,
  fileName,
  listOfObjects;

  /// Plain-language label written into `schema.json` for this data type.
  String get label => switch (this) {
    ExportFieldDataType.text => 'Text',
    ExportFieldDataType.wholeNumber => 'Whole number',
    ExportFieldDataType.decimalNumber => 'Decimal number',
    ExportFieldDataType.trueOrFalse => 'True or false',
    ExportFieldDataType.dateAndTime => 'Date and time (ISO 8601 format)',
    ExportFieldDataType.fileName =>
      'File name (relative to the attachments folder)',
    ExportFieldDataType.listOfObjects => 'List of objects',
  };
}

/// Documents a single field of a single exported file.
///
/// This is the structural building block of `schema.json`. Every field
/// written by any export model must have exactly one [ExportFieldSchema]
/// entry describing it, so every exported file is self-explanatory to a
/// reader without access to the Dart source.
class ExportFieldSchema {
  const ExportFieldSchema({
    required this.fieldName,
    required this.description,
    required this.dataType,
    this.isNullable = false,
    this.valueMeanings,
  });

  /// Exact JSON key as it appears in the exported file, e.g. `amount`.
  final String fieldName;

  /// Plain-language explanation of what this field represents.
  final String description;

  final ExportFieldDataType dataType;

  /// Whether this field may be `null` in the exported JSON.
  final bool isNullable;

  /// Explains specific values this field can take.
  ///
  /// For enum-like fields, keys are the exact values the field can hold
  /// (e.g. `permanent`, `temporary`). For a signed numeric field such as a
  /// transaction's `amount`, keys instead describe a sign (`positive`,
  /// `negative`). Null when [description] alone is sufficient.
  final Map<String, String>? valueMeanings;

  Map<String, dynamic> toJson() => {
    'field': fieldName,
    'description': description,
    'dataType': dataType.label,
    'nullable': isNullable,
    if (valueMeanings != null) ...valueMeanings!,
  };
}

/// Documents every field of a single exported file, e.g. `transactions.json`.
class ExportFileSchema {
  const ExportFileSchema({
    required this.fileName,
    required this.description,
    required this.fields,
  });

  /// Name of the described file or folder, e.g. `transactions.json`.
  final String fileName;

  /// Plain-language explanation of what this file or folder contains.
  final String description;

  /// One entry per field written by this file's export model. Empty for
  /// folders that hold raw files rather than JSON objects, such as
  /// `attachments`.
  final List<ExportFieldSchema> fields;

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'description': description,
    'fields': fields.map((field) => field.toJson()).toList(),
  };
}

/// The complete self-documentation of an export bundle, written to
/// `schema.json`.
///
/// Built from the static declarations in `ExportSchemaCatalog` (see
/// `lib/export/schema/export_schema_catalog.dart`). Every other file in the
/// bundle should be interpretable by reading this one first.
class ExportSchemaDocument {
  const ExportSchemaDocument({
    required this.exportFormatVersion,
    required this.fileSchemas,
  });

  final int exportFormatVersion;

  /// One entry per file/folder in the export bundle, including
  /// `metadata.json` itself.
  final List<ExportFileSchema> fileSchemas;

  Map<String, dynamic> toJson() => {
    'exportFormatVersion': exportFormatVersion,
    'files': fileSchemas.map((file) => file.toJson()).toList(),
  };
}
