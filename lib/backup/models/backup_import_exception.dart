import 'package:family_ledger/backup/models/import_validation_result.dart';

/// Thrown by [RestoreService] when a backup fails validation or the
/// restore itself cannot complete.
///
/// Carries the same [ImportValidationFailureReason] enum
/// [ImportValidator] uses, so the UI can show one specific, actionable
/// message via a single `switch` regardless of which layer produced the
/// failure.
class BackupImportException implements Exception {
  const BackupImportException({required this.reason, required this.message});

  final ImportValidationFailureReason reason;
  final String message;

  @override
  String toString() => 'BackupImportException: $message';
}
