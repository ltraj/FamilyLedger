import 'package:family_ledger/export/models/settings_export_model.dart';
import 'package:family_ledger/models/settings_model.dart';

/// Contract for converting a [SettingsModel] into its export
/// representation.
///
/// No implementation exists yet.
abstract interface class SettingsExportMapper {
  SettingsExportModel toExportModel(SettingsModel settings);
}
