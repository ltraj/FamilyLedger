import 'package:family_ledger/backup/constants/backup_constants.dart';
import 'package:family_ledger/backup/utils/backup_rotation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupRotationPolicy.isAppBackupFileName', () {
    test('matches exactly what BackupConstants.backupFileName produces', () {
      // Pins the deletion pattern to the creation pattern: if the file
      // naming ever changes, this fails before rotation can start
      // ignoring (or worse, mis-matching) real backups.
      final samples = [
        DateTime(2026, 1, 1, 0, 0),
        DateTime(2026, 12, 31, 23, 59),
        DateTime(2026, 7, 21, 9, 5),
      ];
      for (final timestamp in samples) {
        expect(
          BackupRotationPolicy.isAppBackupFileName(
            BackupConstants.backupFileName(timestamp),
          ),
          isTrue,
        );
      }
    });

    test('rejects everything that is not exactly an app backup name', () {
      const nonMatching = [
        'holiday_photo.jpg',
        'FamilyLedger_Backup_2026-07-21_10-30.zip.bak',
        'my_FamilyLedger_Backup_2026-07-21_10-30.zip',
        'FamilyLedger_Backup_2026-7-21_10-30.zip',
        'FamilyLedger_Backup_2026-07-21.zip',
        'FamilyLedger_Backup_2026-07-21_10-30.ZIP',
        'SomeOtherApp_Backup_2026-07-21_10-30.zip',
        'notes.txt',
        'archive.zip',
        '',
      ];
      for (final name in nonMatching) {
        expect(
          BackupRotationPolicy.isAppBackupFileName(name),
          isFalse,
          reason: '"$name" must never be treated as an app backup',
        );
      }
    });
  });

  group('BackupRotationPolicy.selectFilesToDelete', () {
    String backupName(DateTime timestamp) =>
        BackupConstants.backupFileName(timestamp);

    final oldest = backupName(DateTime(2026, 7, 1, 9, 0));
    final older = backupName(DateTime(2026, 7, 10, 9, 0));
    final recent = backupName(DateTime(2026, 7, 18, 9, 0));
    final justCreated = backupName(DateTime(2026, 7, 21, 10, 30));

    test('keeps the newest 2 and returns the older ones to delete', () {
      final toDelete = BackupRotationPolicy.selectFilesToDelete(
        fileNames: [oldest, older, recent, justCreated],
        justCreatedFileName: justCreated,
      );

      // Kept: justCreated + recent. Deleted: older + oldest.
      expect(toDelete, unorderedEquals([older, oldest]));
    });

    test('never selects the just-created file, whatever its position', () {
      // Pathological clock skew: the just-created backup carries the
      // OLDEST timestamp in the folder. It must still be kept.
      final skewedJustCreated = backupName(DateTime(2026, 6, 1, 0, 0));
      final toDelete = BackupRotationPolicy.selectFilesToDelete(
        fileNames: [skewedJustCreated, oldest, older, recent],
        justCreatedFileName: skewedJustCreated,
      );

      expect(toDelete, isNot(contains(skewedJustCreated)));
      // One keep slot is the just-created; the other goes to the newest
      // remaining ([recent]); everything else matching is deletable.
      expect(toDelete, unorderedEquals([older, oldest]));
    });

    test('completely ignores non-matching files mixed into the folder', () {
      const decoys = [
        'holiday_photo.jpg',
        'tax_documents.pdf',
        'archive.zip',
        'FamilyLedger_Backup_2026-07-21_10-30.zip.bak',
        'my_FamilyLedger_Backup_2026-01-01_00-00.zip',
      ];
      final toDelete = BackupRotationPolicy.selectFilesToDelete(
        fileNames: [...decoys, oldest, older, recent, justCreated],
        justCreatedFileName: justCreated,
      );

      for (final decoy in decoys) {
        expect(
          toDelete,
          isNot(contains(decoy)),
          reason: '"$decoy" is not an app backup and must never be deleted',
        );
      }
      expect(toDelete, unorderedEquals([older, oldest]));
    });

    test('nothing to delete when at or under the keep count', () {
      expect(
        BackupRotationPolicy.selectFilesToDelete(
          fileNames: [justCreated],
          justCreatedFileName: justCreated,
        ),
        isEmpty,
      );
      expect(
        BackupRotationPolicy.selectFilesToDelete(
          fileNames: [recent, justCreated],
          justCreatedFileName: justCreated,
        ),
        isEmpty,
      );
    });

    test('a folder with only foreign files yields nothing to delete', () {
      expect(
        BackupRotationPolicy.selectFilesToDelete(
          fileNames: ['photo.jpg', 'report.pdf', 'backup.zip'],
          justCreatedFileName: justCreated,
        ),
        isEmpty,
      );
    });

    test('works when the listing does not include the just-created file', () {
      // E.g. the listing raced the write. The just-created name still
      // reserves a keep slot, so only the newest 1 other backup is kept.
      final toDelete = BackupRotationPolicy.selectFilesToDelete(
        fileNames: [oldest, older, recent],
        justCreatedFileName: justCreated,
      );
      expect(toDelete, unorderedEquals([older, oldest]));
    });
  });
}
