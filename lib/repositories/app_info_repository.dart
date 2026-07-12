import 'package:family_ledger/models/app_info_model.dart';

/// Contract for reading and updating application metadata.
abstract interface class AppInfoRepository {
  /// Returns the single application info row.
  Future<AppInfoModel> getAppInfo();

  /// Updates the application info row. Returns true if the row was updated.
  Future<bool> update(AppInfoModel appInfo);

  /// Records [timestamp] as the most recent successful backup.
  Future<bool> recordBackup(DateTime timestamp);

  /// Records [timestamp] as the most recent successful restore.
  Future<bool> recordRestore(DateTime timestamp);
}
