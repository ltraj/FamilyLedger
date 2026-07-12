import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/people/models/person_filter_option.dart';
import 'package:family_ledger/features/people/models/person_sort_option.dart';
import 'package:family_ledger/projections/person_summary.dart';

/// Search/filter/sort logic for the People screen.
///
/// Kept as a pure function of its inputs, with no Riverpod dependency, so
/// it can be unit-tested directly and reused unchanged if the People
/// screen's state management ever changes.
abstract final class PeopleQueryEngine {
  static List<PersonSummary> apply(
    List<PersonSummary> summaries, {
    required String searchText,
    required PersonSortOption sort,
    required PersonFilterOption filter,
  }) {
    final matching = summaries
        .where((summary) => _matchesFilter(summary, filter))
        .where((summary) => _matchesSearch(summary, searchText))
        .toList();

    return _sorted(matching, sort);
  }

  static bool _matchesFilter(PersonSummary summary, PersonFilterOption filter) {
    final status = summary.person.status;
    final type = summary.person.type;

    return switch (filter) {
      PersonFilterOption.all => true,
      PersonFilterOption.active => status == PersonStatus.active,
      PersonFilterOption.archived => status == PersonStatus.archived,
      PersonFilterOption.permanent =>
        status == PersonStatus.active && type == PersonType.permanent,
      PersonFilterOption.temporary =>
        status == PersonStatus.active && type == PersonType.temporary,
    };
  }

  static bool _matchesSearch(PersonSummary summary, String searchText) {
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) return true;
    return summary.person.name.toLowerCase().contains(query);
  }

  static List<PersonSummary> _sorted(
    List<PersonSummary> summaries,
    PersonSortOption sort,
  ) {
    final sorted = [...summaries];

    switch (sort) {
      case PersonSortOption.customOrder:
        sorted.sort(
          (a, b) => a.person.displayOrder.compareTo(b.person.displayOrder),
        );
      case PersonSortOption.alphabetical:
        sorted.sort(
          (a, b) => a.person.name.toLowerCase().compareTo(
            b.person.name.toLowerCase(),
          ),
        );
      case PersonSortOption.newest:
        sorted.sort((a, b) => b.person.createdAt.compareTo(a.person.createdAt));
      case PersonSortOption.oldest:
        sorted.sort((a, b) => a.person.createdAt.compareTo(b.person.createdAt));
      case PersonSortOption.lastTransaction:
        sorted.sort((a, b) {
          final aDate = a.lastTransactionDate;
          final bDate = b.lastTransactionDate;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
      case PersonSortOption.highestBalance:
        sorted.sort((a, b) => b.balance.compareTo(a.balance));
      case PersonSortOption.lowestBalance:
        sorted.sort((a, b) => a.balance.compareTo(b.balance));
    }

    return sorted;
  }
}
