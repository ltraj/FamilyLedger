import 'package:family_ledger/export/models/exported_file_descriptor_model.dart';

/// AI- and human-readable description of an export bundle itself, written
/// to `metadata.json`.
///
/// This is the first file a reader (human or AI) should open: it identifies
/// the export format and the installation it came from, and lists every
/// other file in the bundle before any entity data is read.
///
/// Distinct from `app_info.json`: this model describes the export bundle
/// (when it was generated, what it contains); `app_info.json` describes the
/// installation the data came from.
class ExportMetadataModel {
  const ExportMetadataModel({
    required this.exportFormatVersion,
    required this.exportGeneratedAt,
    required this.applicationVersion,
    required this.databaseSchemaVersion,
    required this.installationIdentifier,
    this.deviceName,
    required this.timezone,
    required this.currencyCode,
    required this.totalPeopleCount,
    required this.totalTransactionCount,
    required this.totalCategoryCount,
    required this.checksum,
    required this.includedFiles,
  });

  /// Version of the export bundle's own format.
  ///
  /// Deliberately tracked separately from [databaseSchemaVersion] and
  /// [applicationVersion] so the export format can evolve independently of
  /// database migrations and app releases. A future reader/importer should
  /// branch on this number.
  final int exportFormatVersion;

  /// When this export bundle was generated.
  final DateTime exportGeneratedAt;

  /// Semantic version of the app that produced this export.
  final String applicationVersion;

  /// Schema version of the local database at the time of export.
  final int databaseSchemaVersion;

  /// Stable UUID identifying the installation this export came from.
  final String installationIdentifier;

  final String? deviceName;

  /// The device's local timezone at export time, e.g. `IST (UTC+05:30)`.
  final String timezone;

  /// The currency in effect for every amount in this export, e.g. `INR`.
  final String currencyCode;

  final int totalPeopleCount;
  final int totalTransactionCount;
  final int totalCategoryCount;

  /// SHA-256 digest of the bundle's primary data files, computed by
  /// [ExportChecksum.combinedSha256]. Lets an importer detect corruption or
  /// tampering before touching the database. See that class for exactly
  /// which files and order it covers.
  final String checksum;

  /// One entry per file/folder in this export bundle, in the order they
  /// appear on disk.
  final List<ExportedFileDescriptorModel> includedFiles;

  Map<String, dynamic> toJson() => {
    'exportFormatVersion': exportFormatVersion,
    'exportGeneratedAt': exportGeneratedAt.toIso8601String(),
    'applicationVersion': applicationVersion,
    'databaseSchemaVersion': databaseSchemaVersion,
    'installationIdentifier': installationIdentifier,
    'deviceName': deviceName,
    'timezone': timezone,
    'currencyCode': currencyCode,
    'totalPeopleCount': totalPeopleCount,
    'totalTransactionCount': totalTransactionCount,
    'totalCategoryCount': totalCategoryCount,
    'checksum': checksum,
    'includedFiles': includedFiles.map((file) => file.toJson()).toList(),
  };

  factory ExportMetadataModel.fromJson(Map<String, dynamic> json) {
    return ExportMetadataModel(
      exportFormatVersion: json['exportFormatVersion'] as int,
      exportGeneratedAt: DateTime.parse(json['exportGeneratedAt'] as String),
      applicationVersion: json['applicationVersion'] as String,
      databaseSchemaVersion: json['databaseSchemaVersion'] as int,
      installationIdentifier: json['installationIdentifier'] as String,
      deviceName: json['deviceName'] as String?,
      timezone: json['timezone'] as String,
      currencyCode: json['currencyCode'] as String,
      totalPeopleCount: json['totalPeopleCount'] as int,
      totalTransactionCount: json['totalTransactionCount'] as int,
      totalCategoryCount: json['totalCategoryCount'] as int,
      checksum: json['checksum'] as String,
      includedFiles: (json['includedFiles'] as List<dynamic>)
          .map(
            (file) => ExportedFileDescriptorModel.fromJson(
              file as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
