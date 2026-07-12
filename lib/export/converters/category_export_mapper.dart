import 'package:family_ledger/export/models/category_export_model.dart';
import 'package:family_ledger/models/category_model.dart';

/// Contract for converting a [CategoryModel] into its export
/// representation.
///
/// No implementation exists yet.
abstract interface class CategoryExportMapper {
  CategoryExportModel toExportModel(CategoryModel category);
}
