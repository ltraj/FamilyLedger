import 'package:family_ledger/models/settings_model.dart';

/// Contract for reading and updating application settings.
abstract interface class SettingsRepository {
  /// Returns the current application settings.
  Future<SettingsModel> getSettings();

  /// Updates application settings. Returns true if the row was updated.
  Future<bool> update(SettingsModel settings);
}
