import 'package:family_ledger/core/constants/enums.dart';

/// Application-wide user preferences.
class SettingsModel {
  const SettingsModel({
    required this.theme,
    required this.currency,
    required this.backupFrequency,
  });

  /// Preferred application theme.
  final AppThemeMode theme;

  /// ISO 4217 currency code (e.g. `INR`).
  final String currency;

  /// How often automatic backups should run.
  final BackupFrequency backupFrequency;

  SettingsModel copyWith({
    AppThemeMode? theme,
    String? currency,
    BackupFrequency? backupFrequency,
  }) {
    return SettingsModel(
      theme: theme ?? this.theme,
      currency: currency ?? this.currency,
      backupFrequency: backupFrequency ?? this.backupFrequency,
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'currency': currency,
    'backupFrequency': backupFrequency.name,
  };

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      theme: AppThemeMode.values.byName(json['theme'] as String),
      currency: json['currency'] as String,
      backupFrequency: BackupFrequency.values.byName(
        json['backupFrequency'] as String,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModel &&
          theme == other.theme &&
          currency == other.currency &&
          backupFrequency == other.backupFrequency;

  @override
  int get hashCode => Object.hash(theme, currency, backupFrequency);
}
