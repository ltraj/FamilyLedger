/// Thrown when a person's name is empty (after trimming).
class EmptyPersonNameException implements Exception {
  const EmptyPersonNameException();

  String get message => 'Name is required.';

  @override
  String toString() => message;
}

/// Thrown when adding or renaming a person would duplicate an existing
/// person's name (case-insensitive, trimmed).
class DuplicatePersonNameException implements Exception {
  const DuplicatePersonNameException(this.name);

  final String name;

  String get message => 'A person named "$name" already exists.';

  @override
  String toString() => message;
}

/// Thrown when trying to delete a person who still has transaction
/// history. The UI should show [message] and suggest archiving instead.
class PersonHasTransactionsException implements Exception {
  const PersonHasTransactionsException();

  String get message =>
      'This person has transaction history and cannot '
      'be deleted. Archive instead.';

  @override
  String toString() => message;
}
