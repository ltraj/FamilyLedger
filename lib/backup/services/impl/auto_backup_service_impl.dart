import 'dart:io';

import 'package:family_ledger/backup/models/auto_backup_outcome.dart';
import 'package:family_ledger/backup/models/backup_export_exception.dart';
import 'package:family_ledger/backup/services/auto_backup_service.dart';
import 'package:family_ledger/backup/services/backup_service.dart';
import 'package:family_ledger/backup/utils/auto_backup_policy.dart';
import 'package:family_ledger/backup/utils/backup_rotation_policy.dart';
import 'package:family_ledger/repositories/app_info_repository.dart';
import 'package:family_ledger/repositories/settings_repository.dart';
import 'package:path/path.dart' as p;

class AutoBackupServiceImpl implements AutoBackupService {
  AutoBackupServiceImpl({
    required SettingsRepository settingsRepository,
    required AppInfoRepository appInfoRepository,
    required BackupService backupService,
  }) : _settingsRepository = settingsRepository,
       _appInfoRepository = appInfoRepository,
       _backupService = backupService;

  final SettingsRepository _settingsRepository;
  final AppInfoRepository _appInfoRepository;
  final BackupService _backupService;

  @override
  Future<AutoBackupOutcome> runIfDue({DateTime? now}) async {
    try {
      return await _run(now ?? DateTime.now());
    } catch (error) {
      // Unattended startup path: anything unexpected (a StateError from a
      // corrupted settings row, an unforeseen I/O error) becomes a value,
      // never a crash. lastBackup wasn't updated, so the next open
      // retries.
      return AutoBackupFailed('Automatic backup failed: $error');
    }
  }

  Future<AutoBackupOutcome> _run(DateTime now) async {
    final settings = await _settingsRepository.getSettings();
    final intervalDays = settings.autoBackupIntervalDays;
    if (intervalDays == null) return const AutoBackupDisabled();

    final appInfo = await _appInfoRepository.getAppInfo();
    final isDue = AutoBackupPolicy.isDue(
      intervalDays: intervalDays,
      lastBackup: appInfo.lastBackup,
      now: now,
    );
    if (!isDue) return const AutoBackupNotDue();

    final directory = settings.autoBackupDirectory;
    if (directory == null || directory.isEmpty) {
      return const AutoBackupNoFolder();
    }

    try {
      // The existing pipeline: probes writability first (which is what
      // detects a moved/deleted folder or revoked permission), exports,
      // zips, and records lastBackup — the record happens only after the
      // zip is written, so a failed run leaves lastBackup untouched and
      // the backup retries on the next open.
      final result = await _backupService.createBackup(
        destinationDirectoryPath: directory,
      );

      final deleted = await _rotate(
        directory,
        justCreatedFileName: p.basename(result.zipFilePath),
      );

      return AutoBackupSucceeded(result, deletedOldBackups: deleted);
    } on BackupExportException catch (error) {
      return AutoBackupFolderUnavailable(error.message);
    }
  }

  /// Deletes old backups beyond [BackupRotationPolicy.keepCount], newest
  /// kept. All selection logic lives in [BackupRotationPolicy]; this
  /// method only lists one directory (non-recursively — rotation must
  /// never reach into subfolders the user may keep there) and deletes the
  /// names the policy returns, re-joined onto that same directory.
  ///
  /// Every failure path keeps files rather than risking a wrong deletion:
  /// a listing error skips rotation entirely, and a per-file delete error
  /// skips just that file. An extra leftover backup is acceptable; a
  /// wrong deletion is not — and the backup itself already succeeded by
  /// the time this runs.
  Future<int> _rotate(
    String directoryPath, {
    required String justCreatedFileName,
  }) async {
    final List<String> fileNames;
    try {
      fileNames = [
        await for (final entry
            in Directory(directoryPath).list(followLinks: false))
          if (entry is File) p.basename(entry.path),
      ];
    } on FileSystemException {
      return 0;
    }

    final toDelete = BackupRotationPolicy.selectFilesToDelete(
      fileNames: fileNames,
      justCreatedFileName: justCreatedFileName,
    );

    var deleted = 0;
    for (final fileName in toDelete) {
      try {
        await File(p.join(directoryPath, fileName)).delete();
        deleted++;
      } on FileSystemException {
        // Keep the file; see the method doc for why this never escalates.
      }
    }
    return deleted;
  }
}
