import 'package:family_ledger/core/constants/enums.dart';

/// Application-wide user preferences.
class SettingsModel {
  const SettingsModel({
    required this.theme,
    required this.currency,
    required this.backupFrequency,
    this.autoBackupIntervalDays,
    this.autoBackupDirectory,
  });

  /// Preferred application theme.
  final AppThemeMode theme;

  /// ISO 4217 currency code (e.g. `INR`).
  final String currency;

  /// How often automatic backups should run.
  ///
  /// Legacy field superseded by [autoBackupIntervalDays] — see
  /// `settings_table.dart` for why it's kept. Nothing schedules from it.
  final BackupFrequency backupFrequency;

  /// Days between automatic backups; null means automatic backup is off.
  final int? autoBackupIntervalDays;

  /// Folder automatic backups are written into; null until first chosen.
  final String? autoBackupDirectory;

  /// Whether automatic backup is enabled at all.
  bool get isAutoBackupEnabled => autoBackupIntervalDays != null;

  /// [clearAutoBackupIntervalDays]/[clearAutoBackupDirectory] exist
  /// because both fields legitimately need to be *cleared* (turning the
  /// feature off), which a plain `null ?? this.x` copyWith can't express —
  /// the same explicit-null pattern as `TransactionQuery.copyWith`.
  SettingsModel copyWith({
    AppThemeMode? theme,
    String? currency,
    BackupFrequency? backupFrequency,
    int? autoBackupIntervalDays,
    bool clearAutoBackupIntervalDays = false,
    String? autoBackupDirectory,
    bool clearAutoBackupDirectory = false,
  }) {
    return SettingsModel(
      theme: theme ?? this.theme,
      currency: currency ?? this.currency,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      autoBackupIntervalDays: clearAutoBackupIntervalDays
          ? null
          : (autoBackupIntervalDays ?? this.autoBackupIntervalDays),
      autoBackupDirectory: clearAutoBackupDirectory
          ? null
          : (autoBackupDirectory ?? this.autoBackupDirectory),
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'currency': currency,
    'backupFrequency': backupFrequency.name,
    'autoBackupIntervalDays': autoBackupIntervalDays,
    'autoBackupDirectory': autoBackupDirectory,
  };

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      theme: AppThemeMode.values.byName(json['theme'] as String),
      currency: json['currency'] as String,
      backupFrequency: BackupFrequency.values.byName(
        json['backupFrequency'] as String,
      ),
      // Absent in JSON written before these fields existed — falls back
      // to null (automatic backup off) rather than failing to parse.
      autoBackupIntervalDays: json['autoBackupIntervalDays'] as int?,
      autoBackupDirectory: json['autoBackupDirectory'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModel &&
          theme == other.theme &&
          currency == other.currency &&
          backupFrequency == other.backupFrequency &&
          autoBackupIntervalDays == other.autoBackupIntervalDays &&
          autoBackupDirectory == other.autoBackupDirectory;

  @override
  int get hashCode => Object.hash(
    theme,
    currency,
    backupFrequency,
    autoBackupIntervalDays,
    autoBackupDirectory,
  );
}
