import 'package:family_ledger/backup/models/auto_backup_outcome.dart';

/// Runs the "check on open" automatic backup: if the feature is enabled
/// and the last successful backup is at least the configured number of
/// days old, creates a backup in the remembered folder through the same
/// pipeline the manual Export button uses, then rotates old backups so
/// only the newest few remain.
///
/// Never throws — every failure mode is a value in the returned
/// [AutoBackupOutcome], because this runs unattended at startup where an
/// escaped exception would crash the app before first paint.
///
/// Implementation: `AutoBackupServiceImpl` in
/// `lib/backup/services/impl/auto_backup_service_impl.dart`.
abstract interface class AutoBackupService {
  /// [now] is injectable for tests; defaults to the wall clock.
  Future<AutoBackupOutcome> runIfDue({DateTime? now});
}
