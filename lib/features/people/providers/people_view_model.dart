import 'dart:math';

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/core/utils/person_display_order.dart';
import 'package:family_ledger/core/utils/transaction_aggregator.dart';
import 'package:family_ledger/features/people/models/people_exceptions.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads people together with the transaction-derived figures the People
/// screen needs (balance, transaction count, last transaction date), and
/// exposes every mutation the People screen can trigger.
final peopleViewModelProvider =
    AsyncNotifierProvider<PeopleViewModel, List<PersonSummary>>(
      PeopleViewModel.new,
    );

/// Business logic for the People screen.
///
/// Combines two data sources with different reactivity models:
///
/// - Transactions are watched reactively through
///   [transactionsStreamProvider], so this rebuilds automatically whenever
///   the `transactions` table changes anywhere in the app — including
///   from the Transaction module, which this view model has no direct
///   knowledge of — with no manual `invalidate()` call anywhere in that
///   path.
/// - People are read as a one-shot [Future] and refreshed explicitly (see
///   [_refreshAfterPeopleTableChange]) after this view model's own
///   mutations, since [PeopleRepository] doesn't expose a reactive stream
///   the way [TransactionRepository] now does. The people table is only
///   ever mutated through this view model today, so that's sufficient; if
///   another module starts mutating people directly, `PeopleRepository`
///   should grow a `watchAll()` the same way `TransactionRepository` did,
///   and this class should watch it instead of self-invalidating.
class PeopleViewModel extends AsyncNotifier<List<PersonSummary>> {
  @override
  Future<List<PersonSummary>> build() async {
    final transactions = await ref.watch(transactionsStreamProvider.future);
    final people = await ref.read(peopleRepositoryProvider).getAll();
    return _buildSummaries(people, transactions);
  }

  List<PersonSummary> _buildSummaries(
    List<PersonModel> people,
    List<TransactionModel> transactions,
  ) {
    final balances = BalanceCalculator.calculateBalancesByPerson(transactions);
    final transactionsByPerson = TransactionAggregator.groupByPerson(
      transactions,
    );

    return [
      for (final person in people)
        PersonSummary(
          person: person,
          balance: balances[person.id] ?? 0,
          transactionCount: transactionsByPerson[person.id]?.length ?? 0,
          lastTransactionDate: _latestDate(transactionsByPerson[person.id]),
        ),
    ];
  }

  DateTime? _latestDate(List<TransactionModel>? transactions) {
    if (transactions == null || transactions.isEmpty) return null;
    return transactions
        .map((transaction) => transaction.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Reloads after a mutation to the `people` table itself (add/edit/
  /// archive/restore/delete/avatar change). Only needed for that half of
  /// this view model's data — see the class doc comment. Transaction-side
  /// staleness no longer needs this at all: [build] stays fresh on its
  /// own via [transactionsStreamProvider].
  Future<void> _refreshAfterPeopleTableChange() async {
    ref.invalidateSelf();
    await future;
  }

  /// Adds a new active person, appended to the end of the custom sort
  /// order.
  ///
  /// Throws [EmptyPersonNameException] or [DuplicatePersonNameException]
  /// if [name] is invalid; nothing is written in that case.
  ///
  /// [avatarSeed] lets a caller (the add-person dialog) pass through the
  /// seed it already previewed to the user, so the saved avatar matches
  /// exactly what they saw. A fresh random seed is used if omitted.
  Future<void> addPerson({
    required String name,
    required PersonType type,
    int? avatarSeed,
  }) async {
    final trimmedName = _validatedName(name);
    final peopleRepository = ref.read(peopleRepositoryProvider);
    final existing = await peopleRepository.getAll();
    _ensureNameNotDuplicated(existing, trimmedName);

    final now = DateTime.now();
    final highestOrder = existing.isEmpty
        ? null
        : existing.map((person) => person.displayOrder).reduce(max);

    await peopleRepository.insert(
      PersonModel(
        name: trimmedName,
        type: type,
        status: PersonStatus.active,
        avatarSeed: avatarSeed ?? _randomSeed(),
        displayOrder: PersonDisplayOrder.appendAfter(highestOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _refreshAfterPeopleTableChange();
  }

  /// Updates [person]'s name and type, and optionally its avatar color.
  ///
  /// Throws [EmptyPersonNameException] or [DuplicatePersonNameException]
  /// if [name] is invalid; nothing is written in that case.
  ///
  /// [avatarSeed] lets a caller (the edit-person dialog) pass through a
  /// seed the user chose to regenerate to during that edit; the existing
  /// seed is kept if omitted.
  Future<void> updatePerson({
    required PersonModel person,
    required String name,
    required PersonType type,
    int? avatarSeed,
  }) async {
    final trimmedName = _validatedName(name);
    final peopleRepository = ref.read(peopleRepositoryProvider);
    final existing = await peopleRepository.getAll();
    _ensureNameNotDuplicated(existing, trimmedName, excludingId: person.id);

    await peopleRepository.update(
      person.copyWith(
        name: trimmedName,
        type: type,
        avatarSeed: avatarSeed,
        updatedAt: DateTime.now(),
      ),
    );

    await _refreshAfterPeopleTableChange();
  }

  /// Assigns [person] a new random avatar color immediately, keeping the
  /// same name and type. Used by the person card's quick "New avatar
  /// color" action, as distinct from choosing a new color while editing.
  Future<void> regenerateAvatarColor(PersonModel person) async {
    await ref
        .read(peopleRepositoryProvider)
        .update(
          person.copyWith(avatarSeed: _randomSeed(), updatedAt: DateTime.now()),
        );

    await _refreshAfterPeopleTableChange();
  }

  /// Archives [personId]. Archived people are hidden from the active list
  /// but keep their transaction history.
  Future<void> archivePerson(int personId) async {
    await ref.read(peopleRepositoryProvider).archive(personId);
    await _refreshAfterPeopleTableChange();
  }

  /// Restores an archived person to active, reversing [archivePerson].
  Future<void> unarchivePerson(int personId) async {
    final peopleRepository = ref.read(peopleRepositoryProvider);
    final person = await peopleRepository.getById(personId);
    if (person == null) return;

    await peopleRepository.update(
      person.copyWith(status: PersonStatus.active, updatedAt: DateTime.now()),
    );

    await _refreshAfterPeopleTableChange();
  }

  /// Permanently deletes [personId].
  ///
  /// Only people with no transaction history may be deleted — throws
  /// [PersonHasTransactionsException] otherwise, which the screen catches
  /// to show the required message and suggest archiving instead.
  Future<void> deletePerson(int personId) async {
    final transactions = await ref
        .read(transactionRepositoryProvider)
        .getByPersonId(personId);

    if (transactions.isNotEmpty) {
      throw const PersonHasTransactionsException();
    }

    await ref.read(peopleRepositoryProvider).delete(personId);
    await _refreshAfterPeopleTableChange();
  }

  String _validatedName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const EmptyPersonNameException();
    }
    return trimmed;
  }

  void _ensureNameNotDuplicated(
    List<PersonModel> existing,
    String trimmedName, {
    int? excludingId,
  }) {
    final normalized = trimmedName.toLowerCase();
    final isDuplicate = existing.any(
      (person) =>
          person.id != excludingId &&
          person.name.trim().toLowerCase() == normalized,
    );

    if (isDuplicate) {
      throw DuplicatePersonNameException(trimmedName);
    }
  }

  int _randomSeed() => Random().nextInt(1 << 31);
}
