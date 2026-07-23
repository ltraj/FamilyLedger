import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/features/statement/providers/statement_period_controller.dart';
import 'package:family_ledger/features/statement/utils/statement_engine.dart';
import 'package:family_ledger/projections/statement/person_statement.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds one person's plain-language statement for the month currently
/// selected in [statementPeriodProvider].
///
/// `autoDispose` + `.family`, like `TransactionsViewModel`: each person's
/// Statement screen gets its own instance, torn down when the screen
/// closes. Reactive to this person's transactions
/// ([personTransactionsStreamProvider]) and to the selected month, so
/// paging between months or editing a transaction elsewhere in the app
/// both rebuild it with no manual refresh.
final statementViewModelProvider =
    AsyncNotifierProvider.autoDispose.family<
      StatementViewModel,
      PersonStatement,
      int
    >(StatementViewModel.new);

class StatementViewModel
    extends AutoDisposeFamilyAsyncNotifier<PersonStatement, int> {
  @override
  Future<PersonStatement> build(int personId) async {
    final person = await ref.read(peopleRepositoryProvider).getById(personId);
    if (person == null) {
      throw StateError('Person $personId not found.');
    }

    final transactions = await ref.watch(
      personTransactionsStreamProvider(personId).future,
    );
    final categories = await ref.watch(categoriesListProvider.future);
    final period = ref.watch(statementPeriodProvider(personId));
    final currencySymbol = ref.watch(currencySymbolProvider);

    return StatementEngine.build(
      person: person,
      transactions: transactions,
      period: period,
      categories: categories,
      currencySymbol: currencySymbol,
    );
  }
}
