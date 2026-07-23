import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/models/app_info_model.dart';
import 'package:family_ledger/models/backup_model.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/settings_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12, 0);

  group('PersonModel', () {
    final original = PersonModel(
      id: 1,
      name: 'Grandmother',
      type: PersonType.permanent,
      status: PersonStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    test('copyWith, equality, and JSON round-trip', () {
      final copy = original.copyWith(name: 'Grandma');
      expect(copy.name, 'Grandma');
      expect(copy.id, original.id);

      expect(copy == original.copyWith(name: 'Grandma'), isTrue);
      expect(copy.hashCode, original.copyWith(name: 'Grandma').hashCode);

      final json = original.toJson();
      final restored = PersonModel.fromJson(json);
      expect(restored, original);
    });
  });

  group('CategoryModel', () {
    final original = CategoryModel(
      id: 1,
      name: 'Electricity',
      icon: 'bolt',
      color: '#FFC107',
      isDefault: true,
      createdAt: now,
    );

    test('copyWith, equality, and JSON round-trip', () {
      final copy = original.copyWith(color: '#FF0000');
      expect(copy.color, '#FF0000');

      expect(copy == original.copyWith(color: '#FF0000'), isTrue);

      final restored = CategoryModel.fromJson(original.toJson());
      expect(restored, original);
    });
  });

  group('TransactionModel', () {
    final original = TransactionModel(
      id: 1,
      personId: 2,
      amount: 500,
      transactionType: TransactionType.expensePaid,
      categoryId: 3,
      remark: 'WiFi bill',
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    test('copyWith, equality, and JSON round-trip', () {
      final copy = original.copyWith(amount: 600);
      expect(copy.amount, 600);

      expect(copy == original.copyWith(amount: 600), isTrue);

      final restored = TransactionModel.fromJson(original.toJson());
      expect(restored, original);
    });
  });

  group('SettingsModel', () {
    const original = SettingsModel(
      theme: AppThemeMode.system,
      currency: 'INR',
      backupFrequency: BackupFrequency.never,
    );

    test('copyWith, equality, and JSON round-trip', () {
      final copy = original.copyWith(theme: AppThemeMode.dark);
      expect(copy.theme, AppThemeMode.dark);

      expect(copy == original.copyWith(theme: AppThemeMode.dark), isTrue);

      final restored = SettingsModel.fromJson(original.toJson());
      expect(restored, original);
    });

    test('automatic-backup fields round-trip, clear, and default off', () {
      final enabled = original.copyWith(
        autoBackupIntervalDays: 3,
        autoBackupDirectory: '/storage/backups',
      );
      expect(enabled.isAutoBackupEnabled, isTrue);
      expect(SettingsModel.fromJson(enabled.toJson()), enabled);

      final cleared = enabled.copyWith(
        clearAutoBackupIntervalDays: true,
        clearAutoBackupDirectory: true,
      );
      expect(cleared.autoBackupIntervalDays, isNull);
      expect(cleared.autoBackupDirectory, isNull);
      expect(cleared.isAutoBackupEnabled, isFalse);

      // JSON written before these fields existed parses as OFF.
      final legacy = SettingsModel.fromJson({
        'theme': 'system',
        'currency': 'INR',
        'backupFrequency': 'never',
      });
      expect(legacy.autoBackupIntervalDays, isNull);
      expect(legacy.autoBackupDirectory, isNull);
    });
  });

  group('BackupModel', () {
    final original = BackupModel(
      id: 1,
      backupDate: now,
      backupPath: '/tmp/backup.db',
      backupSize: 2048,
    );

    test('copyWith, equality, and JSON round-trip', () {
      final copy = original.copyWith(backupSize: 4096);
      expect(copy.backupSize, 4096);

      expect(copy == original.copyWith(backupSize: 4096), isTrue);

      final restored = BackupModel.fromJson(original.toJson());
      expect(restored, original);
    });
  });

  group('AppInfoModel', () {
    final original = AppInfoModel(
      id: 1,
      databaseVersion: 2,
      appVersion: '1.0.0+1',
      createdAt: now,
      installationId: '11111111-1111-4111-8111-111111111111',
    );

    test('copyWith, equality, and JSON round-trip', () {
      final copy = original.copyWith(lastBackup: now, lastRestore: now);
      expect(copy.lastBackup, now);
      expect(copy.lastRestore, now);
      expect(copy.installationId, original.installationId);

      expect(
        copy == original.copyWith(lastBackup: now, lastRestore: now),
        isTrue,
      );

      final restored = AppInfoModel.fromJson(copy.toJson());
      expect(restored, copy);

      final withoutOptionalFields = AppInfoModel.fromJson(original.toJson());
      expect(withoutOptionalFields, original);
    });
  });
}
