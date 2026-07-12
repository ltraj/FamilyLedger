/// A record of a database backup file.
class BackupModel {
  const BackupModel({
    this.id,
    required this.backupDate,
    required this.backupPath,
    required this.backupSize,
  });

  /// Unique identifier. Null when the backup record has not yet been persisted.
  final int? id;

  /// Timestamp when the backup was created.
  final DateTime backupDate;

  /// Local file path to the backup file.
  final String backupPath;

  /// Size of the backup file in bytes.
  final int backupSize;

  BackupModel copyWith({
    int? id,
    DateTime? backupDate,
    String? backupPath,
    int? backupSize,
  }) {
    return BackupModel(
      id: id ?? this.id,
      backupDate: backupDate ?? this.backupDate,
      backupPath: backupPath ?? this.backupPath,
      backupSize: backupSize ?? this.backupSize,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'backupDate': backupDate.toIso8601String(),
    'backupPath': backupPath,
    'backupSize': backupSize,
  };

  factory BackupModel.fromJson(Map<String, dynamic> json) {
    return BackupModel(
      id: json['id'] as int?,
      backupDate: DateTime.parse(json['backupDate'] as String),
      backupPath: json['backupPath'] as String,
      backupSize: json['backupSize'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupModel &&
          id == other.id &&
          backupDate == other.backupDate &&
          backupPath == other.backupPath &&
          backupSize == other.backupSize;

  @override
  int get hashCode => Object.hash(id, backupDate, backupPath, backupSize);
}
