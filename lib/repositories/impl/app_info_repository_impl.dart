import 'package:drift/drift.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/core/database/mappers/entity_mappers.dart';
import 'package:family_ledger/models/app_info_model.dart';
import 'package:family_ledger/repositories/app_info_repository.dart';

/// Drift-backed implementation of [AppInfoRepository].
class AppInfoRepositoryImpl implements AppInfoRepository {
  AppInfoRepositoryImpl(this._database);

  final AppDatabase _database;

  static const int _appInfoRowId = 1;

  @override
  Future<AppInfoModel> getAppInfo() async {
    final entity = await (_database.select(
      _database.appInfo,
    )..where((row) => row.id.equals(_appInfoRowId))).getSingleOrNull();

    if (entity == null) {
      throw StateError('AppInfo row not found. Database may be corrupted.');
    }

    return EntityMappers.toAppInfo(entity);
  }

  @override
  Future<bool> update(AppInfoModel appInfo) async {
    final rowsAffected =
        await (_database.update(_database.appInfo)
              ..where((row) => row.id.equals(_appInfoRowId)))
            .write(EntityMappers.toAppInfoCompanion(appInfo));

    return rowsAffected > 0;
  }

  @override
  Future<bool> recordBackup(DateTime timestamp) async {
    final rowsAffected =
        await (_database.update(_database.appInfo)
              ..where((row) => row.id.equals(_appInfoRowId)))
            .write(AppInfoCompanion(lastBackup: Value(timestamp)));

    return rowsAffected > 0;
  }

  @override
  Future<bool> recordRestore(DateTime timestamp) async {
    final rowsAffected =
        await (_database.update(_database.appInfo)
              ..where((row) => row.id.equals(_appInfoRowId)))
            .write(AppInfoCompanion(lastRestore: Value(timestamp)));

    return rowsAffected > 0;
  }
}
