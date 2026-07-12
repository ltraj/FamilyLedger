import 'package:family_ledger/export/converters/app_info_export_mapper.dart';
import 'package:family_ledger/export/models/app_info_export_model.dart';
import 'package:family_ledger/models/app_info_model.dart';

/// Converts an [AppInfoModel] into its export representation. A pure
/// transformation of an already-loaded model — no I/O, no database
/// access.
class AppInfoExportMapperImpl implements AppInfoExportMapper {
  const AppInfoExportMapperImpl();

  @override
  AppInfoExportModel toExportModel(AppInfoModel appInfo) {
    return AppInfoExportModel(
      installationIdentifier: appInfo.installationId,
      databaseSchemaVersion: appInfo.databaseVersion,
      applicationVersion: appInfo.appVersion,
      deviceName: appInfo.deviceName,
      lastBackupCompletedAt: appInfo.lastBackup,
      lastRestoreCompletedAt: appInfo.lastRestore,
      recordCreatedAt: appInfo.createdAt,
    );
  }
}
