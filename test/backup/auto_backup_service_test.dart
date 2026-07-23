import 'dart:io';

import 'package:family_ledger/backup/constants/backup_constants.dart';
import 'package:family_ledger/backup/models/auto_backup_outcome.dart';
import 'package:family_ledger/backup/models/backup_export_exception.dart';
import 'package:family_ledger/backup/models/backup_result_model.dart';
import 'package:family_ledger/backup/services/backup_service.dart';
import 'package:family_ledger/backup/services/impl/auto_backup_service_impl.dart';
import 'package:family_ledger/repositories/app_info_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_database.dart';
import '../helpers/test_repositories.dart';

/// Stands in for the full export/zip pipeline: writes a placeholder zip
/// and records lastBackup, mirroring the real `BackupServiceImpl`'s
/// externally visible contract (file appears; lastBackup recorded only on
/// success) without staging a real export bundle.
class _FakeBackupService implements BackupService {
  _FakeBackupService({
    required this.appInfoRepository,
    required this.now,
    this.failWith,
  });

  final AppInfoRepository appInfoRepository;
  final DateTime now;
  final BackupExportException? failWith;
  int createCalls = 0;

  @override
  Future<BackupResultModel> createBackup({
    required String destinationDirectoryPath,
  }) async {
    createCalls++;
    final failure = failWith;
    if (failure != null) throw failure;

    final zipPath = p.join(
      destinationDirectoryPath,
      BackupConstants.backupFileName(now),
    );
    await File(zipPath).writeAsString('fake backup');
    await appInfoRepository.recordBackup(now);

    return BackupResultModel(
      zipFilePath: zipPath,
      fileSizeBytes: 11,
      createdAt: now,
      peopleCount: 2,
      transactionCount: 0,
      categoryCount: 11,
    );
  }
}

void main() {
  final now = DateTime(2026, 7, 21, 10, 30);

  late TestRepositories repos;
  late Directory backupDir;

  setUp(() async {
    repos = TestRepositories(await createTestDatabase());
    backupDir = Directory.systemTemp.createTempSync('auto_backup_test_');
  });

  tearDown(() async {
    await repos.close();
    if (backupDir.existsSync()) backupDir.deleteSync(recursive: true);
  });

  AutoBackupServiceImpl service({BackupExportException? failWith}) {
    return AutoBackupServiceImpl(
      settingsRepository: repos.settings,
      appInfoRepository: repos.appInfo,
      backupService: _FakeBackupService(
        appInfoRepository: repos.appInfo,
        now: now,
        failWith: failWith,
      ),
    );
  }

  Future<void> enableAutoBackup({int days = 3, String? directory}) async {
    final current = await repos.settings.getSettings();
    await repos.settings.update(
      current.copyWith(
        autoBackupIntervalDays: days,
        autoBackupDirectory: directory,
      ),
    );
  }

  test('feature off returns disabled and never touches the pipeline', () async {
    final outcome = await service().runIfDue(now: now);
    expect(outcome, isA<AutoBackupDisabled>());
  });

  test('not due when the last backup is recent enough', () async {
    await enableAutoBackup(days: 3, directory: backupDir.path);
    await repos.appInfo.recordBackup(now.subtract(const Duration(days: 1)));

    final outcome = await service().runIfDue(now: now);
    expect(outcome, isA<AutoBackupNotDue>());
  });

  test('due but no folder chosen surfaces AutoBackupNoFolder and does not '
      'update lastBackup', () async {
    await enableAutoBackup(days: 3);

    final outcome = await service().runIfDue(now: now);
    expect(outcome, isA<AutoBackupNoFolder>());

    final appInfo = await repos.appInfo.getAppInfo();
    expect(appInfo.lastBackup, isNull);
  });

  test('unavailable folder surfaces the failure and leaves lastBackup '
      'untouched so the next open retries', () async {
    await enableAutoBackup(days: 3, directory: backupDir.path);

    final outcome = await service(
      failWith: const BackupExportException('folder gone'),
    ).runIfDue(now: now);

    expect(outcome, isA<AutoBackupFolderUnavailable>());
    expect((outcome as AutoBackupFolderUnavailable).message, 'folder gone');

    final appInfo = await repos.appInfo.getAppInfo();
    expect(appInfo.lastBackup, isNull);
  });

  test('never backed up + due runs a backup and records it', () async {
    await enableAutoBackup(days: 3, directory: backupDir.path);

    final outcome = await service().runIfDue(now: now);
    expect(outcome, isA<AutoBackupSucceeded>());

    final appInfo = await repos.appInfo.getAppInfo();
    expect(appInfo.lastBackup, now);
    expect(
      File(p.join(backupDir.path, BackupConstants.backupFileName(now)))
          .existsSync(),
      isTrue,
    );
  });

  test('rotation keeps the newest 2 backups and never touches other '
      'files', () async {
    await enableAutoBackup(days: 3, directory: backupDir.path);

    final oldest = BackupConstants.backupFileName(DateTime(2026, 6, 1, 8, 0));
    final older = BackupConstants.backupFileName(DateTime(2026, 7, 1, 8, 0));
    final recent = BackupConstants.backupFileName(DateTime(2026, 7, 18, 8, 0));
    const decoyNames = ['holiday_photo.jpg', 'archive.zip', 'notes.txt'];

    for (final name in [oldest, older, recent, ...decoyNames]) {
      File(p.join(backupDir.path, name)).writeAsStringSync('data');
    }
    // A subfolder whose contents must be invisible to rotation, even if
    // they look exactly like backups.
    final subDir = Directory(p.join(backupDir.path, 'old backups'))
      ..createSync();
    final nestedBackup = File(p.join(subDir.path, oldest))
      ..writeAsStringSync('nested');

    final outcome = await service().runIfDue(now: now);
    expect(outcome, isA<AutoBackupSucceeded>());
    expect((outcome as AutoBackupSucceeded).deletedOldBackups, 2);

    final remaining = backupDir
        .listSync()
        .whereType<File>()
        .map((file) => p.basename(file.path))
        .toSet();

    // Kept: the just-created backup + the newest older one.
    expect(remaining, contains(BackupConstants.backupFileName(now)));
    expect(remaining, contains(recent));
    // Deleted: the two oldest app backups.
    expect(remaining, isNot(contains(older)));
    expect(remaining, isNot(contains(oldest)));
    // Untouched: every non-backup file and anything in subfolders.
    expect(remaining, containsAll(decoyNames));
    expect(nestedBackup.existsSync(), isTrue);
  });

  test('a corrupted settings row becomes AutoBackupFailed, not a crash',
      () async {
    // Wipe the settings row so getSettings throws StateError.
    await repos.database.delete(repos.database.settings).go();

    final outcome = await service().runIfDue(now: now);
    expect(outcome, isA<AutoBackupFailed>());
  });
}
