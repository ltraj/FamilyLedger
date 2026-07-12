/// Ways the People screen can order the people list.
enum PersonSortOption {
  /// The user's manually customized order (`PersonModel.displayOrder`).
  ///
  /// Default sort: the list stays exactly where the user last left it,
  /// rather than jumping to an alphabetical or date-based order every time
  /// the screen opens.
  customOrder,

  alphabetical,
  newest,
  oldest,

  /// Most recent transaction date first. People with no transactions sort
  /// after everyone who has at least one.
  lastTransaction,

  highestBalance,
  lowestBalance;

  /// Label shown in the sort picker.
  String get label => switch (this) {
    PersonSortOption.customOrder => 'Custom Order',
    PersonSortOption.alphabetical => 'Alphabetical',
    PersonSortOption.newest => 'Newest',
    PersonSortOption.oldest => 'Oldest',
    PersonSortOption.lastTransaction => 'Last Transaction',
    PersonSortOption.highestBalance => 'Highest Balance',
    PersonSortOption.lowestBalance => 'Lowest Balance',
  };
}
