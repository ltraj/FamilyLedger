import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/core/constants/default_categories.dart';
import 'package:family_ledger/core/constants/default_people.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/database/converters/enum_converters.dart';
import 'package:family_ledger/core/database/migrations/database_migrations.dart';
import 'package:family_ledger/core/database/tables/app_info_table.dart';
import 'package:family_ledger/core/database/tables/backups_table.dart';
import 'package:family_ledger/core/database/tables/categories_table.dart';
import 'package:family_ledger/core/database/tables/people_table.dart';
import 'package:family_ledger/core/database/tables/settings_table.dart';
import 'package:family_ledger/core/database/tables/transactions_table.dart';
import 'package:family_ledger/core/utils/person_display_order.dart';
import 'package:family_ledger/core/utils/uuid_generator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Central Drift database for the Family Ledger application.
@DriftDatabase(
  tables: [People, Categories, Transactions, Settings, Backups, AppInfo],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for in-memory testing.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => AppConstants.databaseSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedDefaultData();
    },
    onUpgrade: (m, from, to) => DatabaseMigrations.onUpgrade(this, m, from, to),
  );

  Future<void> _seedDefaultData() async {
    final now = DateTime.now();

    for (final definition in DefaultCategories.all) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: definition.name,
          icon: definition.icon,
          color: definition.color,
          isDefault: const Value(true),
          createdAt: now,
        ),
      );
    }

    for (var index = 0; index < DefaultPeople.all.length; index++) {
      final definition = DefaultPeople.all[index];
      await into(people).insert(
        PeopleCompanion.insert(
          name: definition.name,
          type: definition.type,
          status: PersonStatus.active,
          displayOrder: Value(
            PersonDisplayOrder.initial + index * PersonDisplayOrder.step,
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await into(settings).insert(
      SettingsCompanion.insert(
        theme: AppThemeMode.system,
        currency: AppConstants.defaultCurrency,
        backupFrequency: BackupFrequency.never,
      ),
    );

    await seedAppInfo();
  }

  /// Inserts the single [AppInfo] row for a fresh installation, or for an
  /// existing installation upgrading to the schema version that introduced
  /// this table. Safe to call at most once per database lifetime.
  Future<void> seedAppInfo() async {
    await into(appInfo).insert(
      AppInfoCompanion.insert(
        databaseVersion: schemaVersion,
        appVersion: AppConstants.appVersion,
        createdAt: DateTime.now(),
        installationId: UuidGenerator.generate(),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
