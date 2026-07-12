import 'package:family_ledger/features/people/providers/people_query_controller.dart';
import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/features/people/utils/people_query_engine.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The people list after applying the current `peopleQueryProvider`
/// selection (search text, sort, filter) to `peopleViewModelProvider`'s
/// data.
///
/// The People screen watches only this provider for its list content, so
/// it never needs to combine loading/query state itself.
final filteredPeopleProvider = Provider<AsyncValue<List<PersonSummary>>>((ref) {
  final query = ref.watch(peopleQueryProvider);
  final summaries = ref.watch(peopleViewModelProvider);

  return summaries.whenData(
    (value) => PeopleQueryEngine.apply(
      value,
      searchText: query.searchText,
      sort: query.sort,
      filter: query.filter,
    ),
  );
});
