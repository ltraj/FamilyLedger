import 'package:family_ledger/models/category_model.dart';

/// Contract for persisting and retrieving expense categories.
abstract interface class CategoryRepository {
  /// Returns all categories ordered by name.
  Future<List<CategoryModel>> getAll();

  /// Returns a single category by [id], or null if not found.
  Future<CategoryModel?> getById(int id);

  /// Inserts a new category and returns the generated ID.
  Future<int> insert(CategoryModel category);

  /// Updates an existing category. Returns true if a row was updated.
  Future<bool> update(CategoryModel category);

  /// Deletes [categoryId], first reassigning every transaction currently
  /// linked to it to [replacementCategoryId].
  ///
  /// The reassignment and the deletion happen in a single atomic database
  /// transaction, so a transaction can never end up without a category —
  /// either both steps succeed, or neither does. The caller (the future
  /// deletion UI) is expected to ask the user to pick [replacementCategoryId]
  /// before calling this, offering the "Other" category as the default
  /// choice alongside any other existing category.
  ///
  /// Throws an [ArgumentError] if [replacementCategoryId] is the same as
  /// [categoryId], or does not refer to an existing category.
  ///
  /// Returns true if [categoryId] was deleted.
  Future<bool> delete(int categoryId, {required int replacementCategoryId});

  /// Permanently deletes every category, bypassing the reassignment
  /// [delete] normally requires.
  ///
  /// Used only by restore, to empty the table before reimporting a
  /// backup. The database rejects this while any transaction still
  /// references a category, so callers must delete all transactions
  /// first.
  Future<void> deleteAll();
}
