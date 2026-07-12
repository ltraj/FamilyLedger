import 'package:family_ledger/core/constants/enums.dart';

/// Definition of a default person seeded on first launch.
class DefaultPersonDefinition {
  const DefaultPersonDefinition({required this.name, required this.type});

  /// Display name of the person.
  final String name;

  /// Whether this is a permanent or temporary contact.
  final PersonType type;
}

/// Predefined people inserted when the database is first created.
///
/// Listed in the order they should appear by default; the seeding code
/// assigns their `displayOrder` from this list's index, so this order is
/// also their initial custom sort order.
abstract final class DefaultPeople {
  static const List<DefaultPersonDefinition> all = [
    DefaultPersonDefinition(name: 'Nani', type: PersonType.permanent),
    DefaultPersonDefinition(name: 'Sudha', type: PersonType.permanent),
  ];
}
