/// AI- and human-readable representation of an expense category, written
/// to `categories.json` as part of an export bundle.
///
/// See `categories.json`'s entry in `schema.json` for the full meaning of
/// every field.
class CategoryExportModel {
  const CategoryExportModel({
    required this.categoryIdentifier,
    required this.categoryName,
    required this.iconIdentifier,
    required this.colorHexCode,
    required this.isSystemDefinedDefault,
    required this.recordCreatedAt,
  });

  /// Local identifier for this category at the time of export.
  final int categoryIdentifier;

  final String categoryName;

  /// Material icon identifier (e.g. `bolt`, `wifi`) used to render this
  /// category in the app. Not meaningful outside a Flutter/Material
  /// context.
  final String iconIdentifier;

  /// Hex color string (e.g. `#FF9800`) used to render this category.
  final String colorHexCode;

  /// Whether this category was created by the app itself rather than by
  /// the user.
  final bool isSystemDefinedDefault;

  final DateTime recordCreatedAt;

  Map<String, dynamic> toJson() => {
    'categoryIdentifier': categoryIdentifier,
    'categoryName': categoryName,
    'iconIdentifier': iconIdentifier,
    'colorHexCode': colorHexCode,
    'isSystemDefinedDefault': isSystemDefinedDefault,
    'recordCreatedAt': recordCreatedAt.toIso8601String(),
  };
}
