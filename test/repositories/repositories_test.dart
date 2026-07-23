import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/models/backup_model.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/settings_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';
import '../helpers/test_repositories.dart';

void main() {
  group('PeopleRepository', () {
    late TestRepositories repos;

    setUp(() async {
      repos = TestRepositories(await createTestDatabase());
    });

    tearDown(() => repos.close());

    test('insert, getById, getAll, update, archive', () async {
      final now = DateTime(2026, 1, 1);

      // Nani and Sudha are seeded by default on a fresh install, so the
      // active list already has 2 people before this test inserts its own.
      final id = await repos.people.insert(
        PersonModel(
          name: 'Grandmother',
          type: PersonType.permanent,
          status: PersonStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final fetched = await repos.people.getById(id);
      expect(fetched?.name, 'Grandmother');

      final activeOnly = await repos.people.getAll(status: PersonStatus.active);
      expect(activeOnly, hasLength(3));

      final updated = fetched!.copyWith(name: 'Grandma', updatedAt: now);
      expect(await repos.people.update(updated), isTrue);
      expect((await repos.people.getById(id))?.name, 'Grandma');

      expect(await repos.people.archive(id), isTrue);
      expect((await repos.people.getById(id))?.status, PersonStatus.archived);
      expect(
        await repos.people.getAll(status: PersonStatus.active),
        hasLength(2),
      );
    });

    test('seeds Nani and Sudha as permanent, active, in order', () async {
      final people = await repos.people.getAll();
      expect(people.map((p) => p.name), containsAll(['Nani', 'Sudha']));

      final nani = people.firstWhere((p) => p.name == 'Nani');
      final sudha = people.firstWhere((p) => p.name == 'Sudha');

      expect(nani.type, PersonType.permanent);
      expect(sudha.type, PersonType.permanent);
      expect(nani.status, PersonStatus.active);
      expect(sudha.status, PersonStatus.active);
      expect(nani.displayOrder, lessThan(sudha.displayOrder));
    });

    test('delete removes a person with no transaction history', () async {
      final now = DateTime(2026, 1, 1);
      final id = await repos.people.insert(
        PersonModel(
          name: 'Temp Helper',
          type: PersonType.temporary,
          status: PersonStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(await repos.people.delete(id), isTrue);
      expect(await repos.people.getById(id), isNull);
    });

    test('the database itself rejects deleting a person directly while '
        'transactions reference them', () async {
      final now = DateTime(2026, 1, 1);
      final personId = await repos.people.insert(
        PersonModel(
          name: 'Temp Helper',
          type: PersonType.temporary,
          status: PersonStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repos.transactions.insert(
        TransactionModel(
          personId: personId,
          amount: 500,
          transactionType: TransactionType.advanceReceived,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(
        () => (repos.database.delete(
          repos.database.people,
        )..where((person) => person.id.equals(personId))).go(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('CategoryRepository', () {
    late TestRepositories repos;

    setUp(() async {
      repos = TestRepositories(await createTestDatabase());
    });

    tearDown(() => repos.close());

    test('getAll returns seeded defaults', () async {
      final categories = await repos.categories.getAll();
      expect(categories, hasLength(11));
      expect(categories.any((c) => c.name == 'Electricity'), isTrue);
    });

    test('insert, getById, update, delete', () async {
      final now = DateTime(2026, 1, 1);
      final id = await repos.categories.insert(
        CategoryModel(
          name: 'Custom',
          icon: 'star',
          color: '#000000',
          isDefault: false,
          createdAt: now,
        ),
      );

      expect((await repos.categories.getById(id))?.name, 'Custom');

      final updated = (await repos.categories.getById(
        id,
      ))!.copyWith(name: 'Custom 2');
      expect(await repos.categories.update(updated), isTrue);

      final other = (await repos.categories.getAll()).firstWhere(
        (c) => c.name == 'Other',
      );

      expect(
        await repos.categories.delete(id, replacementCategoryId: other.id!),
        isTrue,
      );
      expect(await repos.categories.getById(id), isNull);
    });

    test(
      'delete reassigns every linked transaction to the replacement category',
      () async {
        final now = DateTime(2026, 1, 1);
        final uncle = await repos.people.insert(
          PersonModel(
            name: 'Uncle',
            type: PersonType.temporary,
            status: PersonStatus.active,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final aunt = await repos.people.insert(
          PersonModel(
            name: 'Aunt',
            type: PersonType.temporary,
            status: PersonStatus.active,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final categories = await repos.categories.getAll();
        final wifi = categories.firstWhere((c) => c.name == 'WiFi');
        final other = categories.firstWhere((c) => c.name == 'Other');

        final firstTransactionId = await repos.transactions.insert(
          TransactionModel(
            personId: uncle,
            amount: 800,
            transactionType: TransactionType.expensePaid,
            categoryId: wifi.id,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final secondTransactionId = await repos.transactions.insert(
          TransactionModel(
            personId: aunt,
            amount: 500,
            transactionType: TransactionType.expensePaid,
            categoryId: wifi.id,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        // Unrelated transaction using a different category: must stay untouched.
        final unrelatedTransactionId = await repos.transactions.insert(
          TransactionModel(
            personId: uncle,
            amount: 100,
            transactionType: TransactionType.expensePaid,
            categoryId: other.id,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        );

        expect(
          await repos.categories.delete(
            wifi.id!,
            replacementCategoryId: other.id!,
          ),
          isTrue,
        );

        expect(await repos.categories.getById(wifi.id!), isNull);
        expect(
          (await repos.transactions.getById(firstTransactionId))?.categoryId,
          other.id,
        );
        expect(
          (await repos.transactions.getById(secondTransactionId))?.categoryId,
          other.id,
        );
        expect(
          (await repos.transactions.getById(
            unrelatedTransactionId,
          ))?.categoryId,
          other.id,
        );
      },
    );

    test(
      'delete throws when the replacement category does not exist',
      () async {
        final categories = await repos.categories.getAll();
        final wifi = categories.firstWhere((c) => c.name == 'WiFi');
        const nonExistentId = 999999;

        expect(
          () => repos.categories.delete(
            wifi.id!,
            replacementCategoryId: nonExistentId,
          ),
          throwsArgumentError,
        );

        // The category must still exist: the failed call must not have any
        // effect.
        expect(await repos.categories.getById(wifi.id!), isNotNull);
      },
    );

    test(
      'delete throws when the replacement is the category being deleted',
      () async {
        final categories = await repos.categories.getAll();
        final wifi = categories.firstWhere((c) => c.name == 'WiFi');

        expect(
          () => repos.categories.delete(
            wifi.id!,
            replacementCategoryId: wifi.id!,
          ),
          throwsArgumentError,
        );

        expect(await repos.categories.getById(wifi.id!), isNotNull);
      },
    );

    test('the database itself rejects deleting a category directly while '
        'transactions reference it', () async {
      final now = DateTime(2026, 1, 1);
      final personId = await repos.people.insert(
        PersonModel(
          name: 'Uncle',
          type: PersonType.temporary,
          status: PersonStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final wifi = (await repos.categories.getAll()).firstWhere(
        (c) => c.name == 'WiFi',
      );

      await repos.transactions.insert(
        TransactionModel(
          personId: personId,
          amount: 800,
          transactionType: TransactionType.expensePaid,
          categoryId: wifi.id,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Bypasses CategoryRepository.delete entirely, going straight to the
      // database, to prove the ON DELETE RESTRICT foreign key constraint is
      // itself a backstop against ever losing a transaction's category.
      expect(
        () => (repos.database.delete(
          repos.database.categories,
        )..where((category) => category.id.equals(wifi.id!))).go(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TransactionRepository', () {
    late TestRepositories repos;

    setUp(() async {
      repos = TestRepositories(await createTestDatabase());
    });

    tearDown(() => repos.close());

    test('CRUD and calculateBalance from history only', () async {
      final now = DateTime(2026, 1, 1);
      final personId = await repos.people.insert(
        PersonModel(
          name: 'Grandmother',
          type: PersonType.permanent,
          status: PersonStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repos.transactions.insert(
        TransactionModel(
          personId: personId,
          amount: 5000,
          transactionType: TransactionType.advanceReceived,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repos.transactions.insert(
        TransactionModel(
          personId: personId,
          amount: 1500,
          transactionType: TransactionType.expensePaid,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final all = await repos.transactions.getAll();
      expect(all, hasLength(2));

      final byPerson = await repos.transactions.getByPersonId(personId);
      expect(byPerson, hasLength(2));

      expect(await repos.transactions.calculateBalance(personId), 3500);

      final first = byPerson.first;
      final updated = first.copyWith(amount: 1600, updatedAt: now);
      expect(await repos.transactions.update(updated), isTrue);

      expect(await repos.transactions.calculateBalance(personId), 3400);

      expect(await repos.transactions.delete(first.id!), isTrue);
      expect(await repos.transactions.getByPersonId(personId), hasLength(1));
    });
  });

  group('SettingsRepository', () {
    late TestRepositories repos;

    setUp(() async {
      repos = TestRepositories(await createTestDatabase());
    });

    tearDown(() => repos.close());

    test('getSettings returns seeded defaults', () async {
      final settings = await repos.settings.getSettings();
      expect(settings.theme, AppThemeMode.system);
      expect(settings.currency, 'INR');
      expect(settings.backupFrequency, BackupFrequency.never);
    });

    test('update persists changes', () async {
      const updated = SettingsModel(
        theme: AppThemeMode.dark,
        currency: 'USD',
        backupFrequency: BackupFrequency.weekly,
      );

      expect(await repos.settings.update(updated), isTrue);

      final settings = await repos.settings.getSettings();
      expect(settings.theme, AppThemeMode.dark);
      expect(settings.currency, 'USD');
      expect(settings.backupFrequency, BackupFrequency.weekly);
    });

    test('automatic-backup settings persist and can be cleared', () async {
      final seeded = await repos.settings.getSettings();
      expect(seeded.autoBackupIntervalDays, isNull);
      expect(seeded.autoBackupDirectory, isNull);

      await repos.settings.update(
        seeded.copyWith(
          autoBackupIntervalDays: 3,
          autoBackupDirectory: '/storage/backups',
        ),
      );
      final enabled = await repos.settings.getSettings();
      expect(enabled.autoBackupIntervalDays, 3);
      expect(enabled.autoBackupDirectory, '/storage/backups');

      // Clearing must persist null (turning the feature off), not
      // silently keep the old values.
      await repos.settings.update(
        enabled.copyWith(
          clearAutoBackupIntervalDays: true,
          clearAutoBackupDirectory: true,
        ),
      );
      final disabled = await repos.settings.getSettings();
      expect(disabled.autoBackupIntervalDays, isNull);
      expect(disabled.autoBackupDirectory, isNull);
    });
  });

  group('BackupRepository', () {
    late TestRepositories repos;

    setUp(() async {
      repos = TestRepositories(await createTestDatabase());
    });

    tearDown(() => repos.close());

    test('insert, getAll, getById, delete', () async {
      final now = DateTime(2026, 1, 1);

      final id = await repos.backups.insert(
        BackupModel(
          backupDate: now,
          backupPath: '/tmp/backup.db',
          backupSize: 1024,
        ),
      );

      expect(await repos.backups.getAll(), hasLength(1));
      expect((await repos.backups.getById(id))?.backupPath, '/tmp/backup.db');

      expect(await repos.backups.delete(id), isTrue);
      expect(await repos.backups.getAll(), isEmpty);
    });
  });

  group('AppInfoRepository', () {
    late TestRepositories repos;

    setUp(() async {
      repos = TestRepositories(await createTestDatabase());
    });

    tearDown(() => repos.close());

    test('getAppInfo returns the seeded row', () async {
      final appInfo = await repos.appInfo.getAppInfo();

      expect(appInfo.databaseVersion, AppConstants.databaseSchemaVersion);
      expect(appInfo.appVersion, isNotEmpty);
      expect(appInfo.installationId, hasLength(36));
      expect(appInfo.lastBackup, isNull);
      expect(appInfo.lastRestore, isNull);
      expect(appInfo.deviceName, isNull);
    });

    test(
      'recordBackup and recordRestore update timestamps independently',
      () async {
        final backupTime = DateTime(2026, 2, 1);
        expect(await repos.appInfo.recordBackup(backupTime), isTrue);

        final afterBackup = await repos.appInfo.getAppInfo();
        expect(afterBackup.lastBackup, backupTime);
        expect(afterBackup.lastRestore, isNull);

        final restoreTime = DateTime(2026, 3, 1);
        expect(await repos.appInfo.recordRestore(restoreTime), isTrue);

        final afterRestore = await repos.appInfo.getAppInfo();
        expect(afterRestore.lastBackup, backupTime);
        expect(afterRestore.lastRestore, restoreTime);
      },
    );

    test('update persists full row changes', () async {
      final current = await repos.appInfo.getAppInfo();
      final updated = current.copyWith(deviceName: 'Pixel 8');

      expect(await repos.appInfo.update(updated), isTrue);
      expect((await repos.appInfo.getAppInfo()).deviceName, 'Pixel 8');
    });

    test('only one AppInfo row exists', () async {
      final rows = await repos.database.select(repos.database.appInfo).get();
      expect(rows, hasLength(1));

      // Attempting to insert a second row collides on the fixed primary key.
      expect(
        () => repos.database
            .into(repos.database.appInfo)
            .insert(
              AppInfoCompanion.insert(
                databaseVersion: 2,
                appVersion: '1.0.0+1',
                createdAt: DateTime(2026, 1, 1),
                installationId: '22222222-2222-4222-8222-222222222222',
              ),
            ),
        throwsA(isA<Exception>()),
      );

      expect(
        await repos.database.select(repos.database.appInfo).get(),
        hasLength(1),
      );
    });
  });
}
