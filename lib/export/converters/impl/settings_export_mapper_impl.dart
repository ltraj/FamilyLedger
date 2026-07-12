import 'package:family_ledger/export/converters/settings_export_mapper.dart';
import 'package:family_ledger/export/models/settings_export_model.dart';
import 'package:family_ledger/models/settings_model.dart';

/// Converts a [SettingsModel] into its export representation. A pure
/// transformation of an already-loaded model — no I/O, no database
/// access.
class SettingsExportMapperImpl implements SettingsExportMapper {
  const SettingsExportMapperImpl();

  @override
  SettingsExportModel toExportModel(SettingsModel settings) {
    return SettingsExportModel(
      themePreference: settings.theme.name,
      currencyCode: settings.currency,
      automaticBackupFrequency: settings.backupFrequency.name,
    );
  }
}
