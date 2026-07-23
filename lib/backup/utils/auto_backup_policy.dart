/// Decides whether an automatic backup is due — the pure core of the
/// "check on open" trigger, separated from I/O so it can be unit-tested
/// against any combination of interval and last-backup date without a
/// database or clock.
abstract final class AutoBackupPolicy {
  /// Whether a backup should run now.
  ///
  /// - [intervalDays] null (feature off) or non-positive → never due.
  ///   Non-positive values can't be produced by the Settings UI, but a
  ///   corrupted or hand-edited value must fail safe (no backup) rather
  ///   than back up on every single open.
  /// - [lastBackup] null (never backed up) → due immediately: a user who
  ///   just turned the feature on has zero backups, the riskiest state.
  /// - Otherwise due once at least [intervalDays] days have elapsed since
  ///   [lastBackup].
  static bool isDue({
    required int? intervalDays,
    required DateTime? lastBackup,
    required DateTime now,
  }) {
    if (intervalDays == null || intervalDays <= 0) return false;
    if (lastBackup == null) return true;
    return !now.isBefore(lastBackup.add(Duration(days: intervalDays)));
  }
}
