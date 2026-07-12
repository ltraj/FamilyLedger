import 'package:family_ledger/backup/models/backup_result_model.dart';
import 'package:family_ledger/backup/models/restore_result_model.dart';
import 'package:family_ledger/features/backup/providers/backup_info_state.dart';
import 'package:family_ledger/features/backup/providers/backup_service_providers.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the Backup screen's info card, and runs export/restore through
/// `BackupService`/`RestoreService`.
///
/// Deliberately does not track "operation in progress" itself — that's
/// transient UI state owned by the screen, not data loaded from
/// anywhere — see `BackupScreen`'s local `_isBackingUp`/`_isRestoring`.
final backupViewModelProvider =
    AsyncNotifierProvider<BackupViewModel, BackupInfoState>(
      BackupViewModel.new,
    );

class BackupViewModel extends AsyncNotifier<BackupInfoState> {
  @override
  Future<BackupInfoState> build() async {
    final backups = await ref.read(backupRepositoryProvider).getAll();
    final appInfo = await ref.read(appInfoRepositoryProvider).getAppInfo();

    final latestBackup = backups.isEmpty ? null : backups.first;

    return BackupInfoState(
      lastBackupDate: latestBackup?.backupDate,
      lastBackupSizeBytes: latestBackup?.backupSize,
      lastBackupFilePath: latestBackup?.backupPath,
      lastRestoreDate: appInfo.lastRestore,
    );
  }

  /// Creates a full backup into [destinationDirectoryPath].
  ///
  /// Throws `BackupExportException` on failure. Callers should show
  /// `error.message` (or a generic message for any other exception type)
  /// directly to the user.
  Future<BackupResultModel> exportBackup(
    String destinationDirectoryPath,
  ) async {
    final result = await ref
        .read(backupServiceProvider)
        .createBackup(destinationDirectoryPath: destinationDirectoryPath);

    ref.invalidateSelf();
    await future;

    return result;
  }

  /// Replaces every record in the app with the contents of the backup at
  /// [zipFilePath].
  ///
  /// Throws `BackupImportException` on validation failure — nothing is
  /// changed in that case. Callers should show `error.message` directly
  /// to the user and, on success, also refresh any one-shot (non-stream)
  /// provider not already covered by `transactionsStreamProvider`'s
  /// reactivity — see `BackupScreen`'s post-restore
  /// `ref.invalidate(categoriesListProvider)`.
  Future<RestoreResultModel> restoreFromZip(String zipFilePath) async {
    final result = await ref
        .read(restoreServiceProvider)
        .restore(zipFilePath);

    ref.invalidateSelf();
    await future;

    return result;
  }
}
