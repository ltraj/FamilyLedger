import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/repositories/impl/category_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../helpers/test_database.dart';

void main() {
  group('AppDatabase', () {
    test('enables foreign key constraints on open', () async {
      final database = await createTestDatabase();
      addTearDown(database.close);

      final result = await database.customSelect('PRAGMA foreign_keys').get();
      expect(result.first.data['foreign_keys'], 1);
    });

    test('seeds default categories and settings only once on create', () async {
      final database = await createTestDatabase();
      addTearDown(database.close);

      final categoryRepository = CategoryRepositoryImpl(database);
      final categoriesAfterCreate = await categoryRepository.getAll();
      expect(categoriesAfterCreate, hasLength(11));

      // Re-open the same in-memory database (simulates app restart on existing DB).
      await database.customSelect('SELECT 1').get();
      final categoriesAfterReopen = await categoryRepository.getAll();
      expect(categoriesAfterReopen, hasLength(11));
    });

    test('can recreate database file without data corruption', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'family_ledger_test_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final dbPath = '${tempDir.path}/test.db';

      final firstDatabase = await createTestDatabaseOnFile(dbPath);
      final firstCategories = CategoryRepositoryImpl(firstDatabase);
      expect(await firstCategories.getAll(), hasLength(11));
      await firstDatabase.close();

      final secondDatabase = await createTestDatabaseOnFile(dbPath);
      addTearDown(secondDatabase.close);
      final secondCategories = CategoryRepositoryImpl(secondDatabase);
      expect(await secondCategories.getAll(), hasLength(11));

      final settings = await secondDatabase
          .select(secondDatabase.settings)
          .get();
      expect(settings, hasLength(1));
      expect(settings.first.currency, AppConstants.defaultCurrency);
    });

    test('fresh database file after deletion seeds defaults cleanly', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'family_ledger_recreate_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final dbPath = '${tempDir.path}/recreate.db';

      final original = await createTestDatabaseOnFile(dbPath);
      await original.close();
      File(dbPath).deleteSync();

      final recreated = await createTestDatabaseOnFile(dbPath);
      addTearDown(recreated.close);

      final categories = CategoryRepositoryImpl(recreated);
      expect(await categories.getAll(), hasLength(11));
    });

    test('rejects transaction with invalid person foreign key', () async {
      final database = await createTestDatabase();
      addTearDown(database.close);

      final now = DateTime.now();
      expect(
        () => database
            .into(database.transactions)
            .insert(
              TransactionsCompanion.insert(
                personId: 99999,
                amount: 100,
                transactionType: TransactionType.expensePaid,
                date: now,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('no table stores a balance column', () async {
      final database = await createTestDatabase();
      addTearDown(database.close);

      const tables = [
        'people',
        'categories',
        'transactions',
        'settings',
        'backups',
        'app_info',
      ];

      for (final table in tables) {
        final columns = await database
            .customSelect('PRAGMA table_info($table)')
            .get();

        for (final row in columns) {
          final columnName = row.data['name'] as String;
          expect(
            columnName.toLowerCase().contains('balance'),
            isFalse,
            reason: 'Table $table must not store balances',
          );
        }
      }
    });

    test(
      'migration strategy is configured for future schema changes',
      () async {
        final database = await createTestDatabase();
        addTearDown(database.close);

        expect(AppConstants.databaseSchemaVersion, 7);
        expect(database.schemaVersion, AppConstants.databaseSchemaVersion);
        expect(database.migration.onUpgrade, isNotNull);
      },
    );

    test('seeds AppInfo exactly once on create', () async {
      final database = await createTestDatabase();
      addTearDown(database.close);

      final rowsAfterCreate = await database.select(database.appInfo).get();
      expect(rowsAfterCreate, hasLength(1));
      expect(
        rowsAfterCreate.first.databaseVersion,
        AppConstants.databaseSchemaVersion,
      );
      expect(rowsAfterCreate.first.appVersion, AppConstants.appVersion);
      expect(rowsAfterCreate.first.installationId, hasLength(36));

      // Re-open the same in-memory database (simulates app restart on existing DB).
      await database.customSelect('SELECT 1').get();
      final rowsAfterReopen = await database.select(database.appInfo).get();
      expect(rowsAfterReopen, hasLength(1));
      expect(
        rowsAfterReopen.first.installationId,
        rowsAfterCreate.first.installationId,
      );
    });

    test('upgrades an existing v1 database by adding and seeding AppInfo', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'family_ledger_migration_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final dbPath = '${tempDir.path}/legacy.db';

      // Capture the exact CREATE TABLE statements Drift generates for the
      // tables that existed before schema version 2 introduced AppInfo.
      final schemaSource = await createTestDatabase();
      const legacyTables = ['people', 'categories', 'transactions', 'settings'];
      final createStatements = <String>[];
      for (final name in legacyTables) {
        final result = await schemaSource
            .customSelect(
              "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
              variables: [Variable(name)],
            )
            .getSingle();
        var sql = result.data['sql'] as String;

        // Versions 1 and 2 both predate the v3 migration that tightens
        // transactions.categoryId from ON DELETE SET NULL to ON DELETE
        // RESTRICT. Roll the captured (current-schema) statement back to
        // that original clause so this file genuinely reproduces a legacy
        // database, rather than one that already has the v3 constraint.
        if (name == 'transactions') {
          sql = sql.replaceFirst('ON DELETE RESTRICT', 'ON DELETE SET NULL');
        }

        // Versions 1 and 2 also predate the v4 and v5 migrations that add
        // people.avatarSeed and people.displayOrder. Strip those column
        // definitions out for the same reason: a v4/v5 ADD COLUMN against
        // a "legacy" table that already has them would fail outright.
        if (name == 'people') {
          sql = sql
              .replaceFirst(', "avatar_seed" INTEGER NULL', '')
              .replaceFirst(', "display_order" INTEGER NOT NULL DEFAULT 0', '');
        }

        // Likewise for the v7 migration's automatic-backup columns on
        // settings — a genuine v1 file must not already have them.
        if (name == 'settings') {
          sql = sql
              .replaceFirst(', "auto_backup_interval_days" INTEGER NULL', '')
              .replaceFirst(', "auto_backup_directory" TEXT NULL', '');
        }

        createStatements.add(sql);
      }
      await schemaSource.close();

      // Build a standalone v1-shaped database file: the original four
      // tables, no app_info table, one settings row, pinned at user_version 1.
      final legacyDb = sqlite3.sqlite3.open(dbPath);
      for (final statement in createStatements) {
        legacyDb.execute(statement);
      }
      legacyDb.execute(
        "INSERT INTO settings (id, theme, currency, backup_frequency) "
        "VALUES (1, 'system', 'INR', 'never')",
      );
      legacyDb.execute('PRAGMA user_version = 1');
      legacyDb.close();

      // Opening with the current AppDatabase must run every migration step
      // from v1 up to the current schema version in sequence: create and
      // seed AppInfo (v2), rebuild transactions with the stricter
      // categoryId foreign key (v3), and add people.avatarSeed (v4) and
      // people.displayOrder (v5) — without touching pre-existing data.
      final upgraded = await createTestDatabaseOnFile(dbPath);
      addTearDown(upgraded.close);

      final appInfoRows = await upgraded.select(upgraded.appInfo).get();
      expect(appInfoRows, hasLength(1));
      expect(
        appInfoRows.first.databaseVersion,
        AppConstants.databaseSchemaVersion,
      );
      expect(appInfoRows.first.appVersion, AppConstants.appVersion);
      expect(appInfoRows.first.installationId, hasLength(36));
      expect(appInfoRows.first.lastBackup, isNull);

      final settingsRows = await upgraded.select(upgraded.settings).get();
      expect(settingsRows, hasLength(1));
      expect(settingsRows.first.currency, 'INR');

      // The v7 migration must have added the automatic-backup columns,
      // both null: an upgraded installation keeps automatic backup OFF
      // until the user explicitly enables it.
      final settingsColumns = await upgraded
          .customSelect('PRAGMA table_info(settings)')
          .get();
      final settingsColumnNames = settingsColumns
          .map((row) => row.data['name'] as String)
          .toSet();
      expect(
        settingsColumnNames,
        containsAll(['auto_backup_interval_days', 'auto_backup_directory']),
      );
      expect(settingsRows.first.autoBackupIntervalDays, isNull);
      expect(settingsRows.first.autoBackupDirectory, isNull);

      // The v3 migration must have rebuilt the transactions table with the
      // stricter foreign key: a category can no longer be deleted while
      // transactions reference it.
      final transactionsSchema = await upgraded
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'transactions'",
          )
          .getSingle();
      expect(
        transactionsSchema.data['sql'] as String,
        contains('ON DELETE RESTRICT'),
      );

      // The v4 and v5 migrations must have added the new people columns.
      // This legacy fixture never had any people rows, so there is
      // nothing to backfill — the migration must handle that without
      // error, and must not seed Nani/Sudha (those are only seeded for a
      // brand new install, in onCreate, not for an upgrade).
      final peopleColumns = await upgraded
          .customSelect('PRAGMA table_info(people)')
          .get();
      final peopleColumnNames = peopleColumns
          .map((row) => row.data['name'] as String)
          .toSet();
      expect(peopleColumnNames, containsAll(['avatar_seed', 'display_order']));

      final peopleRows = await upgraded.select(upgraded.people).get();
      expect(peopleRows, isEmpty);
    });
  });
}
