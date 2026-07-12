/// AI- and human-readable representation of application settings, written
/// to `settings.json` as part of an export bundle.
///
/// There is exactly one settings record per installation, so this file
/// contains a single JSON object rather than a list. See `settings.json`'s
/// entry in `schema.json` for the full meaning of every field.
class SettingsExportModel {
  const SettingsExportModel({
    required this.themePreference,
    required this.currencyCode,
    required this.automaticBackupFrequency,
  });

  /// `system`, `light`, or `dark`.
  final String themePreference;

  /// ISO 4217 currency code, e.g. `INR`.
  final String currencyCode;

  /// `never`, `daily`, `weekly`, or `monthly`.
  final String automaticBackupFrequency;

  Map<String, dynamic> toJson() => {
    'themePreference': themePreference,
    'currencyCode': currencyCode,
    'automaticBackupFrequency': automaticBackupFrequency,
  };
}
