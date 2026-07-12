/// AI- and human-readable representation of this installation's metadata,
/// written to `app_info.json` as part of an export bundle.
///
/// There is exactly one app info record per installation, so this file
/// contains a single JSON object rather than a list.
///
/// Distinct from `metadata.json`, which describes the export bundle itself
/// (when it was generated, what it contains): this model describes the
/// installation the data came from. See `app_info.json`'s entry in
/// `schema.json` for the full meaning of every field.
class AppInfoExportModel {
  const AppInfoExportModel({
    required this.installationIdentifier,
    required this.databaseSchemaVersion,
    required this.applicationVersion,
    this.deviceName,
    this.lastBackupCompletedAt,
    this.lastRestoreCompletedAt,
    required this.recordCreatedAt,
  });

  /// Stable UUID identifying the installation this data came from.
  final String installationIdentifier;

  /// Schema version of the local database at the time of export.
  final int databaseSchemaVersion;

  /// Semantic version of the app that produced this export.
  final String applicationVersion;

  final String? deviceName;
  final DateTime? lastBackupCompletedAt;
  final DateTime? lastRestoreCompletedAt;
  final DateTime recordCreatedAt;

  Map<String, dynamic> toJson() => {
    'installationIdentifier': installationIdentifier,
    'databaseSchemaVersion': databaseSchemaVersion,
    'applicationVersion': applicationVersion,
    'deviceName': deviceName,
    'lastBackupCompletedAt': lastBackupCompletedAt?.toIso8601String(),
    'lastRestoreCompletedAt': lastRestoreCompletedAt?.toIso8601String(),
    'recordCreatedAt': recordCreatedAt.toIso8601String(),
  };
}
