/// Thrown when an automatic-backup interval is zero or negative. The
/// stepper UI clamps to a valid range, so this guards programmatic
/// callers and any future free-text entry.
class InvalidBackupIntervalException implements Exception {
  const InvalidBackupIntervalException();

  String get message => 'Backup interval must be at least 1 day.';

  @override
  String toString() => message;
}
