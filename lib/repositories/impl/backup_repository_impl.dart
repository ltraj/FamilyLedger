import 'package:drift/drift.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/core/database/mappers/entity_mappers.dart';
import 'package:family_ledger/models/backup_model.dart';
import 'package:family_ledger/repositories/backup_repository.dart';

/// Drift-backed implementation of [BackupRepository].
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<BackupModel>> getAll() async {
    final entities = await (_database.select(
      _database.backups,
    )..orderBy([(backup) => OrderingTerm.desc(backup.backupDate)])).get();

    return entities.map(EntityMappers.toBackup).toList();
  }

  @override
  Future<BackupModel?> getById(int id) async {
    final entity = await (_database.select(
      _database.backups,
    )..where((backup) => backup.id.equals(id))).getSingleOrNull();

    return entity == null ? null : EntityMappers.toBackup(entity);
  }

  @override
  Future<int> insert(BackupModel backup) {
    return _database
        .into(_database.backups)
        .insert(EntityMappers.toBackupCompanion(backup));
  }

  @override
  Future<bool> delete(int id) async {
    final rowsAffected = await (_database.delete(
      _database.backups,
    )..where((backup) => backup.id.equals(id))).go();

    return rowsAffected > 0;
  }
}
