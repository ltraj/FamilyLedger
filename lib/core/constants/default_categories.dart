/// Definition of a default expense category seeded on first launch.
class DefaultCategoryDefinition {
  const DefaultCategoryDefinition({
    required this.name,
    required this.icon,
    required this.color,
  });

  /// Display name of the category.
  final String name;

  /// Material icon name (e.g. `bolt` for electricity).
  final String icon;

  /// Hex color string (e.g. `#FF9800`).
  final String color;
}

/// Predefined categories inserted when the database is first created.
abstract final class DefaultCategories {
  static const List<DefaultCategoryDefinition> all = [
    DefaultCategoryDefinition(
      name: 'Electricity',
      icon: 'bolt',
      color: '#FFC107',
    ),
    DefaultCategoryDefinition(name: 'WiFi', icon: 'wifi', color: '#2196F3'),
    DefaultCategoryDefinition(
      name: 'Recharge',
      icon: 'phone_android',
      color: '#9C27B0',
    ),
    DefaultCategoryDefinition(
      name: 'Medicine',
      icon: 'medical_services',
      color: '#F44336',
    ),
    DefaultCategoryDefinition(name: 'Travel', icon: 'train', color: '#009688'),
    DefaultCategoryDefinition(
      name: 'Food',
      icon: 'restaurant',
      color: '#FF5722',
    ),
    DefaultCategoryDefinition(
      name: 'Shopping',
      icon: 'shopping_cart',
      color: '#E91E63',
    ),
    DefaultCategoryDefinition(name: 'Cash', icon: 'payments', color: '#4CAF50'),
    DefaultCategoryDefinition(
      name: 'Bank',
      icon: 'account_balance',
      color: '#3F51B5',
    ),
    DefaultCategoryDefinition(name: 'UPI', icon: 'qr_code', color: '#673AB7'),
    DefaultCategoryDefinition(
      name: 'Other',
      icon: 'more_horiz',
      color: '#607D8B',
    ),
  ];
}
