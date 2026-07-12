import 'dart:async';

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/features/transactions/models/transaction_exceptions.dart';
import 'package:family_ledger/features/transactions/providers/transactions_view_model.dart';
import 'package:family_ledger/projections/transaction_details.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_repositories.dart';

void main() {
  group('TransactionsViewModel', () {
    late TestRepositories repos;
    late ProviderContainer container;
    late int naniId;

    setUp(() async {
      repos = TestRepositories(await createTestDatabase());
      container = ProviderContainer(
        overrides: [
          peopleRepositoryProvider.overrideWithValue(repos.people),
          transactionRepositoryProvider.overrideWithValue(repos.transactions),
          categoryRepositoryProvider.overrideWithValue(repos.categories),
        ],
      );
      // Dispose the container (and its live watch-stream subscriptions)
      // before closing the database underneath it.
      addTearDown(repos.close);
      addTearDown(container.dispose);

      final people = await repos.people.getAll();
      naniId = people.firstWhere((p) => p.name == 'Nani').id!;
    });

    /// Reads the provider's initial state before returning its notifier.
    ///
    /// Always do this before calling a mutation method: the notifier's
    /// mutations write to the database independently of the provider's
    /// own `build()`, so calling one immediately after `container.read
    /// (provider.notifier)` — without first letting the initial `build()`
    /// establish its watch-stream subscription — races the write against
    /// the subscription setup. `personTransactionsStreamProvider`'s watch
    /// stream can end up subscribing *after* the write's change
    /// notification already fired, which then leaves it waiting
    /// indefinitely for a change that already happened.
    Future<TransactionsViewModel> primedNotifier(int personId) async {
      // The provider is autoDispose: with no listener, Riverpod may tear
      // it down between statements, leaving this helper holding a
      // disposed notifier. A throwaway listener pins it for the rest of
      // the test (the container's own dispose cleans it up).
      container.listen(
        transactionsViewModelProvider(personId),
        (_, _) {},
      );
      await container.read(transactionsViewModelProvider(personId).future);
      return container.read(transactionsViewModelProvider(personId).notifier);
    }

    /// Reads this person's current transaction details, after letting any
    /// pending reactive propagation settle.
    ///
    /// A mutation method (`addTransaction` and friends) returns as soon as
    /// its database write completes — not once the provider's own state
    /// has caught up with that write, which happens on a separate,
    /// slightly-later reactive path (write → Drift's watch stream emits →
    /// `transactionsViewModelProvider` rebuilds). In the real app this gap
    /// is invisible: the UI just watches the provider and redraws
    /// whenever that rebuild lands. A test that wants to assert on the
    /// post-mutation state has no "redraw" to wait for, so it needs an
    /// explicit yield instead — `container.read(...future)` alone can
    /// still return the pre-mutation value if called before that
    /// propagation has had a chance to run.
    Future<List<TransactionDetails>> settledDetails(int personId) async {
      await Future<void>.delayed(Duration.zero);
      return container.read(transactionsViewModelProvider(personId).future);
    }

    test('build returns an empty list for a person with no transactions', () async {
      final details = await container.read(
        transactionsViewModelProvider(naniId).future,
      );
      expect(details, isEmpty);
    });

    test('addTransaction stores it and orders the list newest first', () async {
      final notifier = await primedNotifier(naniId);

      await notifier.addTransaction(
        amount: 5000,
        transactionType: TransactionType.advanceReceived,
        date: DateTime(2026, 1, 1),
      );
      await notifier.addTransaction(
        amount: 800,
        transactionType: TransactionType.expensePaid,
        date: DateTime(2026, 1, 2),
      );

      final details = await settledDetails(naniId);

      expect(details, hasLength(2));
      expect(details.first.transaction.transactionType, TransactionType.expensePaid);
      expect(details.first.transaction.amount, 800);
      expect(details.first.runningBalanceAfter, 4200);
      expect(details.last.runningBalanceAfter, 5000);
    });

    test(
        'addTransaction rejects a non-positive amount for non-adjustment types',
        () async {
      final notifier = await primedNotifier(naniId);

      await expectLater(
        notifier.addTransaction(
          amount: 0,
          transactionType: TransactionType.advanceReceived,
          date: DateTime(2026, 1, 1),
        ),
        throwsA(isA<InvalidTransactionAmountException>()),
      );
      await expectLater(
        notifier.addTransaction(
          amount: -100,
          transactionType: TransactionType.expensePaid,
          date: DateTime(2026, 1, 1),
        ),
        throwsA(isA<InvalidTransactionAmountException>()),
      );
    });

    test('addTransaction allows a negative amount for adjustment', () async {
      final notifier = await primedNotifier(naniId);

      await notifier.addTransaction(
        amount: -200,
        transactionType: TransactionType.adjustment,
        date: DateTime(2026, 1, 1),
      );

      final details = await settledDetails(naniId);
      expect(details.single.runningBalanceAfter, -200);
    });

    test('addTransaction rejects a remark over the max length', () async {
      final notifier = await primedNotifier(naniId);
      final tooLong = 'a' * (maxTransactionRemarkLength + 1);

      await expectLater(
        notifier.addTransaction(
          amount: 100,
          transactionType: TransactionType.advanceReceived,
          remark: tooLong,
          date: DateTime(2026, 1, 1),
        ),
        throwsA(isA<RemarkTooLongException>()),
      );
    });

    test(
        'updateTransaction changes amount and recalculates running balance',
        () async {
      final notifier = await primedNotifier(naniId);
      await notifier.addTransaction(
        amount: 5000,
        transactionType: TransactionType.advanceReceived,
        date: DateTime(2026, 1, 1),
      );

      var details = await settledDetails(naniId);
      final original = details.single.transaction;

      await notifier.updateTransaction(
        original: original,
        amount: 3000,
        transactionType: TransactionType.advanceReceived,
        date: DateTime(2026, 1, 1),
      );

      details = await settledDetails(naniId);
      expect(details.single.transaction.amount, 3000);
      expect(details.single.runningBalanceAfter, 3000);
    });

    test(
        'deleteTransaction removes it and recalculates the remaining running balances',
        () async {
      final notifier = await primedNotifier(naniId);
      await notifier.addTransaction(
        amount: 5000,
        transactionType: TransactionType.advanceReceived,
        date: DateTime(2026, 1, 1),
      );
      await notifier.addTransaction(
        amount: 800,
        transactionType: TransactionType.expensePaid,
        date: DateTime(2026, 1, 2),
      );

      var details = await settledDetails(naniId);
      final advanceId = details.last.transaction.id!;

      await notifier.deleteTransaction(advanceId);

      details = await settledDetails(naniId);
      expect(details, hasLength(1));
      expect(details.single.runningBalanceAfter, -800);
    });

    test(
        'reactive: PeopleViewModel balance updates automatically when a '
        'transaction is added through a different view model, with no '
        'manual invalidation', () async {
      final before = await container.read(peopleViewModelProvider.future);
      expect(before.firstWhere((s) => s.person.id == naniId).balance, 0);

      final completer = Completer<void>();
      final subscription = container.listen(peopleViewModelProvider, (
        previous,
        next,
      ) {
        next.whenData((summaries) {
          final match = summaries.where((s) => s.person.id == naniId);
          if (match.isNotEmpty &&
              match.single.balance == 750 &&
              !completer.isCompleted) {
            completer.complete();
          }
        });
      });
      addTearDown(subscription.close);

      final notifier = await primedNotifier(naniId);
      // Added through TransactionsViewModel — peopleViewModelProvider is
      // never invalidated directly, anywhere in this test.
      await notifier.addTransaction(
        amount: 750,
        transactionType: TransactionType.advanceReceived,
        date: DateTime(2026, 1, 1),
      );

      await completer.future.timeout(const Duration(seconds: 5));

      final after = await container.read(peopleViewModelProvider.future);
      expect(after.firstWhere((s) => s.person.id == naniId).balance, 750);
    });
  });
}
