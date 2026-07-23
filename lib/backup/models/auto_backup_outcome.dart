import 'package:family_ledger/backup/models/backup_result_model.dart';

/// What happened when the automatic-backup check ran.
///
/// A sealed result instead of thrown exceptions because the check runs
/// unattended at app open: most outcomes are entirely normal (not due,
/// feature off) and none may crash the app. The caller pattern-matches to
/// decide what — if anything — to surface. The two "needs the user"
/// outcomes ([AutoBackupNoFolder], [AutoBackupFolderUnavailable]) exist
/// precisely so a broken setup is *always* surfaced rather than becoming
/// a backup system that quietly stopped working.
sealed class AutoBackupOutcome {
  const AutoBackupOutcome();
}

/// Automatic backup is turned off; nothing to do.
class AutoBackupDisabled extends AutoBackupOutcome {
  const AutoBackupDisabled();
}

/// Enabled, but the last successful backup is recent enough.
class AutoBackupNotDue extends AutoBackupOutcome {
  const AutoBackupNotDue();
}

/// Enabled and due, but no backup folder has been chosen yet.
class AutoBackupNoFolder extends AutoBackupOutcome {
  const AutoBackupNoFolder();
}

/// Enabled and due, but the remembered folder could not be written to —
/// moved, deleted, or its permission revoked. `lastBackup` was not
/// updated, so the backup retries on the next open.
class AutoBackupFolderUnavailable extends AutoBackupOutcome {
  const AutoBackupFolderUnavailable(this.message);

  final String message;
}

/// The backup was written and rotation ran.
class AutoBackupSucceeded extends AutoBackupOutcome {
  const AutoBackupSucceeded(this.result, {required this.deletedOldBackups});

  final BackupResultModel result;

  /// How many old backups rotation deleted (0 or more).
  final int deletedOldBackups;
}

/// The backup failed for a reason other than the folder being
/// unavailable. `lastBackup` was not updated, so it retries next open.
class AutoBackupFailed extends AutoBackupOutcome {
  const AutoBackupFailed(this.message);

  final String message;
}
