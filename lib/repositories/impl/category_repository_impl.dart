import 'package:drift/drift.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/core/database/mappers/entity_mappers.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/repositories/category_repository.dart';

/// Drift-backed implementation of [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<CategoryModel>> getAll() async {
    final entities = await (_database.select(
      _database.categories,
    )..orderBy([(category) => OrderingTerm.asc(category.name)])).get();

    return entities.map(EntityMappers.toCategory).toList();
  }

  @override
  Future<CategoryModel?> getById(int id) async {
    final entity = await (_database.select(
      _database.categories,
    )..where((category) => category.id.equals(id))).getSingleOrNull();

    return entity == null ? null : EntityMappers.toCategory(entity);
  }

  @override
  Future<int> insert(CategoryModel category) {
    return _database
        .into(_database.categories)
        .insert(EntityMappers.toCategoryCompanion(category));
  }

  @override
  Future<bool> update(CategoryModel category) async {
    if (category.id == null) return false;

    final rowsAffected =
        await (_database.update(_database.categories)
              ..where((row) => row.id.equals(category.id!)))
            .write(EntityMappers.toCategoryCompanion(category));

    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(
    int categoryId, {
    required int replacementCategoryId,
  }) async {
    if (categoryId == replacementCategoryId) {
      throw ArgumentError.value(
        replacementCategoryId,
        'replacementCategoryId',
        'Must differ from the category being deleted.',
      );
    }

    if (await getById(replacementCategoryId) == null) {
      throw ArgumentError.value(
        replacementCategoryId,
        'replacementCategoryId',
        'No category exists with this id.',
      );
    }

    return _database.transaction(() async {
      await (_database.update(
        _database.transactions,
      )..where((row) => row.categoryId.equals(categoryId))).write(
        TransactionsCompanion(categoryId: Value(replacementCategoryId)),
      );

      final rowsAffected = await (_database.delete(
        _database.categories,
      )..where((category) => category.id.equals(categoryId))).go();

      return rowsAffected > 0;
    });
  }

  @override
  Future<void> deleteAll() async {
    await _database.delete(_database.categories).go();
  }
}
