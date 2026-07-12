import 'package:family_ledger/features/people/models/person_filter_option.dart';
import 'package:family_ledger/features/people/models/person_sort_option.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current search/sort/filter selection on the People screen.
class PeopleQuery {
  const PeopleQuery({
    this.searchText = '',
    this.sort = PersonSortOption.customOrder,
    this.filter = PersonFilterOption.active,
  });

  final String searchText;
  final PersonSortOption sort;
  final PersonFilterOption filter;

  PeopleQuery copyWith({
    String? searchText,
    PersonSortOption? sort,
    PersonFilterOption? filter,
  }) {
    return PeopleQuery(
      searchText: searchText ?? this.searchText,
      sort: sort ?? this.sort,
      filter: filter ?? this.filter,
    );
  }
}

/// Holds the People screen's search/sort/filter selection.
///
/// Deliberately separate from `PeopleViewModel`: this is transient UI
/// state (reset when the screen is disposed), while the view model owns
/// data loaded from the database. Combined into a single list by
/// `filteredPeopleProvider`.
class PeopleQueryController extends Notifier<PeopleQuery> {
  @override
  PeopleQuery build() => const PeopleQuery();

  void setSearchText(String value) {
    state = state.copyWith(searchText: value);
  }

  void setSort(PersonSortOption value) {
    state = state.copyWith(sort: value);
  }

  void setFilter(PersonFilterOption value) {
    state = state.copyWith(filter: value);
  }
}

final peopleQueryProvider =
    NotifierProvider<PeopleQueryController, PeopleQuery>(
      PeopleQueryController.new,
    );
