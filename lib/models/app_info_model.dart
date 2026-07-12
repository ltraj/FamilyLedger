/// Application metadata retained for future maintenance tooling.
class AppInfoModel {
  const AppInfoModel({
    this.id,
    required this.databaseVersion,
    required this.appVersion,
    required this.createdAt,
    this.lastBackup,
    this.lastRestore,
    required this.installationId,
    this.deviceName,
  });

  /// Unique identifier. Null when the row has not yet been persisted.
  final int? id;

  /// Schema version of the database at the time this row was written.
  final int databaseVersion;

  /// Semantic version of the app that created/last touched this row.
  final String appVersion;

  /// Timestamp when this installation's app info was first created.
  final DateTime createdAt;

  /// Timestamp of the most recent successful backup, if any.
  final DateTime? lastBackup;

  /// Timestamp of the most recent successful restore, if any.
  final DateTime? lastRestore;

  /// Stable UUID identifying this installation.
  final String installationId;

  /// Optional human-readable device name.
  final String? deviceName;

  AppInfoModel copyWith({
    int? id,
    int? databaseVersion,
    String? appVersion,
    DateTime? createdAt,
    DateTime? lastBackup,
    DateTime? lastRestore,
    String? installationId,
    String? deviceName,
  }) {
    return AppInfoModel(
      id: id ?? this.id,
      databaseVersion: databaseVersion ?? this.databaseVersion,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt ?? this.createdAt,
      lastBackup: lastBackup ?? this.lastBackup,
      lastRestore: lastRestore ?? this.lastRestore,
      installationId: installationId ?? this.installationId,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'databaseVersion': databaseVersion,
    'appVersion': appVersion,
    'createdAt': createdAt.toIso8601String(),
    'lastBackup': lastBackup?.toIso8601String(),
    'lastRestore': lastRestore?.toIso8601String(),
    'installationId': installationId,
    'deviceName': deviceName,
  };

  factory AppInfoModel.fromJson(Map<String, dynamic> json) {
    return AppInfoModel(
      id: json['id'] as int?,
      databaseVersion: json['databaseVersion'] as int,
      appVersion: json['appVersion'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastBackup: json['lastBackup'] == null
          ? null
          : DateTime.parse(json['lastBackup'] as String),
      lastRestore: json['lastRestore'] == null
          ? null
          : DateTime.parse(json['lastRestore'] as String),
      installationId: json['installationId'] as String,
      deviceName: json['deviceName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfoModel &&
          id == other.id &&
          databaseVersion == other.databaseVersion &&
          appVersion == other.appVersion &&
          createdAt == other.createdAt &&
          lastBackup == other.lastBackup &&
          lastRestore == other.lastRestore &&
          installationId == other.installationId &&
          deviceName == other.deviceName;

  @override
  int get hashCode => Object.hash(
    id,
    databaseVersion,
    appVersion,
    createdAt,
    lastBackup,
    lastRestore,
    installationId,
    deviceName,
  );
}
