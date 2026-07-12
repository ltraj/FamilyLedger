import 'package:family_ledger/features/dashboard/utils/dashboard_aggregator.dart';
import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/projections/dashboard_summary.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the Dashboard's data.
final dashboardViewModelProvider =
    AsyncNotifierProvider<DashboardViewModel, DashboardSummary>(
      DashboardViewModel.new,
    );

/// Business logic for the Dashboard.
///
/// Watches three sources that already exist and are already reactive or
/// cached elsewhere — never re-fetches or recomputes what they already
/// provide:
///
/// - [peopleViewModelProvider]: each person's balance/count/last-
///   transaction-date, already computed once by the People feature. This
///   is also why the Dashboard updates automatically when transactions
///   change — `PeopleViewModel` already watches `transactionsStreamProvider`,
///   so watching it here transitively makes this reactive to transactions
///   too, with no separate subscription needed for that.
/// - [transactionsStreamProvider]: the raw transaction list, needed for
///   figures `PersonSummary` doesn't carry (this month's totals, the
///   recent-activity feed, category usage).
/// - [categoriesListProvider]: for resolving category names/colors and
///   the "most used category" insight.
///
/// All of the actual aggregation — sums, attention items, insights,
/// running balances — lives in [DashboardAggregator], a pure function
/// this just wires up and calls.
class DashboardViewModel extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    final peopleSummaries = await ref.watch(peopleViewModelProvider.future);
    final transactions = await ref.watch(transactionsStreamProvider.future);
    final categories = await ref.watch(categoriesListProvider.future);

    return DashboardAggregator.assemble(
      peopleSummaries: peopleSummaries,
      transactionsNewestFirst: transactions,
      categories: categories,
    );
  }
}
