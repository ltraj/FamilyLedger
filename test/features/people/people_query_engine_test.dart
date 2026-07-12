import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/people/models/person_filter_option.dart';
import 'package:family_ledger/features/people/models/person_sort_option.dart';
import 'package:family_ledger/features/people/utils/people_query_engine.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:flutter_test/flutter_test.dart';

PersonSummary _summary({
  required int id,
  required String name,
  PersonType type = PersonType.temporary,
  PersonStatus status = PersonStatus.active,
  int displayOrder = 0,
  DateTime? createdAt,
  double balance = 0,
  int transactionCount = 0,
  DateTime? lastTransactionDate,
}) {
  return PersonSummary(
    person: PersonModel(
      id: id,
      name: name,
      type: type,
      status: status,
      displayOrder: displayOrder,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      updatedAt: createdAt ?? DateTime(2026, 1, 1),
    ),
    balance: balance,
    transactionCount: transactionCount,
    lastTransactionDate: lastTransactionDate,
  );
}

void main() {
  group('PeopleQueryEngine', () {
    // Four distinct type/status combinations, with no accidental overlap,
    // so each filter test can assert an exact expected subset.
    // `active` is also this fixture set's one active permanent person.
    final active = _summary(
      id: 1,
      name: 'Nani',
      type: PersonType.permanent,
      status: PersonStatus.active,
    );
    final archived = _summary(
      id: 2,
      name: 'Sudha',
      type: PersonType.permanent,
      status: PersonStatus.archived,
    );
    final temporary = _summary(
      id: 3,
      name: 'Helper',
      type: PersonType.temporary,
      status: PersonStatus.active,
    );
    final archivedTemporary = _summary(
      id: 4,
      name: 'Old Helper',
      type: PersonType.temporary,
      status: PersonStatus.archived,
    );
    final all = [active, archived, temporary, archivedTemporary];

    test('filter: active excludes archived people', () {
      final result = PeopleQueryEngine.apply(
        all,
        searchText: '',
        sort: PersonSortOption.customOrder,
        filter: PersonFilterOption.active,
      );
      expect(result, isNot(contains(archived)));
      expect(result, contains(active));
    });

    test('filter: archived returns only archived people, of any type', () {
      final result = PeopleQueryEngine.apply(
        all,
        searchText: '',
        sort: PersonSortOption.customOrder,
        filter: PersonFilterOption.archived,
      );
      expect(result, unorderedEquals([archived, archivedTemporary]));
    });

    test(
      'filter: permanent and temporary restrict by type and imply active',
      () {
        final permanentResult = PeopleQueryEngine.apply(
          all,
          searchText: '',
          sort: PersonSortOption.customOrder,
          filter: PersonFilterOption.permanent,
        );
        expect(permanentResult, [active]);

        final temporaryResult = PeopleQueryEngine.apply(
          all,
          searchText: '',
          sort: PersonSortOption.customOrder,
          filter: PersonFilterOption.temporary,
        );
        expect(temporaryResult, [temporary]);
      },
    );

    test('filter: all includes archived and every type', () {
      final result = PeopleQueryEngine.apply(
        all,
        searchText: '',
        sort: PersonSortOption.customOrder,
        filter: PersonFilterOption.all,
      );
      expect(result, unorderedEquals(all));
    });

    test('search matches name case-insensitively and ignores whitespace', () {
      final result = PeopleQueryEngine.apply(
        all,
        searchText: '  nA  ',
        sort: PersonSortOption.customOrder,
        filter: PersonFilterOption.all,
      );
      expect(result, [active]); // "Nani" contains "na"
    });

    test('sort: customOrder respects displayOrder ascending', () {
      final b = _summary(id: 1, name: 'B', displayOrder: 2000);
      final a = _summary(id: 2, name: 'A', displayOrder: 1000);
      final result = PeopleQueryEngine.apply(
        [b, a],
        searchText: '',
        sort: PersonSortOption.customOrder,
        filter: PersonFilterOption.all,
      );
      expect(result, [a, b]);
    });

    test('sort: alphabetical is case-insensitive', () {
      final zebra = _summary(id: 1, name: 'zebra');
      final apple = _summary(id: 2, name: 'Apple');
      final result = PeopleQueryEngine.apply(
        [zebra, apple],
        searchText: '',
        sort: PersonSortOption.alphabetical,
        filter: PersonFilterOption.all,
      );
      expect(result, [apple, zebra]);
    });

    test('sort: newest and oldest order by createdAt', () {
      final older = _summary(id: 1, name: 'Older', createdAt: DateTime(2020));
      final newer = _summary(id: 2, name: 'Newer', createdAt: DateTime(2026));

      final newest = PeopleQueryEngine.apply(
        [older, newer],
        searchText: '',
        sort: PersonSortOption.newest,
        filter: PersonFilterOption.all,
      );
      expect(newest, [newer, older]);

      final oldest = PeopleQueryEngine.apply(
        [older, newer],
        searchText: '',
        sort: PersonSortOption.oldest,
        filter: PersonFilterOption.all,
      );
      expect(oldest, [older, newer]);
    });

    test('sort: lastTransaction puts no-transaction people last', () {
      final withRecent = _summary(
        id: 1,
        name: 'Recent',
        lastTransactionDate: DateTime(2026, 6),
      );
      final withOld = _summary(
        id: 2,
        name: 'Old',
        lastTransactionDate: DateTime(2026, 1),
      );
      final withNone = _summary(id: 3, name: 'None');

      final result = PeopleQueryEngine.apply(
        [withNone, withOld, withRecent],
        searchText: '',
        sort: PersonSortOption.lastTransaction,
        filter: PersonFilterOption.all,
      );
      expect(result, [withRecent, withOld, withNone]);
    });

    test('sort: highestBalance and lowestBalance order by balance', () {
      final positive = _summary(id: 1, name: 'Positive', balance: 500);
      final negative = _summary(id: 2, name: 'Negative', balance: -200);

      final highest = PeopleQueryEngine.apply(
        [negative, positive],
        searchText: '',
        sort: PersonSortOption.highestBalance,
        filter: PersonFilterOption.all,
      );
      expect(highest, [positive, negative]);

      final lowest = PeopleQueryEngine.apply(
        [negative, positive],
        searchText: '',
        sort: PersonSortOption.lowestBalance,
        filter: PersonFilterOption.all,
      );
      expect(lowest, [negative, positive]);
    });
  });
}
