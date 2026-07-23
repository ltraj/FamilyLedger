import 'package:family_ledger/backup/utils/auto_backup_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoBackupPolicy.isDue', () {
    final now = DateTime(2026, 7, 21, 10, 30);

    test('never backed up is due immediately', () {
      expect(
        AutoBackupPolicy.isDue(intervalDays: 3, lastBackup: null, now: now),
        isTrue,
      );
    });

    test('last backup exactly N days ago is due', () {
      expect(
        AutoBackupPolicy.isDue(
          intervalDays: 3,
          lastBackup: now.subtract(const Duration(days: 3)),
          now: now,
        ),
        isTrue,
      );
    });

    test('last backup more than N days ago is due', () {
      expect(
        AutoBackupPolicy.isDue(
          intervalDays: 3,
          lastBackup: now.subtract(const Duration(days: 10)),
          now: now,
        ),
        isTrue,
      );
    });

    test('last backup less than N days ago is not due', () {
      expect(
        AutoBackupPolicy.isDue(
          intervalDays: 3,
          lastBackup: now.subtract(const Duration(days: 2, hours: 23)),
          now: now,
        ),
        isFalse,
      );
    });

    test('feature off (null interval) is never due, even with no backup', () {
      expect(
        AutoBackupPolicy.isDue(intervalDays: null, lastBackup: null, now: now),
        isFalse,
      );
      expect(
        AutoBackupPolicy.isDue(
          intervalDays: null,
          lastBackup: now.subtract(const Duration(days: 100)),
          now: now,
        ),
        isFalse,
      );
    });

    test('zero or negative interval fails safe to never due', () {
      expect(
        AutoBackupPolicy.isDue(intervalDays: 0, lastBackup: null, now: now),
        isFalse,
      );
      expect(
        AutoBackupPolicy.isDue(intervalDays: -1, lastBackup: null, now: now),
        isFalse,
      );
    });

    test('an interval of 1 day means daily', () {
      expect(
        AutoBackupPolicy.isDue(
          intervalDays: 1,
          lastBackup: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isTrue,
      );
      expect(
        AutoBackupPolicy.isDue(
          intervalDays: 1,
          lastBackup: now.subtract(const Duration(hours: 12)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
