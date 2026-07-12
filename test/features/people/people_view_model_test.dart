import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/people/models/people_exceptions.dart';
import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_repositories.dart';

void main() {
  group('PeopleViewModel', () {
    late TestRepositories repos;
    late ProviderContainer container;

    setUp(() async {
      repos = TestRepositories(await createTestDatabase());
      container = ProviderContainer(
        overrides: [
          peopleRepositoryProvider.overrideWithValue(repos.people),
          transactionRepositoryProvider.overrideWithValue(repos.transactions),
        ],
      );
      // addTearDown runs callbacks in reverse (LIFO) order, so this
      // disposes the container — and with it, PeopleViewModel's live
      // subscription to transactionsStreamProvider's watch() query —
      // before the database underneath it closes. Registering these the
      // other way around closes the database out from under an active
      // Drift watch stream, which hangs the test run.
      addTearDown(repos.close);
      addTearDown(container.dispose);
    });

    test('build loads seeded Nani and Sudha with zero balances', () async {
      final summaries = await container.read(peopleViewModelProvider.future);

      expect(summaries, hasLength(2));
      expect(summaries.every((s) => s.balance == 0), isTrue);
      expect(summaries.every((s) => !s.hasTransactions), isTrue);
    });

    test('addPerson appends after the current highest displayOrder', () async {
      await container.read(peopleViewModelProvider.future);
      final notifier = container.read(peopleViewModelProvider.notifier);

      await notifier.addPerson(name: 'New Helper', type: PersonType.temporary);

      final summaries = await container.read(peopleViewModelProvider.future);
      final added = summaries.firstWhere((s) => s.person.name == 'New Helper');
      final others = summaries.where((s) => s.person.name != 'New Helper');

      expect(
        others.every((s) => s.person.displayOrder < added.person.displayOrder),
        isTrue,
      );
    });

    test('addPerson trims whitespace from the name', () async {
      await container.read(peopleViewModelProvider.future);
      final notifier = container.read(peopleViewModelProvider.notifier);

      await notifier.addPerson(
        name: '   Padded Name   ',
        type: PersonType.temporary,
      );

      final summaries = await container.read(peopleViewModelProvider.future);
      expect(summaries.any((s) => s.person.name == 'Padded Name'), isTrue);
    });

    test('addPerson rejects an empty name', () async {
      await container.read(peopleViewModelProvider.future);
      final notifier = container.read(peopleViewModelProvider.notifier);

      await expectLater(
        notifier.addPerson(name: '   ', type: PersonType.temporary),
        throwsA(isA<EmptyPersonNameException>()),
      );
    });

    test(
      'addPerson rejects a duplicate name, case-insensitive and trimmed',
      () async {
        await container.read(peopleViewModelProvider.future);
        final notifier = container.read(peopleViewModelProvider.notifier);

        await expectLater(
          notifier.addPerson(name: '  nani  ', type: PersonType.permanent),
          throwsA(isA<DuplicatePersonNameException>()),
        );
      },
    );

    test('updatePerson rejects renaming to another existing name', () async {
      final summaries = await container.read(peopleViewModelProvider.future);
      final sudha = summaries.firstWhere((s) => s.person.name == 'Sudha');
      final notifier = container.read(peopleViewModelProvider.notifier);

      await expectLater(
        notifier.updatePerson(
          person: sudha.person,
          name: 'Nani',
          type: sudha.person.type,
        ),
        throwsA(isA<DuplicatePersonNameException>()),
      );
    });

    test('updatePerson allows keeping the same name', () async {
      final summaries = await container.read(peopleViewModelProvider.future);
      final sudha = summaries.firstWhere((s) => s.person.name == 'Sudha');
      final notifier = container.read(peopleViewModelProvider.notifier);

      await notifier.updatePerson(
        person: sudha.person,
        name: 'Sudha',
        type: PersonType.temporary,
      );

      final updated = await container.read(peopleViewModelProvider.future);
      final updatedSudha = updated.firstWhere((s) => s.person.name == 'Sudha');
      expect(updatedSudha.person.type, PersonType.temporary);
    });

    test(
      'regenerateAvatarColor sets an explicit seed, keeping name and type',
      () async {
        final summaries = await container.read(peopleViewModelProvider.future);
        final nani = summaries.firstWhere((s) => s.person.name == 'Nani');
        final notifier = container.read(peopleViewModelProvider.notifier);

        // Nani is seeded on first install without an explicit avatarSeed, so
        // her avatar color falls back to her id (see PersonModel.
        // effectiveAvatarSeed) until a color is regenerated for the first
        // time.
        expect(nani.person.avatarSeed, isNull);

        await notifier.regenerateAvatarColor(nani.person);

        final updated = await container.read(peopleViewModelProvider.future);
        final updatedNani = updated.firstWhere((s) => s.person.name == 'Nani');
        expect(updatedNani.person.name, 'Nani');
        expect(updatedNani.person.type, nani.person.type);
        expect(updatedNani.person.avatarSeed, isNotNull);
      },
    );

    test('archivePerson then unarchivePerson round-trips status', () async {
      final summaries = await container.read(peopleViewModelProvider.future);
      final nani = summaries.firstWhere((s) => s.person.name == 'Nani');
      final notifier = container.read(peopleViewModelProvider.notifier);

      await notifier.archivePerson(nani.person.id!);
      var updated = await container.read(peopleViewModelProvider.future);
      expect(
        updated.firstWhere((s) => s.person.id == nani.person.id).person.status,
        PersonStatus.archived,
      );

      await notifier.unarchivePerson(nani.person.id!);
      updated = await container.read(peopleViewModelProvider.future);
      expect(
        updated.firstWhere((s) => s.person.id == nani.person.id).person.status,
        PersonStatus.active,
      );
    });

    test('deletePerson removes a person with no transactions', () async {
      await container.read(peopleViewModelProvider.future);
      final notifier = container.read(peopleViewModelProvider.notifier);
      await notifier.addPerson(name: 'Disposable', type: PersonType.temporary);

      var summaries = await container.read(peopleViewModelProvider.future);
      final disposable = summaries.firstWhere(
        (s) => s.person.name == 'Disposable',
      );

      await notifier.deletePerson(disposable.person.id!);

      summaries = await container.read(peopleViewModelProvider.future);
      expect(summaries.any((s) => s.person.name == 'Disposable'), isFalse);
    });

    test(
      'deletePerson throws when the person has transaction history',
      () async {
        final summaries = await container.read(peopleViewModelProvider.future);
        final nani = summaries.firstWhere((s) => s.person.name == 'Nani');
        final now = DateTime(2026, 1, 1);

        await repos.transactions.insert(
          TransactionModel(
            personId: nani.person.id!,
            amount: 100,
            transactionType: TransactionType.advanceReceived,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final notifier = container.read(peopleViewModelProvider.notifier);

        await expectLater(
          notifier.deletePerson(nani.person.id!),
          throwsA(isA<PersonHasTransactionsException>()),
        );

        final stillThere = await repos.people.getById(nani.person.id!);
        expect(stillThere, isNotNull);
      },
    );
  });
}
