import 'package:family_ledger/backup/models/restore_result_model.dart';

/// Replaces every record in the app with the contents of a backup `.zip`.
///
/// Validates the bundle first (see `ImportValidator`) and throws
/// `BackupImportException` without touching the database if validation
/// fails — restore is all-or-nothing. On success, every person, category,
/// and transaction currently in the app is gone, replaced by the
/// backup's. The caller is responsible for warning the user and getting
/// their confirmation before calling this — this service does not ask.
///
/// Implementation: [RestoreServiceImpl] in
/// `lib/backup/services/impl/restore_service_impl.dart`.
abstract interface class RestoreService {
  Future<RestoreResultModel> restore(String zipFilePath);
}
