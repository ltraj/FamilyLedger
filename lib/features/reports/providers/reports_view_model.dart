import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/features/reports/providers/report_filter_controller.dart';
import 'package:family_ledger/features/reports/utils/report_engine.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/projections/reports/person_report_detail.dart';
import 'package:family_ledger/projections/reports/reports_overview.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads everything the Reports screen shows.
///
/// Reactivity comes entirely from what it watches:
///
/// - [transactionsStreamProvider] — any transaction change anywhere in
///   the app re-runs the engine, no manual invalidation.
/// - [peopleViewModelProvider] — reuses the People screen's
///   already-computed `PersonSummary` list (person + full-history
///   balance) instead of re-deriving balances, and rebuilds when people
///   are added/edited/archived.
/// - [categoriesListProvider] — category names/colors for display.
/// - [reportFilterProvider] — every filter change recomputes instantly.
/// - [currencySymbolProvider] — Section 8 insights bake a formatted amount
///   into their message text, so a currency change re-runs the engine too.
///
/// All actual computation lives in `ReportEngine`; this class only wires
/// reactive inputs to that pure function.
final reportsViewModelProvider =
    AsyncNotifierProvider<ReportsViewModel, ReportsOverview>(
      ReportsViewModel.new,
    );

class ReportsViewModel extends AsyncNotifier<ReportsOverview> {
  @override
  Future<ReportsOverview> build() async {
    final transactions = await ref.watch(transactionsStreamProvider.future);
    final peopleSummaries = await ref.watch(peopleViewModelProvider.future);
    final categories = await ref.watch(categoriesListProvider.future);
    final filter = ref.watch(reportFilterProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return ReportEngine.buildOverview(
      allTransactionsNewestFirst: transactions,
      peopleSummaries: peopleSummaries,
      categories: categories,
      filter: filter,
      currencySymbol: currencySymbol,
    );
  }
}

/// The per-person detail report, keyed by person id.
///
/// Watches [personTransactionsStreamProvider] — the person-scoped stream,
/// so it doesn't recompute when other people's transactions change — and
/// deliberately ignores [reportFilterProvider]: the detail screen always
/// shows full history (see `PersonReportDetail`). `autoDispose` for the
/// same reason as `transactionsViewModelProvider`: per-person instances
/// must not outlive their screen.
final personReportDetailProvider = AsyncNotifierProvider.autoDispose.family<
  PersonReportDetailViewModel,
  PersonReportDetail,
  int
>(PersonReportDetailViewModel.new);

class PersonReportDetailViewModel
    extends AutoDisposeFamilyAsyncNotifier<PersonReportDetail, int> {
  @override
  Future<PersonReportDetail> build(int personId) async {
    final transactions = await ref.watch(
      personTransactionsStreamProvider(personId).future,
    );
    final categories = await ref.watch(categoriesListProvider.future);
    final person = await ref.read(peopleRepositoryProvider).getById(personId);

    if (person == null) {
      throw StateError('Person $personId no longer exists.');
    }

    return ReportEngine.buildPersonDetail(
      person: person,
      personTransactionsNewestFirst: transactions,
      categories: categories,
    );
  }
}
