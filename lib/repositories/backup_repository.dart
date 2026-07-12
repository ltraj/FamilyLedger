import 'package:family_ledger/models/backup_model.dart';

/// Contract for persisting and retrieving backup records.
abstract interface class BackupRepository {
  /// Returns all backup records ordered by date descending.
  Future<List<BackupModel>> getAll();

  /// Returns a single backup record by [id], or null if not found.
  Future<BackupModel?> getById(int id);

  /// Inserts a new backup record and returns the generated ID.
  Future<int> insert(BackupModel backup);

  /// Permanently deletes a backup record by [id].
  Future<bool> delete(int id);
}
