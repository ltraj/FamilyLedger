import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/core/database/mappers/entity_mappers.dart';
import 'package:family_ledger/models/settings_model.dart';
import 'package:family_ledger/repositories/settings_repository.dart';

/// Drift-backed implementation of [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._database);

  final AppDatabase _database;

  static const int _settingsRowId = 1;

  @override
  Future<SettingsModel> getSettings() async {
    final entity =
        await (_database.select(_database.settings)
              ..where((settings) => settings.id.equals(_settingsRowId)))
            .getSingleOrNull();

    if (entity == null) {
      throw StateError('Settings row not found. Database may be corrupted.');
    }

    return EntityMappers.toSettings(entity);
  }

  @override
  Future<bool> update(SettingsModel settings) async {
    final rowsAffected =
        await (_database.update(_database.settings)
              ..where((row) => row.id.equals(_settingsRowId)))
            .write(EntityMappers.toSettingsCompanion(settings));

    return rowsAffected > 0;
  }
}
