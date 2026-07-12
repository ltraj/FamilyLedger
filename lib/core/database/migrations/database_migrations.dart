import 'package:drift/drift.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/core/utils/person_display_order.dart';

/// Stepwise database migrations for schema version upgrades.
///
/// When bumping [AppConstants.databaseSchemaVersion], add a new case for
/// each version increment. Migrations run sequentially from `from + 1` to `to`.
abstract final class DatabaseMigrations {
  /// Applies migrations from [from] to [to] (exclusive of [from], inclusive of [to]).
  static Future<void> onUpgrade(
    AppDatabase database,
    Migrator migrator,
    int from,
    int to,
  ) async {
    if (from >= to) return;

    for (var version = from + 1; version <= to; version++) {
      await _migrateToVersion(database, migrator, version);
    }
  }

  static Future<void> _migrateToVersion(
    AppDatabase database,
    Migrator migrator,
    int version,
  ) async {
    switch (version) {
      case 2:
        // Introduces the AppInfo table for installations created before it
        // existed. Existing tables and data are untouched.
        await migrator.createTable(database.appInfo);
        await database.seedAppInfo();
        return;
      case 3:
        // Changes transactions.categoryId from ON DELETE SET NULL to
        // ON DELETE RESTRICT: a category can no longer be deleted while
        // transactions still reference it, even by code that bypasses the
        // repository layer. SQLite can't alter a foreign key's action in
        // place, so the table is rebuilt with the same columns and data.
        //
        // Rows written before this migration may already have a null
        // categoryId from the old ON DELETE SET NULL behavior; those are
        // left as-is since there is no reliable replacement category to
        // infer for them. The constraint only prevents *new* nulls.
        await migrator.alterTable(TableMigration(database.transactions));
        return;
      case 4:
        // Adds the nullable avatarSeed column used to generate a stable,
        // deterministic avatar color/initial for each person. A plain
        // ADD COLUMN is sufficient here (unlike version 3) because this
        // only adds a nullable column with no new constraint. Existing
        // rows get null; PersonModel.effectiveAvatarSeed falls back to id
        // for those, so no backfill is needed.
        await migrator.addColumn(database.people, database.people.avatarSeed);
        return;
      case 5:
        // Adds displayOrder for user-customizable sorting (and, later,
        // drag-and-drop). NOT NULL with a default, so a plain ADD COLUMN
        // works: every existing row first gets the default value of 0.
        //
        // That default would collapse every existing person to the same
        // position, so this backfills sequential, gapped values (see
        // PersonDisplayOrder) in the person's current order — by id, i.e.
        // the order they were originally created in, since no ordering
        // concept existed before this column. This preserves how existing
        // installations' people currently appear; it does not reorder
        // anything.
        await migrator.addColumn(database.people, database.people.displayOrder);

        final existingPeople = await (database.select(
          database.people,
        )..orderBy([(person) => OrderingTerm.asc(person.id)])).get();

        for (var index = 0; index < existingPeople.length; index++) {
          await (database.update(database.people)
                ..where((person) => person.id.equals(existingPeople[index].id)))
              .write(
                PeopleCompanion(
                  displayOrder: Value(
                    PersonDisplayOrder.initial +
                        index * PersonDisplayOrder.step,
                  ),
                ),
              );
        }
        return;
      case 6:
        // Adds indexes on transactions(personId), (categoryId), and
        // (date) — the table's hot query paths. Purely additive: no data
        // or column changes, so plain CREATE INDEX statements suffice.
        // New installations get these from onCreate's createAll().
        await migrator.createIndex(database.idxTransactionsPersonId);
        await migrator.createIndex(database.idxTransactionsCategoryId);
        await migrator.createIndex(database.idxTransactionsDate);
        return;
      default:
        throw StateError(
          'No migration defined for schema version $version. '
          'Add a case in DatabaseMigrations before bumping schemaVersion.',
        );
    }
  }
}
