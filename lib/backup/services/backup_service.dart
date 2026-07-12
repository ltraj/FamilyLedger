import 'package:family_ledger/backup/models/backup_result_model.dart';

/// Produces a complete backup `.zip` and writes it into
/// [destinationDirectoryPath] — a folder the user already chose via the
/// platform's Storage Access Framework picker (Downloads, Google Drive,
/// USB, SD card, internal storage; anywhere the OS lets the user browse
/// to). This service never talks to a cloud API itself — the destination
/// is just a folder path, however the user got there.
///
/// Also records the backup in `BackupRepository` and updates
/// `AppInfoRepository.recordBackup`, so "Last Backup Date" and "Backup
/// Size" can be read back later without re-scanning the filesystem.
///
/// Throws `BackupExportException` if writing to the destination fails
/// (permission denied, disk full).
///
/// Implementation: [BackupServiceImpl] in
/// `lib/backup/services/impl/backup_service_impl.dart`.
abstract interface class BackupService {
  Future<BackupResultModel> createBackup({
    required String destinationDirectoryPath,
  });
}
