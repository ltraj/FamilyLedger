/// An expense category used to classify transactions.
class CategoryModel {
  const CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.createdAt,
  });

  /// Unique identifier. Null when the category has not yet been persisted.
  final int? id;

  /// Display name of the category.
  final String name;

  /// Material icon identifier (e.g. `bolt`, `wifi`).
  final String icon;

  /// Hex color string (e.g. `#FF9800`).
  final String color;

  /// Whether this is a system-provided default category.
  final bool isDefault;

  /// Timestamp when the record was created.
  final DateTime createdAt;

  CategoryModel copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isDefault: json['isDefault'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          color == other.color &&
          isDefault == other.isDefault &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, name, icon, color, isDefault, createdAt);
}
