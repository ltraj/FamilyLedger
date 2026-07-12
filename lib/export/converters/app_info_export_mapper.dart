import 'package:family_ledger/export/models/app_info_export_model.dart';
import 'package:family_ledger/models/app_info_model.dart';

/// Contract for converting an [AppInfoModel] into its export
/// representation.
///
/// No implementation exists yet.
abstract interface class AppInfoExportMapper {
  AppInfoExportModel toExportModel(AppInfoModel appInfo);
}
