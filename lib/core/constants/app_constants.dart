/// Application-wide constant values.
abstract final class AppConstants {
  /// Display name of the application.
  static const String appName = 'Family Ledger';

  /// Default currency code (ISO 4217).
  static const String defaultCurrency = 'INR';

  /// Default currency symbol.
  static const String defaultCurrencySymbol = '₹';

  /// Database file name stored in the app documents directory.
  static const String databaseName = 'family_ledger.db';

  /// Schema version for Drift migrations.
  static const int databaseSchemaVersion = 6;

  /// Semantic version of the app, kept in sync with pubspec.yaml.
  static const String appVersion = '1.0.0+1';
}
