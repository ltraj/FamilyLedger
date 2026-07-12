import 'package:family_ledger/export/converters/category_export_mapper.dart';
import 'package:family_ledger/export/models/category_export_model.dart';
import 'package:family_ledger/models/category_model.dart';

/// Converts a [CategoryModel] into its export representation. A pure
/// transformation of an already-loaded model — no I/O, no database
/// access.
class CategoryExportMapperImpl implements CategoryExportMapper {
  const CategoryExportMapperImpl();

  @override
  CategoryExportModel toExportModel(CategoryModel category) {
    return CategoryExportModel(
      categoryIdentifier: category.id!,
      categoryName: category.name,
      iconIdentifier: category.icon,
      colorHexCode: category.color,
      isSystemDefinedDefault: category.isDefault,
      recordCreatedAt: category.createdAt,
    );
  }
}
